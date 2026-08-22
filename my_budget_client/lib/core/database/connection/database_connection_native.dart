import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

/// Where a debug build used to keep its database.
///
/// `getApplicationDocumentsDirectory()` is the user's own Documents folder on
/// desktop - not a place an app should be dropping a 70 MB SQLite file, and not
/// the folder the release build uses. The split meant a debug run and an
/// installed release run saw two different databases while sharing one
/// `shared_preferences.json`, so settings and data disagreed with each other.
Future<File> _legacyDebugDatabaseFile() async {
  final legacyFolder = await getApplicationDocumentsDirectory();
  return File(p.join(legacyFolder.path, 'db.sqlite'));
}

/// Moves a debug database left behind by an older build into the one location
/// both builds now read.
///
/// Only runs when there is nothing to overwrite. If both files exist the two
/// builds have diverged and only a human can say which history is the real
/// one, so this leaves them both alone and says so.
Future<void> _migrateLegacyDebugDatabase(String targetPath) async {
  try {
    final target = File(targetPath);
    if (await target.exists()) {
      final legacy = await _legacyDebugDatabaseFile();
      if (await legacy.exists()) {
        debugPrint(
          '[DB] Two databases exist: ${legacy.path} (legacy debug location) '
          'and $targetPath (current). Using the current one; the legacy file '
          'is left untouched.',
        );
      }
      return;
    }

    final legacy = await _legacyDebugDatabaseFile();
    if (!await legacy.exists()) return;

    await target.parent.create(recursive: true);
    // The write-ahead log and shared-memory files belong to the database; a
    // database copied without its -wal is missing every committed transaction
    // that has not been checkpointed yet.
    for (final suffix in const ['', '-wal', '-shm']) {
      final source = File('${legacy.path}$suffix');
      if (await source.exists()) {
        await source.copy('$targetPath$suffix');
      }
    }
    debugPrint(
      '[DB] Migrated legacy debug database ${legacy.path} -> $targetPath',
    );
  } catch (e) {
    // A failed migration must not stop the app from opening a database - the
    // worst case is an empty one, which is what the user had anyway.
    debugPrint('[DB] Legacy database migration skipped: $e');
  }
}

QueryExecutor openConnection() {
  debugPrint('[DB_DEBUG] Using NATIVE openConnection');
  debugPrint('[DB_DEBUG] Creating driftDatabase...');
  final executor = driftDatabase(
    name: 'my_budget_db',
    native: DriftNativeOptions(
      databasePath: () async {
        debugPrint('[DB_DEBUG] databasePath callback START');
        // Same folder in debug and in release. A debug build that reads a
        // different database from the installed one turns every "is this bug
        // real?" question into a question about which file is being read.
        final dbFolder = await getApplicationSupportDirectory();
        debugPrint(
          '[DB_DEBUG] databasePath: getApplicationSupportDirectory OK: ${dbFolder.path}',
        );
        final path = p.join(dbFolder.path, 'db.sqlite');
        await _migrateLegacyDebugDatabase(path);
        debugPrint('[DB_DEBUG] databasePath callback END: $path');
        return path;
      },
    ),
  );
  debugPrint(
    '[DB_DEBUG] driftDatabase created (executor ready, connection not yet open)',
  );
  return executor;
}
