part of 'transactions_bloc.dart';

enum TransactionStatus { initial, loading, success, failure }

final class TransactionsState extends Equatable {
  const TransactionsState({
    this.status = TransactionStatus.initial,
    this.transactions = const <Transaction>[],
    this.hasMoreUp = true,
    this.hasMoreDown = true,
    this.startIndex = 0,
    this.windowSize = 200,
  });

  final TransactionStatus status;
  final List<Transaction> transactions;
  final bool hasMoreUp;
  final bool hasMoreDown;
  final int startIndex;
  final int windowSize;

  TransactionsState copyWith({
    TransactionStatus? status,
    List<Transaction>? transactions,
    bool? hasMoreUp,
    bool? hasMoreDown,
    int? startIndex,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      hasMoreUp: hasMoreUp ?? this.hasMoreUp,
      hasMoreDown: hasMoreDown ?? this.hasMoreDown,
      startIndex: startIndex ?? this.startIndex,
      windowSize: windowSize,
    );
  }

  @override
  List<Object> get props => [
        status,
        transactions,
        hasMoreUp,
        hasMoreDown,
        startIndex,
        windowSize,
      ];
}

final class TransactionActionSuccess extends TransactionsState {}

final class TransactionActionFailure extends TransactionsState {
  final String message;

  const TransactionActionFailure(this.message);

  @override
  List<Object> get props => [message];
}
