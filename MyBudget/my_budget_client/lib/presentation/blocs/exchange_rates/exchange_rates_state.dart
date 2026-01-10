part of 'exchange_rates_bloc.dart';

enum ExchangeRatesStatus { initial, loading, success, failure }

class ExchangeRatesState extends Equatable {
  final ExchangeRatesStatus status;
  final List<ExchangeRateDomain> exchangeRates;
  final DateTime activeDate;
  final DateTimeRange? activeDateRange;
  final DateStep dateStep;
  final FilterMode filterMode;
  final Sort sort;
  final String? fromCurrencyFilter;
  final String? toCurrencyFilter;
  final List<int> presetFilters;
  final List<Currency> currencies;
  final String? error;
  final bool hasReachedMax;
  final int totalCount;
  final bool isSelectionModeActive;
  final Set<ExchangeRateDomain> selectedExchangeRates;

  ExchangeRatesState({
    this.status = ExchangeRatesStatus.initial,
    this.exchangeRates = const [],
    DateTime? activeDate,
    this.activeDateRange,
    this.dateStep = DateStep.month,
    this.filterMode = FilterMode.date,
    this.sort = Sort.descending,
    this.fromCurrencyFilter,
    this.toCurrencyFilter,
    this.presetFilters = const [],
    this.currencies = const [],
    this.error,
    this.hasReachedMax = false,
    this.totalCount = 0,
    this.isSelectionModeActive = false,
    this.selectedExchangeRates = const {},
  }) : activeDate =
           activeDate ??
           DateTime.now(); // Note: removed const from constructor because of initializer? No, activeDate is final. But DateTime.now() is not const. So constructor can't be const.

  ExchangeRatesState copyWith({
    ExchangeRatesStatus? status,
    List<ExchangeRateDomain>? exchangeRates,
    DateTime? activeDate,
    DateTimeRange? activeDateRange,
    DateStep? dateStep,
    FilterMode? filterMode,
    Sort? sort,
    String? fromCurrencyFilter,
    String? toCurrencyFilter,
    List<int>? presetFilters,
    bool clearFromCurrencyFilter = false,
    bool clearToCurrencyFilter = false,
    List<Currency>? currencies,
    String? error,
    bool? hasReachedMax,
    int? totalCount,
    bool? isSelectionModeActive,
    Set<ExchangeRateDomain>? selectedExchangeRates,
  }) {
    return ExchangeRatesState(
      status: status ?? this.status,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      activeDate: activeDate ?? this.activeDate,
      activeDateRange: activeDateRange ?? this.activeDateRange,
      dateStep: dateStep ?? this.dateStep,
      filterMode: filterMode ?? this.filterMode,
      sort: sort ?? this.sort,
      fromCurrencyFilter: clearFromCurrencyFilter
          ? null
          : (fromCurrencyFilter ?? this.fromCurrencyFilter),
      toCurrencyFilter: clearToCurrencyFilter
          ? null
          : (toCurrencyFilter ?? this.toCurrencyFilter),
      presetFilters: presetFilters ?? this.presetFilters,
      currencies: currencies ?? this.currencies,
      error: error ?? this.error,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalCount: totalCount ?? this.totalCount,
      isSelectionModeActive:
          isSelectionModeActive ?? this.isSelectionModeActive,
      selectedExchangeRates:
          selectedExchangeRates ?? this.selectedExchangeRates,
    );
  }

  @override
  List<Object?> get props => [
    status,
    exchangeRates,
    activeDate,
    activeDateRange,
    dateStep,
    filterMode,
    sort,
    fromCurrencyFilter,
    toCurrencyFilter,
    presetFilters,
    currencies,
    error,
    hasReachedMax,
    totalCount,
    isSelectionModeActive,
    selectedExchangeRates,
  ];
}
