import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/services/fee_calculator.dart';

void main() {
  group('FeeCalculator', () {
    test('FixedFee calculates correctly', () {
      final rule = FixedFee(10.0);
      expect(rule.apply(100.0), 90.0);
    });

    test('PercentFee calculates correctly', () {
      final rule = PercentFee(0.10); // 10%
      expect(rule.apply(100.0), 90.0);
    });

    test('TaxRate calculates correctly with 0 cost basis', () {
      final rule = TaxRate(0.20); // 20%
      expect(rule.apply(100.0), 80.0); // 100 * (1 - 0.2)
    });

    test('TaxRate calculates correctly with positive cost basis (Profit)', () {
      // Cost: 50, Value: 100. Profit: 50. Tax: 50 * 0.2 = 10. Net: 100 - 10 = 90.
      final rule = TaxRate(0.20, costBasis: 50.0);
      expect(rule.apply(100.0), 90.0);
    });

    test('TaxRate calculates correctly with high cost basis (Loss)', () {
      // Cost: 150, Value: 100. Loss. Tax: 0. Net: 100.
      final rule = TaxRate(0.20, costBasis: 150.0);
      expect(rule.apply(100.0), 100.0);
    });

    test('calculateNetValue handles null/empty json', () {
      expect(
        FeeCalculator.calculateNetValue(
          nominalValue: 100.0,
          feeStructureJson: null,
        ),
        100.0,
      );
      expect(
        FeeCalculator.calculateNetValue(
          nominalValue: 100.0,
          feeStructureJson: '',
        ),
        100.0,
      );
    });

    test('calculateNetValue handles JSON list correctly', () {
      // 1. Fixed Fee of 10. (100 -> 90)
      // 2. Percent Fee of 10% (0.1). (90 -> 81)
      final rules = [FixedFee(10.0).toJson(), PercentFee(0.10).toJson()];
      final json = jsonEncode(rules);

      expect(
        FeeCalculator.calculateNetValue(
          nominalValue: 100.0,
          feeStructureJson: json,
        ),
        81.0,
      );
    });

    test('calculateNetValue with TaxRate', () {
      // 100 Value. Cost Basis 50. Tax 20%.
      // Profit 50. Tax 10. Net 90.
      final rules = [TaxRate(0.20, costBasis: 50.0).toJson()];
      final json = jsonEncode(rules);

      expect(
        FeeCalculator.calculateNetValue(
          nominalValue: 100.0,
          feeStructureJson: json,
        ),
        90.0,
      );
    });

    test('Parse and apply sequence', () {
      // 1. Tax (20% on 50 profit from 100) -> 90
      // 2. Fixed (5) -> 85
      final rules = [
        TaxRate(0.20, costBasis: 50.0).toJson(),
        FixedFee(5.0).toJson(),
      ];
      final json = jsonEncode(rules);

      expect(
        FeeCalculator.calculateNetValue(
          nominalValue: 100.0,
          feeStructureJson: json,
        ),
        85.0,
      );
    });
  });
}
