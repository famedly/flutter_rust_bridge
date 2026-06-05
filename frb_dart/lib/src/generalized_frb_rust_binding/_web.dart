// ignore_for_file: non_constant_identifier_names, undefined_getter, unused_field, prefer_final_fields

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_rust_bridge/src/generalized_uint8list/generalized_uint8list.dart';
import 'package:flutter_rust_bridge/src/platform_types/_web.dart';
import 'package:web/web.dart' as web;

/// {@macro flutter_rust_bridge.only_for_generated_code}
class GeneralizedFrbRustBinding {
  final String _wasmBindgenName;
  final web.Worker? _worker;
  int _syncIdCounter = 0;
  final Map<int, Completer<JSArrayBuffer>> _pendingSyncCalls = {};

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  GeneralizedFrbRustBinding(ExternalLibrary externalLibrary)
      : _wasmBindgenName = externalLibrary.wasmBindgenName,
        _worker = externalLibrary.worker {
    if (_worker != null) {
      _setupWorkerSyncHandler();
    }
  }

  bool get _isWorkerMode => _worker != null;

  void _setupWorkerSyncHandler() {
    _worker!.addEventListener(
      'message',
      ((web.MessageEvent event) {
        final data = event.data as JSObject;
        final type = (data.getProperty('type'.toJS) as JSString).toDart;
        if (type == 'syncResult') {
          final id = (data.getProperty('id'.toJS) as JSNumber).toDartInt;
          final buffer =
              data.getProperty('buffer'.toJS) as JSArrayBuffer;
          _pendingSyncCalls.remove(id)?.complete(buffer);
        }
      }).toJS,
    );
  }

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  void storeDartPostCObject() {}

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  void initFrbDartApiDl() {}

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  void initShutdownWatcher() {}

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  void pdeFfiDispatcherPrimary({
    required int funcId,
    required NativePortType port,
    required PlatformGeneralizedUint8ListPtr ptr,
    required int rustVecLen,
    required int dataLen,
  }) {
    if (_isWorkerMode) {
      _workerDispatchPrimary(
        funcId: funcId,
        port: port,
        ptr: ptr,
        rustVecLen: rustVecLen,
        dataLen: dataLen,
      );
    } else {
      _wasmBindgen.frb_pde_ffi_dispatcher_primary(
          funcId, port, ptr, rustVecLen, dataLen);
    }
  }

