part of 'accounts_bloc.dart';

abstract class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object?> get props => [];

  // Default values for properties that are common across states
  List<Account> get accounts => [];
  List<AccountType> get accountTypes => [];
  bool get hasReachedMax => false;
  int get limit => 500;
  int get totalCount => 0;
  bool get sortAscending => false;
  String get selectedAccountTypeId => 'all';
  Account? get recentlyDeletedAccount => null;
  Map<String, double> get historicalBalances => {};
  Map<String, double> get realBalances => {};
  Map<String, double> get inflationLosses => {};
  bool get isHistorical => false;
  bool get isSelectionModeActive => false;
  Set<String> get selectedAccountIds => {};
  DateStep get dateStep => DateStep.month;
  DateTime get activeDate => DateTime.now();
  AccountFilters get filters => const AccountFilters(sort: Sort.descending);
}

class AccountsInitial extends AccountsState {}

class AccountsLoadInProgress extends AccountsState {
  @override
  final DateTime activeDate;
  @override
  final DateStep dateStep;
  @override
  final AccountFilters filters;

  AccountsLoadInProgress({
    DateTime? activeDate,
    this.dateStep = DateStep.month,
    this.filters = const AccountFilters(sort: Sort.descending),
  }) : activeDate = activeDate ?? DateTime.now();

  @override
  List<Object?> get props => [activeDate, dateStep, filters];
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
  final Account? recentlyDeletedAccount;
  @override
  final Map<String, double> historicalBalances;
  @override
  final bool isHistorical;
  @override
  final bool isSelectionModeActive;
  @override
  final Set<String> selectedAccountIds;
  @override
  final DateStep dateStep;
  @override
  final DateTime activeDate;
  @override
  final AccountFilters filters;
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
    this.recentlyDeletedAccount,
    this.historicalBalances = const {},
    this.isHistorical = false,
    this.isSelectionModeActive = false,
    this.selectedAccountIds = const {},
    this.dateStep = DateStep.month,
    required this.activeDate,
    this.filters = const AccountFilters(sort: Sort.descending),
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

  AccountsLoadSuccess copyWith({
    List<Account>? accounts,
    List<AccountType>? accountTypes,
    bool? hasReachedMax,
    int? totalCount,
    bool? sortAscending,
    Account? recentlyDeletedAccount,
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
      recentlyDeletedAccount:
          recentlyDeletedAccount, // Always update, even if null
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
      assetStats: assetStats ?? this.assetStats, // Added
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

class AccountsLoadFailure extends AccountsState {}
