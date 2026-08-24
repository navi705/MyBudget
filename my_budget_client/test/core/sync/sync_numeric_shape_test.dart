import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// The shape a number arrives in must not decide whether a change applies.
///
/// A packet's payload is JSON, and JSON has one number type: a writer is free
/// to render 1.0 as `1`, and several do - a value that round-trips through a
/// server, a hand-written packet, a build compiled for the web. The receiver
/// used to cast `exchangeRate` straight to `double?`, which throws for an
/// integer-shaped rate. The throw is caught per change, so nothing looked
/// broken: the transaction was quietly skipped, and no later packet re-sends a
/// change already sent, so it stayed missing on that device forever.
///
/// A value that is not a number at all is still refused - that skip is the
/// intended behaviour and is pinned here too, so the fix cannot drift into
/// accepting garbage.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase db;
  late SyncService service;

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp('mybudget_sync_shape_');
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

  var packetCount = 0;
  Future<void> deliver(List<SyncChange> changes) async {
    packetCount++;
    final bytes = SyncBinaryFormat.encode(
      deviceId: 'device-peer',
      timestamp: 1700000000000 + packetCount,
      changes: changes,
    );
    await File(
      '${syncFolder.path}/device-peer_$packetCount.sync',
    ).writeAsBytes(bytes);
    await service.importNow();
  }

  Future<void> deliverTransaction(Map<String, dynamic> data) => deliver([
    SyncChange(
      tableId: SyncTableId.transactions,
      recordId: data['id'] as String,
      action: SyncAction.upsert,
      data: data,
    ),
  ]);

  Future<void> deliverAccount(Map<String, dynamic> data) => deliver([
    SyncChange(
      tableId: SyncTableId.accounts,
      recordId: data['id'] as String,
      action: SyncAction.upsert,
      data: data,
    ),
  ]);

  Future<Transaction?> transaction(String id) =>
      (db.select(db.transactions)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  /// Every key `_transactionToJson` writes, with the numbers left to the
  /// caller so each test can choose the shape they arrive in.
  Map<String, dynamic> transactionPayload({
    required String id,
    required Object? amount,
    required Object? fee,
    required Object? exchangeRate,
    required Object? exchangeRatePreset,
    Object? modifiedAt = 1000,
  }) => {
    'id': id,
    'description': 'Payload $id',
    'amount': amount,
    'date': DateTime(2024, 4, 4).toIso8601String(),
    'accountId': 'acc-1',
    'categoryId': 'cat-1',
    'currencyCode': 'USD',
    'exchangeRate': exchangeRate,
    'exchangeRatePreset': exchangeRatePreset,
    'fee': fee,
    'linkedTransactionId': null,
    'modifiedAt': modifiedAt,
    'deviceId': 'device-peer',
    'isDeleted': false,
  };

  Map<String, dynamic> accountPayload({
    required String id,
    required Object? balance,
    required Object? assetQuantity,
  }) => {
    'id': id,
    'name': 'Payload $id',
    'description': null,
    'balance': balance,
    'currencyCode': 'USD',
    'currencyDesignationId': 'cd-1',
    'accountTypeId': 'at-1',
    'styleId': null,
    'creationDate': DateTime(2023, 1, 1).toIso8601String(),
    'country': null,
    'assetId': null,
    'assetQuantity': assetQuantity,
    'feeStructure': null,
    'modifiedAt': 1000,
    'deviceId': 'device-peer',
    'isDeleted': false,
  };

  group('a transaction whose numbers arrive as integers', () {
    test('applies, with the rate read as the double it means', () async {
      await deliverTransaction(
        transactionPayload(
          id: 'tx-int-rate',
          amount: 5,
          fee: 0,
          exchangeRate: 1,
          exchangeRatePreset: 2,
        ),
      );

      final row = await transaction('tx-int-rate');
      expect(
        row,
        isNotNull,
        reason: 'an integer-shaped rate must not cost the whole transaction',
      );
      expect(row!.exchangeRate, 1.0);
      expect(row.exchangeRatePreset, 2);
      expect(row.amount, 5.0);
      expect(row.fee, 0.0);
      expect(row.modifiedAt, 1000);
    });

    test('a fractional rate still arrives unchanged', () async {
      await deliverTransaction(
        transactionPayload(
          id: 'tx-frac-rate',
          amount: 12.34,
          fee: 0.5,
          exchangeRate: 0.91,
          exchangeRatePreset: 1,
        ),
      );

      final row = await transaction('tx-frac-rate');
      expect(row!.exchangeRate, 0.91);
      expect(row.amount, 12.34);
      expect(row.fee, 0.5);
    });

    test('an absent rate is still absent, not zero', () async {
      await deliverTransaction(
        transactionPayload(
          id: 'tx-no-rate',
          amount: 1.0,
          fee: 0.0,
          exchangeRate: null,
          exchangeRatePreset: null,
        ),
      );

      final row = await transaction('tx-no-rate');
      expect(row!.exchangeRate, isNull);
      expect(row.exchangeRatePreset, isNull);
    });
  });

  group('an account whose numbers arrive as integers', () {
    test('applies with the balance and quantity it was sent', () async {
      await deliverAccount(
        accountPayload(id: 'acc-int', balance: 100, assetQuantity: 2),
      );

      final row = await (db.select(
        db.accounts,
      )..where((t) => t.id.equals('acc-int'))).getSingleOrNull();
      expect(row, isNotNull);
      expect(row!.balance, 100.0);
      expect(row.assetQuantity, 2.0);
    });
  });

  group('a payload that is not a number at all', () {
    test('is skipped, and does not take the packet with it', () async {
      await deliver([
        SyncChange(
          tableId: SyncTableId.transactions,
          recordId: 'tx-garbage',
          action: SyncAction.upsert,
          data: transactionPayload(
            id: 'tx-garbage',
            amount: 1.0,
            fee: 0.0,
            exchangeRate: 'not a rate',
            exchangeRatePreset: null,
          ),
        ),
        SyncChange(
          tableId: SyncTableId.transactions,
          recordId: 'tx-good',
          action: SyncAction.upsert,
          data: transactionPayload(
            id: 'tx-good',
            amount: 2.0,
            fee: 0.0,
            exchangeRate: 1,
            exchangeRatePreset: null,
          ),
        ),
      ]);

      expect(await transaction('tx-garbage'), isNull);
      expect(
        (await transaction('tx-good'))?.amount,
        2.0,
        reason: 'the other changes in the packet still apply',
      );
    });
  });

  group('a clock that arrives as a double', () {
    // `modifiedAt` rides on every change of every table and is read twice: by
    // the converter that builds the row, and by the conflict resolution that
    // decides whether the change is allowed to land at all. A peer is free to
    // render 1700000000000 as 1.7e12, and the cast that used to sit on both
    // reads threw for it - one silently skipped change at a time, which for a
    // peer that always writes its clock that way is the whole packet.
    test('still stamps the row it arrives with', () async {
      await deliverTransaction(
        transactionPayload(
          id: 'tx-double-clock',
          amount: 3.0,
          fee: 0.0,
          exchangeRate: null,
          exchangeRatePreset: null,
          modifiedAt: 1700000000000.0,
        ),
      );

      final row = await transaction('tx-double-clock');
      expect(row, isNotNull, reason: 'a double-shaped clock is still a clock');
      expect(row!.modifiedAt, 1700000000000);
    });

    test('still wins the conflict its value says it wins', () async {
      await deliverTransaction(
        transactionPayload(
          id: 'tx-clock-race',
          amount: 1.0,
          fee: 0.0,
          exchangeRate: null,
          exchangeRatePreset: null,
          modifiedAt: 1000,
        ),
      );
      expect((await transaction('tx-clock-race'))!.amount, 1.0);

      await deliverTransaction(
        transactionPayload(
          id: 'tx-clock-race',
          amount: 42.0,
          fee: 0.0,
          exchangeRate: null,
          exchangeRatePreset: null,
          modifiedAt: 2000.0,
        ),
      );

      final row = await transaction('tx-clock-race');
      expect(
        row!.amount,
        42.0,
        reason: 'the newer edit is newer whichever way its clock is written',
      );
      expect(row.modifiedAt, 2000);
    });

    test('an older edit still loses, double-shaped or not', () async {
      await deliverTransaction(
        transactionPayload(
          id: 'tx-clock-stale',
          amount: 7.0,
          fee: 0.0,
          exchangeRate: null,
          exchangeRatePreset: null,
          modifiedAt: 5000,
        ),
      );

      await deliverTransaction(
        transactionPayload(
          id: 'tx-clock-stale',
          amount: 8.0,
          fee: 0.0,
          exchangeRate: null,
          exchangeRatePreset: null,
          modifiedAt: 4000.0,
        ),
      );

      expect((await transaction('tx-clock-stale'))!.amount, 7.0);
    });
  });
}
