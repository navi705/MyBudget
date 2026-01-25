part of 'accounts_bloc.dart';

abstract class AccountsState extends Equatable {
  final Account? recentlyDeletedAccount;
  final DateTime activeDate;
  final DateStep dateStep;
  final AccountFilters filters;

  const AccountsState({
    this.recentlyDeletedAccount,
    required this.activeDate,
    this.dateStep = DateStep.month,
    this.filters = const AccountFilters(sort: Sort.descending),
  });

  @override
  List<Object?> get props => [
    recentlyDeletedAccount,
    activeDate,
    dateStep,
    filters,
  ];

  AccountsState copyWith({
    Account? recentlyDeletedAccount,
    bool clearRecentlyDeletedAccount = false,
    DateTime? activeDate,
    DateStep? dateStep,
    AccountFilters? filters,
  });

  // Default values for properties that are common across states
  List<Account> get accounts => [];
  List<AccountType> get accountTypes => [];
  bool get hasReachedMax => false;
  int get limit => 500;
  int get totalCount => 0;
  bool get sortAscending => false;
  String get selectedAccountTypeId => 'all';
  Map<String, double> get historicalBalances => {};
  Map<String, double> get realBalances => {};
  Map<String, double> get inflationLosses => {};
  bool get isHistorical => false;
  bool get isSelectionModeActive => false;
  Set<String> get selectedAccountIds => {};
}

class AccountsInitial extends AccountsState {
  AccountsInitial() : super(activeDate: DateTime.now());

  @override
  AccountsInitial copyWith({
    Account? recentlyDeletedAccount,
    bool clearRecentlyDeletedAccount = false,
    DateTime? activeDate,
    DateStep? dateStep,
    AccountFilters? filters,
  }) {
    // Initial state doesn't really change, but we implement for signature
    return this;
  }
}

class AccountsLoadInProgress extends AccountsState {
  const AccountsLoadInProgress({
    super.recentlyDeletedAccount,
    required super.activeDate,
    super.dateStep,
    super.filters,
  });

  @override
  List<Object?> get props => [filters];

  @override
  AccountsLoadInProgress copyWith({
    Account? recentlyDeletedAccount,
    bool clearRecentlyDeletedAccount = false,
    DateTime? activeDate,
    DateStep? dateStep,
    AccountFilters? filters,
  }) {
    return AccountsLoadInProgress(
      recentlyDeletedAccount: clearRecentlyDeletedAccount
          ? null
          : (recentlyDeletedAccount ?? this.recentlyDeletedAccount),
      activeDate: activeDate ?? this.activeDate,
      dateStep: dateStep ?? this.dateStep,
      filters: filters ?? this.filters,
    );
  }
}

class AccountsLoadSuccess extends AccountsState {
  @override
  final List<Account> accounts;
  @override
  final List<AccountType> accountTypes;
  @override
  final bool hasReachedMax;
  @override
  final int totalCount;
  @override
  final bool sortAscending;
  @override
  final Map<String, double> historicalBalances;
  @override
  final bool isHistorical;
  @override
  final bool isSelectionModeActive;
  @override
  final Set<String> selectedAccountIds;
  final List<ExchangeRateDomain> exchangeRates;
  @override
  final Map<String, double> realBalances;
  @override
  final Map<String, double> inflationLosses;
  final Map<String, double> previousPeriodRealBalances;
  final Map<String, double> previousPeriodBalances;
  final List<Category> categories; // Added

  // Current Period Stats (Per Account)
  final Map<String, double> accountIncomes;
  final Map<String, double> accountExpenses;
  final Map<String, double> accountRealIncomes;
  final Map<String, double> accountRealExpenses;
  final Map<String, double> assetValues; // Added
  final Map<String, AssetStats> assetStats; // Added: Detailed Asset Stats

  // Previous Period Stats (Per Account)
  final Map<String, double> previousAccountIncomes;
  final Map<String, double> previousAccountExpenses;
  final Map<String, double> previousAccountRealIncomes;
  final Map<String, double> previousAccountRealExpenses;

  final double income;
  final double expense;

  const AccountsLoadSuccess({
    required this.accounts,
    required this.accountTypes,
    required this.hasReachedMax,
    required this.totalCount,
    this.sortAscending = false,
    super.recentlyDeletedAccount,
    this.historicalBalances = const {},
    this.isHistorical = false,
    this.isSelectionModeActive = false,
    this.selectedAccountIds = const {},
    super.dateStep = DateStep.month,
    required super.activeDate,
    super.filters = const AccountFilters(sort: Sort.descending),
    required this.exchangeRates,
    this.realBalances = const {},
    this.inflationLosses = const {},
    this.previousPeriodRealBalances = const {},
    this.previousPeriodBalances = const {},
    this.categories = const [],
    this.accountIncomes = const {},
    this.accountExpenses = const {},
    this.accountRealIncomes = const {},
    this.accountRealExpenses = const {},
    this.assetValues = const {},
    this.assetStats = const {}, // Added
    this.previousAccountIncomes = const {},
    this.previousAccountExpenses = const {},
    this.previousAccountRealIncomes = const {},
    this.previousAccountRealExpenses = const {},
    this.income = 0.0,
    this.expense = 0.0,
  });

