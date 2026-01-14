import 'dart:convert';

abstract class FeeRule {
  double apply(double amount);
  Map<String, dynamic> toJson();
}

class FixedFee extends FeeRule {
  final double amount;
  FixedFee(this.amount);

  @override
  double apply(double currentAmount) => currentAmount - amount;

  @override
  Map<String, dynamic> toJson() => {'type': 'fixed', 'amount': amount};
}

class PercentFee extends FeeRule {
  final double rate; // 0.01 = 1%
  PercentFee(this.rate);

  @override
  double apply(double currentAmount) => currentAmount * (1 - rate);

  @override
  Map<String, dynamic> toJson() => {'type': 'percent', 'rate': rate};
}

class TaxRate extends FeeRule {
  final double rate; // 0.13 = 13%
  final double costBasis;

  TaxRate(this.rate, {this.costBasis = 0.0});

  @override
  double apply(double currentAmount) {
    final profit = currentAmount - costBasis;
    if (profit <= 0) return currentAmount;
    return currentAmount - (profit * rate);
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'tax',
    'rate': rate,
    'costBasis': costBasis,
  };
}

class FeeCalculator {
  static double calculateNetValue({
    required double nominalValue,
    required String? feeStructureJson,
  }) {
    if (feeStructureJson == null || feeStructureJson.isEmpty) {
      return nominalValue;
    }

    try {
      final List<dynamic> rules = jsonDecode(feeStructureJson);
      double currentValue = nominalValue;

      for (final ruleJson in rules) {
        final rule = parseRule(ruleJson);
        if (rule != null) {
          currentValue = rule.apply(currentValue);
        }
      }

      return currentValue;
    } catch (e) {
      // Return nominal if parsing fails to avoid crashing UI
      return nominalValue;
    }
  }

  static FeeRule? parseRule(Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'fixed') {
      return FixedFee((json['amount'] as num).toDouble());
    } else if (type == 'percent') {
      return PercentFee((json['rate'] as num).toDouble());
    } else if (type == 'tax') {
      return TaxRate(
        (json['rate'] as num).toDouble(),
        costBasis: (json['costBasis'] as num?)?.toDouble() ?? 0.0,
      );
    }
    return null;
  }
}
