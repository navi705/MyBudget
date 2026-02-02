import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show debugPrint;

QueryExecutor openConnection() {
  debugPrint('[DB_DEBUG_WEB] Using WEB openConnection');
  debugPrint('[DB_DEBUG_WEB] sqlite3Wasm: sqlite3.wasm');
  debugPrint('[DB_DEBUG_WEB] driftWorker: drift_worker.js');

  return driftDatabase(
    name: 'my_budget_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
      onResult: (result) {
        debugPrint('[DB_DEBUG_WEB] Database opened successfully!');
        debugPrint('[DB_DEBUG_WEB] Storage: ${result.chosenImplementation}');
        debugPrint(
          '[DB_DEBUG_WEB] Missing features: ${result.missingFeatures}',
        );
      },
    ),
  );
}
