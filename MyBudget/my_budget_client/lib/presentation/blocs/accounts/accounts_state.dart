part of 'accounts_bloc.dart';

abstract class AccountsState extends Equatable {
  final List<Account> accounts;
  final List<AccountType> accountTypes;
  final Account? recentlyDeletedAccount;

  const AccountsState({
    this.accounts = const [],
    this.accountTypes = const [],
    this.recentlyDeletedAccount,
  });

  @override
  List<Object?> get props => [
        accounts,
        accountTypes,
        recentlyDeletedAccount
      ];
}

class AccountsInitial extends AccountsState {}

class AccountsLoadInProgress extends AccountsState {}

class AccountsLoadSuccess extends AccountsState {
  const AccountsLoadSuccess({
    super.accounts,
    super.accountTypes,
    super.recentlyDeletedAccount,
  });

  AccountsLoadSuccess copyWith({
    List<Account>? accounts,
    List<AccountType>? accountTypes,
    Account? recentlyDeletedAccount,
    bool clearRecentlyDeleted = false,
  }) {
    return AccountsLoadSuccess(
      accounts: accounts ?? this.accounts,
      accountTypes: accountTypes ?? this.accountTypes,
      recentlyDeletedAccount: clearRecentlyDeleted
          ? null
          : recentlyDeletedAccount ?? this.recentlyDeletedAccount,
    );
  }
}

class AccountsLoadFailure extends AccountsState {}
