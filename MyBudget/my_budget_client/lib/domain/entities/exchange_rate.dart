import 'package:equatable/equatable.dart';

class ExchangeRate extends Equatable {
  final int fromCurrencyId;
  final int toCurrencyId;
  final double rate;
  final DateTime date;

  const ExchangeRate({
    required this.fromCurrencyId,
    required this.toCurrencyId,
    required this.rate,
    required this.date,
  });

  @override
  List<Object?> get props => [fromCurrencyId, toCurrencyId, rate, date];
}
