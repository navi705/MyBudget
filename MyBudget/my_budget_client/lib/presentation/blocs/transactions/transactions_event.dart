part of 'transactions_bloc.dart';

abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object> get props => [];
}

class LoadTransactions extends TransactionsEvent {}

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
  final int id;

  const DeleteTransaction(this.id);

  @override
  List<Object> get props => [id];
}

class _TransactionsUpdated extends TransactionsEvent {
  final List<Transaction> transactions;

  const _TransactionsUpdated(this.transactions);

  @override
  List<Object> get props => [transactions];
}
