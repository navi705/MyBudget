import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;

/// How `getCategoryTotalsInMainCurrency` picks the rate it converts with.
///
/// The SQL used to compare `date(date/1000, 'unixepoch')` on both sides.
/// Drift stores a DateTime as unix SECONDS, so that divided an already-divided
/// value and folded roughly every date inside a 2.7-year span onto one bucket:
/// the equality then matched an arbitrary rate from that span, and which one it
/// found depended on index order. These fixtures put two rates years apart on
/// the same pair, which is exactly the case that bucket could not tell apart.
///
/// Synthetic currency codes, because the seed ships a real rate history and a
/// real code would let the subqueries find a rate this test did not write.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  const zzq = 'ZZQ';

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final languageCode = (await db.select(db.languages).get())
        .first
        .languageCode;
    await db
        .into(db.currencies)
        .insert(
          CurrenciesCompanion.insert(
            name: 'Rate Date Test Unit',
            code: zzq,
            languageCode: languageCode,
          ),
        );

    await db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: const Value('rd_acc'),
            name: 'Acc',
            balance: 0,
            currencyCode: 'EUR',
            currencyDesignationId: (await db
                .select(db.currencyDesignations)
                .get()).first.id,
            accountTypeId: (await db.select(db.accountTypes).get()).first.id,
            creationDate: Value(DateTime(2018, 1, 1)),
          ),
        );

    for (final id in ['rd_recent', 'rd_old', 'rd_gap', 'rd_same']) {
      await db
          .into(db.categories)
          .insert(CategoriesCompanion.insert(id: Value(id), name: id));
    }

    Future<void> rate(String from, String to, double value, DateTime date) =>
        db
            .into(db.exchangeRates)
            .insert(
              ExchangeRatesCompanion.insert(
                fromCurrencyCode: from,
                toCurrencyCode: to,
                rate: value,
                preset: 0,
                date: date,
              ),
            );

    // Two rates on one pair, five years apart. Under the collapsed bucket both
    // are "the same day" and the older one wins.
    await rate('EUR', zzq, 10.0, DateTime(2020, 1, 1));
    await rate('EUR', zzq, 2.0, DateTime(2025, 6, 1));
    // Deliberately not the inverse of either: a round trip through EUR and
    // back would show up as a changed number rather than as float noise.
    await rate(zzq, 'EUR', 0.4, DateTime(2025, 6, 10));

    Future<void> tx(
      String category,
      double amount,
      DateTime date, {
      String currency = 'EUR',
    }) => db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: Value('tx_$category'),
            description: category,
            amount: amount,
            date: date,
            accountId: 'rd_acc',
            categoryId: category,
            currencyCode: currency,
          ),
        );

    // After the newer rate.
    await tx('rd_recent', 100.0, DateTime(2025, 6, 15));
    // Before every rate this database holds.
    await tx('rd_old', 100.0, DateTime(2019, 1, 1));
    // Between the two rates, on a day no rate was quoted at all.
    await tx('rd_gap', 100.0, DateTime(2023, 3, 3));
    // Already in the main currency.
    await tx('rd_same', 50.0, DateTime(2025, 6, 15), currency: zzq);
  });

  tearDownAll(() async => db.close());

  Future<Map<String, double>> totals() => db.transactionsDao
      .getCategoryTotalsInMainCurrency(mainCurrencyCode: zzq);

  test('converts at the rate in effect on the transaction date', () async {
    // 100 EUR at the 2025-06-01 rate of 2.0. The 2020 rate of 10.0 is the
    // wrong answer the collapsed bucket used to give.
    expect((await totals())['rd_recent'], closeTo(200.0, 0.0001));
  });

  test('a day with no rate of its own takes the last one quoted', () async {
    // 2023-03-03 sits between the two rates; the one in effect is the 2020
    // one, not the 2025 one that had not been quoted yet.
    expect((await totals())['rd_gap'], closeTo(1000.0, 0.0001));
  });

  test('a transaction older than every rate reaches forward', () async {
    // Nothing was in effect yet, so the earliest rate is the only honest
    // answer available - and it beats the silent 1.0 that would read 100 EUR
    // as 100 ZZQ.
    expect((await totals())['rd_old'], closeTo(1000.0, 0.0001));
  });

  test('an amount already in the main currency is not converted', () async {
    // Pivoting ZZQ -> EUR -> ZZQ over rates that are not each other's inverse
    // would return 40.0. There is nothing to convert here, so nothing should
    // be looked up.
    expect((await totals())['rd_same'], closeTo(50.0, 0.0001));
  });
}
