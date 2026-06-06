import 'dart:async';

import 'package:flutter_rust_bridge/src/loader/_common.dart';
import 'package:flutter_rust_bridge/src/platform_types/_web.dart';
import 'package:flutter_rust_bridge/src/wasm_module/_web.dart';

/// See `loadExternalLibrary` in the counterpart `_io.dart` for doc
FutureOr<ExternalLibrary> loadExternalLibrary(
  ExternalLibraryLoaderConfig config,
) async {
  return loadExternalLibraryRaw(
    moduleRoot: '${config.webPrefix}${config.stem}',
    wasmBindgenName: config.wasmBindgenName,
  );
}

/// Please see `loadExternalLibrary` for details
Future<ExternalLibrary> loadExternalLibraryRaw({
  required String moduleRoot,
  String wasmBindgenName = 'wasm_bindgen',
}) async {
  await initializeWasmModule(
    root: moduleRoot,
    wasmBindgenName: wasmBindgenName,
  );
  return ExternalLibrary(
    debugInfo: 'moduleRoot=$moduleRoot',
    wasmBindgenName: wasmBindgenName,
  );
}

/// Load the WASM module inside a Dedicated Web Worker.
///
/// This enables OPFS (FileSystemSyncAccessHandle) and Atomics.wait
/// inside the Worker context, which are blocked on the main thread.
///
/// [workerScriptUrl] is the URL to the Worker JS entry point
/// (e.g. 'frb_worker.js').
Future<ExternalLibrary> loadExternalLibraryInWorker({
  required String moduleRoot,
  required String workerScriptUrl,
  String wasmBindgenName = 'wasm_bindgen',
}) async {
  final result = await initializeWasmModuleInWorker(
    root: moduleRoot,
    workerScriptUrl: workerScriptUrl,
  );
  return ExternalLibrary(
    debugInfo: 'moduleRoot=$moduleRoot (worker)',
    wasmBindgenName: wasmBindgenName,
    worker: result.worker,
    workerContentHash: result.contentHash,
  );
}
