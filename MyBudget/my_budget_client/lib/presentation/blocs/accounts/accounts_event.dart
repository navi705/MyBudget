part of 'accounts_bloc.dart';

abstract class AccountsEvent extends Equatable {
  const AccountsEvent();

  @override
  List<Object> get props => [];
}

class LoadAccounts extends AccountsEvent {}

class LoadMoreAccounts extends AccountsEvent {}

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
  final String id;

  const DeleteAccount(this.id);

  @override
  List<Object> get props => [id];
}

class UndoDeleteAccount extends AccountsEvent {}

class SortAccounts extends AccountsEvent {
  final bool sortAscending;

  const SortAccounts(this.sortAscending);

  @override
  List<Object> get props => [sortAscending];
}

class FilterAccounts extends AccountsEvent {
  final String accountTypeId;

  const FilterAccounts(this.accountTypeId);

  @override
  List<Object> get props => [accountTypeId];
}

class LoadHistoricalBalances extends AccountsEvent {
  final DateTime date;

  const LoadHistoricalBalances(this.date);

  @override
  List<Object> get props => [date];
}

class ClearHistoricalBalances extends AccountsEvent {}

class ToggleSelectionMode extends AccountsEvent {
  final bool isSelectionModeActive;

  const ToggleSelectionMode(this.isSelectionModeActive);

  @override
  List<Object> get props => [isSelectionModeActive];
}

class ToggleAccountSelection extends AccountsEvent {
  final String accountId;

  const ToggleAccountSelection(this.accountId);

  @override
  List<Object> get props => [accountId];
}

class SelectAllAccounts extends AccountsEvent {}

class ClearSelection extends AccountsEvent {}

class DeleteMultipleAccounts extends AccountsEvent {
  final List<String> accountIds;

  const DeleteMultipleAccounts(this.accountIds);

  @override
  List<Object> get props => [accountIds];
}

class UpdateAccountTypeForMultipleAccounts extends AccountsEvent {
  final List<String> accountIds;
  final String accountTypeId;

  const UpdateAccountTypeForMultipleAccounts(this.accountIds, this.accountTypeId);

  @override
  List<Object> get props => [accountIds, accountTypeId];
}

class DatePeriodNavigated extends AccountsEvent {
  final int direction;

  const DatePeriodNavigated(this.direction);

  @override
  List<Object> get props => [direction];
}

class DateStepChanged extends AccountsEvent {
  final DateStep dateStep;

  const DateStepChanged(this.dateStep);

  @override
  List<Object> get props => [dateStep];
}

class ActiveDateChanged extends AccountsEvent {
  final DateTime date;

  const ActiveDateChanged(this.date);

  @override
  List<Object> get props => [date];
}
