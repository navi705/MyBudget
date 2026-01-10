part of 'inflation_bloc.dart';

enum InflationStatus { initial, loading, success, failure }

class InflationState extends Equatable {
  final InflationStatus status;
  final List<InflationRateDomain> rates;
  final bool hasMore;
  final int offset;
  final int limit;
  final bool isLoadingMore;
  final DateStep dateStep;
  final FilterMode filterMode;
  final DateTime activeDate;
  final DateTimeRange? activeDateRange;
  final Sort sort;
  final String? errorMessage;
  final int totalCount;

  const InflationState({
    this.status = InflationStatus.initial,
    this.rates = const [],
    this.hasMore = true,
    this.offset = 0,
    this.limit = 50,
    this.isLoadingMore = false,
    this.dateStep = DateStep.month,
    this.filterMode = FilterMode.date,
    required this.activeDate,
    this.activeDateRange,
    this.sort = Sort.descending,
    this.errorMessage,
    this.totalCount = 0,
    this.countryFilters,
    this.presetFilters,
    this.selectedRates = const {},
    this.isSelectionModeActive = false,
  });

  final List<String>? countryFilters;
  final List<int>? presetFilters;
  final Set<InflationRateDomain> selectedRates;
  final bool isSelectionModeActive;

  InflationState copyWith({
    InflationStatus? status,
    List<InflationRateDomain>? rates,
    bool? hasMore,
    int? offset,
    int? limit,
    bool? isLoadingMore,
    DateStep? dateStep,
    FilterMode? filterMode,
    DateTime? activeDate,
    DateTimeRange? activeDateRange,
    Sort? sort,
    String? errorMessage,
    int? totalCount,
    List<String>? countryFilters,
    List<int>? presetFilters,
    Set<InflationRateDomain>? selectedRates,
    bool? isSelectionModeActive,
    bool forceNullCountryFilters = false,
    bool forceNullPresetFilters = false,
  }) {
    return InflationState(
      status: status ?? this.status,
      rates: rates ?? this.rates,
      hasMore: hasMore ?? this.hasMore,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      dateStep: dateStep ?? this.dateStep,
      filterMode: filterMode ?? this.filterMode,
      activeDate: activeDate ?? this.activeDate,
      activeDateRange: activeDateRange ?? this.activeDateRange,
      sort: sort ?? this.sort,
      errorMessage: errorMessage ?? this.errorMessage,
      totalCount: totalCount ?? this.totalCount,
      countryFilters: forceNullCountryFilters
          ? null
          : (countryFilters ?? this.countryFilters),
      presetFilters: forceNullPresetFilters
          ? null
          : (presetFilters ?? this.presetFilters),
      selectedRates: selectedRates ?? this.selectedRates,
      isSelectionModeActive:
          isSelectionModeActive ?? this.isSelectionModeActive,
    );
  }

  @override
  List<Object?> get props => [
    status,
    rates,
    hasMore,
    offset,
    limit,
    isLoadingMore,
    dateStep,
    filterMode,
    activeDate,
    activeDateRange,
    sort,
    errorMessage,
    totalCount,
    countryFilters,
    presetFilters,
    selectedRates,
    isSelectionModeActive,
  ];
}
