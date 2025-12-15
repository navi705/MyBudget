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

EventTransformer<E> throttleSequential<E>(Duration duration) {
  return (events, mapper) {
    return events.throttle(duration).asyncExpand(mapper);
  };
}

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository _transactionRepository;

  TransactionsBloc({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(const TransactionsState()) {
    on<InnitialLoadTransactions>(_onLoadTransactionsInital,
        transformer: droppable());

    on<LoadTransactionsUp>(
      _onLoadTransactionsUp,
      transformer: throttleSequential(throttleDuration),
    );

    on<LoadTransactionsDown>(_onLoadTransactionsDown,
        transformer: throttleSequential(throttleDuration),
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
      final transactions = await _transactionRepository.getTransactionsPaginated(
          limit: event.limit, offset: 0);

      emit(
        const TransactionsState().copyWith(
          status: TransactionStatus.success,
          downList: transactions,
          upList: [],
          initialOffset: 0,
          hasMoreUp: false,
          hasMoreDown: transactions.isNotEmpty,
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
    if (!state.hasMoreUp) return;

    try {
      final offset =
          (state.initialOffset - state.upList.length - event.limit)
              .clamp(0, double.infinity)
              .toInt();
      final newTransactions = await _transactionRepository
          .getTransactionsPaginated(limit: event.limit, offset: offset);

      if (newTransactions.isEmpty) {
        return emit(state.copyWith(hasMoreUp: false));
      }

      var newUpList = [...newTransactions.reversed, ...state.upList];
      var newDownList = state.downList;

      final totalLength = newUpList.length + newDownList.length;
      if (totalLength > state.windowSize) {
        final removedCount = totalLength - state.windowSize;
        if (newDownList.length > removedCount) {
          newDownList = newDownList.sublist(0, newDownList.length - removedCount);
        } else {
          newDownList = [];
        }
      }

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          upList: newUpList,
          downList: newDownList,
          hasMoreUp: newTransactions.length == event.limit && (offset > 0),
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
    if (!state.hasMoreDown) return;
    try {
      final offset = state.initialOffset + state.downList.length;
      final newTransactions = await _transactionRepository
          .getTransactionsPaginated(limit: event.limit, offset: offset);

      if (newTransactions.isEmpty) {
        return emit(state.copyWith(hasMoreDown: false));
      }
      
      var newDownList = [...state.downList, ...newTransactions];
      var newUpList = state.upList;
      
      final totalLength = newDownList.length + newUpList.length;
      if (totalLength > state.windowSize) {
        final removedCount = totalLength - state.windowSize;
        if (newUpList.length > removedCount) {
          newUpList = newUpList.sublist(removedCount);
        } else {
          newUpList = [];
        }
      }

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          downList: newDownList,
          upList: newUpList,
          hasMoreDown: newTransactions.isNotEmpty,
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
      add(InnitialLoadTransactions());
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
      add(InnitialLoadTransactions());
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
      add(InnitialLoadTransactions());
    } catch (e) {
      emit(TransactionActionFailure(e.toString()));
    }
  }
}