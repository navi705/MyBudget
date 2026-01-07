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

class AccountsLoadInProgress extends AccountsState {}

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
        income,
        expense,
      ];
}

class AccountsLoadFailure extends AccountsState {}
