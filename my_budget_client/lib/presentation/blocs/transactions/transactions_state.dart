part of 'transactions_bloc.dart';

enum TransactionStatus { initial, loading, success, failure }

class TransactionsState extends Equatable {
  final TransactionStatus status;
  final List<TransactionCategory> transactions; // Changed type here
  final int windowSize;
  final bool hasMoreUp;
  final bool hasMoreDown;
  final int startIndex;
  final String? jumpToItemId;
  final double? jumpToAlignment;
  final int totalCount;
  final Sort sort;

  // New UI state fields
  final DateStep dateStep;
  final FilterMode filterMode;
  final DateTime activeDate;
  final DateTimeRange? activeDateRange;
  final TransactionFilters nonDateFilters;

  // Selection state
  final bool isSelectionModeActive;
  final Set<String> selectedTransactionIds;

  final List<CurrencyDesignation> currencyDesignations;
  final Map<DateTime, double> dailyTotals;
  final String mainCurrencyCode;

  final List<Transaction>? recentlyDeletedTransactions;

  TransactionsState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.windowSize = 1000,
    this.hasMoreUp = false,
    this.hasMoreDown = true,
    this.startIndex = 0,
    this.jumpToItemId,
    this.jumpToAlignment,
    this.totalCount = 0,
    this.sort = Sort.descending,
    this.dateStep = DateStep.month,
    this.filterMode = FilterMode.date,
    DateTime? activeDate,
    this.activeDateRange,
    this.nonDateFilters = const TransactionFilters(),
    this.isSelectionModeActive = false,
    this.selectedTransactionIds = const {},
    this.currencyDesignations = const [],
    this.dailyTotals = const {},
    this.mainCurrencyCode = 'EUR',
    this.recentlyDeletedTransactions,
  }) : activeDate = activeDate ?? DateTime.now();

  // Combined filters getter
  TransactionFilters get filters {
    if (filterMode == FilterMode.range && activeDateRange != null) {
      return nonDateFilters.copyWith(
        dateFrom: activeDateRange!.start,
        dateTo: activeDateRange!.end,
      );
    }

    DateTime startDate;
    DateTime endDate;
    switch (dateStep) {
      case DateStep.day:
        startDate = DateTime(activeDate.year, activeDate.month, activeDate.day);
        endDate = DateTime(
          activeDate.year,
          activeDate.month,
          activeDate.day,
          23,
          59,
          59,
        );
        break;
      case DateStep.month:
        startDate = DateTime(activeDate.year, activeDate.month, 1);
        endDate = DateTime(
          activeDate.year,
          activeDate.month + 1,
          0,
          23,
          59,
          59,
        );
        break;
      case DateStep.year:
        startDate = DateTime(activeDate.year, 1, 1);
        endDate = DateTime(activeDate.year, 12, 31, 23, 59, 59);
        break;
    }
    return nonDateFilters.copyWith(dateFrom: startDate, dateTo: endDate);
  }

  TransactionsState copyWith({
    TransactionStatus? status,
    List<TransactionCategory>? transactions, // Changed type here
    int? windowSize,
    bool? hasMoreUp,
    bool? hasMoreDown,
    int? startIndex,
    String? jumpToItemId,
    double? jumpToAlignment,
    int? totalCount,
    Sort? sort,
    DateStep? dateStep,
    FilterMode? filterMode,
    DateTime? activeDate,
    ValueGetter<DateTimeRange?>? activeDateRange,
    TransactionFilters? nonDateFilters,
    bool? isSelectionModeActive,
    Set<String>? selectedTransactionIds,
    List<CurrencyDesignation>? currencyDesignations,
    Map<DateTime, double>? dailyTotals,
    String? mainCurrencyCode,
    List<Transaction>? recentlyDeletedTransactions,
    bool clearRecentlyDeletedTransactions = false,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      windowSize: windowSize ?? this.windowSize,
      hasMoreUp: hasMoreUp ?? this.hasMoreUp,
      hasMoreDown: hasMoreDown ?? this.hasMoreDown,
      startIndex: startIndex ?? this.startIndex,
      jumpToItemId: jumpToItemId,
      jumpToAlignment: jumpToAlignment,
      totalCount: totalCount ?? this.totalCount,
      sort: sort ?? this.sort,
      dateStep: dateStep ?? this.dateStep,
      filterMode: filterMode ?? this.filterMode,
      activeDate: activeDate ?? this.activeDate,
      activeDateRange: activeDateRange != null
          ? activeDateRange()
          : this.activeDateRange,
      nonDateFilters: nonDateFilters ?? this.nonDateFilters,
      isSelectionModeActive:
          isSelectionModeActive ?? this.isSelectionModeActive,
      selectedTransactionIds:
          selectedTransactionIds ?? this.selectedTransactionIds,
      currencyDesignations: currencyDesignations ?? this.currencyDesignations,
      dailyTotals: dailyTotals ?? this.dailyTotals,
      mainCurrencyCode: mainCurrencyCode ?? this.mainCurrencyCode,
      recentlyDeletedTransactions: clearRecentlyDeletedTransactions
          ? null
          : (recentlyDeletedTransactions ?? this.recentlyDeletedTransactions),
    );
  }

  @override
  List<Object?> get props => [
    status,
    transactions,
    windowSize,
    hasMoreUp,
    hasMoreDown,
    startIndex,
    jumpToItemId,
    jumpToAlignment,
    totalCount,
    sort,
    dateStep,
    filterMode,
    activeDate,
    activeDateRange,
    nonDateFilters,
    isSelectionModeActive,
    selectedTransactionIds,
    currencyDesignations,
    dailyTotals,
    mainCurrencyCode,
    recentlyDeletedTransactions,
  ];
}
