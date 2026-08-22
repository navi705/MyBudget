import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';

/// The table holds a row per currency pair per day — 341 currencies over 870
/// days is close to 300k rows on the phone this was measured on — and a screen
/// prices amounts in a handful of them. Reading all of them back to convert
/// fifty rows was most of what a page load did, so callers can now name the
/// codes they care about.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  DateTime day(int d) => DateTime(2026, 1, d);

  Future<void> storeRate(String from, String to, DateTime date) =>
      db.exchangeRatesDao.insertAllExchangeRates([
        ExchangeRatesCompanion.insert(
          fromCurrencyCode: from,
          toCurrencyCode: to,
          rate: 1.5,
          preset: 0,
          date: date,
        ),
      ]);

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Opening the database seeds the whole bundled history, which would drown
    // out the handful of rows each test is about.
    await db.delete(db.exchangeRates).go();
  });

  tearDown(() async => db.close());

  test('only the pairs that touch one of the codes come back', () async {
    await storeRate('USD', 'EUR', day(10));
    await storeRate('USD', 'JPY', day(10));
    await storeRate('USD', 'GBP', day(10));

    final rates = await db.exchangeRatesDao.getAllExchangesRates(
      [day(10)],
      currencyCodes: {'EUR'},
    );

    expect(rates.map((r) => r.toCurrencyCode), ['EUR']);
  });

  test('a code on the from side counts as a match', () async {
    await storeRate('GBP', 'JPY', day(10));
    await storeRate('USD', 'JPY', day(10));

    final rates = await db.exchangeRatesDao.getAllExchangesRates(
      [day(10)],
      currencyCodes: {'GBP'},
    );

    expect(rates.map((r) => r.fromCurrencyCode), ['GBP']);
  });

  test('the two halves of a triangular hop both survive the filter', () async {
    // EUR -> JPY has no row of its own; the converter pivots through USD, and
    // each leg of that hop touches a wanted code on one side only. An AND over
    // the pair would drop both and report JPY as unconvertible.
    await storeRate('USD', 'EUR', day(10));
    await storeRate('USD', 'JPY', day(10));
    await storeRate('USD', 'GBP', day(10));

    final rates = await db.exchangeRatesDao.getAllExchangesRates(
      [day(10)],
      currencyCodes: {'EUR', 'JPY'},
    );

    expect(rates.map((r) => r.toCurrencyCode).toSet(), {'EUR', 'JPY'});
  });

  test('the fallback to a nearby day is filtered the same way', () async {
    // Nothing on the day asked about, so the lookup falls back to the nearest
    // stored day — and has to apply the filter there too, or the saving is
    // undone by whatever the gap pulls in.
    await storeRate('USD', 'EUR', day(10));
    await storeRate('USD', 'JPY', day(10));

    final rates = await db.exchangeRatesDao.getAllExchangesRates(
      [day(25)],
      currencyCodes: {'EUR'},
    );

    expect(rates, hasLength(1));
    expect(rates.single.toCurrencyCode, 'EUR');
    expect(rates.single.date, day(10));
  });

  test('no codes means every pair, as before', () async {
    await storeRate('USD', 'EUR', day(10));
    await storeRate('USD', 'JPY', day(10));

    final all = await db.exchangeRatesDao.getAllExchangesRates([day(10)]);
    final empty = await db.exchangeRatesDao.getAllExchangesRates(
      [day(10)],
      currencyCodes: const {},
    );

    expect(all, hasLength(2));
    expect(empty, hasLength(2));
  });
}
