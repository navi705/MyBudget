import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';

/// Verifies the v7->v8 minor-unit backfill SQL: fiat rows get exact integer
/// minor units at the right per-currency scale; crypto rows stay NULL.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  Future<String> commonIds() async {
    // Return a category id; designations/types fetched inline where needed.
    return (await db.select(db.categories).get()).first.id;
  }

  Future<void> account(String id, String code, double balance) async {
    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: Value(id),
            name: id,
            balance: balance,
            currencyCode: code,
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
          ),
        );
  }

  Future<void> tx(
    String id,
    String acc,
    String code,
    double amount,
    double fee,
  ) async {
    final categoryId = await commonIds();
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            id: Value(id),
            description: id,
            amount: amount,
            date: DateTime(2024, 1, 1),
            accountId: acc,
            categoryId: categoryId,
            currencyCode: code,
            fee: Value(fee),
          ),
        );
  }

  Future<int?> accBalanceMinor(String id) async {
    final row = await (db.select(db.accounts)..where((a) => a.id.equals(id)))
        .getSingle();
    return row.balanceMinor;
  }

  Future<(int?, int?)> txMinor(String id) async {
    final row =
        await (db.select(db.transactions)..where((t) => t.id.equals(id)))
            .getSingle();
    return (row.amountMinor, row.feeMinor);
  }

  test('backfills fiat balances at the right scale, crypto stays null',
      () async {
    await account('eur', 'EUR', 123.45);
    await account('jpy', 'JPY', 1000); // 0-decimal
    await account('kwd', 'KWD', 1.234); // 3-decimal
    await account('btc', 'BTC', 0.5); // crypto

    await db.backfillMinorUnits();

    expect(await accBalanceMinor('eur'), 12345);
    expect(await accBalanceMinor('jpy'), 1000);
    expect(await accBalanceMinor('kwd'), 1234);
    expect(await accBalanceMinor('btc'), isNull); // crypto not scaled
  });

  test('backfills transaction amount and fee for fiat, null for crypto',
      () async {
    await account('eur', 'EUR', 0);
    await account('btc', 'BTC', 0);
    await tx('t1', 'eur', 'EUR', 10.10, 0.05);
    await tx('t2', 'btc', 'BTC', 0.25, 0.0);

    await db.backfillMinorUnits();

    expect(await txMinor('t1'), (1010, 5));
    expect(await txMinor('t2'), (null, null));
  });

  test('getTransactionTotalsGrouped subtotals are exact for fiat', () async {
    await account('eur', 'EUR', 0);
    await tx('a', 'eur', 'EUR', 0.1, 0.0);
    await tx('b', 'eur', 'EUR', 0.2, 0.0);
    await db.backfillMinorUnits();

    final totals = await db.transactionsDao.getTransactionTotalsGrouped();
    final eur =
        totals.where((t) => t.currencyCode == 'EUR').fold<double>(0, (s, t) => s + t.total);

    // 0.1 + 0.2 via integer minor units == exactly 0.3 (double SUM would be
    // 0.30000000000000004).
    expect(eur, 0.3);
  });
}
