import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/currency_converter.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

ExchangeRateDomain rate(
  String from,
  String to,
  double value,
  DateTime date, {
  int preset = 1,
}) {
  return ExchangeRateDomain(
    fromCurrencyCode: from,
    toCurrencyCode: to,
    rate: value,
    date: date,
    preset: preset,
  );
}

void main() {
  final day = DateTime(2024, 6, 15);

  group('direct / inverse / identity', () {
    test('direct rate is applied as-is', () {
      final c = CurrencyConverter([
        rate('USD', 'EUR', 0.9, day),
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 100, from: 'USD', to: 'EUR', date: day),
        closeTo(90.0, 1e-9),
      );
    });

    test('inverse rate is 1/rate', () {
      final c = CurrencyConverter([
        rate('EUR', 'USD', 1.25, day),
      ], baseCurrency: 'EUR');

      expect(
        c.tryConvert(amount: 100, from: 'USD', to: 'EUR', date: day),
        closeTo(80.0, 1e-9),
      );
    });

    test('from == to short-circuits to 1.0 even with no rates at all', () {
      final c = CurrencyConverter(const [], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 42.5, from: 'JPY', to: 'JPY', date: day),
        42.5,
      );
      expect(c.convert(amount: 42.5, from: 'JPY', to: 'JPY', date: day), 42.5);
    });

    test('a zero inverse rate does not produce an infinity', () {
      // Only a degenerate "1 USD = 0 EUR" row exists; 1/0 would be Infinity.
      final c = CurrencyConverter([
        rate('EUR', 'USD', 0.0, day),
      ], baseCurrency: 'EUR');

      final result = c.tryConvert(
        amount: 100,
        from: 'USD',
        to: 'EUR',
        date: day,
      );
      expect(result, isNull);
      expect(
        c.convert(amount: 100, from: 'USD', to: 'EUR', date: day).isNaN,
        isTrue,
      );
    });

    test('a zero direct rate is still an honest zero, not a miss', () {
      final c = CurrencyConverter([
        rate('USD', 'EUR', 0.0, day),
      ], baseCurrency: 'USD');

      expect(c.tryConvert(amount: 100, from: 'USD', to: 'EUR', date: day), 0.0);
    });
  });

  group('triangular pivot through baseCurrency', () {
    test('resolves a pair with no direct or inverse row', () {
      // Pivot USD: 1 USD = 150 JPY, 1 USD = 0.9 EUR  =>  JPY->EUR = 0.9/150.
      final c = CurrencyConverter([
        rate('USD', 'JPY', 150.0, day),
        rate('USD', 'EUR', 0.9, day),
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 1500, from: 'JPY', to: 'EUR', date: day),
        closeTo(9.0, 1e-9),
      );
    });

    test('the pivot is the configured base, NOT a hardcoded EUR', () {
      // Regression test for the hardcoded `const baseCurrency = 'EUR'`.
      // The same rate set gives different answers depending on the pivot,
      // because each pivot has a different pair of legs available.
      final rates = [
        // USD-anchored legs
        rate('USD', 'JPY', 150.0, day),
        rate('USD', 'CHF', 0.90, day),
        // EUR-anchored legs, deliberately implying a different cross rate
        rate('EUR', 'JPY', 160.0, day),
        rate('EUR', 'CHF', 1.04, day),
      ];

      final viaUsd = CurrencyConverter(rates, baseCurrency: 'USD');
      final viaEur = CurrencyConverter(rates, baseCurrency: 'EUR');

      final usdResult = viaUsd.tryConvert(
        amount: 15000,
        from: 'JPY',
        to: 'CHF',
        date: day,
      )!;
      final eurResult = viaEur.tryConvert(
        amount: 15000,
        from: 'JPY',
        to: 'CHF',
        date: day,
      )!;

      expect(usdResult, closeTo(15000 * 0.90 / 150.0, 1e-9)); // 90.0
      expect(eurResult, closeTo(15000 * 1.04 / 160.0, 1e-9)); // 97.5
      expect(usdResult, isNot(closeTo(eurResult, 1e-6)));
    });

    test('a non-EUR base finds a path where the old EUR pivot found none', () {
      // No EUR row anywhere: the old hardcoded pivot returned 0.0 here.
      final rates = [
        rate('GBP', 'JPY', 190.0, day),
        rate('GBP', 'CHF', 1.13, day),
      ];

      final viaGbp = CurrencyConverter(rates, baseCurrency: 'GBP');
      final viaEur = CurrencyConverter(rates, baseCurrency: 'EUR');

      expect(
        viaGbp.tryConvert(amount: 1900, from: 'JPY', to: 'CHF', date: day),
        closeTo(1900 * 1.13 / 190.0, 1e-9),
      );
      // A base with no rows of its own no longer means "unpriceable": the pair
      // is resolved through the currency the table is anchored on, which is the
      // only pivot these rows can support anyway. This used to return null, and
      // that null is what a dashboard shown in a currency the rate table is not
      // anchored on reported for every foreign amount it held.
      expect(
        viaEur.tryConvert(amount: 1900, from: 'JPY', to: 'CHF', date: day),
        closeTo(1900 * 1.13 / 190.0, 1e-9),
      );
    });

    test('falls back to the currency the table is anchored on', () {
      // Callers pass the currency the RESULT is shown in, and the dashboard's
      // currency selector changes it on every tap. The stored table is anchored
      // on whatever it was fetched against — here EUR — so viewing totals in
      // RUB asked for `RUB -> ETH`, found nothing, and reported ETH, RSD, USD
      // and USDT as unconvertible with every row needed to price them present.
      final rates = [
        rate('EUR', 'ETH', 0.00046308555, day),
        rate('EUR', 'RUB', 96.63036, day),
        rate('EUR', 'USD', 1.16761295, day),
      ];

      final viaRub = CurrencyConverter(rates, baseCurrency: 'RUB');

      expect(
        viaRub.tryConvert(amount: 1, from: 'ETH', to: 'USD', date: day),
        closeTo(1.16761295 / 0.00046308555, 1e-6),
      );
      // The requested pivot still works where it can, and RUB itself is
      // reachable through the anchor.
      expect(
        viaRub.tryConvert(amount: 1, from: 'ETH', to: 'RUB', date: day),
        closeTo(96.63036 / 0.00046308555, 1e-6),
      );
    });

    test('the requested pivot wins when both can price the pair', () {
      // The fallback is a fallback: it must not quietly re-anchor a conversion
      // the caller's own pivot could already do, or switching the display
      // currency would stop changing which legs a cross rate is built from.
      final rates = [
        rate('USD', 'JPY', 150.0, day),
        rate('USD', 'CHF', 0.90, day),
        // EUR reaches one more currency, so it is the anchor by row count.
        rate('EUR', 'JPY', 160.0, day),
        rate('EUR', 'CHF', 1.04, day),
        rate('EUR', 'GBP', 0.85, day),
      ];

      final viaUsd = CurrencyConverter(rates, baseCurrency: 'USD');

      expect(
        viaUsd.tryConvert(amount: 15000, from: 'JPY', to: 'CHF', date: day),
        closeTo(15000 * 0.90 / 150.0, 1e-9),
      );
    });

    test('a single reversed pair is not mistaken for an anchor', () {
      // An anchor prices many currencies. One stray `RSD -> USDT` row must not
      // become a pivot and start pricing things through a single stale rate.
      final rates = [
        rate('RSD', 'USDT', 0.00834951, DateTime(2020, 1, 1)),
        rate('EUR', 'USD', 1.1, day),
      ];

      final c = CurrencyConverter(rates, baseCurrency: 'GBP');

      expect(
        c.tryConvert(amount: 100, from: 'USDT', to: 'CHF', date: day),
        isNull,
      );
    });

    test('a zero base->from leg does not produce an infinity', () {
      final c = CurrencyConverter([
        rate('USD', 'JPY', 0.0, day),
        rate('USD', 'EUR', 0.9, day),
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 1500, from: 'JPY', to: 'EUR', date: day),
        isNull,
      );
    });
  });

  group('nearest-date selection', () {
    test('a rate dated AFTER the request wins when it is closer', () {
      // Requested 2024-06-15: the 06-16 row is 1 day away, the 06-01 row 14.
      final c = CurrencyConverter([
        rate('USD', 'EUR', 0.80, DateTime(2024, 6, 1)),
        rate('USD', 'EUR', 0.95, DateTime(2024, 6, 16)),
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 100, from: 'USD', to: 'EUR', date: day),
        closeTo(95.0, 1e-9),
      );
    });

    test('a transaction before the earliest stored row still converts', () {
      // The old backward-only lookup found nothing at all here and the whole
      // amount silently became 0.
      final c = CurrencyConverter([
        rate('USD', 'EUR', 0.9, DateTime(2024, 6, 20)),
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(
          amount: 100,
          from: 'USD',
          to: 'EUR',
          date: DateTime(2020, 1, 1),
        ),
        closeTo(90.0, 1e-9),
      );
    });

    test('an exact match beats neighbours on both sides', () {
      final c = CurrencyConverter([
        rate('USD', 'EUR', 0.80, DateTime(2024, 6, 14)),
        rate('USD', 'EUR', 0.90, DateTime(2024, 6, 15)),
        rate('USD', 'EUR', 0.99, DateTime(2024, 6, 16)),
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 100, from: 'USD', to: 'EUR', date: day),
        closeTo(90.0, 1e-9),
      );
    });

    test('an equidistant tie picks the EARLIER row', () {
      // 06-10 and 06-20 are both 5 days from 06-15.
      final c = CurrencyConverter([
        rate('USD', 'EUR', 0.80, DateTime(2024, 6, 10)),
        rate('USD', 'EUR', 0.95, DateTime(2024, 6, 20)),
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 100, from: 'USD', to: 'EUR', date: day),
        closeTo(80.0, 1e-9),
      );
    });

    test('tie resolution is independent of input list order', () {
      final later = rate('USD', 'EUR', 0.95, DateTime(2024, 6, 20));
      final earlier = rate('USD', 'EUR', 0.80, DateTime(2024, 6, 10));

      final a = CurrencyConverter([later, earlier], baseCurrency: 'USD');
      final b = CurrencyConverter([earlier, later], baseCurrency: 'USD');

      expect(
        a.tryConvert(amount: 100, from: 'USD', to: 'EUR', date: day),
        closeTo(80.0, 1e-9),
      );
      expect(
        b.tryConvert(amount: 100, from: 'USD', to: 'EUR', date: day),
        closeTo(80.0, 1e-9),
      );
    });

    test('a fresher inverse row beats a stale direct row', () {
      final c = CurrencyConverter([
        rate('USD', 'EUR', 0.50, DateTime(2020, 1, 1)), // 4+ years stale
        rate('EUR', 'USD', 1.25, DateTime(2024, 6, 14)), // 1 day off => 0.8
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 100, from: 'USD', to: 'EUR', date: day),
        closeTo(80.0, 1e-9),
      );
    });
  });

  group('stalest-leg rule', () {
    test('a direct rate a few days off beats a triangular with an old leg', () {
      final c = CurrencyConverter([
        // Direct: 3 days off.
        rate('JPY', 'EUR', 0.0058, DateTime(2024, 6, 12)),
        // Triangular legs: one is today, the other is years old.
        rate('USD', 'JPY', 150.0, day),
        rate('USD', 'EUR', 0.9, DateTime(2019, 1, 1)),
      ], baseCurrency: 'USD');

      final result = c.tryConvert(
        amount: 1000,
        from: 'JPY',
        to: 'EUR',
        date: day,
      )!;
      expect(result, closeTo(5.8, 1e-9)); // 1000 * 0.0058 (direct)
      // The triangular alternative (0.9/150 = 0.006 -> 6.0) was rejected
      // because its stalest leg is 2019.
      expect(result, isNot(closeTo(6.0, 1e-6)));
    });

    test('the triangular candidate is dated by its WORSE leg', () {
      // Direct row is 10 days off. Triangular legs: today, and 400 days off.
      // Ranked by the stale leg the triangular loses, so the direct wins.
      final c = CurrencyConverter([
        rate('JPY', 'CHF', 0.0070, DateTime(2024, 6, 5)), // 10 days off
        rate('USD', 'JPY', 150.0, day), // 0 days off
        rate('USD', 'CHF', 0.90, DateTime(2023, 5, 12)), // ~400 days off
      ], baseCurrency: 'USD');

      final result = c.tryConvert(
        amount: 1000,
        from: 'JPY',
        to: 'CHF',
        date: day,
      )!;
      expect(result, closeTo(7.0, 1e-9)); // direct 0.0070
      // Sanity: the triangular value it beat is a different number.
      expect(result, isNot(closeTo(1000 * 0.90 / 150.0, 1e-6)));
    });

    test(
      'triangular still wins when both legs are fresher than the direct',
      () {
        final c = CurrencyConverter([
          rate('JPY', 'CHF', 0.0070, DateTime(2020, 1, 1)), // years off
          rate('USD', 'JPY', 150.0, day),
          rate('USD', 'CHF', 0.90, day),
        ], baseCurrency: 'USD');

        expect(
          c.tryConvert(amount: 1000, from: 'JPY', to: 'CHF', date: day),
          closeTo(1000 * 0.90 / 150.0, 1e-9),
        );
      },
    );
  });

  group('unpriceable amounts', () {
    test('tryConvert returns null and convert returns NaN — never 0.0', () {
      final c = CurrencyConverter([
        rate('USD', 'EUR', 0.9, day),
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 5000, from: 'XYZ', to: 'EUR', date: day),
        isNull,
      );

      final converted = c.convert(
        amount: 5000,
        from: 'XYZ',
        to: 'EUR',
        date: day,
      );
      expect(converted.isNaN, isTrue);
      // The whole point of the change: a 5000 XYZ account must not silently
      // count as zero and disappear from the total.
      expect(converted, isNot(0.0));
    });

    test('an empty rate table cannot price a cross pair', () {
      final c = CurrencyConverter(const [], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 1, from: 'USD', to: 'EUR', date: day),
        isNull,
      );
      expect(
        c.convert(amount: 1, from: 'USD', to: 'EUR', date: day).isNaN,
        isTrue,
      );
    });

    test('only one triangular leg present is not a path', () {
      final c = CurrencyConverter([
        rate('USD', 'JPY', 150.0, day),
      ], baseCurrency: 'USD');

      expect(
        c.tryConvert(amount: 1000, from: 'JPY', to: 'CHF', date: day),
        isNull,
      );
    });
  });

  group('resolveRate', () {
    test('reports the date of the winning candidate', () {
      final c = CurrencyConverter([
        rate('USD', 'EUR', 0.9, DateTime(2024, 6, 14)),
      ], baseCurrency: 'USD');

      final resolved = c.resolveRate('USD', 'EUR', day);
      expect(resolved, isNotNull);
      expect(resolved!.rate, closeTo(0.9, 1e-9));
      expect(resolved.date, DateTime(2024, 6, 14));
    });

    test('identity pair reports the requested date', () {
      final c = CurrencyConverter(const [], baseCurrency: 'USD');

      final resolved = c.resolveRate('EUR', 'EUR', day);
      expect(resolved!.rate, 1.0);
      expect(resolved.date, day);
    });
  });
}
