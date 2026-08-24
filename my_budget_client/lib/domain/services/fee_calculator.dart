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
    var currentValue = nominalValue;
    for (final rule in rulesFrom(feeStructureJson)) {
      currentValue = rule.apply(currentValue);
    }
    return currentValue;
  }

  /// The rules [feeStructureJson] describes, skipping anything unreadable.
  ///
  /// One rule this could not read used to discard the whole structure: the
  /// numbers came off bare `as num` casts inside a single try, so a rule
  /// missing its `amount` - or a list holding something that was not an object
  /// at all - was caught at the top and the account's net value silently
  /// became its gross. The editor did the same and then wrote the empty list
  /// back on save, turning a display bug into the loss of every other fee the
  /// account had.
  ///
  /// A non-finite fee is refused rather than applied: it is not a slightly
  /// wrong deduction but one that turns the account's value, and every total
  /// that reaches it, into NaN.
  static List<FeeRule> rulesFrom(String? feeStructureJson) {
    if (feeStructureJson == null || feeStructureJson.isEmpty) return const [];

    dynamic decoded;
    try {
      decoded = jsonDecode(feeStructureJson);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];

    return decoded.map(parseRule).whereType<FeeRule>().toList();
  }

  static FeeRule? parseRule(dynamic json) {
    if (json is! Map) return null;
    switch (json['type']) {
      case 'fixed':
        final amount = _finite(json['amount']);
        return amount == null ? null : FixedFee(amount);
      case 'percent':
        final rate = _finite(json['rate']);
        return rate == null ? null : PercentFee(rate);
      case 'tax':
        final rate = _finite(json['rate']);
        if (rate == null) return null;
        return TaxRate(rate, costBasis: _finite(json['costBasis']) ?? 0.0);
    }
    return null;
  }

  static double? _finite(dynamic value) {
    final number = value is num
        ? value.toDouble()
        : value is String
        ? double.tryParse(value.trim())
        : null;
    if (number == null || !number.isFinite) return null;
    return number;
  }
}
