import 'package:my_budget_server/rates/rate_request.dart';
import 'package:my_budget_server/rates/rate_store.dart';
import 'package:test/test.dart';

void main() {
  group('parseRateQuery', () {
    test('defaults to EUR, every currency, and the fetched preset', () {
      final parsed = parseRateQuery({});
      final query = parsed.query!;

      expect(parsed.error, isNull);
      expect(query.fromCurrencyCode, 'EUR');
      expect(query.toCurrencyCodes, isEmpty);
      expect(query.preset, kFetchedRatePreset);
      expect(query.limit, defaultRateLimit);
      expect(query.dateFrom, isNull);
      expect(query.dateTo, isNull);
    });

    test('upper-cases and de-duplicates the `to` list', () {
      final query = parseRateQuery({'to': 'usd, USD ,jpy'}).query!;

      expect(query.toCurrencyCodes, ['USD', 'JPY']);
    });

    test('rejects a `to` entry that is not a currency code', () {
      final parsed = parseRateQuery({'to': 'USD,US D'});

      expect(parsed.query, isNull);
      expect(parsed.error!.message, contains('`to`'));
    });

    test('refuses a `to` list longer than the cap', () {
      final codes =
          List.generate(maxRateCurrencies + 1, (i) => 'C${i.toString()}');
      final parsed = parseRateQuery({'to': codes.join(',')});

      expect(parsed.query, isNull);
      expect(parsed.error!.message, contains('$maxRateCurrencies'));
    });

    test('`date` is a one-day window, normalised to UTC midnight', () {
      final query = parseRateQuery({'date': '2026-03-14T15:00:00Z'}).query!;

      expect(query.dateFrom, DateTime.utc(2026, 3, 14));
      expect(query.dateTo, DateTime.utc(2026, 3, 14));
    });

    test('`date` wins over the range parameters', () {
      final query = parseRateQuery({
        'date': '2026-03-14',
        'date_from': '2020-01-01',
        'date_to': '2030-01-01',
      }).query!;

      expect(query.dateFrom, DateTime.utc(2026, 3, 14));
      expect(query.dateTo, DateTime.utc(2026, 3, 14));
    });

    test('rejects an inverted range rather than returning nothing', () {
      // An empty result would read to the client as "no data published",
      // which is the answer it gives up on rather than retries.
      final parsed = parseRateQuery({
        'date_from': '2026-03-14',
        'date_to': '2026-03-01',
      });

      expect(parsed.query, isNull);
      expect(parsed.error!.message, contains('after'));
    });

    test('rejects an unparseable date', () {
      expect(parseRateQuery({'date': 'yesterday'}).error, isNotNull);
      expect(parseRateQuery({'date_from': 'yesterday'}).error, isNotNull);
      expect(parseRateQuery({'date_to': 'yesterday'}).error, isNotNull);
    });

    test('`preset=all` asks for every preset, a number for exactly one', () {
      expect(parseRateQuery({'preset': 'all'}).query!.preset, isNull);
      expect(parseRateQuery({'preset': 'ALL'}).query!.preset, isNull);
      expect(parseRateQuery({'preset': '0'}).query!.preset, 0);
    });

    test('rejects a preset that is neither', () {
      final parsed = parseRateQuery({'preset': 'fetched'});

      expect(parsed.query, isNull);
      expect(parsed.error!.message, contains('`preset`'));
    });

    test('rejects a `from` that is not a currency code', () {
      expect(parseRateQuery({'from': 'e'}).error, isNotNull);
      expect(parseRateQuery({'from': 'eur;drop'}).error, isNotNull);
      expect(parseRateQuery({'from': 'btc'}).query!.fromCurrencyCode, 'BTC');
    });

    test('an empty parameter falls back rather than failing', () {
      final query = parseRateQuery({
        'from': '  ',
        'to': '',
        'date': '',
        'preset': '',
      }).query!;

      expect(query.fromCurrencyCode, 'EUR');
      expect(query.toCurrencyCodes, isEmpty);
      expect(query.dateFrom, isNull);
      expect(query.preset, kFetchedRatePreset);
    });
  });

  group('parseRateLimit', () {
    test('falls back when missing or unparseable', () {
      expect(parseRateLimit(null), defaultRateLimit);
      expect(parseRateLimit('lots'), defaultRateLimit);
    });

    test('clamps instead of rejecting', () {
      // `LIMIT 0` reads to the caller as "nothing to fetch" and stalls it
      // silently, which is worse than handing back a small page.
      expect(parseRateLimit('0'), 1);
      expect(parseRateLimit('-5'), 1);
      expect(parseRateLimit('${maxRateLimit + 1}'), maxRateLimit);
      expect(parseRateLimit(' 42 '), 42);
    });
  });
}
