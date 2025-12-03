import 'package:equatable/equatable.dart';

class ExchangeRate extends Equatable {
  final String fromCurrencyCode;
  final String toCurrencyCode;
  final int preset;
  final double rate;
  final DateTime date;

  const ExchangeRate({
    required this.fromCurrencyCode,
    required this.toCurrencyCode,
    required this.preset,
    required this.rate,
    required this.date,
  });

  @override
  List<Object?> get props => [fromCurrencyCode, toCurrencyCode, preset, rate, date];
}
