import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';

void main() {
  group('MoneyFormatter.format', () {
    test('fiat uses per-currency decimals', () {
      expect(MoneyFormatter.format(1234.5, 'EUR'), '1 234.50'); // 2 decimals
      expect(MoneyFormatter.format(1000, 'JPY'), '1 000'); // 0 decimals
      expect(MoneyFormatter.format(1.234, 'KWD'), '1.234'); // 3 decimals
    });

    test('groups thousands with spaces', () {
      expect(MoneyFormatter.format(1234567.89, 'USD'), '1 234 567.89');
    });

    test('signed prefixes + only for positive', () {
      expect(MoneyFormatter.format(5, 'EUR', signed: true), '+5.00');
      expect(MoneyFormatter.format(-5, 'EUR', signed: true), '-5.00');
      expect(MoneyFormatter.format(0, 'EUR', signed: true), '0.00');
    });

    test('crypto shows extra precision for tiny values', () {
      // Below 0.01 -> up to 6 places (pattern '#,##0.00####')
      expect(MoneyFormatter.format(0.00001234, 'BTC'), '0.000012');
      // Normal magnitude -> 2 places
      expect(MoneyFormatter.format(1.5, 'BTC'), '1.50');
    });
  });

  group('MoneyFormatter.decimalsFor', () {
    test('fiat', () {
      expect(MoneyFormatter.decimalsFor('EUR'), 2);
      expect(MoneyFormatter.decimalsFor('JPY'), 0);
      expect(MoneyFormatter.decimalsFor('KWD'), 3);
    });

    test('crypto dynamic', () {
      expect(MoneyFormatter.decimalsFor('BTC', 0.0001), 6);
      expect(MoneyFormatter.decimalsFor('BTC', 5.0), 2);
    });
  });
}
