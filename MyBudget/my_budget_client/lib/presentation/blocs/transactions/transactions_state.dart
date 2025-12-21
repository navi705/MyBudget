part of 'transactions_bloc.dart';

enum TransactionStatus { initial, loading, success, failure }

class TransactionsState extends Equatable {
  final TransactionStatus status;
  final List<Transaction> transactions;
  final int windowSize;
  final bool hasMoreUp;
  final bool hasMoreDown;
  final int startIndex;
  final String? jumpToItemId;
  final double? jumpToAlignment;
  final int totalCount;

  const TransactionsState({
    this.status = TransactionStatus.initial,
    this.transactions = const [],
    this.windowSize = 1000,
    this.hasMoreUp = false,
    this.hasMoreDown = true,
    this.startIndex = 0,
    this.jumpToItemId,
    this.jumpToAlignment,
    this.totalCount = 0,
  });

  TransactionsState copyWith({
    TransactionStatus? status,
    List<Transaction>? transactions,
    int? windowSize,
    bool? hasMoreUp,
    bool? hasMoreDown,
    int? startIndex,
    String? jumpToItemId,
    double? jumpToAlignment,
    int? totalCount,
  }) {
    return TransactionsState(
      status: status ?? this.status,
      transactions: transactions ?? this.transactions,
      windowSize: windowSize ?? this.windowSize,
      hasMoreUp: hasMoreUp ?? this.hasMoreUp,
      hasMoreDown: hasMoreDown ?? this.hasMoreDown,
      startIndex: startIndex ?? this.startIndex,
      jumpToItemId: jumpToItemId,
      jumpToAlignment: jumpToAlignment,
      totalCount: totalCount ?? this.totalCount,
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
        jumpToItemId,
        jumpToAlignment,
        totalCount,
      ];
}
