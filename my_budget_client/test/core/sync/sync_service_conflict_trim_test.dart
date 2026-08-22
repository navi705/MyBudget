import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// `conflict_history` is trimmed once per packet, not once per change.
///
/// The trim ran at the end of every single `_applyChange`, and the DAO behind
/// it reads the whole table - every `rejected_data` blob included - into a Dart
/// list just to work out which rows fall past the cap. A 20 000-change packet
/// therefore issued 20 000 unbounded SELECTs and up to 20 000 DELETEs to remove
/// at most one row each time, none of which has anything to do with the change
/// being applied. Per packet is the right granularity: the cap is a property of
/// the table, not of any one row that went into it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase dbA;
  late AppDatabase dbB;
  late SyncService serviceA;
  late SyncService serviceB;

  Future<void> setDeviceId(AppDatabase db, String id) =>
      db.settingsDao.setSetting(
        SettingsCompanion(
          key: const Value('local_device_id'),
          value: Value(id),
        ),
      );

  Future<SyncService> configuredService(AppDatabase db, String deviceId) async {
    await setDeviceId(db, deviceId);
    final service = SyncService(db);
    await service.startSync(syncFolder.path);
    await service.stopSync();
    return service;
  }

  Future<void> insertStyle(
    AppDatabase db,
    String id,
    String name,
    int modifiedAt,
  ) async {
    await db.stylesDao.insertStyle(
      StylesCompanion.insert(
        id: Value(id),
        name: name,
        iconName: 'star',
        colorHex: '#111111',
      ),
    );
    await db.customStatement('UPDATE styles SET modified_at = ? WHERE id = ?', [
      modifiedAt,
      id,
    ]);
  }

  Future<void> seedConflicts(AppDatabase db, int count) async {
    for (var i = 0; i < count; i++) {
      await db.conflictHistoryDao.saveConflict(
        tableName: 'styles',
        recordId: 'seeded-$i',
        rejectedDataJson: '{"id":"seeded-$i"}',
        rejectedDevice: 'device-z',
      );
    }
  }

  Future<void> syncAToB() async {
    await serviceA.exportNow();
    await dbA.customStatement(
      'UPDATE sync_log SET exported = 1 WHERE exported = 0',
    );
    await serviceB.importNow();
  }

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp('mybudget_sync_trim_');
    dbA = AppDatabase.forTesting(NativeDatabase.memory());
    dbB = AppDatabase.forTesting(NativeDatabase.memory());
    serviceA = await configuredService(dbA, 'device-a');
    serviceB = await configuredService(dbB, 'device-b');
    // The seed logs every row it lays down, and both installs lay down the
    // same rows under the same stable ids and the same clock - so the first
    // export would otherwise ship a few hundred styles/categories that tie with
    // B's own copies and lose the device-id tie-break, filling the conflict
    // table before the test has written a thing.
    await dbA.customStatement('UPDATE sync_log SET exported = 1');
  });

  tearDown(() async {
    await dbA.close();
    await dbB.close();
    if (await syncFolder.exists()) {
      await syncFolder.delete(recursive: true);
    }
  });

  test('a packet that resolves no conflict does not touch the table', () async {
    // Six brand new styles: nothing to reject, so nothing is added to the
    // conflict table - and nothing may be removed from it either. Trimming here
    // is the per-change trim showing through, because a packet of pure inserts
    // has no reason to visit conflict_history at all.
    serviceB.maxConflictHistory = 100;
    await seedConflicts(dbB, 150);
    for (var i = 0; i < 6; i++) {
      await insertStyle(dbA, 'new-$i', 'Brand New $i', 1000);
    }

    await syncAToB();

    expect(
      (await dbB.select(dbB.styles).get())
          .where((s) => s.id.startsWith('new-'))
          .length,
      6,
    );
    expect(
      (await dbB.conflictHistoryDao.getAllConflicts()).length,
      150,
      reason: 'an import that grew nothing must not trim',
    );
  });

  test('the cap still holds after a packet full of conflicts', () async {
    // The behaviour the trim exists for is unchanged: whatever one packet adds,
    // the table is back under the cap by the time the packet is committed.
    serviceB.maxConflictHistory = 5;
    for (var i = 0; i < 12; i++) {
      // B holds the newer row every time, so each incoming change loses
      // last-write-wins and is written to conflict_history.
      await insertStyle(dbB, 'c-$i', 'B Name $i', 5000);
      await insertStyle(dbA, 'c-$i', 'A Name $i', 1000);
    }

    await syncAToB();

    expect((await dbB.conflictHistoryDao.getAllConflicts()).length, 5);
  });

  group('clearOldConflicts keeps the newest N', () {
    // The trim itself, away from the packet path: it is one DELETE now, and
    // what it deletes has to be the same set the read-everything version chose.
    Future<List<String>> remainingIds(AppDatabase db) async {
      final rows = await db.conflictHistoryDao.getAllConflicts();
      return rows.map((r) => r.recordId).toList();
    }

    Future<void> seedStamped(AppDatabase db, List<int> stamps) async {
      for (var i = 0; i < stamps.length; i++) {
        await db.conflictHistoryDao.saveConflict(
          tableName: 'styles',
          recordId: 'r$i',
          rejectedDataJson: '{"id":"r$i"}',
          rejectedDevice: 'device-z',
        );
        await db.customStatement(
          'UPDATE conflict_history SET rejected_at = ? WHERE record_id = ?',
          [stamps[i], 'r$i'],
        );
      }
    }

    test('the oldest rows go and the newest stay', () async {
      await seedStamped(dbB, [10, 40, 20, 50, 30]);

      await dbB.conflictHistoryDao.clearOldConflicts(2);

      expect((await remainingIds(dbB)).toSet(), {'r3', 'r1'});
    });

    test('a table already under the cap is left alone', () async {
      await seedStamped(dbB, [10, 20]);

      await dbB.conflictHistoryDao.clearOldConflicts(5);

      expect((await remainingIds(dbB)).toSet(), {'r0', 'r1'});
    });

    test('rows sharing a millisecond leave a defined pair behind', () async {
      // Every stamp equal: without the id tie-break in the ORDER BY, SQLite is
      // free to hand back a different two rows each run and the trim deletes a
      // different three. The rule is spelled out here so a rewrite that drops
      // the tie-break fails instead of flaking.
      await seedStamped(dbB, [7, 7, 7, 7, 7]);
      final ids =
          (await dbB.conflictHistoryDao.getAllConflicts())
              .map((r) => r.id)
              .toList()
            ..sort();
      final expected = ids.reversed.take(2).toSet();

      await dbB.conflictHistoryDao.clearOldConflicts(2);

      final survivors = (await dbB.conflictHistoryDao.getAllConflicts())
          .map((r) => r.id)
          .toSet();
      expect(survivors, expected);
    });

    test('a cap of zero empties the table', () async {
      await seedStamped(dbB, [10, 20, 30]);

      await dbB.conflictHistoryDao.clearOldConflicts(0);

      expect(await remainingIds(dbB), isEmpty);
    });
  });
}
