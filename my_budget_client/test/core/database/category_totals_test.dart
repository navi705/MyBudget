import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;

/// Characterization tests for the two production category/transaction
/// aggregate SQLs in `TransactionsDao`
/// (lib/core/database/app_database.dart):
///
///  - `getTransactionTotalsGrouped` (per category/currency/day totals, feeds
///    the exact-minor-unit dashboard breakdown)
///  - `getCategoryTotalsInMainCurrency` (per-category totals converted to a
///    single main currency via EUR-pivoted exchange rates, used by
///    `CategoriesBloc` — lib/presentation/blocs/categories/categories_bloc.dart
///    line ~369 — to build the Categories screen)
///
/// Both are confirmed (by reading the SQL) to filter `is_deleted = 0`/
/// `isDeleted.equals(false)` and to treat `dateFrom`/`dateTo` as inclusive
/// (`>=`/`<=`). These tests pin that behavior so a regression (e.g. someone
/// "optimizing" the WHERE clause) is caught.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late String eurCode;
  late String btcCode;
  late String designationId;
  late String accountTypeId;
  late String catFood;
  late String catSalary;
  late String catEmpty; // never has a transaction

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final currencies = await db.select(db.currencies).get();
    eurCode = currencies.firstWhere((c) => c.code == 'EUR').code;
    btcCode = currencies.firstWhere((c) => c.code == 'BTC').code;
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    accountTypeId = (await db.select(db.accountTypes).get()).first.id;

    // Synthetic fiat currency ('ZZT') not present in the real ~150-currency
    // seed list or the 283k-row seeded exchange-rate history: using a real
    // code like USD here would let the SQL's un-filtered (no `preset`
    // clause), un-LIMIT-1'd exchange-rate subquery silently pick a seeded
    // historical rate instead of the rate this test controls, making the
    // pivot-conversion assertion flaky/wrong. ZZT sidesteps that entirely.
    final languageCode = (await db.select(db.languages).get()).first.languageCode;
    await db.into(db.currencies).insert(
      CurrenciesCompanion.insert(
        name: 'Test Currency Unit',
        code: 'ZZT',
        languageCode: languageCode,
      ),
    );

    await db.into(db.accounts).insert(
      AccountsCompanion.insert(
        id: const Value('acc1'),
        name: 'Acc',
        balance: 0,
        currencyCode: eurCode,
        currencyDesignationId: designationId,
        accountTypeId: accountTypeId,
        creationDate: Value(DateTime(2024, 1, 1)),
      ),
    );

    for (final c in [
      CategoriesCompanion.insert(id: const Value('test_cat_food'), name: 'Food'),
      CategoriesCompanion.insert(
        id: const Value('test_cat_salary'),
        name: 'Salary',
      ),
      CategoriesCompanion.insert(id: const Value('test_cat_empty'), name: 'Empty'),
    ]) {
      await db.into(db.categories).insert(c);
    }
    catFood = 'test_cat_food';
    catSalary = 'test_cat_salary';
    catEmpty = 'test_cat_empty';

    Future<void> tx({
      required String id,
      required String category,
      required double amount,
      required DateTime date,
      String? currency,
      bool isDeleted = false,
    }) {
      return db.into(db.transactions).insert(
        TransactionsCompanion.insert(
          id: Value(id),
          description: id,
          amount: amount,
          date: date,
          accountId: 'acc1',
          categoryId: category,
          currencyCode: currency ?? eurCode,
          isDeleted: Value(isDeleted),
        ),
      );
    }

    // -- getTransactionTotalsGrouped / sign + soft-delete + boundary fixtures --
    // Expense (negative) and income (positive) on the same day/category.
    await tx(
      id: 'g_expense',
      category: catFood,
      amount: -12.34,
      date: DateTime(2025, 6, 10),
    );
    await tx(
      id: 'g_income',
      category: catSalary,
      amount: 2000.00,
      date: DateTime(2025, 6, 10),
    );
    // Soft-deleted row: must be excluded from every grouped total.
    await tx(
      id: 'g_deleted',
      category: catFood,
      amount: -999.99,
      date: DateTime(2025, 6, 10),
      isDeleted: true,
    );
    // Crypto transaction: amountMinor stays NULL, must fall back to the
    // double `amount` sum.
    await tx(
      id: 'g_crypto',
      category: catFood,
      amount: 0.5,
      date: DateTime(2025, 6, 10),
      currency: btcCode,
    );
    // Boundary fixtures: one exactly on dateFrom, one exactly on dateTo.
    await tx(
      id: 'g_on_from',
      category: catFood,
      amount: -1.00,
      date: DateTime(2025, 6, 1),
    );
    await tx(
      id: 'g_on_to',
      category: catFood,
      amount: -2.00,
      date: DateTime(2025, 6, 30),
    );
    // Just outside the range on both sides.
    await tx(
      id: 'g_before_range',
      category: catFood,
      amount: -5.00,
      date: DateTime(2025, 5, 31),
    );
    await tx(
      id: 'g_after_range',
      category: catFood,
      amount: -7.00,
      date: DateTime(2025, 7, 1),
    );

    // -- getCategoryTotalsInMainCurrency fixtures --
    // A same-day EUR->ZZT rate so a non-EUR, non-main-currency transaction
    // needs the two-step EUR pivot.
    await db.into(db.exchangeRates).insert(
      ExchangeRatesCompanion.insert(
        fromCurrencyCode: 'EUR',
        toCurrencyCode: 'ZZT',
        rate: 2.0, // 1 EUR = 2 ZZT, deliberately not 1:1 so pivoting is visible
        preset: 0,
        date: DateTime(2025, 6, 15),
      ),
    );
    await tx(
      id: 'm_eur_expense',
      category: catFood,
      amount: -10.0,
      date: DateTime(2025, 6, 15),
    );
    await tx(
      id: 'm_zzt_income',
      category: catSalary,
      amount: 50.0,
      date: DateTime(2025, 6, 15),
      currency: 'ZZT',
    );
    await tx(
      id: 'm_deleted',
      category: catFood,
      amount: -123.0,
      date: DateTime(2025, 6, 15),
      isDeleted: true,
    );
  });

  tearDownAll(() async {
    await db.close();
  });

  group('getTransactionTotalsGrouped', () {
    test('preserves the signed amount (income positive, expense negative) '
        'per category/currency/day group', () async {
      final totals = await db.transactionsDao.getTransactionTotalsGrouped(
        dateFrom: DateTime(2025, 6, 10),
        dateTo: DateTime(2025, 6, 10),
      );

      final food = totals.firstWhere(
        (t) => t.categoryId == catFood && t.currencyCode == eurCode,
      );
      final salary = totals.firstWhere((t) => t.categoryId == catSalary);

      // Would fail if the SQL summed abs(amount) or dropped the sign.
      expect(food.total, -12.34);
      expect(salary.total, 2000.00);
    });

    test('excludes soft-deleted transactions from the group total', () async {
      final totals = await db.transactionsDao.getTransactionTotalsGrouped(
        dateFrom: DateTime(2025, 6, 10),
        dateTo: DateTime(2025, 6, 10),
      );
      final food = totals.firstWhere(
        (t) => t.categoryId == catFood && t.currencyCode == eurCode,
      );
      // If the -999.99 soft-deleted row were included, this would be
      // -1012.33 instead of -12.34.
      expect(food.total, -12.34);
    });

    test('crypto group falls back to the double amount sum (amountMinor is '
        'NULL for crypto, never coerced to 0)', () async {
      final totals = await db.transactionsDao.getTransactionTotalsGrouped(
        dateFrom: DateTime(2025, 6, 10),
        dateTo: DateTime(2025, 6, 10),
      );
      final crypto = totals.firstWhere((t) => t.currencyCode == btcCode);
      expect(crypto.total, 0.5);
    });

    test('dateFrom/dateTo are both inclusive', () async {
      final totals = await db.transactionsDao.getTransactionTotalsGrouped(
        dateFrom: DateTime(2025, 6, 1),
        dateTo: DateTime(2025, 6, 30),
      );
      final byId = {
        for (final t in totals)
          if (t.categoryId == catFood && t.currencyCode == eurCode)
            t.date: t.total,
      };
      // The boundary-day rows are included...
      expect(byId[DateTime(2025, 6, 1)], -1.00);
      expect(byId[DateTime(2025, 6, 30)], -2.00);
      // ...but the rows one day outside the range are not.
      expect(byId.containsKey(DateTime(2025, 5, 31)), isFalse);
      expect(byId.containsKey(DateTime(2025, 7, 1)), isFalse);
    });

    test('a category with zero transactions in range produces no group row '
        '(caller treats absence as 0, verified against the real DAO return '
        'type: List<GroupedTransactionTotal>, not a total-per-category map)',
        () async {
      final totals = await db.transactionsDao.getTransactionTotalsGrouped(
        dateFrom: DateTime(2025, 6, 10),
        dateTo: DateTime(2025, 6, 10),
      );
      expect(totals.any((t) => t.categoryId == catEmpty), isFalse);
    });
  });

  group('getCategoryTotalsInMainCurrency', () {
    test('converts through the EUR pivot and preserves sign, when main '
        'currency differs from both EUR and the transaction currency',
        () async {
      final totals = await db.transactionsDao.getCategoryTotalsInMainCurrency(
        dateFrom: DateTime(2025, 6, 15),
        dateTo: DateTime(2025, 6, 15),
        mainCurrencyCode: 'ZZT',
      );

      // EUR -10.0 expense -> ZZT at rate 2.0 -> -20.0.
      expect(totals[catFood], closeTo(-20.0, 1e-9));
      // ZZT 50.0 income, main currency IS ZZT: step1 (ZZT->EUR) derives from
      // inverting the seeded EUR->ZZT rate (1/2.0=0.5), step2 (EUR->ZZT)
      // uses it directly (2.0); 0.5*2.0 round-trips to identity -> unchanged.
      expect(totals[catSalary], closeTo(50.0, 1e-9));
    });

    test('excludes soft-deleted transactions', () async {
      final totals = await db.transactionsDao.getCategoryTotalsInMainCurrency(
        dateFrom: DateTime(2025, 6, 15),
        dateTo: DateTime(2025, 6, 15),
        mainCurrencyCode: 'EUR',
      );
      // If the soft-deleted -123.0 EUR row were included, catFood would be
      // -10.0 + -123.0 = -133.0 instead of -10.0.
      expect(totals[catFood], closeTo(-10.0, 1e-9));
    });

    test(
      'a category with zero transactions in range is ABSENT from the map, '
      'not present with value 0.0 (unlike getCategoriesWithTotals\' LEFT '
      'JOIN) — this is safe only because every call site does '
      '`map[category.id] ?? 0.0` (see categories_bloc.dart line ~379)',
      () async {
        final totals = await db.transactionsDao
            .getCategoryTotalsInMainCurrency(
              dateFrom: DateTime(2025, 6, 15),
              dateTo: DateTime(2025, 6, 15),
              mainCurrencyCode: 'EUR',
            );
        expect(totals.containsKey(catEmpty), isFalse);
      },
    );
  });

  group('getCategoriesWithTotals', () {
    // Own categories, own date window (2027) and an own name prefix, so this
    // group's assertions are unaffected by the fixtures above.
    setUpAll(() async {
      for (final c in [
        CategoriesCompanion.insert(
          id: const Value('gcwt_live'),
          name: 'GCWT Live',
        ),
        CategoriesCompanion.insert(
          id: const Value('gcwt_gone'),
          name: 'GCWT Gone',
        ),
      ]) {
        await db.into(db.categories).insert(c);
      }

      Future<void> tx({
        required String id,
        required String category,
        required double amount,
        bool isDeleted = false,
      }) {
        return db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            id: Value(id),
            description: id,
            amount: amount,
            date: DateTime(2027, 1, 15),
            accountId: 'acc1',
            categoryId: category,
            currencyCode: eurCode,
            isDeleted: Value(isDeleted),
          ),
        );
      }

      await tx(id: 'gcwt_a', category: 'gcwt_live', amount: -10.0);
      await tx(id: 'gcwt_b', category: 'gcwt_live', amount: -5.0);
      await tx(
        id: 'gcwt_deleted',
        category: 'gcwt_live',
        amount: -1000.0,
        isDeleted: true,
      );
      await tx(id: 'gcwt_c', category: 'gcwt_gone', amount: -3.0);

      await db.categoriesDao.deleteCategory(
        CategoriesCompanion(id: const Value('gcwt_gone')),
      );
    });

    test('excludes soft-deleted transactions from the total', () async {
      final results = await db.categoriesDao.getCategoriesWithTotals(
        name: 'GCWT Live',
        dateFrom: DateTime(2027, 1, 1),
        dateTo: DateTime(2027, 1, 31),
      );
      final live = results.singleWhere((r) => r.category.id == 'gcwt_live');
      // The subquery had no is_deleted filter, so the -1000.0 row the user
      // had already deleted was still inflating the Categories screen:
      // -1015.0 instead of -15.0.
      expect(live.total, closeTo(-15.0, 1e-9));
    });

    test('excludes soft-deleted categories from the result rows', () async {
      final results = await db.categoriesDao.getCategoriesWithTotals(
        name: 'GCWT',
        dateFrom: DateTime(2027, 1, 1),
        dateTo: DateTime(2027, 1, 31),
      );
      expect(results.map((r) => r.category.id), ['gcwt_live']);
    });

    test('a category with no transaction in range still appears, with 0.0 '
        '(the LEFT JOIN is load-bearing)', () async {
      final results = await db.categoriesDao.getCategoriesWithTotals(
        name: 'GCWT Live',
        dateFrom: DateTime(2028, 1, 1),
        dateTo: DateTime(2028, 1, 31),
      );
      final live = results.singleWhere((r) => r.category.id == 'gcwt_live');
      expect(live.total, 0.0);
    });
  });
}
