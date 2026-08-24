import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/services/custom_api_service.dart';

/// A custom data source is a URL the user typed, so its answer is only as
/// well-formed as the server behind it. Every row used to be read with bare
/// casts, so a single row in the wrong shape threw out of the middle of the
/// loop and the whole answer was lost - reported to the user as a failed
/// fetch, with nothing to say which row did it.
void main() {
  // assetCompanionsFor formats the day for the deterministic id.
  setUpAll(initializeDateFormatting);

  group('rateCompanionsFor', () {
    test('reads a well-formed row', () {
      final companions = CustomApiService.rateCompanionsFor([
        {'date': '2026-08-22', 'from': 'EUR', 'to': 'USD', 'rate': 1.09},
      ]);

      expect(companions, hasLength(1));
      expect(companions.single.date.value, DateTime(2026, 8, 22));
      expect(companions.single.fromCurrencyCode.value, 'EUR');
      expect(companions.single.toCurrencyCode.value, 'USD');
      expect(companions.single.rate.value, 1.09);
      expect(companions.single.preset.value, 2);
    });

    test('keeps the good rows when one is unreadable', () {
      final companions = CustomApiService.rateCompanionsFor([
        {'date': '2026-08-22', 'from': 'EUR', 'to': 'USD', 'rate': 1.09},
        {'date': 'the 22nd', 'from': 'EUR', 'to': 'GBP', 'rate': 0.85},
        {'date': '2026-08-22', 'from': 'EUR', 'to': 'CHF', 'rate': 0.94},
      ]);

      expect(
        companions.map((c) => c.toCurrencyCode.value),
        ['USD', 'CHF'],
      );
    });

    test('upper-cases the codes', () {
      // Every other writer of this table stores upper case, and a code stored
      // in another case is one no lookup in the app finds.
      final companions = CustomApiService.rateCompanionsFor([
        {'date': '2026-08-22', 'from': 'eur', 'to': 'usd', 'rate': 1.09},
      ]);

      expect(companions.single.fromCurrencyCode.value, 'EUR');
      expect(companions.single.toCurrencyCode.value, 'USD');
    });

    test('reads a rate quoted as a string', () {
      final companions = CustomApiService.rateCompanionsFor([
        {'date': '2026-08-22', 'from': 'EUR', 'to': 'USD', 'rate': '1.09'},
      ]);

      expect(companions.single.rate.value, 1.09);
    });

    test('refuses a rate that cannot convert', () {
      final companions = CustomApiService.rateCompanionsFor([
        {'date': '2026-08-22', 'from': 'EUR', 'to': 'USD', 'rate': 0},
        {'date': '2026-08-22', 'from': 'EUR', 'to': 'GBP', 'rate': -1.2},
        {'date': '2026-08-22', 'from': 'EUR', 'to': 'CHF', 'rate': 'soon'},
        {'date': '2026-08-22', 'from': 'EUR', 'to': 'SEK'},
      ]);

      expect(companions, isEmpty);
    });

    test('refuses a row missing a currency', () {
      final companions = CustomApiService.rateCompanionsFor([
        {'date': '2026-08-22', 'to': 'USD', 'rate': 1.09},
        {'date': '2026-08-22', 'from': '  ', 'to': 'USD', 'rate': 1.09},
        {'date': '2026-08-22', 'from': 'EUR', 'to': 7, 'rate': 1.09},
      ]);

      expect(companions, isEmpty);
    });

    test('refuses a row that is not an object', () {
      expect(
        CustomApiService.rateCompanionsFor([null, 5, 'EUR', <int>[]]),
        isEmpty,
      );
    });
  });

  group('inflationCompanionsFor', () {
    test('reads a well-formed row and upper-cases the country', () {
      final companions = CustomApiService.inflationCompanionsFor([
        {'date': '2025-01-01', 'country': 'srb', 'rate': 4.2},
      ]);

      expect(companions.single.country.value, 'SRB');
      expect(companions.single.percent.value, 4.2);
      expect(companions.single.date.value, DateTime(2025, 1, 1));
    });

    test('keeps a negative percent', () {
      // Deflation is a real reading, not a bad row.
      final companions = CustomApiService.inflationCompanionsFor([
        {'date': '2025-01-01', 'country': 'JPN', 'rate': -0.4},
      ]);

      expect(companions.single.percent.value, -0.4);
    });

    test('keeps the good rows when one is unreadable', () {
      final companions = CustomApiService.inflationCompanionsFor([
        {'date': '2025-01-01', 'country': 'SRB', 'rate': 4.2},
        {'date': '2026', 'country': 'SRB', 'rate': 3.1},
        {'date': '2024-01-01', 'country': 'SRB', 'rate': 7.8},
      ]);

      expect(companions.map((c) => c.percent.value), [4.2, 7.8]);
    });

    test('refuses a row with no country or no percent', () {
      final companions = CustomApiService.inflationCompanionsFor([
        {'date': '2025-01-01', 'rate': 4.2},
        {'date': '2025-01-01', 'country': 'SRB'},
      ]);

      expect(companions, isEmpty);
    });
  });

  group('assetCompanionsFor', () {
    test('reads a well-formed row', () {
      final companions = CustomApiService.assetCompanionsFor([
        {
          'date': '2026-08-22',
          'code': 'AAPL',
          'value': 231.4,
          'currency': 'usd',
          'name': 'Apple',
        },
      ]);

      expect(companions.single.assetId.value, 'AAPL');
      expect(companions.single.value.value, 231.4);
      expect(companions.single.currencyCode.value, 'USD');
      expect(companions.single.name.value, 'Apple');
      expect(companions.single.source.value, 'custom_api');
    });

    test('falls back to the code for the name and to EUR for the currency', () {
      final companions = CustomApiService.assetCompanionsFor([
        {'date': '2026-08-22', 'code': 'AAPL', 'value': 231.4},
      ]);

      expect(companions.single.name.value, 'AAPL');
      expect(companions.single.currencyCode.value, 'EUR');
    });

    test('gives the same day the same id twice, so a refetch updates', () {
      Value<String> idOf(String date) => CustomApiService.assetCompanionsFor([
        {'date': date, 'code': 'AAPL', 'value': 1.0},
      ]).single.id;

      expect(idOf('2026-08-22'), idOf('2026-08-22T15:04:05'));
      expect(idOf('2026-08-22'), isNot(idOf('2026-08-23')));
    });

    test('keeps a value of zero or below', () {
      // An asset can be worth nothing and a holding can be a debt.
      final companions = CustomApiService.assetCompanionsFor([
        {'date': '2026-08-22', 'code': 'AAPL', 'value': 0},
        {'date': '2026-08-22', 'code': 'LOAN', 'value': -1200.0},
      ]);

      expect(companions.map((c) => c.value.value), [0.0, -1200.0]);
    });

    test('keeps the good rows when one is unreadable', () {
      final companions = CustomApiService.assetCompanionsFor([
        {'date': '2026-08-22', 'code': 'AAPL', 'value': 231.4},
        {'date': '2026-08-22', 'value': 12.0},
        {'date': 'yesterday', 'code': 'MSFT', 'value': 12.0},
        {'date': '2026-08-22', 'code': 'MSFT', 'value': 'n/a'},
        {'date': '2026-08-22', 'code': 'NVDA', 'value': 98.6},
      ]);

      expect(companions.map((c) => c.assetId.value), ['AAPL', 'NVDA']);
    });
  });
}
