part of 'exchange_rates_bloc.dart';

enum ExchangeRatesStatus { initial, loading, success, failure }

class ExchangeRatesState extends Equatable {
  final ExchangeRatesStatus status;
  final List<ExchangeRateDomain> exchangeRates;
  final DateTime? dateFilter;
  final String? fromCurrencyFilter;
  final String? toCurrencyFilter;
  final List<Currency> currencies;
  final String? error;
  final bool hasReachedMax;
  final int totalCount;

  const ExchangeRatesState({
    this.status = ExchangeRatesStatus.initial,
    this.exchangeRates = const [],
    this.dateFilter,
    this.fromCurrencyFilter,
    this.toCurrencyFilter,
    this.currencies = const [],
    this.error,
    this.hasReachedMax = false,
    this.totalCount = 0,
  });

  ExchangeRatesState copyWith({
    ExchangeRatesStatus? status,
    List<ExchangeRateDomain>? exchangeRates,
    DateTime? dateFilter,
    String? fromCurrencyFilter,
    String? toCurrencyFilter,
    bool clearDateFilter = false,
    bool clearFromCurrencyFilter = false,
    bool clearToCurrencyFilter = false,
    List<Currency>? currencies,
    String? error,
    bool? hasReachedMax,
    int? totalCount,
  }) {
    return ExchangeRatesState(
      status: status ?? this.status,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      dateFilter: clearDateFilter ? null : (dateFilter ?? this.dateFilter),
      fromCurrencyFilter: clearFromCurrencyFilter
          ? null
          : (fromCurrencyFilter ?? this.fromCurrencyFilter),
      toCurrencyFilter: clearToCurrencyFilter
          ? null
          : (toCurrencyFilter ?? this.toCurrencyFilter),
      currencies: currencies ?? this.currencies,
      error: error ?? this.error,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  List<Object?> get props => [
    status,
    exchangeRates,
    dateFilter,
    fromCurrencyFilter,
    toCurrencyFilter,
    currencies,
    error,
    hasReachedMax,
    totalCount,
  ];
}
