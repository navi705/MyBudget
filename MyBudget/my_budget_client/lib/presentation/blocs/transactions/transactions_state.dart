part of 'transactions_bloc.dart';

enum TransactionStatus { initial, loading, success, failure }

final class TransactionsState extends Equatable {
  const TransactionsState({
    this.page = 0,
    this.status = TransactionStatus.initial,
    this.transactions = const <Transaction>[],
    this.hasMoreUp = true,
    this.hasMoreDown = true,
    this.hasReachedMax = false,
  });

  final TransactionStatus status;
  final List<Transaction> transactions;
  final int page;
  final bool hasMoreUp;
  final bool hasMoreDown;
  final bool hasReachedMax;

  TransactionsState copyWith({
    int? page,
    TransactionStatus? status,
    List<Transaction>? transactions,
    bool? hasMoreUp,
    bool? hasMoreDown,
    bool? hasReachedMax,
  }) {
    return TransactionsState(
      page: page ?? this.page,
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      hasMoreUp: hasMoreUp ?? this.hasMoreUp,
      hasMoreDown: hasMoreDown ?? this.hasMoreDown,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object> get props => [status, transactions, hasMoreUp, hasMoreDown, hasReachedMax];
}

final class TransactionActionSuccess extends TransactionsState {}

final class TransactionActionFailure extends TransactionsState {
  final String message;

  const TransactionActionFailure(this.message);

  @override
  List<Object> get props => [message];
}
