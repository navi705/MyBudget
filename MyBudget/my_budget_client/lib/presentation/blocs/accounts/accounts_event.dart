part of 'accounts_bloc.dart';

abstract class AccountsEvent extends Equatable {
  const AccountsEvent();

  @override
  List<Object> get props => [];
}

class LoadAccounts extends AccountsEvent {}

class AddAccount extends AccountsEvent {
  final Account account;

  const AddAccount(this.account);

  @override
  List<Object> get props => [account];
}

class UpdateAccount extends AccountsEvent {
  final Account account;

  const UpdateAccount(this.account);

  @override
  List<Object> get props => [account];
}

class DeleteAccount extends AccountsEvent {
  final int id;

  const DeleteAccount(this.id);

  @override
  List<Object> get props => [id];
}

class UndoDeleteAccount extends AccountsEvent {}

class _AccountsAndAccountTypesUpdated extends AccountsEvent {
  final List<Account> accounts;
  final List<AccountType> accountTypes;

  const _AccountsAndAccountTypesUpdated(this.accounts, this.accountTypes);

  @override
  List<Object> get props => [accounts, accountTypes];
}