  @override
  AccountsLoadSuccess copyWith({
    List<Account>? accounts,
    List<AccountType>? accountTypes,
    bool? hasReachedMax,
    int? totalCount,
    bool? sortAscending,
    Account? recentlyDeletedAccount,
    bool clearRecentlyDeletedAccount = false,
    Map<String, double>? historicalBalances,
    bool? isHistorical,
    bool? isSelectionModeActive,
    Set<String>? selectedAccountIds,
    DateStep? dateStep,
    DateTime? activeDate,
    AccountFilters? filters,
    List<ExchangeRateDomain>? exchangeRates,
    Map<String, double>? realBalances,
    Map<String, double>? inflationLosses,
    Map<String, double>? previousPeriodRealBalances,
    Map<String, double>? previousPeriodBalances,
    List<Category>? categories,
    Map<String, double>? accountIncomes,
    Map<String, double>? accountExpenses,
    Map<String, double>? accountRealIncomes,
    Map<String, double>? accountRealExpenses,
    Map<String, double>? assetValues,
    Map<String, AssetStats>? assetStats, // Added
    Map<String, double>? previousAccountIncomes,
    Map<String, double>? previousAccountExpenses,
    Map<String, double>? previousAccountRealIncomes,
    Map<String, double>? previousAccountRealExpenses,
    double? income,
    double? expense,
  }) {
    return AccountsLoadSuccess(
      accounts: accounts ?? this.accounts,
      accountTypes: accountTypes ?? this.accountTypes,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      totalCount: totalCount ?? this.totalCount,
      sortAscending: sortAscending ?? this.sortAscending,
      recentlyDeletedAccount: clearRecentlyDeletedAccount
          ? null
          : (recentlyDeletedAccount ?? this.recentlyDeletedAccount),
      historicalBalances: historicalBalances ?? this.historicalBalances,
      isHistorical: isHistorical ?? this.isHistorical,
      isSelectionModeActive:
          isSelectionModeActive ?? this.isSelectionModeActive,
      selectedAccountIds: selectedAccountIds ?? this.selectedAccountIds,
      dateStep: dateStep ?? this.dateStep,
      activeDate: activeDate ?? this.activeDate,
      filters: filters ?? this.filters,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      realBalances: realBalances ?? this.realBalances,
      inflationLosses: inflationLosses ?? this.inflationLosses,
      previousPeriodRealBalances:
          previousPeriodRealBalances ?? this.previousPeriodRealBalances,
      previousPeriodBalances:
          previousPeriodBalances ?? this.previousPeriodBalances,
      categories: categories ?? this.categories,
      accountIncomes: accountIncomes ?? this.accountIncomes,
      accountExpenses: accountExpenses ?? this.accountExpenses,
      accountRealIncomes: accountRealIncomes ?? this.accountRealIncomes,
      accountRealExpenses: accountRealExpenses ?? this.accountRealExpenses,
      assetValues: assetValues ?? this.assetValues,
      assetStats: assetStats ?? this.assetStats,
      previousAccountIncomes:
          previousAccountIncomes ?? this.previousAccountIncomes,
      previousAccountExpenses:
          previousAccountExpenses ?? this.previousAccountExpenses,
      previousAccountRealIncomes:
          previousAccountRealIncomes ?? this.previousAccountRealIncomes,
      previousAccountRealExpenses:
          previousAccountRealExpenses ?? this.previousAccountRealExpenses,
      income: income ?? this.income,
      expense: expense ?? this.expense,
    );
  }

  @override
  List<Object?> get props => [
    accounts,
    accountTypes,
    hasReachedMax,
    totalCount,
    sortAscending,
    recentlyDeletedAccount,
    historicalBalances,
    isHistorical,
    isSelectionModeActive,
    selectedAccountIds,
    dateStep,
    activeDate,
    filters,
    exchangeRates,
    realBalances,
    inflationLosses,
    previousPeriodRealBalances,
    previousPeriodBalances,
    categories,
    accountIncomes,
    accountExpenses,
    accountRealIncomes,
    accountRealExpenses,
    assetValues,
    assetStats, // Added
    previousAccountIncomes,
    previousAccountExpenses,
    previousAccountRealIncomes,
    previousAccountRealExpenses,
    income,
    expense,
  ];
}

class AccountsLoadFailure extends AccountsState {
  const AccountsLoadFailure({
    super.recentlyDeletedAccount,
    required super.activeDate,
    super.dateStep,
    super.filters,
  });

  @override
  AccountsLoadFailure copyWith({
    Account? recentlyDeletedAccount,
    bool clearRecentlyDeletedAccount = false,
    DateTime? activeDate,
    DateStep? dateStep,
    AccountFilters? filters,
  }) {
    return AccountsLoadFailure(
      recentlyDeletedAccount: clearRecentlyDeletedAccount
          ? null
          : (recentlyDeletedAccount ?? this.recentlyDeletedAccount),
      activeDate: activeDate ?? this.activeDate,
      dateStep: dateStep ?? this.dateStep,
      filters: filters ?? this.filters,
    );
  }
}
