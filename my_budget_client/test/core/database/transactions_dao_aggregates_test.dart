import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' hide Transaction;
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';

/// Characterization tests for the SQL balance aggregates
/// (`getSumOfTransactionsAfterDate`, `getFutureSumsGrouped`) against the
/// current Dart engine (`FinanceCalculator.calculateBalances`).
///
/// These pin the equivalence that the planned AccountsBloc SQL-aggregate swap
/// relies on: for a STANDARD account,
///   balanceAt(date) == storedBalance - SUM(amount WHERE date > target)
/// which is exactly what `getFutureSumsGrouped` returns. They also nail down
/// the one place the two disagree — the day boundary — so the swap is made
/// deliberately, not by accident.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late String currencyCode;
  late String designationId;
  late String accountTypeId;
  late String categoryId;

  // Known target day used across tests.
  final targetDay = DateTime(2025, 3, 15);
  final targetEndOfDay = DateTime(2025, 3, 15, 23, 59, 59);

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    // Reuse seeded reference rows to satisfy FKs (foreign_keys = ON).
    final currencies = await db.select(db.currencies).get();
    final cur = currencies.firstWhere(
      (c) => c.code == 'EUR',
      orElse: () => currencies.first,
    );
    currencyCode = cur.code;
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    categoryId = (await db.select(db.categories).get()).first.id;

    // Account A: standard, stored balance 1000, only inter-day transactions.
    await db.into(db.accounts).insert(
      AccountsCompanion.insert(
        id: const Value('accA'),
        name: 'Account A',
        balance: 1000.0,
        currencyCode: currencyCode,
        currencyDesignationId: designationId,
        accountTypeId: accountTypeId,
        creationDate: Value(DateTime(2024, 1, 1)),
      ),
    );

    // Account B: standard, stored balance 500, one INTRADAY tx on the target day.
    await db.into(db.accounts).insert(
      AccountsCompanion.insert(
        id: const Value('accB'),
        name: 'Account B',
        balance: 500.0,
        currencyCode: currencyCode,
        currencyDesignationId: designationId,
        accountTypeId: accountTypeId,
        creationDate: Value(DateTime(2024, 1, 1)),
      ),
    );

    Future<void> tx(String id, String acc, double amount, DateTime date) {
      return db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          id: Value(id),
          description: id,
          amount: amount,
          date: date,
          accountId: acc,
          categoryId: categoryId,
          currencyCode: currencyCode,
        ),
      );
    }

    // Account A transactions.
    await tx('a1', 'accA', 200.0, DateTime(2025, 3, 10)); // before target
    await tx('a2', 'accA', 50.0, DateTime(2025, 3, 20)); // after target
    await tx('a3', 'accA', -30.0, DateTime(2025, 3, 25)); // after target

    // Account B transaction: intraday on the target day at 10:00.
    await tx('b1', 'accB', 100.0, DateTime(2025, 3, 15, 10, 0));
  });

  tearDownAll(() async {
    await db.close();
  });

  // Domain transactions mirroring what was inserted, for FinanceCalculator.
  List<Transaction> domainTx() => [
    Transaction(id: 'a1', description: 'a1', amount: 200.0, date: DateTime(2025, 3, 10), accountId: 'accA', categoryId: 'c', currencyCode: 'EUR'),
    Transaction(id: 'a2', description: 'a2', amount: 50.0, date: DateTime(2025, 3, 20), accountId: 'accA', categoryId: 'c', currencyCode: 'EUR'),
    Transaction(id: 'a3', description: 'a3', amount: -30.0, date: DateTime(2025, 3, 25), accountId: 'accA', categoryId: 'c', currencyCode: 'EUR'),
    Transaction(id: 'b1', description: 'b1', amount: 100.0, date: DateTime(2025, 3, 15, 10, 0), accountId: 'accB', categoryId: 'c', currencyCode: 'EUR'),
  ];

  Account domainAccount(String id, double balance) => Account(
    id: id,
    name: id,
    balance: balance,
    currencyCode: 'EUR',
    currencyDesignationId: 'code',
    accountTypeId: 'general',
    creationDate: DateTime(2024, 1, 1),
  );

  FinancialSnapshot snapshotAt(DateTime date) => FinancialSnapshot(
    accounts: [domainAccount('accA', 1000.0), domainAccount('accB', 500.0)],
    transactions: domainTx(),
    assetData: const [],
    categories: const [],
    exchangeRates: const [],
    inflationRates: const [],
    date: date,
    dateStep: DateStep.day,
    baseCurrency: 'EUR',
  );

  group('getSumOfTransactionsAfterDate', () {
    test('sums only strictly-after-end-of-day transactions', () async {
      // Account A future txs relative to 2025-03-15: a2 (+50), a3 (-30) => 20.
      final sum = await db.transactionsDao.getSumOfTransactionsAfterDate(
        'accA',
        targetDay,
      );
      expect(sum, 20.0);
    });

    test('intraday transaction on target day is NOT counted as future', () async {
      // b1 is at 10:00 on the target day; end-of-day cutoff excludes it.
      final sum = await db.transactionsDao.getSumOfTransactionsAfterDate(
        'accB',
        targetDay,
      );
      expect(sum, 0.0);
    });
  });

  group('getFutureSumsGrouped', () {
    test('groups future sums per account', () async {
      final sums = await db.transactionsDao.getFutureSumsGrouped(targetDay);
      expect(sums['accA'], 20.0);
      // accB has no future tx (its only tx is intraday on the target day).
      expect(sums['accB'], isNull);
    });
  });

  group('SQL aggregate == FinanceCalculator (equivalence the swap relies on)', () {
    test('inter-day account matches at end-of-day target', () async {
      final futureSums = await db.transactionsDao.getFutureSumsGrouped(targetDay);
      final sqlBalanceA = 1000.0 - (futureSums['accA'] ?? 0.0);

      // FinanceCalculator with end-of-day reference (matches SQL cutoff).
      final fcBalances =
          FinanceCalculator().calculateBalances(snapshotAt(targetEndOfDay));

      expect(sqlBalanceA, 980.0);
      expect(fcBalances['accA'], sqlBalanceA);
    });

    test(
      'BOUNDARY: FinanceCalculator at MIDNIGHT diverges from SQL on intraday tx',
      () async {
        final futureSums =
            await db.transactionsDao.getFutureSumsGrouped(targetDay);
        final sqlBalanceB = 500.0 - (futureSums['accB'] ?? 0.0); // 500

        // At midnight, the 10:00 intraday tx counts as "future" and is undone.
        final fcMidnight =
            FinanceCalculator().calculateBalances(snapshotAt(targetDay));
        // At end-of-day, it is included — matching SQL.
        final fcEndOfDay =
            FinanceCalculator().calculateBalances(snapshotAt(targetEndOfDay));

        expect(sqlBalanceB, 500.0);
        expect(fcEndOfDay['accB'], 500.0, reason: 'end-of-day matches SQL');
        expect(
          fcMidnight['accB'],
          400.0,
          reason:
              'midnight target treats same-day tx as future -> DIVERGES from SQL. '
              'The swap must normalize the target to end-of-day.',
        );
      },
    );
  });
}
