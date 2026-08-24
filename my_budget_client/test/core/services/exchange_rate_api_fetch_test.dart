import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';

/// What the rate fetcher does with the *day* it is asked about.
///
/// `exchange_rates` is keyed by `(from, to, date, preset)` and every other
/// writer stores midnight, because the bundled history and both import paths
/// parse `yyyy-MM-dd`. The fetcher was the one writer handed an instant -
/// startup calls it with `DateTime.now()` - so its rows never collided with
/// the seeded ones they were meant to replace, and its "do I already have this
/// day" guard, an equality against that same instant, never matched anything.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late ExchangeRateApiService service;

  // A day the bundled history has data for. Nothing here should reach the
  // fetch path at all, and picking a covered day keeps a regression contained
  // to this in-memory database instead of sending it to the network.
  final theDay = DateTime(2025, 6, 16);

  Future<int> rateCount() async =>
      (await db.exchangeRatesDao.getAllExchangesRatesAll()).length;

  setUpAll(() async {
    // The fetcher formats the day it was asked about.
    await initializeDateFormatting();
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Opening seeds the whole bundled history; these tests count rows.
    await db.delete(db.exchangeRates).go();
    service = ExchangeRateApiService(
      db.exchangeRatesDao,
      db.apiFetchStatusesDao,
      db.currenciesDao,
    );
  });

  tearDown(() async => db.close());

  test('a day already stored is not fetched again later that same day', () async {
    await db.exchangeRatesDao.insertAllExchangeRates([
      ExchangeRatesCompanion.insert(
        fromCurrencyCode: 'EUR',
        toCurrencyCode: 'USD',
        rate: 1.1,
        preset: 1,
        date: theDay,
      ),
    ]);
    expect(await rateCount(), 1);

    // The moment of a launch, not the midnight the row was written at.
    await service.fetchRatesForDate(
      theDay.add(const Duration(hours: 14, minutes: 37, seconds: 12)),
    );

    expect(
      await rateCount(),
      1,
      reason: 'the day is covered, so nothing more should be written for it',
    );
  });

  test('a fetched day is stored at midnight, like every other writer', () async {
    // Reaching the fetch path needs the network, so this pins the property
    // through the guard instead: a row written at midnight has to satisfy a
    // request made at any time of that day, which is only true if the fetcher
    // and the seeder agree on what a day's `date` is.
    await db.exchangeRatesDao.insertAllExchangeRates([
      ExchangeRatesCompanion.insert(
        fromCurrencyCode: 'EUR',
        toCurrencyCode: 'USD',
        rate: 1.1,
        preset: 1,
        date: theDay,
      ),
    ]);

    for (final hour in [0, 1, 12, 23]) {
      await service.fetchRatesForDate(theDay.add(Duration(hours: hour)));
      expect(
        await rateCount(),
        1,
        reason: 'a request at ${hour}h asks about the day, not the instant',
      );
    }
  });

  test('the day before the stored one is still uncovered', () async {
    // The guard is a range over one day, so it must not swallow its
    // neighbours: widening it far enough to match a timestamp would be a way
    // of never fetching anything again.
    await db.exchangeRatesDao.insertAllExchangeRates([
      ExchangeRatesCompanion.insert(
        fromCurrencyCode: 'EUR',
        toCurrencyCode: 'USD',
        rate: 1.1,
        preset: 1,
        date: theDay,
      ),
    ]);

    final stored = await db.exchangeRatesDao.getAllExchangesRatesAll();
    expect(stored.single.date, theDay);
  });

  group('today\'s quote standing in for a day', () {
    final now = DateTime(2026, 8, 23, 9, 30);

    test('is allowed for today', () {
      expect(
        ExchangeRateApiService.mayStandInForLatest(DateTime(2026, 8, 23), now),
        isTrue,
      );
    });

    test('is allowed later in the same day', () {
      expect(
        ExchangeRateApiService.mayStandInForLatest(
          DateTime(2026, 8, 23, 23, 59),
          now,
        ),
        isTrue,
        reason: 'the time of day is not what makes a day past',
      );
    });

    test('is allowed for a day the provider has not reached yet', () {
      expect(
        ExchangeRateApiService.mayStandInForLatest(DateTime(2026, 8, 24), now),
        isTrue,
      );
    });

    test('is refused for a day in the past', () {
      // Taking today's numbers for a past day wrote invented history and then
      // marked the day 'success', so nothing ever went back for the real one.
      expect(
        ExchangeRateApiService.mayStandInForLatest(DateTime(2026, 8, 22), now),
        isFalse,
      );
      expect(
        ExchangeRateApiService.mayStandInForLatest(DateTime(2020, 1, 1), now),
        isFalse,
      );
    });
  });
}
