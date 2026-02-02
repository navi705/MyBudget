import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

QueryExecutor openConnection() {
  debugPrint('[DB_DEBUG] Using NATIVE openConnection');
  return driftDatabase(
    name: 'my_budget_db',
    native: DriftNativeOptions(
      databasePath: () async {
        final Directory dbFolder;
        if (kDebugMode) {
          dbFolder = await getApplicationDocumentsDirectory();
        } else {
          dbFolder = await getApplicationSupportDirectory();
        }
        return p.join(dbFolder.path, 'db.sqlite');
      },
    ),
  );
}