  void _workerDispatchPrimary({
    required int funcId,
    required NativePortType port,
    required PlatformGeneralizedUint8ListPtr ptr,
    required int rustVecLen,
    required int dataLen,
  }) {
    // Copy the Uint8Array data into a transferable ArrayBuffer
    final dartBytes = ptr.toDart;
    final buffer = dartBytes.buffer.toJS;

    final msg = JSObject();
    msg.setProperty('type'.toJS, 'call'.toJS);
    msg.setProperty('funcId'.toJS, funcId.toJS);
    msg.setProperty('buffer'.toJS, buffer);
    msg.setProperty('rustVecLen'.toJS, rustVecLen.toJS);
    msg.setProperty('dataLen'.toJS, dataLen.toJS);

    // Port must be a MessagePort to be transferable
    if (port.isA<web.MessagePort>()) {
      final transferList = <JSObject>[buffer, port as web.MessagePort].toJS;
      _worker!.postMessage(msg, transferList);
    } else {
      // BroadcastChannel — not transferable, pass by name
      // Worker needs to create its own BroadcastChannel
      final bc = port as web.BroadcastChannel;
      msg.setProperty('broadcastChannelName'.toJS, bc.name.toJS);
      final transferList = <JSObject>[buffer].toJS;
      _worker!.postMessage(msg, transferList);
    }
  }

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  WireSyncRust2DartSse pdeFfiDispatcherSync({
    required int funcId,
    required PlatformGeneralizedUint8ListPtr ptr,
    required int rustVecLen,
    required int dataLen,
  }) {
    if (_isWorkerMode) {
      // Sync calls cannot block the main thread waiting for a Worker response.
      // Mark these functions as async in your Rust code instead of #[frb(sync)].
      throw UnsupportedError(
        'Sync FFI calls are not supported in Worker mode. '
        'Remove #[frb(sync)] from the Rust function or use async instead. '
        'funcId=$funcId',
      );
    }
    return _wasmBindgen.frb_pde_ffi_dispatcher_sync(
      funcId,
      ptr,
      rustVecLen,
      dataLen,
    );
  }

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  void dartFnDeliverOutput({
    required int callId,
    required PlatformGeneralizedUint8ListPtr ptr,
    required int rustVecLen,
    required int dataLen,
  }) {
    if (_isWorkerMode) {
      final dartBytes = ptr.toDart;
      final buffer = dartBytes.buffer.toJS;

      final msg = JSObject();
      msg.setProperty('type'.toJS, 'deliverOutput'.toJS);
      msg.setProperty('callId'.toJS, callId.toJS);
      msg.setProperty('buffer'.toJS, buffer);
      msg.setProperty('rustVecLen'.toJS, rustVecLen.toJS);
      msg.setProperty('dataLen'.toJS, dataLen.toJS);

      _worker!.postMessage(msg, [buffer].toJS);
      return;
    }
    return _wasmBindgen.frb_dart_fn_deliver_output(
      callId,
      ptr,
      rustVecLen,
      dataLen,
    );
  }

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  int getRustContentHash() {
    web.console.log('getRustContentHash: _isWorkerMode=$_isWorkerMode, _worker=$_worker'.toJS);
    if (_isWorkerMode) {
      // Content hash was stored during Worker init
      final rawProp = web.window.getProperty('_frb_worker_content_hash'.toJS);
      web.console.log('getRustContentHash: rawProp=$rawProp, type=${rawProp.runtimeType}'.toJS);
      final hash = rawProp as JSNumber;
      final result = hash.toDartInt;
      web.console.log('getRustContentHash: returning $result'.toJS);
      return result;
    }
    return _wasmBindgen.frb_get_rust_content_hash();
  }

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  PlatformPointer dartOpaqueDart2RustEncode(
          Object object, NativePortType dartHandlerPort) =>
      _isWorkerMode
          ? throw UnsupportedError(
              'Dart opaques are not supported in Worker mode')
          : _wasmBindgen.frb_dart_opaque_dart2rust_encode(
              object.jsify()!, dartHandlerPort);

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  Object dartOpaqueRust2DartDecode(int ptr) => _isWorkerMode
      ? throw UnsupportedError(
          'Dart opaques are not supported in Worker mode')
      : _wasmBindgen.frb_dart_opaque_rust2dart_decode(ptr).dartify()!;

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  void dartOpaqueDropThreadBoxPersistentHandle(int ptr) {
    if (_isWorkerMode) {
      final msg = JSObject();
      msg.setProperty('type'.toJS, 'dartOpaqueDrop'.toJS);
      msg.setProperty('ptr'.toJS, ptr.toJS);
      _worker!.postMessage(msg);
      return;
    }
    _wasmBindgen.frb_dart_opaque_drop_thread_box_persistent_handle(ptr);
  }

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  void freeWireSyncRust2DartDco(WireSyncRust2DartDco raw) {}

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  void freeWireSyncRust2DartSse(WireSyncRust2DartSse raw) {}

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  _JSWasmBindgen get _wasmBindgen {
    final jsObject = web.window.getProperty(_wasmBindgenName.toJS) as JSObject;
    return _JSWasmBindgen(jsObject);
  }
}

/// {@macro flutter_rust_bridge.only_for_generated_code}
extension type _JSWasmBindgen(JSObject _) implements JSObject {
  /// {@macro flutter_rust_bridge.only_for_generated_code}
  @JS("frb_pde_ffi_dispatcher_primary")
  external void frb_pde_ffi_dispatcher_primary(
    int funcId,
    NativePortType port,
    PlatformGeneralizedUint8ListPtr ptr,
    int rustVecLen,
    int dataLen,
  );

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  @JS("frb_pde_ffi_dispatcher_sync")
  external WireSyncRust2DartSse frb_pde_ffi_dispatcher_sync(
    int funcId,
    PlatformGeneralizedUint8ListPtr ptr,
    int rustVecLen,
    int dataLen,
  );

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  @JS("frb_dart_fn_deliver_output")
  external void frb_dart_fn_deliver_output(
    int callId,
    PlatformGeneralizedUint8ListPtr ptr,
    int rustVecLen,
    int dataLen,
  );

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  @JS("frb_get_rust_content_hash")
  external int frb_get_rust_content_hash();

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  @JS("frb_dart_opaque_dart2rust_encode")
  external int frb_dart_opaque_dart2rust_encode(
    ExternalDartReference<Object?> object,
    NativePortType dartHandlerPort,
  );

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  @JS("frb_dart_opaque_rust2dart_decode")
  external ExternalDartReference<Object?> frb_dart_opaque_rust2dart_decode(
    int ptr,
  );

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  @JS("frb_dart_opaque_drop_thread_box_persistent_handle")
  external void frb_dart_opaque_drop_thread_box_persistent_handle(int ptr);
}
