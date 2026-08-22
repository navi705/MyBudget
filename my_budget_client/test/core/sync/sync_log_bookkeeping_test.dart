import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// sync_log export bookkeeping: a row must only be marked exported once its
/// change has actually landed in a written `.sync` file, a failed write must
/// leave it pending for retry, and a delete must produce a log row that a
/// peer can apply.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase db;
  late SyncService service;

  Future<void> setDeviceId(AppDatabase db, String id) =>
      db.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('local_device_id'),
          value: Value(id),
        ),
      );

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp(
      'mybudget_sync_bookkeeping_',
    );
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await setDeviceId(db, 'device-a');
    service = SyncService(db);
    await service.startSync(syncFolder.path);
    await service.stopSync();

    // Drain the ambient sync_log backlog left by unconditional DB seeding
    // (~283k rows, dominated by exchange rates) via raw SQL, not exportNow().
    // PRODUCTION BUG (see REPORT): SyncService.exportNow() ->
    // _exportPendingChanges() (sync_service_io.dart:243) always calls
    // syncLogDao.markExported(pendingChanges.map((e) => e.id).toList())
    // (app_database.dart:3890), which builds `WHERE id IN (...)` with one
    // bound SQL variable per pending row. With the full seed backlog
    // included, that throws SqliteException(1): "too many SQL variables",
    // which the blanket `catch (e, stack)` in _exportPendingChanges
    // (sync_service_io.dart:381) silently swallows (debugPrint only, no
    // rethrow) - AFTER the .sync file has already been written
    // (sync_service_io.dart:357, which runs before markExported at :361).
    // So every real exportNow() call in this DB's lifetime writes a correct
    // file but then fails to mark anything exported, and the backlog only
    // grows. That is a real, separate bug from what this file's tests are
    // about (bookkeeping semantics for changes the test itself makes), so
    // draining the noise here keeps each test's assertions scoped to what
    // it actually did, without depending on this unrelated crash being
    // fixed.
    await db.customStatement(
      'UPDATE sync_log SET exported = 1 WHERE exported = 0',
    );
  });

  tearDown(() async {
    await db.close();
    if (await syncFolder.exists()) {
      await syncFolder.delete(recursive: true);
    }
  });

  // Fresh DB creation seeds default styles/categories/account
  // types/currency designations via the logging insertAllX() DAO methods, so
  // sync_log already has ambient pending rows for that seed data before any
  // test-added row exists. Assertions below are scoped to a specific
  // recordId rather than the whole table so ambient seed rows never leak
  // into the expected counts.
  Future<List<SyncLogData>> pendingLogs() =>
      (db.select(db.syncLog)..where((t) => t.exported.equals(false))).get();
  Future<SyncLogData?> pendingLogFor(String recordId) =>
      (db.select(db.syncLog)..where(
            (t) => t.recordId.equals(recordId) & t.exported.equals(false),
          ))
          .getSingleOrNull();
  Future<SyncLogData?> exportedLogFor(String recordId) =>
      (db.select(db.syncLog)..where(
            (t) => t.recordId.equals(recordId) & t.exported.equals(true),
          ))
          .getSingleOrNull();

  Future<void> addStyle(String id) => db.stylesDao.insertStyle(
    StylesCompanion.insert(
      id: Value(id),
      name: 'Style $id',
      iconName: 'star',
      colorHex: '#123456',
    ),
  );

  test(
    'a successful export marks its rows exported and writes a file',
    () async {
      await addStyle('s1');
      expect(await pendingLogFor('s1'), isNot(null));

      await service.exportNow();

      expect(await pendingLogFor('s1'), null);
      expect(await exportedLogFor('s1'), isNot(null));

      final files = await syncFolder
          .list()
          .where((e) => e.path.endsWith('.sync'))
          .toList();
      expect(files, hasLength(1));
    },
  );

  test(
    'a failed export (folder gone) leaves the row pending for retry',
    () async {
      await addStyle('s1');
      expect(await pendingLogFor('s1'), isNot(null));

      // Simulate a write failure without relying on OS-specific permission
      // APIs: delete the folder out from under the service so
      // file.writeAsBytes() throws FileSystemException. sync_service_io.dart's
      // _exportPendingChanges() catches that and returns before calling
      // markExported, so the log row must still be pending afterwards.
      await syncFolder.delete(recursive: true);

      await service.exportNow();

      expect(
        await pendingLogFor('s1'),
        isNot(null),
        reason: 'a write that never reached disk must not be marked exported',
      );

      // Recreate the folder and retry: the same pending row must now export
      // successfully, proving the earlier failure did not corrupt or drop it.
      await syncFolder.create(recursive: true);
      await service.exportNow();

      expect(await pendingLogFor('s1'), null);
      expect(await exportedLogFor('s1'), isNot(null));
    },
  );

  test(
    'deleting a record produces a delete log row that is exported',
    () async {
      await addStyle('s1');
      await service.exportNow();
      expect(await pendingLogs(), isEmpty);

      await db.stylesDao.deleteStyle(StylesCompanion(id: const Value('s1')));

      final pending = await pendingLogs();
      expect(pending, hasLength(1));
      expect(pending.single.action, 'delete');
      expect(pending.single.recordId, 's1');
      expect(pending.single.changedTableName, 'styles');

      await service.exportNow();
      expect(await pendingLogs(), isEmpty);
    },
  );

  test(
    'importing an exported delete soft-deletes the record on the peer',
    () async {
      // Device A: create then delete a style, export both changes.
      await addStyle('s1');
      await db.stylesDao.deleteStyle(StylesCompanion(id: const Value('s1')));
      await service.exportNow();

      final files = await syncFolder
          .list()
          .where((e) => e.path.endsWith('.sync'))
          .toList();
      expect(files, isNotEmpty);

      // Device B: fresh DB pointed at the same folder picks up A's packet(s).
      final dbB = AppDatabase.forTesting(NativeDatabase.memory());
      await setDeviceId(dbB, 'device-b');
      final serviceB = SyncService(dbB);
      await serviceB.startSync(syncFolder.path);
      await serviceB.stopSync();
      await serviceB.importNow();

      final row = await (dbB.select(
        dbB.styles,
      )..where((t) => t.id.equals('s1'))).getSingleOrNull();

      // The create and the delete may have landed in the same packet or two
      // separate ones (one export per test run here, so one packet with both
      // log rows) - either way, the peer must end up with a soft-deleted row,
      // not a missing one and not a live one.
      expect(row, isNotNull);
      expect(row!.isDeleted, isTrue);

      await dbB.close();
    },
  );

  test(
    'only rows touched by a given export are marked exported (later local writes stay pending)',
    () async {
      await addStyle('s1');
      await service.exportNow();
      expect(await pendingLogs(), isEmpty);

      // A second, unrelated local change made after the export must remain
      // pending - export bookkeeping must be scoped to the batch it actually
      // wrote, not "everything in the table".
      await addStyle('s2');

      final pending = await pendingLogs();
      expect(pending, hasLength(1));
      expect(pending.single.recordId, 's2');
    },
  );
}
