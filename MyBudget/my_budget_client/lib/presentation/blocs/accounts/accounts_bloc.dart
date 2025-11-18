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
  StreamSubscription? _accountsSubscription;
  StreamSubscription? _accountTypesSubscription;

  AccountsBloc({required AccountRepository accountRepository})
      : _accountRepository = accountRepository,
        super(AccountsInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<AddAccount>(_onAddAccount);
    on<UpdateAccount>(_onUpdateAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<UndoDeleteAccount>(_onUndoDeleteAccount);
    on<_AccountsAndAccountTypesUpdated>(_onAccountsAndAccountTypesUpdated);
  }

  void _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountsState> emit,
  ) {
    emit(AccountsLoadInProgress());
    _accountsSubscription?.cancel();
    _accountTypesSubscription?.cancel();

    _accountsSubscription = Rx.combineLatest2(
      _accountRepository.watchAccounts(),
      _accountRepository.watchAccountTypes(),
      (List<Account> accounts, List<AccountType> accountTypes) =>
          add(_AccountsAndAccountTypesUpdated(accounts, accountTypes)),
    ).listen(
      null,
      onError: (error, stackTrace) {
        emit(AccountsLoadFailure());
      },
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

  void _onAccountsAndAccountTypesUpdated(
    _AccountsAndAccountTypesUpdated event,
    Emitter<AccountsState> emit,
  ) {
    emit(AccountsLoadSuccess(
      accounts: event.accounts,
      accountTypes: event.accountTypes,
    ));
  }

  @override
  Future<void> close() {
    _accountsSubscription?.cancel();
    _accountTypesSubscription?.cancel();
    return super.close();
  }
}
