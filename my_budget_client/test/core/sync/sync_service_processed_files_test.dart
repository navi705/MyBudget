import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// The lifetime of a `sync_processed_files` marker.
///
/// A marker's only job is to stop a packet that is still lying in the sync
/// folder from being imported a second time, so it has to outlive that file and
/// nothing else. It used to be aged out after seven days while the packets
/// themselves were kept forever (imports are deliberately left in place so the
/// other peers can still pick them up), which turned every packet into a weekly
/// replay: the whole folder history was re-decoded and re-applied on a ~7 day
/// cycle, and anything the user had deleted in the meantime that leaves no
/// tombstone came back with it.
///
/// `exchange_rates` is the table that makes the damage visible: it has no
/// `isDeleted` column, so a delete is a real DELETE and the replayed insert has
/// nothing to lose a last-write-wins comparison against.
void main() {
  // Exchange-rate record ids embed a `yyyy-MM-dd` day formatted through a
  // locale-pinned DateFormat, and a pinned locale needs its CLDR data loaded -
  // `app.dart` does this at startup, a bare `flutter test` does not.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase db;
  late SyncService service;

  final rateDate = DateTime(2099, 1, 15);
  const rateRecordId = 'USD_EUR_2099-01-15_0';

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp(
      'mybudget_sync_processed_',
    );
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

  Future<void> writeRatePacket(String name) async {
    final bytes = SyncBinaryFormat.encode(
      deviceId: 'device-peer',
      timestamp: 1,
      changes: [
        SyncChange(
          tableId: SyncTableId.exchangeRates,
          recordId: rateRecordId,
          action: SyncAction.upsert,
          data: {
            'fromCurrencyCode': 'USD',
            'toCurrencyCode': 'EUR',
            'rate': 0.9,
            'preset': 0,
            'date': rateDate.toIso8601String(),
            'modifiedAt': 5000,
          },
        ),
      ],
    );
    await File('${syncFolder.path}/$name').writeAsBytes(bytes);
  }

  Future<ExchangeRate?> importedRate() =>
      (db.select(db.exchangeRates)..where(
            (t) =>
                t.fromCurrencyCode.equals('USD') &
                t.toCurrencyCode.equals('EUR') &
                t.preset.equals(0) &
                t.date.equals(rateDate),
          ))
          .getSingleOrNull();

  /// Backdates a marker as if it had been written [age] ago, which is the only
  /// thing seven days of real time used to change about it.
  Future<void> ageMarker(String fileName, Duration age) => db.customStatement(
    'UPDATE sync_processed_files SET processed_at = ? WHERE file_name = ?',
    [DateTime.now().subtract(age).millisecondsSinceEpoch, fileName],
  );

  test(
    'a marker outlives its age as long as the packet it names is still in the folder',
    () async {
      await writeRatePacket('peer_rate.sync');
      await service.importNow();
      expect(await importedRate(), isNotNull);

      await ageMarker('peer_rate.sync', const Duration(days: 8));
      // The cleanup runs at the END of a scan, so the damage always took two
      // runs: one to prune the marker, the next to re-import the file it named.
      await service.importNow();

      expect(
        await db.syncProcessedFilesDao.isProcessed('peer_rate.sync'),
        isTrue,
        reason:
            'the packet is still on disk, so the marker that keeps it from '
            'being re-imported is still needed',
      );
    },
  );

  test(
    'a deleted exchange rate is not resurrected by a packet the folder still holds',
    () async {
      await writeRatePacket('peer_rate.sync');
      await service.importNow();
      expect(await importedRate(), isNotNull);

      // The user deletes the rate. exchange_rates has no isDeleted column, so
      // this is a real DELETE and leaves no tombstone for a replay to lose to.
      await (db.delete(db.exchangeRates)..where(
            (t) =>
                t.fromCurrencyCode.equals('USD') &
                t.toCurrencyCode.equals('EUR') &
                t.preset.equals(0) &
                t.date.equals(rateDate),
          ))
          .go();
      expect(await importedRate(), isNull);

      await ageMarker('peer_rate.sync', const Duration(days: 8));
      await service.importNow();
      await service.importNow();

      expect(
        await importedRate(),
        isNull,
        reason:
            'a packet that was already imported must never be applied a '
            'second time just because time passed',
      );
    },
  );

  test('a marker whose packet has left the folder is dropped', () async {
    await writeRatePacket('peer_rate.sync');
    await service.importNow();
    expect(
      await db.syncProcessedFilesDao.isProcessed('peer_rate.sync'),
      isTrue,
    );

    // Syncthing removed the packet, or the user cleared the folder. Nothing can
    // replay it now, so keeping a row per packet the device ever saw would only
    // grow forever.
    await File('${syncFolder.path}/peer_rate.sync').delete();
    await service.importNow();

    expect(
      await db.syncProcessedFilesDao.isProcessed('peer_rate.sync'),
      isFalse,
    );
  });
}
