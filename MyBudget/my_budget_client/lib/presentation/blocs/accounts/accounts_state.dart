part of 'accounts_bloc.dart';

abstract class AccountsState extends Equatable {
  final List<Account> accounts;
  final List<AccountType> accountTypes;
  final Account? recentlyDeletedAccount;
  final bool hasReachedMax;

  const AccountsState({
    this.accounts = const [],
    this.accountTypes = const [],
    this.recentlyDeletedAccount,
    this.hasReachedMax = false,
  });

  @override
  List<Object?> get props => [
        accounts,
        accountTypes,
        recentlyDeletedAccount,
        hasReachedMax,
      ];
}

class AccountsInitial extends AccountsState {}

class AccountsLoadInProgress extends AccountsState {}

class AccountsLoadSuccess extends AccountsState {
  const AccountsLoadSuccess({
    super.accounts,
    super.accountTypes,
    super.recentlyDeletedAccount,
    super.hasReachedMax,
  });

  AccountsLoadSuccess copyWith({
    List<Account>? accounts,
    List<AccountType>? accountTypes,
    Account? recentlyDeletedAccount,
    bool? hasReachedMax,
    bool clearRecentlyDeleted = false,
  }) {
    return AccountsLoadSuccess(
      accounts: accounts ?? this.accounts,
      accountTypes: accountTypes ?? this.accountTypes,
      recentlyDeletedAccount: clearRecentlyDeleted
          ? null
          : recentlyDeletedAccount ?? this.recentlyDeletedAccount,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }
}

class AccountsLoadFailure extends AccountsState {}
