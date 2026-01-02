part of 'exchange_rates_bloc.dart';

abstract class ExchangeRatesEvent extends Equatable {
  const ExchangeRatesEvent();

  @override
  List<Object?> get props => [];
}

class LoadExchangeRates extends ExchangeRatesEvent {
  const LoadExchangeRates();
}

class AddExchangeRate extends ExchangeRatesEvent {
  final ExchangeRateDomain exchangeRate;

  const AddExchangeRate(this.exchangeRate);

  @override
  List<Object?> get props => [exchangeRate];
}

class ChangeExchangeRatesFilters extends ExchangeRatesEvent {
  final DateTime? date;
  final String? fromCurrency;
  final String? toCurrency;

  const ChangeExchangeRatesFilters({
    this.date,
    this.fromCurrency,
    this.toCurrency,
  });

  @override
  List<Object?> get props => [date, fromCurrency, toCurrency];
}
