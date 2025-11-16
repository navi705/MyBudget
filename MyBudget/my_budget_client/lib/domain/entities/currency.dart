import 'package:my_budget_client/domain/entities/currency_designation.dart';

class Currency {
  final int id;
  final String name;
  final String code;
  final CurrencyDesignation designation;

  Currency({
    required this.id,
    required this.name,
    required this.code,
    required this.designation,
  });

  Currency copyWith({
    int? id,
    String? name,
    String? code,
    CurrencyDesignation? designation,
  }) {
    return Currency(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      designation: designation ?? this.designation,
    );
  }
}
