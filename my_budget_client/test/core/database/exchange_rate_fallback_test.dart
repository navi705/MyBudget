import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';

/// The stored history stops somewhere — the bundled file ends in January and
/// the free API answers 404 for anything past its own last publication — so a
/// budget read today asks for days no row exists on. Returning only exact
/// matches handed the converter an empty set for those days and the dashboard
/// then reported every foreign currency as unconvertible, even though a rate
/// from a fortnight earlier was sitting in the table.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  DateTime day(int d) => DateTime(2026, 1, d);

  Future<void> storeRateOn(DateTime date, double rate) =>
      db.exchangeRatesDao.insertAllExchangeRates([
        ExchangeRatesCompanion.insert(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          rate: rate,
          preset: 0,
          date: date,
        ),
      ]);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Opening the database seeds the whole bundled history; these tests are
    // about which day a lookup falls back to, which is unreadable with a few
    // hundred thousand other rows in the way.
    await db.delete(db.exchangeRates).go();
  });

  tearDown(() async => db.close());

  test('a day past the newest stored rate falls back to that newest rate', () async {
    await storeRateOn(day(20), 0.9);

    final rates = await db.exchangeRatesDao.getAllExchangesRates([day(31)]);

    expect(rates, hasLength(1));
    expect(rates.single.date, day(20));
    expect(rates.single.rate, 0.9);
  });

  test('a day before the oldest stored rate falls back to that oldest rate', () async {
    await storeRateOn(day(20), 0.9);

    final rates = await db.exchangeRatesDao.getAllExchangesRates([day(5)]);

    expect(rates.map((r) => r.date), [day(20)]);
  });

  test('a day inside a hole falls back to whichever side is nearer', () async {
    await storeRateOn(day(1), 0.8);
    await storeRateOn(day(20), 0.9);

    // The 18th is two days from the 20th and seventeen from the 1st.
    final rates = await db.exchangeRatesDao.getAllExchangesRates([day(18)]);

    expect(rates.map((r) => r.date), [day(20)]);

    // And the 4th the other way round.
    final earlier = await db.exchangeRatesDao.getAllExchangesRates([day(4)]);
    expect(earlier.map((r) => r.date), [day(1)]);
  });

  test('an exact match is not doubled up by the fallback', () async {
    await storeRateOn(day(20), 0.9);

    final rates = await db.exchangeRatesDao.getAllExchangesRates([
      day(20),
      day(21),
    ]);

    expect(rates, hasLength(1));
    expect(rates.single.date, day(20));
  });

  test('an empty table falls back to nothing rather than throwing', () async {
    final rates = await db.exchangeRatesDao.getAllExchangesRates([day(20)]);

    expect(rates, isEmpty);
  });

  test('rates naming a currency the app does not know are skipped, not fatal', () async {
    // Both currency columns are foreign keys into `currencies`. A single
    // unknown code used to abort the whole batch with `FOREIGN KEY constraint
    // failed`, which on Android left the table with no rates at all.
    await db.exchangeRatesDao.insertAllExchangeRates([
      ExchangeRatesCompanion.insert(
        fromCurrencyCode: 'NOTACODE',
        toCurrencyCode: 'EUR',
        rate: 1.0,
        preset: 0,
        date: day(20),
      ),
      ExchangeRatesCompanion.insert(
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'EUR',
        rate: 0.9,
        preset: 0,
        date: day(20),
      ),
    ]);

    final rates = await db.exchangeRatesDao.getAllExchangeRates();
    expect(rates.map((r) => r.fromCurrencyCode), ['USD']);
  });

  test('a rate written after the first lookup is not hidden by the day cache', () async {
    await storeRateOn(day(1), 0.8);
    // Warms the cached list of days the table holds rows on.
    expect(
      (await db.exchangeRatesDao.getAllExchangesRates([day(20)])).single.date,
      day(1),
    );

    await storeRateOn(day(19), 0.95);

    final rates = await db.exchangeRatesDao.getAllExchangesRates([day(20)]);
    expect(rates.single.date, day(19));
  });
}
