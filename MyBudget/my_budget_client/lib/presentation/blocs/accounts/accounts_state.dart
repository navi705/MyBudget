part of 'accounts_bloc.dart';

abstract class AccountsState extends Equatable {
  const AccountsState();

  @override
  List<Object> get props => [];
}

class AccountsInitial extends AccountsState {}

class AccountsLoadInProgress extends AccountsState {}

class AccountsLoadSuccess extends AccountsState {
  final List<Account> accounts;

  const AccountsLoadSuccess([this.accounts = const []]);

  @override
  List<Object> get props => [accounts];
}

class AccountsLoadFailure extends AccountsState {}
