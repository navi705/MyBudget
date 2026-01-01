import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/core/utils/device_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final AccountRepository _accountRepository;
  final SettingsRepository _settingsRepository;

  AccountsBloc(
      {required AccountRepository accountRepository,
      required SettingsRepository settingsRepository})
      : _accountRepository = accountRepository,
        _settingsRepository = settingsRepository,
        super(AccountsInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<LoadMoreAccounts>(_onLoadMoreAccounts);
    on<AddAccount>(_onAddAccount);
    on<UpdateAccount>(_onUpdateAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<UndoDeleteAccount>(_onUndoDeleteAccount);
    on<SortAccounts>(_onSortAccounts);
    on<FiltersChanged>(_onFiltersChanged);
    on<LoadHistoricalBalances>(_onLoadHistoricalBalances);
    on<ClearHistoricalBalances>(_onClearHistoricalBalances);
    on<ToggleSelectionMode>(_onToggleSelectionMode);
    on<ToggleAccountSelection>(_onToggleAccountSelection);
    on<SelectAllAccounts>(_onSelectAllAccounts);
    on<ClearSelection>(_onClearSelection);
    on<DeleteMultipleAccounts>(_onDeleteMultipleAccounts);
    on<UpdateAccountTypeForMultipleAccounts>(
        _onUpdateAccountTypeForMultipleAccounts);
    on<DatePeriodNavigated>(_onDatePeriodNavigated);
    on<DateStepChanged>(_onDateStepChanged);
    on<ActiveDateChanged>(_onActiveDateChanged);
  }

  void _onDatePeriodNavigated(
    DatePeriodNavigated event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess) return;

    DateTime newDate;
    switch (currentState.dateStep) {
      case DateStep.day:
        newDate = currentState.activeDate.add(Duration(days: event.direction));
        break;
      case DateStep.month:
        newDate = DateTime(
          currentState.activeDate.year,
          currentState.activeDate.month + event.direction,
          currentState.activeDate.day,
        );
        break;
      case DateStep.year:
        newDate = DateTime(
          currentState.activeDate.year + event.direction,
          currentState.activeDate.month,
          currentState.activeDate.day,
        );
        break;
    }
    emit(currentState.copyWith(activeDate: newDate));
    add(LoadHistoricalBalances(newDate));
  }

  void _onDateStepChanged(
    DateStepChanged event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(currentState.copyWith(dateStep: event.dateStep));
      add(LoadHistoricalBalances(currentState.activeDate));
    }
  }

  void _onActiveDateChanged(
    ActiveDateChanged event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(currentState.copyWith(activeDate: event.date));
      add(LoadHistoricalBalances(event.date));
    }
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    emit(AccountsLoadInProgress());
    try {
      var filters = currentState.filters;
      final savedFilters =
          await _settingsRepository.getSetting('account_filters');
      if (savedFilters != null) {
        filters = AccountFilters.fromJsonString(savedFilters.value);
      }

      final results = await Future.wait([
        _accountRepository.getAccountTypes(),
        _accountRepository.getAccountsPaginatedFiltered(
            limit: currentState.limit, offset: 0, accountFilters: filters),
        _accountRepository.getCountWithFilters(
            accountTypeIds: filters.accountTypeIds),
      ]);

      

      final accountTypes = results[0] as List<AccountType>;
      final accounts = results[1] as List<Account>;
      final totalCount = results[2] as int;

      emit(AccountsLoadSuccess(
        accounts: accounts,
        accountTypes: accountTypes,
        hasReachedMax: accounts.length >= totalCount,
        totalCount: totalCount,
        sortAscending: filters.sort == Sort.ascending,
        filters: filters,
        activeDate: currentState.activeDate,
        isSelectionModeActive: currentState.isSelectionModeActive,
        selectedAccountIds: currentState.selectedAccountIds,
        dateStep: currentState.dateStep,
      ));
    } catch (e) {
      emit(AccountsLoadFailure());
    }
  }

  Future<void> _onLoadMoreAccounts(
    LoadMoreAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess || currentState.hasReachedMax) {
      return;
    }

    try {
      final accounts = await _accountRepository.getAccountsPaginatedFiltered(
        offset: currentState.accounts.length,
        limit: currentState.limit,
        accountFilters: currentState.filters,
      );
      if (accounts.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true));
      } else {
        emit(
          currentState.copyWith(
            accounts: List.of(currentState.accounts)..addAll(accounts),
            hasReachedMax:
                (currentState.accounts.length + accounts.length) >=
                    currentState.totalCount,
          ),
        );
      }
    } catch (_) {
      // Keep current state on error
    }
  }

  Future<void> _onAddAccount(
    AddAccount event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.addAccount(event.account);
    add(LoadAccounts()); // Reload list
  }

  Future<void> _onUpdateAccount(
    UpdateAccount event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.updateAccount(event.account);
    add(LoadAccounts()); // Reload list
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      try {
        final accountToDelete =
            currentState.accounts.firstWhere((acc) => acc.id == event.id);
        emit(currentState.copyWith(recentlyDeletedAccount: accountToDelete));
        await _accountRepository.deleteAccount(event.id);
        add(LoadAccounts()); // Reload list
      } catch (e) {
        // Handle case where account is not found or other errors
      }
    }
  }

  Future<void> _onUndoDeleteAccount(
    UndoDeleteAccount event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess &&
        currentState.recentlyDeletedAccount != null) {
      await _accountRepository
          .restoreAccount(currentState.recentlyDeletedAccount!);
      add(LoadAccounts()); // Reload list
    }
  }

  void _onSortAccounts(SortAccounts event, Emitter<AccountsState> emit) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final newFilters = currentState.filters
          .copyWith(sort: event.sortAscending ? Sort.ascending : Sort.descending);
      add(FiltersChanged(newFilters));
    }
  }

  Future<void> _onFiltersChanged(
      FiltersChanged event, Emitter<AccountsState> emit) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final deviceName = await getDeviceName();
      await _settingsRepository.setSetting(Settings(
        key: 'account_filters',
        value: event.filters.toJsonString(),
        device: deviceName,
      ));
      emit(currentState.copyWith(filters: event.filters));
      add(LoadAccounts());
    }
  }

  Future<void> _onLoadHistoricalBalances(
    LoadHistoricalBalances event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final historicalBalances =
          await _accountRepository.getBalancesAtDate(event.date);
      emit(currentState.copyWith(
        historicalBalances: historicalBalances,
        isHistorical: true,
      ));
    }
  }

  void _onClearHistoricalBalances(
    ClearHistoricalBalances event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(currentState.copyWith(
        historicalBalances: {},
        isHistorical: false,
      ));
    }
  }

  void _onToggleSelectionMode(
    ToggleSelectionMode event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(currentState.copyWith(
        isSelectionModeActive: event.isSelectionModeActive,
        selectedAccountIds:
            event.isSelectionModeActive ? currentState.selectedAccountIds : {},
      ));
    }
  }

  void _onToggleAccountSelection(
    ToggleAccountSelection event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final newSelectedIds =
          Set<String>.from(currentState.selectedAccountIds);
      if (newSelectedIds.contains(event.accountId)) {
        newSelectedIds.remove(event.accountId);
      } else {
        newSelectedIds.add(event.accountId);
      }
      emit(currentState.copyWith(selectedAccountIds: newSelectedIds));
    }
  }

  void _onSelectAllAccounts(
    SelectAllAccounts event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final allIds = currentState.accounts.map((acc) => acc.id!).toSet();
      emit(currentState.copyWith(selectedAccountIds: allIds));
    }
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(currentState.copyWith(selectedAccountIds: {}));
    }
  }

  Future<void> _onDeleteMultipleAccounts(
    DeleteMultipleAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.deleteMultipleAccounts(event.accountIds);
    add(LoadAccounts());
  }

  Future<void> _onUpdateAccountTypeForMultipleAccounts(
    UpdateAccountTypeForMultipleAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.updateAccountTypeForMultipleAccounts(
      event.accountIds,
      event.accountTypeId,
    );
    add(LoadAccounts());
  }
}