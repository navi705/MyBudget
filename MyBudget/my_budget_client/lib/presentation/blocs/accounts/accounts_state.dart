part of 'accounts_bloc.dart';

abstract class AccountsState extends Equatable {
  final List<Account> accounts;
  final List<AccountType> accountTypes;
  final Account? recentlyDeletedAccount;
  final bool hasReachedMax;
  final bool sortAscending;
  final String selectedAccountTypeId;
  final Map<String, double> historicalBalances;
  final bool isHistorical;
  final int totalCount;
  final bool isSelectionModeActive;
  final Set<String> selectedAccountIds;
  final DateStep dateStep;
  final DateTime activeDate;
  final int limit;

  AccountsState({
    this.accounts = const [],
    this.accountTypes = const [],
    this.recentlyDeletedAccount,
    this.hasReachedMax = false,
    this.sortAscending = true,
    this.selectedAccountTypeId = 'all',
    this.historicalBalances = const {},
    this.isHistorical = false,
    this.totalCount = 0,
    this.isSelectionModeActive = false,
    this.selectedAccountIds = const {},
    this.dateStep = DateStep.month,
    DateTime? activeDate,
    this.limit = 500,
  }) : activeDate = activeDate ?? DateTime.now();

  @override
  List<Object?> get props => [
        accounts,
        accountTypes,
        recentlyDeletedAccount,
        hasReachedMax,
        sortAscending,
        selectedAccountTypeId,
        historicalBalances,
        isHistorical,
        totalCount,
        isSelectionModeActive,
        selectedAccountIds,
        dateStep,
        activeDate,
        limit,
      ];
}

class AccountsInitial extends AccountsState {}

class AccountsLoadInProgress extends AccountsState {}

class AccountsLoadSuccess extends AccountsState {
  AccountsLoadSuccess({
    super.accounts,
    super.accountTypes,
    super.recentlyDeletedAccount,
    super.hasReachedMax,
    super.sortAscending,
    super.selectedAccountTypeId,
    super.historicalBalances,
    super.isHistorical,
    super.totalCount,
    super.isSelectionModeActive,
    super.selectedAccountIds,
    super.dateStep,
    super.activeDate,
    super.limit,
  });

  AccountsLoadSuccess copyWith({
    List<Account>? accounts,
    List<AccountType>? accountTypes,
    Account? recentlyDeletedAccount,
    bool? hasReachedMax,
    bool? sortAscending,
    String? selectedAccountTypeId,
    Map<String, double>? historicalBalances,
    bool? isHistorical,
    int? totalCount,
    bool? isSelectionModeActive,
    Set<String>? selectedAccountIds,
    DateStep? dateStep,
    DateTime? activeDate,
    int? limit,
    bool clearRecentlyDeleted = false,
  }) {
    return AccountsLoadSuccess(
      accounts: accounts ?? this.accounts,
      accountTypes: accountTypes ?? this.accountTypes,
      recentlyDeletedAccount: clearRecentlyDeleted
          ? null
          : recentlyDeletedAccount ?? this.recentlyDeletedAccount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      sortAscending: sortAscending ?? this.sortAscending,
      selectedAccountTypeId:
          selectedAccountTypeId ?? this.selectedAccountTypeId,
      historicalBalances: historicalBalances ?? this.historicalBalances,
      isHistorical: isHistorical ?? this.isHistorical,
      totalCount: totalCount ?? this.totalCount,
      isSelectionModeActive:
          isSelectionModeActive ?? this.isSelectionModeActive,
      selectedAccountIds: selectedAccountIds ?? this.selectedAccountIds,
      dateStep: dateStep ?? this.dateStep,
      activeDate: activeDate ?? this.activeDate,
      limit: limit ?? this.limit,
    );
  }
}

class AccountsLoadFailure extends AccountsState {}
