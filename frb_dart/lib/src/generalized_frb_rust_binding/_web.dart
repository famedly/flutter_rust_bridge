// ignore_for_file: non_constant_identifier_names

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_rust_bridge/src/generalized_uint8list/_web.dart';
import 'package:flutter_rust_bridge/src/platform_types/_web.dart';
import 'package:web/web.dart' as web;

/// {@macro flutter_rust_bridge.only_for_generated_code}
class GeneralizedFrbRustBinding {
  final String _wasmBindgenName;
  final web.Worker? _worker;
  final int? _workerContentHash;

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  GeneralizedFrbRustBinding(ExternalLibrary externalLibrary)
    : _wasmBindgenName = externalLibrary.wasmBindgenName,
      _worker = externalLibrary.worker,
      _workerContentHash = externalLibrary.workerContentHash;

  bool get _isWorkerMode => _worker != null;

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
        funcId,
        port,
        ptr,
        rustVecLen,
        dataLen,
      );
    }
  }

  void _workerDispatchPrimary({
    required int funcId,
    required NativePortType port,
    required PlatformGeneralizedUint8ListPtr ptr,
    required int rustVecLen,
    required int dataLen,
  }) {
    // Copy exactly the relevant bytes into a fresh, transferable ArrayBuffer.
    // We must not transfer `ptr`'s underlying buffer directly: it may be a
    // view with a non-zero offset into a larger (possibly reused) buffer, and
    // transferring would detach that buffer on the main thread.
    final buffer = _toTransferableBuffer(ptr);

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
      final buffer = _toTransferableBuffer(ptr);

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
    if (_isWorkerMode) {
      // The hash is reported by the Worker during initialization, since the
      // WASM module cannot be queried from the main thread in Worker mode.
      return _workerContentHash!;
    }
    return _wasmBindgen.frb_get_rust_content_hash();
  }

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  PlatformPointer dartOpaqueDart2RustEncode(
    Object object,
    NativePortType dartHandlerPort,
  ) => _isWorkerMode
      ? throw UnsupportedError('Dart opaques are not supported in Worker mode')
      : _wasmBindgen.frb_dart_opaque_dart2rust_encode(
          object.toExternalReference,
          dartHandlerPort,
        );

  /// {@macro flutter_rust_bridge.only_for_generated_code}
  Object dartOpaqueRust2DartDecode(int ptr) => _isWorkerMode
      ? throw UnsupportedError('Dart opaques are not supported in Worker mode')
      : _wasmBindgen.frb_dart_opaque_rust2dart_decode(ptr).toDartObject!;

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

  /// Copies the bytes referenced by [ptr] into a fresh [JSArrayBuffer] that is
  /// safe to put on a postMessage transfer list.
  JSArrayBuffer _toTransferableBuffer(PlatformGeneralizedUint8ListPtr ptr) {
    final view = ptr.toDart;
    final copy = Uint8List.fromList(view);
    return copy.buffer.toJS;
  }

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
