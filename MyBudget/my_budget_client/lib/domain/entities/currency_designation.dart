import 'package:equatable/equatable.dart';

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
