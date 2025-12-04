part of 'transactions_bloc.dart';

abstract class TransactionsState extends Equatable {
  const TransactionsState();

  @override
  List<Object> get props => [];
}

class TransactionsInitial extends TransactionsState {}

class TransactionsLoadInProgress extends TransactionsState {}

class TransactionsLoadSuccess extends TransactionsState {
  final List<Transaction> transactions;
  final bool hasReachedMax;

  const TransactionsLoadSuccess({
    this.transactions = const [],
    this.hasReachedMax = false,
  });

  TransactionsLoadSuccess copyWith({
    List<Transaction>? transactions,
    bool? hasReachedMax,
  }) {
    return TransactionsLoadSuccess(
      transactions: transactions ?? this.transactions,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [transactions, hasReachedMax];
}

class TransactionsLoadFailure extends TransactionsState {}
