import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:stream_transform/stream_transform.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

const throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> throttleDroppable<E>(Duration duration) {
  return (events, mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository _transactionRepository;

  TransactionsBloc({required TransactionRepository transactionRepository})
    : _transactionRepository = transactionRepository,
      super(TransactionsState()) {

    on<InnitialLoadTransactions>(_onLoadTransactionsInital,  
    transformer: throttleDroppable(throttleDuration)
    );

    on<LoadTransactionsUp>(
      _onLoadTransactionsUp,
      transformer: throttleDroppable(throttleDuration),
    );

    on<LoadTransactionsDown>(_onLoadTransactionsDown,  
    transformer: throttleDroppable(throttleDuration)
    );

    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactionsInital(
    InnitialLoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      final transactions = await _transactionRepository
          .getTransactionsPaginated(limit: event.limit, offset: state.page * event.limit);

      if (transactions.isEmpty) {
        return emit(state.copyWith(hasReachedMax: true));
      }

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: transactions,
          page: state.page + 1,
        ),

      );
    } catch (_) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onLoadTransactionsUp(
    LoadTransactionsUp event,
    Emitter<TransactionsState> emit,
  ) async {
    if (state.hasReachedMax) return;
    try {
      final transactions = await _transactionRepository
          .getTransactionsPaginated(limit: event.limit, offset: state.page * event.limit);

      if (transactions.isEmpty) {
        return emit(state.copyWith(hasReachedMax: true));
      }

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: [...transactions, ...state.transactions],
          page: state.page - 1,
           hasMoreUp: transactions.isNotEmpty,
        ),

      );
    } catch (_) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onLoadTransactionsDown(
    LoadTransactionsDown event,
    Emitter<TransactionsState> emit,
  ) async {
    if (state.hasReachedMax) return;
    try {
      final transactions = await _transactionRepository
          .getTransactionsPaginated(limit: event.limit, offset: state.page * event.limit);

      if (transactions.isEmpty) {
        return emit(state.copyWith(hasReachedMax: true));
      }

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: [...state.transactions, ...transactions],
          page: state.page + 1,
          hasMoreDown: transactions.isNotEmpty,
        ),

      );
    } catch (_) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      await _transactionRepository.addTransaction(event.transaction);
      emit(TransactionActionSuccess());
    } catch (e) {
      emit(TransactionActionFailure(e.toString()));
    }
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      await _transactionRepository.updateTransaction(event.transaction);
      emit(TransactionActionSuccess());
    } catch (e) {
      emit(TransactionActionFailure(e.toString()));
    }
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      await _transactionRepository.deleteTransaction(event.id);
      emit(TransactionActionSuccess());
    } catch (e) {
      emit(TransactionActionFailure(e.toString()));
    }
  }
}

// 1️⃣ Добавляем параметры окна

// В TransactionsState:

// final int windowSize; // максимальное число элементов в памяти
// final int startIndex; // индекс первого элемента в окне


// windowSize = например 50

// startIndex = индекс в общем списке (для якоря)

// 2️⃣ При подгрузке вверх (LoadTransactionsUp)

// Загружаем новые элементы сверху

// Склеиваем с текущими

// Если длина > windowSize, отрезаем элементы снизу

// final newTransactions = await _transactionRepository.getTransactionsPaginated(
//     limit: event.limit,
//     offset: state.pageUp * event.limit,
// );

// // Склеиваем сверху
// final updated = [...newTransactions, ...state.transactions];

// // Отрезаем снизу
// final trimmed = updated.length > state.windowSize
//     ? updated.sublist(0, state.windowSize)
//     : updated;

// // Новый startIndex = старый + кол-во отрезанных снизу
// final removedCount = updated.length - trimmed.length;
// final newStartIndex = state.startIndex + removedCount;

// emit(state.copyWith(
//   transactions: trimmed,
//   pageUp: state.pageUp - 1,
//   startIndex: newStartIndex,
//   hasMoreUp: newTransactions.isNotEmpty,
// ));

// 3️⃣ При подгрузке вниз (LoadTransactionsDown)

// Загружаем новые элементы снизу

// Склеиваем с текущими

// Если длина > windowSize, отрезаем элементы сверху

// final newTransactions = await _transactionRepository.getTransactionsPaginated(
//     limit: event.limit,
//     offset: state.pageDown * event.limit,
// );

// final updated = [...state.transactions, ...newTransactions];

// final trimmed = updated.length > state.windowSize
//     ? updated.sublist(updated.length - state.windowSize)
//     : updated;

// // Коррекция startIndex
// final removedCount = updated.length - trimmed.length;
// final newStartIndex = state.startIndex + removedCount;

// emit(state.copyWith(
//   transactions: trimmed,
//   pageDown: state.pageDown + 1,
//   startIndex: newStartIndex,
//   hasMoreDown: newTransactions.isNotEmpty,
// ));

// 4️⃣ В UI: компенсируем scroll

// При удалении элементов с одной стороны надо якориться на видимом элементе:

// final firstVisible = itemPositionsListener.itemPositions.value
//     .where((p) => p.itemLeadingEdge >= 0)
//     .reduce((a, b) => a.itemLeadingEdge < b.itemLeadingEdge ? a : b);

// WidgetsBinding.instance.addPostFrameCallback((_) {
//   itemScrollController.jumpTo(
//     index: firstVisible.index + removedCount,
//     alignment: firstVisible.itemLeadingEdge,
//   );
// });


// removedCount = сколько элементов удалили с противоположной стороны

// Так scroll не дергается

// 5️⃣ Итог

// В памяти держится только windowSize элементов

// Подгрузка вверх/вниз + удаление старых элементов

// Scroll остаётся стабильным

// Любая высота элементов работает (ScrollPositionIndexedList берёт индексы, а не пиксели)