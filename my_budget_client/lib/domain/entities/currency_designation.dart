import 'package:equatable/equatable.dart';

/// Represents the symbol or abbreviation for a currency, e.g., "$", "€".
/// This entity is intended to be independent and should not be coupled with
/// styling information.
class CurrencyDesignation extends Equatable {
  final String id;
  final String value;
  final String currencyCode;

  const CurrencyDesignation({
    required this.id,
    required this.value,
    required this.currencyCode,
  });

  CurrencyDesignation copyWith({
    String? id,
    String? value,
    String? currencyCode,
  }) {
    return CurrencyDesignation(
      id: id ?? this.id,
      value: value ?? this.value,
      currencyCode: currencyCode ?? this.currencyCode,
    );
  }

  @override
  List<Object?> get props => [id, value, currencyCode];
}
