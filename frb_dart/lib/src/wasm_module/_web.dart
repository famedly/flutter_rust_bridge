import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_rust_bridge/src/platform_utils/_web.dart';
import 'package:web/web.dart' as web;

/// {@macro flutter_rust_bridge.internal}
Future<void> initializeWasmModule({
  required String root,
  String wasmBindgenName = 'wasm_bindgen',
}) async {
  _ensureCrossOriginIsolated();

  final script = web.HTMLScriptElement()..src = '$root.js';
  web.document.head!.append(script);

  await script.onLoad.first;

  jsEval('window.$wasmBindgenName = $wasmBindgenName');

  final jsObject = web.window.getProperty(wasmBindgenName.toJS) as JSObject;
  final wasmBindgen = _JSWasmBindgen(jsObject);
  await wasmBindgen('${root}_bg.wasm'.toJS).toDart;
}

/// Expected Worker protocol version — must match `PROTOCOL_VERSION` in
/// `frb_worker.js`. Bump this whenever the message protocol changes.
const _kExpectedProtocolVersion = 1;

/// How long to wait for the Worker to report `ready` before giving up.
const _kWorkerInitTimeout = Duration(seconds: 30);

/// Result of initializing the WASM module inside a Dedicated Web Worker.
typedef WorkerInitResult = ({web.Worker worker, int contentHash});

/// Initialize the WASM module inside a Dedicated Web Worker.
///
/// This enables APIs that require Worker context:
/// - OPFS `FileSystemSyncAccessHandle` (for SQLite/sahpool)
/// - `Atomics.wait` (for Rust mutex/rwlock)
///
/// Returns the [web.Worker] together with the Rust content hash reported by
/// the Worker. The caller is responsible for routing FRB dispatch calls
/// through the Worker via postMessage.
///
/// Additionally installs a JS Proxy on `window.wasm_bindgen` so that generated
/// code (e.g. `RustLibWire`) that calls `wasmModule.rust_arc_*` transparently
/// routes those calls through the Worker instead of trying to call WASM
/// functions that do not exist on the main thread.
Future<WorkerInitResult> initializeWasmModuleInWorker({
  required String root,
  required String workerScriptUrl,
}) async {
  _ensureCrossOriginIsolated();

  final worker = web.Worker(workerScriptUrl.toJS);

  final readyCompleter = Completer<int>();

  final onMessage = (web.MessageEvent event) {
    final data = event.data;
    if (data == null || readyCompleter.isCompleted) return;
    final obj = data as JSObject;
    if (_stringProp(obj, 'type') != 'ready') return;

    final version =
        (obj.getProperty('protocolVersion'.toJS) as JSNumber?)?.toDartInt ?? -1;
    if (version != _kExpectedProtocolVersion) {
      readyCompleter.completeError(
        StateError(
          'FRB Worker protocol mismatch: expected v$_kExpectedProtocolVersion, '
          'got v$version. Rebuild the Worker (frb_worker.js).',
        ),
      );
      return;
    }
    final contentHash =
        (obj.getProperty('contentHash'.toJS) as JSNumber).toDartInt;
    readyCompleter.complete(contentHash);
  }.toJS;

  worker.addEventListener('message', onMessage);

  // Install a persistent error listener that logs Worker-side errors to the
  // browser console (errors would otherwise be silently lost).
  _installWorkerErrorListener(worker);

  // URLs are resolved by the Worker relative to the current page.
  final initMsg = <String, dynamic>{
    'type': 'init',
    'jsUrl': '$root.js',
    'wasmUrl': '${root}_bg.wasm',
  }.jsify();
  worker.postMessage(initMsg);

  final int contentHash;
  try {
    contentHash = await readyCompleter.future.timeout(
      _kWorkerInitTimeout,
      onTimeout: () => throw StateError(
        'FRB Worker failed to initialize within '
        '${_kWorkerInitTimeout.inSeconds} seconds',
      ),
    );
  } catch (_) {
    // Clean up the half-initialized Worker so it does not leak.
    worker.terminate();
    rethrow;
  } finally {
    worker.removeEventListener('message', onMessage);
  }

  // Install a JS Proxy on window.wasm_bindgen that intercepts rust_arc_* calls
  // and routes them through the Worker. This makes generated RustLibWire code
  // work unchanged — `wasmModule.rust_arc_increment/decrement_strong_count_*`
  // becomes a fire-and-forget postMessage to the Worker. postMessage ordering
  // guarantees the arc op executes before any subsequent FFI call dispatched
  // to the same Worker.
  _installWasmBindgenProxy(worker, contentHash);

  return (worker: worker, contentHash: contentHash);
}

