part of 'exchange_rates_bloc.dart';

enum ExchangeRatesStatus { initial, loading, success, failure }

class ExchangeRatesState extends Equatable {
  final ExchangeRatesStatus status;
  final List<ExchangeRateDomain> exchangeRates;
  final List<ExchangeRateDomain> filteredExchangeRates;
  final DateTime? dateFilter;
  final String? fromCurrencyFilter;
  final String? toCurrencyFilter;
  final List<Currency> currencies;
  final String? error;

  const ExchangeRatesState({
    this.status = ExchangeRatesStatus.initial,
    this.exchangeRates = const [],
    this.filteredExchangeRates = const [],
    this.dateFilter,
    this.fromCurrencyFilter,
    this.toCurrencyFilter,
    this.currencies = const [],
    this.error,
  });

  ExchangeRatesState copyWith({
    ExchangeRatesStatus? status,
    List<ExchangeRateDomain>? exchangeRates,
    List<ExchangeRateDomain>? filteredExchangeRates,
    DateTime? dateFilter,
    String? fromCurrencyFilter,
    String? toCurrencyFilter,
    bool clearDateFilter = false,
    bool clearFromCurrencyFilter = false,
    bool clearToCurrencyFilter = false,
    List<Currency>? currencies,
    String? error,
  }) {
    return ExchangeRatesState(
      status: status ?? this.status,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      filteredExchangeRates:
          filteredExchangeRates ?? this.filteredExchangeRates,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      fromCurrencyFilter: clearFromCurrencyFilter
          ? null
          : (fromCurrencyFilter ?? this.fromCurrencyFilter),
      toCurrencyFilter: clearToCurrencyFilter
          ? null
          : (toCurrencyFilter ?? this.toCurrencyFilter),
      currencies: currencies ?? this.currencies,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    status,
    exchangeRates,
    filteredExchangeRates,
    dateFilter,
    fromCurrencyFilter,
    toCurrencyFilter,
    currencies,
    error,
  ];
}
