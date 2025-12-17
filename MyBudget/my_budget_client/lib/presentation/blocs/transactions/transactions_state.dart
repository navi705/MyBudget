part of 'transactions_bloc.dart';

enum TransactionStatus { initial, loading, success, failure }

class TransactionsState extends Equatable {
  final TransactionStatus status;
  final List<Transaction> transactions;
  final int windowSize;
  final bool hasMoreUp;
  final bool hasMoreDown;
  final int startIndex;
  final int? jumpToIndex;
  final double? jumpToAlignment;

  const TransactionsState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.windowSize = 200,
    this.hasMoreUp = false,
    this.hasMoreDown = true,
    this.startIndex = 0,
    this.jumpToIndex,
    this.jumpToAlignment,
  });

  TransactionsState copyWith({
    TransactionStatus? status,
    List<Transaction>? transactions,
    int? windowSize,
    bool? hasMoreUp,
    bool? hasMoreDown,
    int? startIndex,
    int? jumpToIndex,
    double? jumpToAlignment,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      windowSize: windowSize ?? this.windowSize,
      hasMoreUp: hasMoreUp ?? this.hasMoreUp,
      hasMoreDown: hasMoreDown ?? this.hasMoreDown,
      startIndex: startIndex ?? this.startIndex,
      jumpToIndex: jumpToIndex,
      jumpToAlignment: jumpToAlignment,
    );
  }

  @override
  List<Object?> get props => [
        status,
        transactions,
        windowSize,
        hasMoreUp,
        hasMoreDown,
        startIndex,
        jumpToIndex,
        jumpToAlignment,
      ];
}
