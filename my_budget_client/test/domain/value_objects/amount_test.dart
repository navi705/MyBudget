import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/value_objects/amount.dart';
import 'package:my_budget_client/domain/value_objects/currency_precision.dart';

void main() {
  group('CurrencyPrecision.decimalsFor', () {
    test('2 decimals is the default', () {
      expect(CurrencyPrecision.decimalsFor('EUR'), 2);
      expect(CurrencyPrecision.decimalsFor('USD'), 2);
      expect(CurrencyPrecision.decimalsFor('RUB'), 2);
      expect(CurrencyPrecision.decimalsFor('ZZZ'), 2); // unknown -> 2
    });

    test('0-decimal currencies', () {
      for (final c in ['JPY', 'KRW', 'VND', 'CLP', 'ISK', 'XAF']) {
        expect(CurrencyPrecision.decimalsFor(c), 0, reason: c);
      }
    });

    test('3-decimal currencies', () {
      for (final c in ['KWD', 'BHD', 'OMR', 'TND', 'IQD', 'JOD', 'LYD']) {
        expect(CurrencyPrecision.decimalsFor(c), 3, reason: c);
      }
    });

    test('is case-insensitive', () {
      expect(CurrencyPrecision.decimalsFor('jpy'), 0);
      expect(CurrencyPrecision.decimalsFor('kwd'), 3);
    });
  });

  group('CurrencyPrecision.isMinorUnit', () {
    test('only fiat uses integer minor units', () {
      expect(CurrencyPrecision.isMinorUnit(TypeCurrency.currency), isTrue);
      expect(CurrencyPrecision.isMinorUnit(TypeCurrency.crypto), isFalse);
      expect(CurrencyPrecision.isMinorUnit(TypeCurrency.commoditity), isFalse);
      expect(CurrencyPrecision.isMinorUnit(TypeCurrency.stock), isFalse);
      expect(CurrencyPrecision.isMinorUnit(TypeCurrency.other), isFalse);
    });
  });

  group('toMinorUnits', () {
    test('kills the 0.1 + 0.2 float bug', () {
      final a = toMinorUnits(0.1, 2);
      final b = toMinorUnits(0.2, 2);
      expect(a, 10);
      expect(b, 20);
      expect(a + b, 30); // exact, unlike 0.1 + 0.2 == 0.30000000000000004
    });

    test('scales by decimals', () {
      expect(toMinorUnits(123.45, 2), 12345);
      expect(toMinorUnits(100, 0), 100); // JPY: no minor unit
      expect(toMinorUnits(1.5, 3), 1500); // KWD
    });

    test('rounds and handles negatives', () {
      expect(toMinorUnits(-7.005, 2), -701); // half-away-from-zero
      expect(toMinorUnits(0.005, 2), 1);
    });
  });

  group('parseMinorUnits', () {
    test('parses plain decimals exactly (no double round-trip)', () {
      expect(parseMinorUnits('123.45', 2), 12345);
      expect(parseMinorUnits('0.1', 2), 10);
      expect(parseMinorUnits('0.2', 2), 20);
      // The headline invariant, straight from string input:
      expect(parseMinorUnits('0.1', 2)! + parseMinorUnits('0.2', 2)!, 30);
    });

    test('accepts comma decimal separator and signs', () {
      expect(parseMinorUnits('0,30', 2), 30);
      expect(parseMinorUnits('-7', 2), -700);
      expect(parseMinorUnits('+7', 2), 700);
    });

    test('leading/trailing dot and bare fraction', () {
      expect(parseMinorUnits('.5', 2), 50);
      expect(parseMinorUnits('5.', 2), 500);
    });

    test('rounds excess fractional digits half-up', () {
      expect(parseMinorUnits('1.005', 2), 101);
      expect(parseMinorUnits('1.004', 2), 100);
      expect(parseMinorUnits('2.5', 0), 3); // JPY-style, rounds to whole
    });

    test('respects 0- and 3-decimal scales', () {
      expect(parseMinorUnits('1000', 0), 1000);
      expect(parseMinorUnits('1.234', 3), 1234);
    });

    test('returns null on invalid input', () {
      expect(parseMinorUnits('abc', 2), isNull);
      expect(parseMinorUnits('', 2), isNull);
      expect(parseMinorUnits('1.2.3', 2), isNull);
      expect(parseMinorUnits('   ', 2), isNull);
    });
  });

  group('Amount.fromMajor', () {
    test('fiat becomes exact FiatAmount', () {
      final a = Amount.fromMajor(123.45, TypeCurrency.currency, 'EUR');
      expect(a, isA<FiatAmount>());
      final f = a as FiatAmount;
      expect(f.minorUnits, 12345);
      expect(f.decimals, 2);
      expect(f.major, 123.45);
    });

    test('0-decimal fiat', () {
      final a = Amount.fromMajor(1000, TypeCurrency.currency, 'JPY');
      expect((a as FiatAmount).minorUnits, 1000);
      expect(a.decimals, 0);
      expect(a.major, 1000);
    });

    test('crypto stays a RawAmount double', () {
      final a = Amount.fromMajor(0.5, TypeCurrency.crypto, 'BTC');
      expect(a, isA<RawAmount>());
      expect((a as RawAmount).value, 0.5);
      expect(a.major, 0.5);
    });

    test('commodity stays raw', () {
      final a = Amount.fromMajor(2.3456, TypeCurrency.commoditity, 'XAU');
      expect(a, isA<RawAmount>());
      expect(a.major, 2.3456);
    });
  });

  group('FiatAmount arithmetic', () {
    test('addition and subtraction stay exact', () {
      const a = FiatAmount(1010, 2); // 10.10
      const b = FiatAmount(2005, 2); // 20.05
      expect((a + b).minorUnits, 3015);
      expect((b - a).minorUnits, 995);
    });

    test('equality by value and scale', () {
      expect(const FiatAmount(100, 2), const FiatAmount(100, 2));
      expect(const FiatAmount(100, 2), isNot(const FiatAmount(100, 0)));
    });
  });
}
