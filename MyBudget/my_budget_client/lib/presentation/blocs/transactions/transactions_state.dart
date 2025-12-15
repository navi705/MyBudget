part of 'transactions_bloc.dart';

enum TransactionStatus { initial, loading, success, failure }

final class TransactionsState extends Equatable {
  const TransactionsState({
    this.status = TransactionStatus.initial,
    this.upList = const <Transaction>[],
    this.downList = const <Transaction>[],
    this.hasMoreUp = true,
    this.hasMoreDown = true,
    this.windowSize = 100,
    this.initialOffset = 0,
  });

  final TransactionStatus status;
  final List<Transaction> upList;
  final List<Transaction> downList;
  final bool hasMoreUp;
  final bool hasMoreDown;
  final int windowSize;
  final int initialOffset;

  TransactionsState copyWith({
    TransactionStatus? status,
    List<Transaction>? upList,
    List<Transaction>? downList,
    bool? hasMoreUp,
    bool? hasMoreDown,
    int? initialOffset,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      upList: upList ?? this.upList,
      downList: downList ?? this.downList,
      hasMoreUp: hasMoreUp ?? this.hasMoreUp,
      hasMoreDown: hasMoreDown ?? this.hasMoreDown,
      windowSize: windowSize,
      initialOffset: initialOffset ?? this.initialOffset,
    );
  }

  @override
  List<Object> get props => [
        status,
        upList,
        downList,
        hasMoreUp,
        hasMoreDown,
        windowSize,
        initialOffset,
      ];
}

final class TransactionActionSuccess extends TransactionsState {}

final class TransactionActionFailure extends TransactionsState {
  final String message;

  const TransactionActionFailure(this.message);

  @override
  List<Object> get props => [message];
}
