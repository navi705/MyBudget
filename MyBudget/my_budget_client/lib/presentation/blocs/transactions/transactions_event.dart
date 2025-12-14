part of 'transactions_bloc.dart';

abstract class TransactionsEvent extends Equatable {
  const TransactionsEvent();

  @override
  List<Object> get props => [];
} 

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
