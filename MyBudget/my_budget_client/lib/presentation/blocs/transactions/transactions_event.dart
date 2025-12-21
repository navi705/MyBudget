part of 'transactions_bloc.dart';

abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object?> get props => [];
}

// Event for all other filters
class NonDateFiltersChanged extends TransactionsEvent {
  final TransactionFilters filters;

  const NonDateFiltersChanged(this.filters);

  @override
  List<Object> get props => [filters];
}

// Events for date and sort UI controls
class DatePeriodNavigated extends TransactionsEvent {
  final int direction; // -1 for previous, 1 for next
  const DatePeriodNavigated(this.direction);
  @override
  List<Object> get props => [direction];
}

class DateStepChanged extends TransactionsEvent {
  final DateStep dateStep;
  const DateStepChanged(this.dateStep);
  @override
  List<Object> get props => [dateStep];
}

class FilterModeChanged extends TransactionsEvent {
  final FilterMode filterMode;
  const FilterModeChanged(this.filterMode);
  @override
  List<Object> get props => [filterMode];
}

class ActiveDateChanged extends TransactionsEvent {
  final DateTime date;
  const ActiveDateChanged(this.date);
  @override
  List<Object> get props => [date];
}

class ActiveDateRangeChanged extends TransactionsEvent {
  final DateTimeRange dateRange;
  const ActiveDateRangeChanged(this.dateRange);
  @override
  List<Object> get props => [dateRange];
}

class SortChanged extends TransactionsEvent {
  final Sort sort;
  const SortChanged(this.sort);
  @override
  List<Object> get props => [sort];
}


// --- Data Loading Events ---

class InnitialLoadTransactions extends TransactionsEvent {
  final int limit;

  const InnitialLoadTransactions({this.limit = 50});

  @override
  List<Object> get props => [limit];
}

class LoadTransactionsUp extends TransactionsEvent {
  final int limit;

  const LoadTransactionsUp({this.limit = 50});

  @override
  List<Object> get props => [limit];
}

class LoadTransactionsDown extends TransactionsEvent {
  final int limit;

  const LoadTransactionsDown({this.limit = 50});

  @override
  List<Object> get props => [limit];
}

// --- CUD Events ---

class AddTransaction extends TransactionsEvent {
  final Transaction transaction;

  const AddTransaction(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class UpdateTransaction extends TransactionsEvent {
  final Transaction transaction;

  const UpdateTransaction(this.transaction);

  @override
  List<Object> get props => [transaction];
}

class DeleteTransaction extends TransactionsEvent {
  final String id;

  const DeleteTransaction(this.id);

  @override
  List<Object> get props => [id];
}
