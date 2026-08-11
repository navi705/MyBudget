import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_transaction_repository.dart';
import 'package:my_budget_client/domain/entities/settings.dart' as domain;
import 'package:my_budget_client/domain/entities/transaction.dart' as domain_tx;
import 'package:shared_preferences/shared_preferences.dart';

/// What a pull does to a balance that two devices moved at the same time.
///
/// Transactions merge as a set and balances used to merge as a scalar, so a
/// device that spent 10 while another spent 50 ended up holding both
/// transactions and one of the two balances — a number that the transactions
/// underneath it no longer add up to, with nothing in the app to notice or
/// repair it. The balance is now rebuilt from the opening-balance anchor after
/// every batch, so it is a function of rows that merge properly.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;
  late LocalTransactionRepository transactionRepository;
  late ServerSyncService service;
  late String categoryId;

  /// Bodies served to the pull loop, in order; the last is repeated so a loop
  /// that asks for more pages than were queued stops rather than throwing.
  late List<Map<String, dynamic>> pages;

  /// Newer than anything written locally in these tests, so the server row
  /// always wins the last-writer-wins guard and the rebuild is what decides
  /// the balance rather than the guard rejecting the row.
  late int serverModifiedAt;

  Map<String, dynamic> page({
    List<Map<String, dynamic>> accounts = const [],
    List<Map<String, dynamic>> transactions = const [],
  }) => {
    'changes': {'accounts': accounts, 'transactions': transactions},
    'server_timestamp': 1,
    'has_more': false,
  };

  Map<String, dynamic> accountJson(
    String id, {
    required double balance,
    required int balanceMinor,
    double? openingBalance,
    int? openingBalanceMinor,
    required String designationId,
    required String accountTypeId,
  }) => {
    'id': id,
    'name': 'Joint account',
    'description': null,
    'balance': balance,
    'balanceMinor': balanceMinor,
    // Left out entirely when null, which is how a server or a peer that
    // predates the anchor speaks.
    if (openingBalance != null) 'openingBalance': openingBalance,
    if (openingBalance != null) 'openingBalanceMinor': openingBalanceMinor,
    'currencyCode': 'EUR',
    'currencyDesignationId': designationId,
    'styleId': null,
    'accountTypeId': accountTypeId,
    'creationDate': DateTime(2024, 1, 1).toIso8601String(),
    'country': null,
    'assetId': null,
    'assetQuantity': 0.0,
    'feeStructure': null,
    'modifiedAt': serverModifiedAt,
    'deviceId': 'device-b',
    'isDeleted': false,
  };

  Map<String, dynamic> transactionJson(
    String id, {
    required double amount,
    required int amountMinor,
    required String accountId,
    String currencyCode = 'EUR',
  }) => {
    'id': id,
    'description': id,
    'amount': amount,
    'amountMinor': amountMinor,
    'date': DateTime(2024, 6, 1).toIso8601String(),
    'accountId': accountId,
    'categoryId': categoryId,
    'currencyCode': currencyCode,
    'exchangeRate': null,
    'exchangeRatePreset': null,
    'fee': 0.0,
    'feeMinor': 0,
    'linkedTransactionId': null,
    'modifiedAt': serverModifiedAt,
    'deviceId': 'device-b',
    'isDeleted': false,
  };

  Future<void> insertAccount(String id, double balance) async {
    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    await db.accountsDao.insertAccount(
      AccountsCompanion.insert(
        id: Value(id),
        name: id,
        balance: balance,
        balanceMinor: Value((balance * 100).round()),
        currencyCode: 'EUR',
        currencyDesignationId: designationId,
        accountTypeId: accountTypeId,
      ),
    );
  }

  Future<DbAccount> account(String id) =>
      (db.select(db.accounts)..where((a) => a.id.equals(id))).getSingle();

  domain_tx.Transaction tx(String id, double amount, String accountId) =>
      domain_tx.Transaction(
        id: id,
        description: id,
        amount: amount,
        date: DateTime(2024, 6, 1),
        accountId: accountId,
        categoryId: categoryId,
        currencyCode: 'EUR',
      );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Drift opens lazily and _seedData stamps every seeded row with
    // DateTime.now(); force it now so the push watermark parked below really
    // does sit above the seed.
    await db.select(db.styles).get();
    categoryId = (await db.select(db.categories).get()).first.id;
    settingsRepository = LocalSettingsRepository(db);
    transactionRepository = LocalTransactionRepository(db);
    pages = [];
    serverModifiedAt = DateTime.now().millisecondsSinceEpoch + 600000;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'server_last_push_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
    await settingsRepository.setSetting(
      const domain.Settings(
        key: 'server_sync_enabled',
        value: 'true',
        device: 'device-a',
      ),
    );

    var pulls = 0;
    service = ServerSyncService(
      database: db,
      settingsRepository: settingsRepository,
      httpClient: MockClient((request) async {
        if (request.method == 'POST') {
          return http.Response('{"status":"ok"}', 200);
        }
        pulls++;
        final body = pages.isEmpty
            ? page()
            : pages[pulls <= pages.length ? pulls - 1 : pages.length - 1];
        return http.Response(jsonEncode(body), 200);
      }),
    );
  });

  tearDown(() async => db.close());

  test('both devices\' transactions are counted, not just the last balance '
      'written', () async {
    // Device A and device B start from the same 100.00 and each add one
    // transaction while offline.
    await insertAccount('acc', 100.0);
    await transactionRepository.addTransaction(tx('tx-a', 10.0, 'acc'));
    expect((await account('acc')).balanceMinor, 11000);

    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    pages = [
      page(
        accounts: [
          accountJson(
            'acc',
            // What device B computed for itself: its own 50 on top of 100. It
            // has never heard of tx-a.
            balance: 150.0,
            balanceMinor: 15000,
            openingBalance: 100.0,
            openingBalanceMinor: 10000,
            designationId: designationId,
            accountTypeId: accountTypeId,
          ),
        ],
        transactions: [
          transactionJson('tx-b', amount: 50.0, amountMinor: 5000, accountId: 'acc'),
        ],
      ),
    ];

    await service.sync();

    final acc = await account('acc');
    expect(
      acc.balanceMinor,
      16000,
      reason: 'the opening 100 plus both transactions; 15000 would mean device '
          "A's transaction is in the list but not in the balance",
    );
    expect(acc.balance, closeTo(160.0, 1e-9));
    expect((await db.select(db.transactions).get()).length, 2);
  });

  test('a server that does not send the anchor keeps the balance it did send',
      () async {
    // Nothing in the payload says what the account opened with, so the only
    // honest reading of it is that the sender's own balance is right and the
    // opening balance is whatever makes it so.
    await insertAccount('acc', 100.0);
    await transactionRepository.addTransaction(tx('tx-a', 10.0, 'acc'));

    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    pages = [
      page(
        accounts: [
          accountJson(
            'acc',
            balance: 150.0,
            balanceMinor: 15000,
            designationId: designationId,
            accountTypeId: accountTypeId,
          ),
        ],
        transactions: [
          transactionJson('tx-b', amount: 50.0, amountMinor: 5000, accountId: 'acc'),
        ],
      ),
    ];

    await service.sync();

    final acc = await account('acc');
    expect(acc.balanceMinor, 15000);
    expect(
      acc.openingBalanceMinor,
      9000,
      reason: 'the anchor absorbs the difference so the rebuild is a no-op '
          'rather than a restatement of the sender\'s balance',
    );
  });

  test('the account a pulled transaction moves away from is rebuilt too',
      () async {
    await insertAccount('acc', 100.0);
    await insertAccount('acc2', 0.0);
    await transactionRepository.addTransaction(tx('tx-a', 10.0, 'acc'));
    expect((await account('acc')).balanceMinor, 11000);

    pages = [
      page(
        transactions: [
          // The same transaction, moved to the other account on device B.
          transactionJson('tx-a', amount: 10.0, amountMinor: 1000, accountId: 'acc2'),
        ],
      ),
    ];

    await service.sync();

    expect(
      (await account('acc')).balanceMinor,
      10000,
      reason: 'nothing in the payload names the account it left, so its id has '
          'to be read before the move overwrites it',
    );
    expect((await account('acc2')).balanceMinor, 1000);
  });

  test('a pulled transaction in a foreign currency does not scale the balance',
      () async {
    await insertAccount('acc', 100.0);

    pages = [
      page(
        transactions: [
          transactionJson(
            'tx-usd',
            amount: 100.0,
            amountMinor: 10000,
            accountId: 'acc',
            currencyCode: 'USD',
          ),
        ],
      ),
    ];

    await service.sync();

    expect((await account('acc')).balanceMinor, 10000);
  });
}
