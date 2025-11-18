part of 'accounts_bloc.dart';

abstract class AccountsState extends Equatable {
  final List<Account> accounts;
  final Account? recentlyDeletedAccount;

  const AccountsState({this.accounts = const [], this.recentlyDeletedAccount});

  @override
  List<Object?> get props => [accounts, recentlyDeletedAccount];
}

class AccountsInitial extends AccountsState {}

class AccountsLoadInProgress extends AccountsState {}

class AccountsLoadSuccess extends AccountsState {
  const AccountsLoadSuccess({
    super.accounts = const [],
    super.recentlyDeletedAccount,
  });

  AccountsLoadSuccess copyWith({
    List<Account>? accounts,
    Account? recentlyDeletedAccount,
    bool clearRecentlyDeleted = false,
  }) {
    return AccountsLoadSuccess(
      accounts: accounts ?? this.accounts,
      recentlyDeletedAccount: clearRecentlyDeleted
          ? null
          : recentlyDeletedAccount ?? this.recentlyDeletedAccount,
    );
  }
}

class AccountsLoadFailure extends AccountsState {}
