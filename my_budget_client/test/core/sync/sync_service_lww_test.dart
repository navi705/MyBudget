import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// Last-write-wins conflict resolution, exercised end to end through
/// [SyncService.exportNow]/[importNow] rather than by calling `_applyChange`
/// directly (it is private). Uses the `styles` table because it has no
/// foreign-key columns, so the test can focus purely on the modifiedAt
/// comparison the P2P sync engine performs on every table.
///
/// Two devices share one folder (mirrors how Syncthing hands a `.sync` file
/// to every peer watching the same directory): device A always exports,
/// device B always imports, so every assertion below is about what A's
/// change did to B's row.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase dbA;
  late AppDatabase dbB;
  late SyncService serviceA;
  late SyncService serviceB;

  Future<void> setDeviceId(AppDatabase db, String id) => db.settingsDao
      .setSetting(SettingsCompanion(key: const Value('local_device_id'), value: Value(id)));

  Future<SyncService> configuredService(AppDatabase db, String deviceId) async {
    await setDeviceId(db, deviceId);
    final service = SyncService(db);
    // startSync() sets the folder + device id and does one initial import
    // pass; stopSync() immediately kills the periodic export Timer and the
    // Directory.watch() subscription so the test controls timing exactly via
    // exportNow()/importNow() (neither of which checks _isRunning).
    await service.startSync(syncFolder.path);
    await service.stopSync();
    return service;
  }

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp('mybudget_sync_lww_');
    dbA = AppDatabase.forTesting(NativeDatabase.memory());
    dbB = AppDatabase.forTesting(NativeDatabase.memory());
    serviceA = await configuredService(dbA, 'device-a');
    serviceB = await configuredService(dbB, 'device-b');
  });

  tearDown(() async {
    await dbA.close();
    await dbB.close();
    if (await syncFolder.exists()) {
      await syncFolder.delete(recursive: true);
    }
  });

  Future<void> insertStyleOnA(String id, String name, int modifiedAt) async {
    await dbA.stylesDao.insertStyle(
      StylesCompanion.insert(
        id: Value(id),
        name: name,
        iconName: 'star',
        colorHex: '#111111',
      ),
    );
    // insertStyle() always stamps modifiedAt = DateTime.now(); override it to
    // get a precise, deterministic value for the LWW comparison, the same way
    // the record is re-read fresh at export time regardless.
    await dbA.customStatement(
      'UPDATE styles SET modified_at = ? WHERE id = ?',
      [modifiedAt, id],
    );
  }

  Future<void> insertStyleOnB(String id, String name, int modifiedAt) async {
    await dbB.stylesDao.insertStyle(
      StylesCompanion.insert(
        id: Value(id),
        name: name,
        iconName: 'star',
        colorHex: '#222222',
      ),
    );
    await dbB.customStatement(
      'UPDATE styles SET modified_at = ? WHERE id = ?',
      [modifiedAt, id],
    );
  }

  Future<Style> styleOnB(String id) =>
      (dbB.select(dbB.styles)..where((t) => t.id.equals(id))).getSingle();

  Future<Style?> styleOnBOrNull(String id) => (dbB.select(
    dbB.styles,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> syncAToB() async {
    await serviceA.exportNow();
    // PRODUCTION BUG (see REPORT): exportNow() -> _exportPendingChanges()
    // (sync_service_io.dart:243) always calls
    // syncLogDao.markExported(pendingChanges.map((e) => e.id).toList())
    // (app_database.dart:3890), which builds `WHERE id IN (...)` with one
    // bound SQL variable per pending row. With the ~283k-row ambient seed
    // backlog (dominated by exchange rates) included, that throws
    // SqliteException(1): "too many SQL variables", silently swallowed by
    // the blanket catch in _exportPendingChanges (sync_service_io.dart:381)
    // - AFTER the .sync file has already been written correctly. So the
    // .sync file this call just produced is trustworthy, but A's own
    // sync_log rows (this test's included) are never actually marked
    // exported and would be bundled again into the *next* exportNow() call
    // in the same test with a brand-new packet timestamp - which would
    // silently corrupt tests further down this file that export twice
    // (delete, then a later upsert) by re-delivering the first delete with
    // a second, later timestamp. Draining here keeps each syncAToB() call
    // isolated to the changes made since the last one, independent of that
    // unrelated bug.
    await dbA.customStatement('UPDATE sync_log SET exported = 1 WHERE exported = 0');
    await serviceB.importNow();
  }

  // Deletes carry no payload over the wire (sync_service_io.dart _applyChange
  // docs: "Deletes carry no payload, so the packet timestamp is the only
  // clock a delete has") - the receiving side's LWW comparison for a delete
  // uses the *packet's* export-time timestamp (real DateTime.now(), captured
  // in _exportPendingChanges at sync_service_io.dart:340), never the deleted
  // row's own modifiedAt column. A customStatement override of the row's
  // modifiedAt before exporting a delete has no effect on what travels or on
  // what a peer compares against - only the export's real wall-clock moment
  // matters. That timestamp is recoverable after the fact from the written
  // filename ('${deviceId}_$timestamp.sync', sync_service_io.dart:351), which
  // is how the tests below pin down the exact value a delete was compared
  // and stamped with, instead of guessing at a hand-picked integer.
  Future<int> latestExportTimestamp() async {
    final files = await syncFolder
        .list()
        .where((e) => e.path.endsWith('.sync'))
        .toList();
    var latest = 0;
    for (final f in files) {
      final name = f.uri.pathSegments.last;
      final withoutExt = name.substring(0, name.length - '.sync'.length);
      final ts = int.parse(withoutExt.substring(withoutExt.lastIndexOf('_') + 1));
      if (ts > latest) latest = ts;
    }
    return latest;
  }

  group('upsert vs upsert', () {
    test('older incoming change leaves the local row untouched', () async {
      await insertStyleOnB('s1', 'Local Name', 5000);
      await insertStyleOnA('s1', 'Incoming Older Name', 1000);

      await syncAToB();

      final style = await styleOnB('s1');
      expect(style.name, 'Local Name');
      expect(style.modifiedAt, 5000);
    });

    test('newer incoming change overwrites the local row', () async {
      await insertStyleOnB('s1', 'Local Name', 1000);
      await insertStyleOnA('s1', 'Incoming Newer Name', 5000);

      await syncAToB();

      final style = await styleOnB('s1');
      expect(style.name, 'Incoming Newer Name');
      expect(style.modifiedAt, 5000);
    });

    test('equal modifiedAt is deterministic: local wins, incoming is rejected', () async {
      await insertStyleOnB('s1', 'Local Name', 3000);
      await insertStyleOnA('s1', 'Incoming Tied Name', 3000);

      await syncAToB();

      final style = await styleOnB('s1');
      // Confirmed from sync_service_io.dart _applyChange: the upsert branch is
      // `if (localData == null) insert; else if (incoming > local) update;
      // else <local wins, save incoming to conflict history>`. A tie takes the
      // final else, so it is deterministic every run - not a race.
      expect(style.name, 'Local Name');
      expect(style.modifiedAt, 3000);
    });

    test('brand new record with no local counterpart is always inserted', () async {
      await insertStyleOnA('s-new', 'Brand New', 1);

      await syncAToB();

      final style = await styleOnB('s-new');
      expect(style.name, 'Brand New');
      expect(style.modifiedAt, 1);
    });
  });

  group('delete vs local state', () {
    test('delete older than the local row is ignored', () async {
      // The delete's comparable clock is the export's real wall-clock time
      // (see latestExportTimestamp() doc above), so "local row is newer"
      // has to be simulated by stamping B's row into the future, well past
      // whatever DateTime.now() is when A exports the delete moments later.
      final future = DateTime.now().millisecondsSinceEpoch + 10000000;
      await insertStyleOnB('s1', 'Local Name', future);
      await insertStyleOnA('s1', 'To Delete', 1000);
      await dbA.stylesDao.deleteStyle(StylesCompanion(id: const Value('s1')));

      await syncAToB();

      final style = await styleOnB('s1');
      expect(style.isDeleted, isFalse);
      expect(style.name, 'Local Name');
    });

    test('delete newer than the local row soft-deletes it', () async {
      await insertStyleOnB('s1', 'Local Name', 1000);
      await insertStyleOnA('s1', 'To Delete', 1000);
      await dbA.stylesDao.deleteStyle(StylesCompanion(id: const Value('s1')));

      await syncAToB();
      final exportedAt = await latestExportTimestamp();

      final style = await styleOnB('s1');
      expect(style.isDeleted, isTrue);
      expect(style.modifiedAt, exportedAt);
    });

    test('delete of a record never seen locally inserts a tombstone', () async {
      await insertStyleOnA('s-ghost', 'Ghost', 1000);
      await dbA.stylesDao.deleteStyle(
        StylesCompanion(id: const Value('s-ghost')),
      );

      await syncAToB();
      final exportedAt = await latestExportTimestamp();

      // getStyleById filters isDeleted = false, so read the raw row directly
      // to see the tombstone.
      final tombstone = await (dbB.select(
        dbB.styles,
      )..where((t) => t.id.equals('s-ghost'))).getSingleOrNull();
      expect(tombstone, isNotNull);
      expect(tombstone!.isDeleted, isTrue);
      expect(tombstone.modifiedAt, exportedAt);
    });

    test('an older upsert arriving after a tombstone is rejected, not resurrected', () async {
      // First sync: B learns the record was deleted. The tombstone's clock
      // is the delete packet's real export timestamp (see
      // latestExportTimestamp() doc above), not any hand-picked integer, so
      // it has to be read back from the written file before it can be beaten
      // or missed on purpose below.
      await insertStyleOnA('s1', 'Deleted Elsewhere', 1000);
      await dbA.stylesDao.deleteStyle(StylesCompanion(id: const Value('s1')));
      await syncAToB();
      expect((await styleOnBOrNull('s1'))!.isDeleted, isTrue);
      final deletedAt = await latestExportTimestamp();

      // Second sync: A produces a stale upsert (modifiedAt < deletedAt) for
      // the same id - e.g. a third device's older edit propagating late.
      // A already has this row locally (soft-deleted by the delete above),
      // so this must be an update, not another insertStyle() - the row's id
      // is still present and a second plain INSERT would violate the
      // primary-key UNIQUE constraint.
      await dbA.stylesDao.updateStyle(
        StylesCompanion(
          id: const Value('s1'),
          name: const Value('Stale Resurrection Attempt'),
          iconName: const Value('star'),
          colorHex: const Value('#333333'),
          isDeleted: const Value(false),
          modifiedAt: Value(deletedAt - 1000),
        ),
      );
      await syncAToB();

      final style = await styleOnB('s1');
      expect(style.isDeleted, isTrue, reason: 'a stale upsert must not resurrect a tombstoned record');
    });

    test('a newer upsert arriving after a tombstone does resurrect the record', () async {
      await insertStyleOnA('s1', 'Deleted Elsewhere', 1000);
      await dbA.stylesDao.deleteStyle(StylesCompanion(id: const Value('s1')));
      await syncAToB();
      expect((await styleOnBOrNull('s1'))!.isDeleted, isTrue);
      final deletedAt = await latestExportTimestamp();

      // A already has this row locally (soft-deleted above); resurrect it via
      // an update, not another insertStyle() - see the sibling test above for
      // why a second plain INSERT would fail.
      await dbA.stylesDao.updateStyle(
        StylesCompanion(
          id: const Value('s1'),
          name: const Value('Genuinely Newer'),
          iconName: const Value('star'),
          colorHex: const Value('#444444'),
          isDeleted: const Value(false),
          modifiedAt: Value(deletedAt + 1000),
        ),
      );
      await syncAToB();

      final style = await styleOnB('s1');
      expect(style.isDeleted, isFalse);
      expect(style.name, 'Genuinely Newer');
      expect(style.modifiedAt, deletedAt + 1000);
    });
  });
}
