part of 'transactions_bloc.dart';

abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

/// Marks the events that write to the transactions table.
///
/// The bloc reloads itself when the table changes, and its own writes reach
/// that watcher too — this is what lets it tell them apart and skip the second
/// load its own handler has already done.
mixin TransactionWrite on TransactionsEvent {}

class LoadTransactions extends TransactionsEvent {
  const LoadTransactions();
}

class InitialLoadTransactions extends TransactionsEvent {
  final int limit;
  final String? mainCurrencyCode;

  const InitialLoadTransactions({this.limit = 50, this.mainCurrencyCode});

  @override
  List<Object?> get props => [limit, mainCurrencyCode];
}

class LoadTransactionsUp extends TransactionsEvent {
  final int limit;

  const LoadTransactionsUp({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

class LoadTransactionsDown extends TransactionsEvent {
  final int limit;

  const LoadTransactionsDown({this.limit = 20});

  @override
  List<Object?> get props => [limit];
}

class SearchTransaction extends TransactionsEvent {
  final String query;

  const SearchTransaction(this.query);

  @override
  List<Object?> get props => [query];
}

class NonDateFiltersChanged extends TransactionsEvent {
  final TransactionFilters filters;

  const NonDateFiltersChanged(this.filters);

  @override
  List<Object?> get props => [filters];
}

class DatePeriodNavigated extends TransactionsEvent {
  final int direction;

  const DatePeriodNavigated(this.direction);

  @override
  List<Object?> get props => [direction];
}

class DateStepChanged extends TransactionsEvent {
  final DateStep dateStep;

  const DateStepChanged(this.dateStep);

  @override
  List<Object?> get props => [dateStep];
}

class SortChanged extends TransactionsEvent {
  final Sort sort;

  const SortChanged(this.sort);

  @override
  List<Object?> get props => [sort];
}

class FilterModeChanged extends TransactionsEvent {
  final FilterMode filterMode;

  const FilterModeChanged(this.filterMode);

  @override
  List<Object?> get props => [filterMode];
}

class ActiveDateChanged extends TransactionsEvent {
  final DateTime date;

  const ActiveDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class ActiveDateRangeChanged extends TransactionsEvent {
  final DateTimeRange dateRange;

  const ActiveDateRangeChanged(this.dateRange);

  @override
  List<Object?> get props => [dateRange];
}

class AddTransaction extends TransactionsEvent with TransactionWrite {
  final Transaction transaction;

  const AddTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class UpdateTransaction extends TransactionsEvent with TransactionWrite {
  final Transaction transaction;

  const UpdateTransaction(this.transaction);

  @override
  List<Object?> get props => [transaction];
}

class DeleteTransaction extends TransactionsEvent with TransactionWrite {
  final String id;

  const DeleteTransaction(this.id);

  @override
  List<Object?> get props => [id];
}

class ToggleSelectionMode extends TransactionsEvent {
  final bool isSelectionModeActive;

  const ToggleSelectionMode(this.isSelectionModeActive);

  @override
  List<Object?> get props => [isSelectionModeActive];
}

class ToggleTransactionSelection extends TransactionsEvent {
  final String transactionId;

  const ToggleTransactionSelection(this.transactionId);

  @override
  List<Object?> get props => [transactionId];
}

class SelectAllTransactions extends TransactionsEvent {
  const SelectAllTransactions();
}

class ClearSelection extends TransactionsEvent {
  const ClearSelection();
}

class DeleteMultipleTransactions extends TransactionsEvent with TransactionWrite {
  final List<String> ids;

  const DeleteMultipleTransactions(this.ids);

  @override
  List<Object?> get props => [ids];
}

class UpdateDateForMultipleTransactions extends TransactionsEvent with TransactionWrite {
  final List<String> ids;
  final DateTime newDate;

  const UpdateDateForMultipleTransactions(this.ids, this.newDate);

  @override
  List<Object?> get props => [ids, newDate];
}

class UpdateCategoryForMultipleTransactions extends TransactionsEvent with TransactionWrite {
  final List<String> ids;
  final String newCategoryId;

  const UpdateCategoryForMultipleTransactions(this.ids, this.newCategoryId);

  @override
  List<Object?> get props => [ids, newCategoryId];
}

class ApplyAdvancedFilter extends TransactionsEvent {
  final TransactionFilters filters;

  const ApplyAdvancedFilter(this.filters);

  @override
  List<Object?> get props => [filters];
}

class ClearAdvancedFilter extends TransactionsEvent {
  const ClearAdvancedFilter();
}

class TransactionTypeFilterChanged extends TransactionsEvent {
  final TransactionTypeFilter transactionType;

  const TransactionTypeFilterChanged(this.transactionType);

  @override
  List<Object?> get props => [transactionType];
}

class UndoDeleteTransactions extends TransactionsEvent with TransactionWrite {
  const UndoDeleteTransactions();
}

class ClearRecentlyDeletedTransactions extends TransactionsEvent {
  const ClearRecentlyDeletedTransactions();
}
