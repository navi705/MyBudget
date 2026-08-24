import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/services/fee_calculator.dart';

/// Reading a fee structure one rule at a time.
///
/// Every number came off a bare `as num` inside one try block, so a single
/// unreadable rule threw and the catch handed back the nominal value: an
/// account with a 1% fee and one malformed rule showed its gross value as if
/// it had no fees at all. The editor read the same JSON the same way and then
/// wrote its empty list back on the next save.
void main() {
  group('rulesFrom', () {
    test('reads a whole structure', () {
      final rules = FeeCalculator.rulesFrom(
        '[{"type":"fixed","amount":10},{"type":"percent","rate":0.01}]',
      );

      expect(rules, hasLength(2));
      expect(rules[0], isA<FixedFee>());
      expect(rules[1], isA<PercentFee>());
    });

    test('nothing at all reads as no rules', () {
      expect(FeeCalculator.rulesFrom(null), isEmpty);
      expect(FeeCalculator.rulesFrom(''), isEmpty);
    });

    test('keeps the readable rules when one is not', () {
      final rules = FeeCalculator.rulesFrom(
        '[{"type":"fixed"},{"type":"percent","rate":0.01},'
        '{"type":"nonsense"},"not an object",null]',
      );

      expect(rules, hasLength(1));
      expect(rules.single, isA<PercentFee>());
    });

    test('refuses JSON that is not a list of rules', () {
      expect(FeeCalculator.rulesFrom('{"type":"fixed","amount":10}'), isEmpty);
      expect(FeeCalculator.rulesFrom('not json at all'), isEmpty);
      expect(FeeCalculator.rulesFrom('7'), isEmpty);
    });

    test('reads a number written as a string', () {
      final rules = FeeCalculator.rulesFrom('[{"type":"fixed","amount":"2.5"}]');

      expect(rules.single.apply(10.0), 7.5);
    });

    test('refuses a non-finite fee', () {
      expect(
        FeeCalculator.rulesFrom('[{"type":"percent","rate":"NaN"}]'),
        isEmpty,
      );
      expect(
        FeeCalculator.rulesFrom('[{"type":"fixed","amount":"Infinity"}]'),
        isEmpty,
      );
    });

    test('a tax rule without a cost basis reads as one with a zero basis', () {
      final rules = FeeCalculator.rulesFrom('[{"type":"tax","rate":0.5}]');

      expect(rules.single.apply(100.0), 50.0);
    });

    test('a tax rule with an unreadable cost basis still charges its rate', () {
      final rules = FeeCalculator.rulesFrom(
        '[{"type":"tax","rate":0.5,"costBasis":"later"}]',
      );

      expect(rules.single.apply(100.0), 50.0);
    });
  });

  group('calculateNetValue', () {
    test('still charges the fees it can read', () {
      final net = FeeCalculator.calculateNetValue(
        nominalValue: 100.0,
        feeStructureJson:
            '[{"type":"fixed"},{"type":"percent","rate":0.10}]',
      );

      expect(net, closeTo(90.0, 1e-9));
    });

    test('applies the rules in the order they are written', () {
      final feeFirst = FeeCalculator.calculateNetValue(
        nominalValue: 100.0,
        feeStructureJson:
            '[{"type":"fixed","amount":10},{"type":"percent","rate":0.10}]',
      );
      final percentFirst = FeeCalculator.calculateNetValue(
        nominalValue: 100.0,
        feeStructureJson:
            '[{"type":"percent","rate":0.10},{"type":"fixed","amount":10}]',
      );

      expect(feeFirst, closeTo(81.0, 1e-9));
      expect(percentFirst, closeTo(80.0, 1e-9));
    });

    test('an unreadable structure leaves the nominal value alone', () {
      expect(
        FeeCalculator.calculateNetValue(
          nominalValue: 100.0,
          feeStructureJson: 'broken',
        ),
        100.0,
      );
    });
  });
}
