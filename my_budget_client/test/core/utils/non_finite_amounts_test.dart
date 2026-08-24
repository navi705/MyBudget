import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/sms_parser.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/data/models/steam_inventory_model.dart';
import 'package:my_budget_client/domain/value_objects/amount.dart';

/// `double.tryParse` reads 'NaN', 'Infinity' and '-Infinity' as numbers, so a
/// null check is not a validity check. A non-finite amount that gets past one
/// either takes down the write that tries to scale it to minor units, or - on
/// a crypto row, which keeps its raw double - is stored and turns every total
/// that ever sums it into NaN.
void main() {
  group('toMinorUnits', () {
    test('refuses a non-finite amount, naming the value', () {
      for (final bad in [double.nan, double.infinity, -double.infinity]) {
        expect(
          () => toMinorUnits(bad, 2),
          throwsA(
            isA<ArgumentError>().having(
              // Compared through `identical` because NaN equals nothing, not
              // even itself.
              (e) => identical(e.invalidValue, bad),
              'carries the offending value',
              isTrue,
            ),
          ),
          reason: '$bad',
        );
      }
    });

    test('still scales a finite amount', () {
      expect(toMinorUnits(123.45, 2), 12345);
      expect(toMinorUnits(-0.005, 2), -1);
    });
  });

  group('Amount.fromMajorCode', () {
    test('refuses a non-finite fiat amount', () {
      expect(
        () => Amount.fromMajorCode(double.nan, 'USD'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('PriceToDoubleConverter', () {
    const converter = PriceToDoubleConverter();

    test('reads a real price', () {
      expect(converter.fromJson('12,34€'), 12.34);
    });

    test('refuses a non-finite price', () {
      expect(converter.fromJson('NaN'), isNull);
      expect(converter.fromJson('Infinity'), isNull);
      expect(converter.fromJson('-Infinity€'), isNull);
    });

    test('refuses text that is not a number at all', () {
      expect(converter.fromJson('sold out'), isNull);
    });
  });

  group('SmsParser amounts', () {
    final parser = SmsParser();

    // A rule's own regex decides what text reaches the amount parser, and a
    // user writes these rules by hand.
    SmsParseResult parseWith(String body) => parser.parse(
      body,
      SmsPreset(
        id: 'test',
        name: 'Test',
        senderFilter: 'TEST',
        rules: const [
          SmsParsingRule(
            id: 'r1',
            type: TransactionType.expense,
            matchPattern: r'spent',
            amountPattern: r'spent (\S+)',
          ),
        ],
      ),
      DateTime(2024, 5, 10),
    );

    test('reads a real amount in either separator convention', () {
      expect(parseWith('spent 1,000.50').amount, 1000.50);
      expect(parseWith('spent 1.000,50').amount, 1000.50);
    });

    test('refuses a non-finite amount', () {
      expect(parseWith('spent NaN').isMatch, isFalse);
      expect(parseWith('spent Infinity').isMatch, isFalse);
      expect(parseWith('spent -Infinity').isMatch, isFalse);
    });
  });
}
