import 'package:my_budget_server/rates/rate_provider.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeDay', () {
    test('strips a local timestamp down to UTC midnight', () {
      final day = normalizeDay(DateTime(2026, 3, 14, 17, 45, 12));
      expect(day.isUtc, isTrue);
      expect(day, DateTime.utc(2026, 3, 14));
    });

    test('is idempotent, so a re-normalised key still matches', () {
      final once = normalizeDay(DateTime.utc(2026, 3, 14, 23, 59));
      expect(normalizeDay(once), once);
    });

    test('two instants in the same UTC day collapse to one key', () {
      // The database primary key carries `date`, so anything but a single
      // canonical value per day writes duplicate rows for that day.
      expect(
        normalizeDay(DateTime.utc(2026, 3, 14, 0, 0, 1)),
        normalizeDay(DateTime.utc(2026, 3, 14, 23, 59, 59)),
      );
    });
  });

  group('FawazCurrencyApi.ratesFrom', () {
    test('reads the base currency key and upper-cases the quotes', () {
      final rates = FawazCurrencyApi.ratesFrom('EUR', {
        'date': '2026-03-14',
        'eur': {'usd': 1.09, 'jpy': 162.4},
      });

      expect(rates, {'USD': 1.09, 'JPY': 162.4});
    });

    test('accepts a numeric string, as the data set sometimes publishes', () {
      final rates = FawazCurrencyApi.ratesFrom('EUR', {
        'eur': {'usd': '1.09'},
      });

      expect(rates['USD'], 1.09);
    });

    test('drops rates that cannot be used for a conversion', () {
      // A zero or negative rate divides or flips a balance; a NaN poisons every
      // sum it reaches. Better to have no quote for that currency than a wrong
      // one stored under the same primary key as a good one.
      final rates = FawazCurrencyApi.ratesFrom('EUR', {
        'eur': {'usd': 1.09, 'aaa': 0, 'bbb': -2, 'ccc': 'not a number'},
      });

      expect(rates, {'USD': 1.09});
    });

    test('returns empty when the payload has no section for the base', () {
      expect(
        FawazCurrencyApi.ratesFrom('EUR', {'usd': <String, dynamic>{}}),
        isEmpty,
      );
      expect(FawazCurrencyApi.ratesFrom('EUR', {'eur': 'oops'}), isEmpty);
      expect(FawazCurrencyApi.ratesFrom('EUR', 'not a map'), isEmpty);
      expect(FawazCurrencyApi.ratesFrom('EUR', null), isEmpty);
    });

    test('matches the base case-insensitively', () {
      final rates = FawazCurrencyApi.ratesFrom('eur', {
        'eur': {'usd': 1.09},
      });

      expect(rates, {'USD': 1.09});
    });
  });
}
