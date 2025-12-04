import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final AccountRepository _accountRepository;
  AccountsBloc({required AccountRepository accountRepository})
      : _accountRepository = accountRepository,
        super(AccountsInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<LoadMoreAccounts>(_onLoadMoreAccounts);
    on<AddAccount>(_onAddAccount);
    on<UpdateAccount>(_onUpdateAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<UndoDeleteAccount>(_onUndoDeleteAccount);
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    emit(AccountsLoadInProgress());
    try {
      // Fetch account types and the first page of accounts in parallel
      final results = await Future.wait([
        _accountRepository.getAccountTypes(),
        _accountRepository.getAccountsPaginated(limit: 50, offset: 0),
      ]);

      final accountTypes = results[0] as List<AccountType>;
      final accounts = results[1] as List<Account>;

      emit(AccountsLoadSuccess(
        accounts: accounts,
        accountTypes: accountTypes,
        hasReachedMax: accounts.length < 50,
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
      final accounts = await _accountRepository.getAccountsPaginated(
        offset: currentState.accounts.length,
        limit: 50,
      );
      if (accounts.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true));
      } else {
        emit(
          currentState.copyWith(
            accounts: List.of(currentState.accounts)..addAll(accounts),
            hasReachedMax: accounts.length < 50,
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
    // We keep the 'undo' feature UI-side by snapshotting the account
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
    if (currentState.recentlyDeletedAccount != null) {
      await _accountRepository.restoreAccount(currentState.recentlyDeletedAccount!);
      add(LoadAccounts()); // Reload list
    }
  }
}
