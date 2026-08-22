import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';
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

    // Drain the ambient sync_log backlog left by unconditional DB seeding via
    // raw SQL rather than exportNow(), so each test's assertions cover only
    // the rows that test wrote.
    //
    // This used to carry a note that exportNow() could not drain it at all:
    // markExported built one `WHERE id IN (...)` over the whole backlog, blew
    // past SQLite's 999-variable cap, and the blanket catch in
    // _exportPendingChanges swallowed the exception after the file had already
    // been written - so nothing was ever marked exported. markExported now
    // writes in chunks of 500 and that no longer happens; the raw drain stays
    // because it is faster and because it keeps this file's assertions scoped
    // to what each test did.
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

  // `clearExportedBefore` was written and then never called from anywhere, so
  // `sync_log` only grew: one row per write, for the life of the install, none
  // of which anything reads back - `getPendingChanges` asks for
  // `exported = false`. Settings made it visible, since a filter or a sort
  // order is rewritten dozens of times in a session, but every table was
  // feeding a table nothing emptied.
  Future<int> logRowsFor(String recordId) async {
    final rows = await (db.select(
      db.syncLog,
    )..where((t) => t.recordId.equals(recordId))).get();
    return rows.length;
  }

  Future<void> ageLogRowsFor(String recordId, Duration by) => db
      .customStatement('UPDATE sync_log SET timestamp = ? WHERE record_id = ?', [
        DateTime.now().subtract(by).millisecondsSinceEpoch,
        recordId,
      ]);

  test('an export drops exported rows older than the retention window', () async {
    await addStyle('old');
    await service.exportNow();
    expect(await logRowsFor('old'), 1);

    await ageLogRowsFor('old', const Duration(days: 30));

    await addStyle('new');
    await service.exportNow();

    expect(
      await logRowsFor('old'),
      0,
      reason: 'nothing reads an exported row once its file has been written',
    );
    expect(await logRowsFor('new'), 1);
  });

  test('a recently exported row is kept', () async {
    // The window is there to leave a trail worth reading when an export is
    // being investigated; pruning on the spot would remove it.
    await addStyle('s1');
    await service.exportNow();

    await addStyle('s2');
    await service.exportNow();

    expect(await logRowsFor('s1'), 1);
    expect(await logRowsFor('s2'), 1);
  });

  test('an old pending row is carried before it is pruned', () async {
    // Age alone is not the criterion. A change that has not reached a file yet
    // still has to be sent, so pruning has to run after the write - a prune
    // that went first would drop the row and the peer would never see it.
    await addStyle('s1');
    await ageLogRowsFor('s1', const Duration(days: 365));

    await service.exportNow();

    final file = (await syncFolder.list().where((e) => e.path.endsWith('.sync')).toList())
        .single;
    final packet = SyncBinaryFormat.decode(
      await File(file.path).readAsBytes(),
    );
    expect(
      packet.changes.map((c) => c.recordId),
      contains('s1'),
      reason: 'the row was pending, so this export is what carries it',
    );
  });
}