/// Reads a string property from [obj], or `null` if absent / not a string.
String? _stringProp(JSObject obj, String name) {
  final value = obj.getProperty(name.toJS);
  if (value == null || !value.typeofEquals('string')) return null;
  return (value as JSString).toDart;
}

/// Creates a JS Proxy on `window.wasm_bindgen` that intercepts property
/// access.  Any property starting with `rust_arc_` returns a function
/// that sends a `{ type: 'arcOp', fnName, ptr }` message to the Worker.
/// All other properties return `undefined` (they shouldn't be accessed
/// on the main thread in Worker mode anyway).
///
/// Built entirely via Dart's `dart:js_interop` — no `eval()`, CSP-safe.
void _installWasmBindgenProxy(web.Worker worker, int contentHash) {
  final workerJs = worker as JSObject;

  // The Proxy 'get' trap: intercepts property access on the target object.
  // Returns a forwarding function for `rust_arc_*` properties,
  // the content hash for `frb_get_rust_content_hash`, and undefined
  // for everything else.
  JSAny? getTrap(JSObject target, JSAny prop, JSObject receiver) {
    // Symbols are not strings — ignore them.
    if (prop.typeofEquals('string')) {
      final name = (prop as JSString).toDart;
      if (name.startsWith('rust_arc_')) {
        // Return a one-arg function that routes the arc op to the Worker.
        return ((JSAny ptr) {
          final msg = JSObject();
          msg.setProperty('type'.toJS, 'arcOp'.toJS);
          msg.setProperty('fnName'.toJS, name.toJS);
          msg.setProperty('ptr'.toJS, ptr);
          workerJs.callMethod('postMessage'.toJS, msg);
        }).toJS;
      }
      // Content hash: return a no-arg function that returns the hash
      // received during Worker init.  This lets the FRB content-hash
      // sanity check pass without calling into the WASM module on the
      // main thread.
      if (name == 'frb_get_rust_content_hash') {
        return (() => contentHash.toJS).toJS;
      }
    }
    return null;
  }

  // Build the handler object with the 'get' trap.
  final handler = JSObject();
  handler.setProperty('get'.toJS, getTrap.toJS);

  // Construct the Proxy via `new Proxy({}, handler)`.
  final proxyConstructor =
      globalContext.getProperty('Proxy'.toJS) as JSFunction;
  final proxy =
      proxyConstructor.callAsConstructor<JSObject>(JSObject(), handler);

  // Install as `window.wasm_bindgen` so generated RustLibWire code
  // (`@JS('wasm_bindgen') external ...`) finds it.
  web.window.setProperty('wasm_bindgen'.toJS, proxy);
}

/// Listens for `{ type: 'error' }` messages from the Worker and logs them
/// to the browser console.  Without this, Worker-side exceptions in arcOp
/// or other fire-and-forget messages would be silently lost.
void _installWorkerErrorListener(web.Worker worker) {
  worker.addEventListener(
    'message',
    ((web.MessageEvent event) {
      final data = event.data;
      if (data == null) return;
      final jsObj = data as JSObject;
      if (_stringProp(jsObj, 'type') != 'error') return;
      final source = _stringProp(jsObj, 'source') ?? 'unknown';
      final message = _stringProp(jsObj, 'message') ?? 'no message';
      web.console.error('FRB Worker error [$source]: $message'.toJS);
    }).toJS,
  );
}

void _ensureCrossOriginIsolated() {
  switch (crossOriginIsolated) {
    case false:
      web.console.warn(
        'Warning: Buffers cannot be shared due to missing cross-origin headers. Please refer to https://fzyzcjy.github.io/flutter_rust_bridge/manual/miscellaneous/web-cross-origin for details.'
            .toJS,
      );
      return;
    case true:
      return;
    case null:
      web.console.warn(
        'Warning: crossOriginIsolated is null, browser might not support buffer sharing.'
            .toJS,
      );
      return;
  }
}

extension type _JSWasmBindgen(JSObject _) implements JSObject {
  @JS()
  external JSPromise call(JSAny? arg);
}
