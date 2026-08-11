import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// A `.sync` file dropped by a peer (or Syncthing mid-write) can be
/// corrupt in several ways. None of them may throw out of
/// [SyncService.importNow] (that would take the sync isolate down) and none
/// may leave the local database partially written.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase db;
  late SyncService service;

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp('mybudget_sync_malformed_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.settingsDao.setSetting(
      SettingsCompanion(
        key: const Value('local_device_id'),
        value: const Value('device-local'),
      ),
    );
    service = SyncService(db);
    await service.startSync(syncFolder.path);
    await service.stopSync();
  });

  tearDown(() async {
    await db.close();
    if (await syncFolder.exists()) {
      await syncFolder.delete(recursive: true);
    }
  });

  Future<void> writeSyncFile(String name, List<int> bytes) async {
    final file = File('${syncFolder.path}/$name');
    await file.writeAsBytes(bytes);
  }

  Future<void> addLocalStyle(String id) => db.stylesDao.insertStyle(
    StylesCompanion.insert(
      id: Value(id),
      name: 'Untouched',
      iconName: 'star',
      colorHex: '#654321',
    ),
  );

  Future<List<Style>> allStyles() => db.select(db.styles).get();
  // Fresh DB creation seeds ~22 default styles, so "untouched" must be
  // checked as a before/after set comparison, not an absolute row count.
  Future<Set<String>> styleIds() async =>
      (await allStyles()).map((s) => s.id).toSet();

  test('empty file does not throw and leaves local data untouched', () async {
    await addLocalStyle('s1');
    final before = await styleIds();
    await writeSyncFile('peer_1.sync', const []);

    await expectLater(service.importNow(), completes);

    expect(await styleIds(), before);
    final s1 = await (db.select(
      db.styles,
    )..where((t) => t.id.equals('s1'))).getSingle();
    expect(s1.name, 'Untouched');
  });

  test('non-gzip garbage does not throw and leaves local data untouched', () async {
    await addLocalStyle('s1');
    final before = await styleIds();
    await writeSyncFile('peer_2.sync', utf8.encode('not even close to gzip'));

    await expectLater(service.importNow(), completes);

    expect(await styleIds(), before);
    final s1 = await (db.select(
      db.styles,
    )..where((t) => t.id.equals('s1'))).getSingle();
    expect(s1.name, 'Untouched');
  });

  test('truncated packet does not throw and leaves local data untouched', () async {
    await addLocalStyle('s1');
    final before = await styleIds();

    final valid = SyncBinaryFormat.encode(
      deviceId: 'device-peer',
      timestamp: 1,
      changes: [
        SyncChange(
          tableId: SyncTableId.styles,
          recordId: 's-remote',
          action: SyncAction.upsert,
          data: {
            'id': 's-remote',
            'name': 'Should Never Land',
            'colorHex': '#000000',
            'iconName': 'star',
            'iconType': 0,
            'modifiedAt': 999999,
            'isDeleted': false,
          },
        ),
      ],
    );
    final decompressed = GZipDecoder().decodeBytes(valid);
    final truncated = decompressed.sublist(0, decompressed.length - 15);
    final tamperedGzip = Uint8List.fromList(GZipEncoder().encode(truncated)!);

    await writeSyncFile('peer_3.sync', tamperedGzip);

    await expectLater(service.importNow(), completes);

    expect(
      await styleIds(),
      before,
      reason: 'a truncated packet must not partially apply',
    );
    final s1 = await (db.select(
      db.styles,
    )..where((t) => t.id.equals('s1'))).getSingle();
    expect(s1.name, 'Untouched');
  });

  test('unknown table id byte does not throw and leaves local data untouched', () async {
    await addLocalStyle('s1');
    final before = await styleIds();

    final valid = SyncBinaryFormat.encode(
      deviceId: 'device-peer',
      timestamp: 1,
      changes: [
        SyncChange(
          tableId: SyncTableId.styles,
          recordId: 's-remote',
          action: SyncAction.upsert,
          data: {'id': 's-remote'},
        ),
      ],
    );
    final decompressed = GZipDecoder().decodeBytes(valid);
    const tableIdOffset = 4 + 1 + 36 + 8 + 4;
    decompressed[tableIdOffset] = 250;
    final tamperedGzip = Uint8List.fromList(
      GZipEncoder().encode(decompressed)!,
    );

    await writeSyncFile('peer_4.sync', tamperedGzip);

    await expectLater(service.importNow(), completes);

    expect(await styleIds(), before);
    final s1 = await (db.select(
      db.styles,
    )..where((t) => t.id.equals('s1'))).getSingle();
    expect(s1.name, 'Untouched');
  });

  test('a malformed file does not block a valid file from importing', () async {
    await addLocalStyle('s1');

    await writeSyncFile('peer_bad.sync', utf8.encode('garbage'));

    final validBytes = SyncBinaryFormat.encode(
      deviceId: 'device-peer',
      timestamp: 1,
      changes: [
        SyncChange(
          tableId: SyncTableId.styles,
          recordId: 's-good',
          action: SyncAction.upsert,
          data: {
            'id': 's-good',
            'name': 'Arrived Fine',
            'colorHex': '#abcdef',
            'iconName': 'star',
            'iconType': 0,
            'modifiedAt': 1,
            'isDeleted': false,
          },
        ),
      ],
    );
    await writeSyncFile('peer_good.sync', validBytes);

    await expectLater(service.importNow(), completes);

    final styles = await allStyles();
    expect(styles.map((s) => s.id), containsAll(['s1', 's-good']));
  });

  test('a permanently malformed file is not marked processed and does not spam retries beyond the quarantine limit', () async {
    await writeSyncFile('peer_bad.sync', utf8.encode('garbage'));

    // Calling importNow() repeatedly (as the periodic scan would) must keep
    // completing without throwing, even after the file is quarantined.
    for (var i = 0; i < 5; i++) {
      await expectLater(service.importNow(), completes);
    }

    final processed = await db.syncProcessedFilesDao.isProcessed(
      'peer_bad.sync',
    );
    expect(
      processed,
      isFalse,
      reason: 'a file that only ever fails to decode must never be marked processed',
    );
  });
}
