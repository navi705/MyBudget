import 'package:drift/wasm.dart';

/// This is the drift worker entry point for web.
/// It's compiled to JavaScript and used by the web database connection.
/// Compile with: dart compile js -O4 web/drift_worker.dart -o web/drift_worker.js
void main() => WasmDatabase.workerMainForOpen();
