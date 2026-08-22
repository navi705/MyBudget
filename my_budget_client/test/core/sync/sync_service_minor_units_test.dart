import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';

/// What the import path does with a packet whose money keys
/// (`amountMinor`/`feeMinor`/`balanceMinor`) are absent, as every packet
/// written by a build from before those keys existed is.
///
/// The columns are nullable with no default and the peer applies a packet with
/// `InsertMode.insertOrReplace`, so "absent" and "explicitly null" would both
/// land as NULL if the receiver simply forwarded what it read. It does not: an
/// absent key is re-derived from the major-unit double, which restores exact
/// cents for fiat and yields nothing for crypto/commodity, whose double is the
/// source of truth. An explicitly null key is the sender saying the row has no
/// minor units, and is honoured as sent.
///
/// The packets here are hand-built rather than exported from a second device,
/// because a legacy sender is exactly what no current build can produce.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase db;
  late SyncService service;

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp('mybudget_sync_minor_');
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

  /// Everything `_transactionToJson` carries except the money keys, which
  /// callers add (or leave out, to speak as a legacy sender).
  Map<String, dynamic> transactionPayload({
    required String id,
    required double amount,
    required double fee,
    required String currencyCode,
    int modifiedAt = 1000,
  }) => {
    'id': id,
    'description': 'Payload $id',
    'amount': amount,
    'date': DateTime(2024, 4, 4).toIso8601String(),
    'accountId': 'acc-1',
    'categoryId': 'cat-1',
    'currencyCode': currencyCode,
    'exchangeRate': null,
    'exchangeRatePreset': null,
    'fee': fee,
    'linkedTransactionId': null,
    'modifiedAt': modifiedAt,
    'deviceId': 'device-peer',
    'isDeleted': false,
  };

  Map<String, dynamic> accountPayload({
    required String id,
    required double balance,
    required String currencyCode,
    int modifiedAt = 1000,
  }) => {
    'id': id,
    'name': 'Payload $id',
    'description': null,
    'balance': balance,
    'currencyCode': currencyCode,
    'currencyDesignationId': 'cd-1',
    'accountTypeId': 'at-1',
    'styleId': null,
    'creationDate': DateTime(2023, 1, 1).toIso8601String(),
    'country': null,
    'assetId': null,
    'assetQuantity': 0.0,
    'feeStructure': null,
    'modifiedAt': modifiedAt,
    'deviceId': 'device-peer',
    'isDeleted': false,
  };

  /// Deliver [changes] as one packet from a peer and let the service import it.
  /// The file name is unique per call so a test can deliver several in a row
  /// (an already-processed name is skipped by design).
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

  Future<Transaction> transaction(String id) =>
      (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();

  Future<DbAccount> account(String id) =>
      (db.select(db.accounts)..where((t) => t.id.equals(id))).getSingle();

  group('a packet that predates the money keys', () {
    test('gives a fiat transaction back its exact minor units', () async {
      await deliverTransaction(
        transactionPayload(
          id: 'tx-usd',
          amount: 12.34,
          fee: 0.5,
          currencyCode: 'USD',
        ),
      );

      final row = await transaction('tx-usd');
      expect(row.amountMinor, 1234);
      expect(row.feeMinor, 50);
    });

    test(
      'respects a zero-decimal currency rather than assuming cents',
      () async {
        await deliverTransaction(
          transactionPayload(
            id: 'tx-jpy',
            amount: 1500.0,
            fee: 0.0,
            currencyCode: 'JPY',
          ),
        );

        final row = await transaction('tx-jpy');
        expect(row.amountMinor, 1500);
        expect(row.feeMinor, 0);
      },
    );

    test(
      'leaves a crypto transaction on its double, with no invented units',
      () async {
        await deliverTransaction(
          transactionPayload(
            id: 'tx-btc',
            amount: 0.001,
            fee: 0.0,
            currencyCode: 'BTC',
          ),
        );

        final row = await transaction('tx-btc');
        expect(row.amount, 0.001);
        expect(row.amountMinor, null);
        expect(row.feeMinor, null);
      },
    );

    test('gives a fiat account back its exact minor units', () async {
      await deliverAccount(
        accountPayload(id: 'acc-usd', balance: 100.5, currencyCode: 'USD'),
      );

      expect((await account('acc-usd')).balanceMinor, 10050);
    });

    test(
      'leaves a crypto account on its double, with no invented units',
      () async {
        await deliverAccount(
          accountPayload(id: 'acc-btc', balance: 0.75, currencyCode: 'BTC'),
        );

        final row = await account('acc-btc');
        expect(row.balance, 0.75);
        expect(row.balanceMinor, null);
      },
    );

    test(
      'replacing a row that already has exact units does not wipe them',
      () async {
        // The corruption this guards against: the replace writes every column,
        // so a payload silent about the money keys would blank out cents the
        // local row already holds.
        final current = transactionPayload(
          id: 'tx-usd',
          amount: 12.34,
          fee: 0.5,
          currencyCode: 'USD',
        )..addAll({'amountMinor': 1234, 'feeMinor': 50});
        await deliverTransaction(current);
        expect((await transaction('tx-usd')).amountMinor, 1234);

        await deliverTransaction(
          transactionPayload(
            id: 'tx-usd',
            amount: 99.99,
            fee: 1.25,
            currencyCode: 'USD',
            modifiedAt: 2000,
          ),
        );

        final row = await transaction('tx-usd');
        expect(row.amount, 99.99);
        expect(row.amountMinor, 9999);
        expect(row.feeMinor, 125);
      },
    );
  });

  test('an explicitly null minor value is honoured, not re-derived', () async {
    // A sender that knows the key and sends null is stating this row has no
    // minor units - a fiat row whose exact value has never been established.
    // Deriving one here would put a number on the wire's behalf that no device
    // ever wrote.
    final data = transactionPayload(
      id: 'tx-null',
      amount: 12.34,
      fee: 0.5,
      currencyCode: 'USD',
    )..addAll({'amountMinor': null, 'feeMinor': null});
    await deliverTransaction(data);

    final row = await transaction('tx-null');
    expect(row.amount, 12.34);
    expect(row.amountMinor, null);
    expect(row.feeMinor, null);
  });
}
