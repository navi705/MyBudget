import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// Imports are serialised behind one queue.
///
/// They used to be started and never awaited - the watcher fires one per file
/// system event (Windows reports a single delivered file as a create AND a
/// modify, 500 ms apart) while the initial scan starts one per file - so
/// several ran interleaved on the same connection. Two things broke:
///
///  * `PRAGMA foreign_keys` is connection-global and not reentrant, so the
///    small packet that finished first turned enforcement back ON in the middle
///    of the large one still running, and that one's next child row - whose
///    parent legitimately travels in a later packet - was rejected;
///  * the `sync_processed_files` check became check-then-act: two futures for
///    the same file both read "not processed" and both applied the packet.
///
/// The second is what these tests pin, because it is the one with a
/// deterministic, observable footprint: a change that loses last-write-wins
/// writes a `conflict_history` row, and a packet applied twice writes it twice.
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
    // Kills the periodic export timer and the Directory.watch() subscription,
    // so the only imports in these tests are the ones started explicitly.
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

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp('mybudget_sync_conc_');
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

  test('two imports started at once apply each packet exactly once', () async {
    // B holds the newer row, so A's packet loses last-write-wins and every
    // application of it leaves one conflict_history row behind - a counter for
    // how many times the file was really applied.
    await insertStyle(dbB, 's1', 'B Name', 5000);
    await insertStyle(dbA, 's1', 'A Name', 1000);
    await serviceA.exportNow();

    await Future.wait([serviceB.importNow(), serviceB.importNow()]);

    final conflicts = await dbB.conflictHistoryDao.getAllConflicts();
    expect(
      conflicts.where((c) => c.recordId == 's1').length,
      1,
      reason: 'the second import must see the first one\'s processed marker',
    );
    expect(
      (await dbB.select(dbB.styles).get()).where((s) => s.id == 's1').length,
      1,
    );
  });

  test('a packet queued behind another still runs, and only once', () async {
    // Two packets from the same peer, imported by four overlapping calls: the
    // queue must neither drop one nor let any of them be applied twice.
    await insertStyle(dbB, 's1', 'B Name', 5000);
    await insertStyle(dbA, 's1', 'A Name', 1000);
    await serviceA.exportNow();
    await dbA.customStatement(
      'UPDATE sync_log SET exported = 1 WHERE exported = 0',
    );

    // A second file needs a second millisecond: exports are named
    // '${deviceId}_$timestamp.sync'.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await insertStyle(dbB, 's2', 'B Name', 5000);
    await insertStyle(dbA, 's2', 'A Name', 1000);
    await serviceA.exportNow();

    expect(
      (await syncFolder.list().where((e) => e.path.endsWith('.sync')).toList())
          .length,
      2,
    );

    await Future.wait([
      serviceB.importNow(),
      serviceB.importNow(),
      serviceB.importNow(),
      serviceB.importNow(),
    ]);

    final conflicts = await dbB.conflictHistoryDao.getAllConflicts();
    expect(conflicts.where((c) => c.recordId == 's1').length, 1);
    expect(conflicts.where((c) => c.recordId == 's2').length, 1);
    expect((await dbB.select(dbB.syncProcessedFiles).get()).length, 2);
  });

  test('foreign key enforcement is back on once the queue drains', () async {
    // Each import toggles the connection-global pragma. Overlapping imports
    // left the flag at whatever the last one to finish wanted; serialised, the
    // last thing the queue does is restore enforcement.
    await insertStyle(dbA, 's1', 'A Name', 1000);
    await serviceA.exportNow();

    await Future.wait([serviceB.importNow(), serviceB.importNow()]);

    final row = await dbB.customSelect('PRAGMA foreign_keys').getSingle();
    expect(row.data.values.first, 1);
  });
}
