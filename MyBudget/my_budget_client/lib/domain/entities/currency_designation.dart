import 'package:equatable/equatable.dart';

/// Represents the symbol or abbreviation for a currency, e.g., "$", "€".
/// This entity is intended to be independent and should not be coupled with
/// styling information.
class CurrencyDesignation extends Equatable {
  final int id;
  final String value;
  final int currencyId;

  const CurrencyDesignation({
    required this.id,
    required this.value,
    required this.currencyId,
  });

  CurrencyDesignation copyWith({
    int? id,
    String? value,
    int? currencyId,
  }) {
    return CurrencyDesignation(
      id: id ?? this.id,
      value: value ?? this.value,
      currencyId: currencyId ?? this.currencyId,
    );
  }

  @override
  List<Object?> get props => [id, value, currencyId];
}
