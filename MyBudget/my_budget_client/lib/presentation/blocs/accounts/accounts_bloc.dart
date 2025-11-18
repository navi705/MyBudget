import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final AccountRepository _accountRepository;
  StreamSubscription? _accountsSubscription;

  AccountsBloc({required AccountRepository accountRepository})
      : _accountRepository = accountRepository,
        super(AccountsInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<AddAccount>(_onAddAccount);
    on<UpdateAccount>(_onUpdateAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<UndoDeleteAccount>(_onUndoDeleteAccount);
    on<_AccountsUpdated>(_onAccountsUpdated);
  }

  void _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountsState> emit,
  ) {
    emit(AccountsLoadInProgress());
    _accountsSubscription?.cancel();
    _accountsSubscription = _accountRepository.watchAccounts().listen(
          (accounts) => add(_AccountsUpdated(accounts)),
          onError: (_) => emit(AccountsLoadFailure()),
        );
  }

  Future<void> _onAddAccount(
    AddAccount event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.addAccount(event.account);
  }

  Future<void> _onUpdateAccount(
    UpdateAccount event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.updateAccount(event.account);
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final accountToDelete =
          currentState.accounts.firstWhere((acc) => acc.id == event.id);
      emit(currentState.copyWith(recentlyDeletedAccount: accountToDelete));
      await _accountRepository.deleteAccount(event.id);
    }
  }

  Future<void> _onUndoDeleteAccount(
    UndoDeleteAccount event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState.recentlyDeletedAccount != null) {
      await _accountRepository.restoreAccount(currentState.recentlyDeletedAccount!);
      if (currentState is AccountsLoadSuccess) {
        emit(currentState.copyWith(clearRecentlyDeleted: true));
      }
    }
  }

  void _onAccountsUpdated(
    _AccountsUpdated event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(currentState.copyWith(accounts: event.accounts));
    } else {
      emit(AccountsLoadSuccess(accounts: event.accounts));
    }
  }

  @override
  Future<void> close() {
    _accountsSubscription?.cancel();
    return super.close();
  }
}
