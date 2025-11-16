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
    on<DeleteAccount>(_onDeleteAccount);
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
        );
  }

  Future<void> _onAddAccount(
    AddAccount event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.addAccount(event.account);
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.deleteAccount(event.id);
  }

  void _onAccountsUpdated(
    _AccountsUpdated event,
    Emitter<AccountsState> emit,
  ) {
    emit(AccountsLoadSuccess(event.accounts));
  }

  @override
  Future<void> close() {
    _accountsSubscription?.cancel();
    return super.close();
  }
}
