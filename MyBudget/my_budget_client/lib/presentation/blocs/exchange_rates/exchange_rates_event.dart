part of 'exchange_rates_bloc.dart';

abstract class ExchangeRatesEvent extends Equatable {
  const ExchangeRatesEvent();

  @override
  List<Object?> get props => [];
}

class LoadExchangeRates extends ExchangeRatesEvent {
  final bool isRefresh;
  const LoadExchangeRates({this.isRefresh = false});

  @override
  List<Object?> get props => [isRefresh];
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

class ChangeExchangeRatesDateStep extends ExchangeRatesEvent {
  final DateStep dateStep;
  const ChangeExchangeRatesDateStep(this.dateStep);
  @override
  List<Object?> get props => [dateStep];
}

class ChangeExchangeRatesFilterMode extends ExchangeRatesEvent {
  final FilterMode filterMode;
  const ChangeExchangeRatesFilterMode(this.filterMode);
  @override
  List<Object?> get props => [filterMode];
}

class ChangeExchangeRatesSort extends ExchangeRatesEvent {
  final Sort sort;
  const ChangeExchangeRatesSort(this.sort);
  @override
  List<Object?> get props => [sort];
}

class ChangeExchangeRatesActiveDate extends ExchangeRatesEvent {
  final DateTime date;
  const ChangeExchangeRatesActiveDate(this.date);
  @override
  List<Object?> get props => [date];
}

class ChangeExchangeRatesActiveDateRange extends ExchangeRatesEvent {
  final DateTimeRange dateRange;
  const ChangeExchangeRatesActiveDateRange(this.dateRange);
  @override
  List<Object?> get props => [dateRange];
}
