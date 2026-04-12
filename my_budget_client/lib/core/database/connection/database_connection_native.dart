import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

QueryExecutor openConnection() {
  debugPrint('[DB_DEBUG] Using NATIVE openConnection');
  debugPrint('[DB_DEBUG] Creating driftDatabase...');
  final executor = driftDatabase(
    name: 'my_budget_db',
    native: DriftNativeOptions(
      databasePath: () async {
        debugPrint('[DB_DEBUG] databasePath callback START');
        final Directory dbFolder;
        if (kDebugMode) {
          debugPrint('[DB_DEBUG] databasePath: calling getApplicationDocumentsDirectory...');
          dbFolder = await getApplicationDocumentsDirectory();
          debugPrint('[DB_DEBUG] databasePath: getApplicationDocumentsDirectory OK: ${dbFolder.path}');
        } else {
          debugPrint('[DB_DEBUG] databasePath: calling getApplicationSupportDirectory...');
          dbFolder = await getApplicationSupportDirectory();
          debugPrint('[DB_DEBUG] databasePath: getApplicationSupportDirectory OK: ${dbFolder.path}');
        }
        final path = p.join(dbFolder.path, 'db.sqlite');
        debugPrint('[DB_DEBUG] databasePath callback END: $path');
        return path;
      },
    ),
  );
  debugPrint('[DB_DEBUG] driftDatabase created (executor ready, connection not yet open)');
  return executor;
}
