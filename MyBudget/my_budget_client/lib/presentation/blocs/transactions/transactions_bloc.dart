import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository _transactionRepository;

  TransactionsBloc({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(const TransactionsState()) {
    on<InnitialLoadTransactions>(_onLoadTransactionsInital,
        transformer: droppable());

    on<LoadTransactionsUp>(
      _onLoadTransactionsUp,
      transformer: droppable(),
    );

    on<LoadTransactionsDown>(
      _onLoadTransactionsDown,
      transformer: droppable(),
    );

    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactionsInital(
    InnitialLoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(const TransactionsState(status: TransactionStatus.loading));
    try {
      final transactions = await _transactionRepository.getTransactionsPaginated(
          limit: event.limit, offset: 0);

      emit(
        const TransactionsState().copyWith(
          status: TransactionStatus.success,
          transactions: transactions,
          startIndex: 0,
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
    if (!state.hasMoreUp || state.status == TransactionStatus.loading) return;

    emit(state.copyWith(status: TransactionStatus.loading));

    try {
      final offset = (state.startIndex - event.limit).clamp(0, double.infinity).toInt();
      final newTransactions = await _transactionRepository
          .getTransactionsPaginated(limit: event.limit, offset: offset);

      if (newTransactions.isEmpty) {
        return emit(state.copyWith(
          status: TransactionStatus.success, 
          hasMoreUp: false
        ));
      }

      final updatedList = [...newTransactions, ...state.transactions];
      final newStartIndex = state.startIndex - newTransactions.length;
      int? targetJumpIndex;
      double? jumpAlignment;

      if (updatedList.length > state.windowSize) {
        final removeCount = updatedList.length - state.windowSize;
        updatedList.removeRange(updatedList.length - removeCount, updatedList.length);
        
        // When loading up, we want to keep the old top item in view.
        // The old top item is now at index `newTransactions.length`.
        targetJumpIndex = newTransactions.length;
        jumpAlignment = 0.0; // 0.0 means align to top
      }

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: updatedList,
          startIndex: newStartIndex,
          hasMoreDown: true,
          hasMoreUp: newStartIndex > 0,
          jumpToIndex: targetJumpIndex,
          jumpToAlignment: jumpAlignment,
        ),
      );
      
      emit(state.copyWith(jumpToIndex: null, jumpToAlignment: null));
    } catch (_) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onLoadTransactionsDown(
    LoadTransactionsDown event,
    Emitter<TransactionsState> emit,
  ) async {
    // 1. Prevent double calls
    if (!state.hasMoreDown || state.status == TransactionStatus.loading) return;

    // OPTIONAL: Don't emit loading if you want smooth infinite scroll.
    // If you must emit loading, ensure your UI doesn't destroy the list.
    emit(state.copyWith(status: TransactionStatus.loading));

    try {
      final offset = state.startIndex + state.transactions.length;
      final newTransactions = await _transactionRepository
          .getTransactionsPaginated(limit: event.limit, offset: offset);

      if (newTransactions.isEmpty) {
        return emit(state.copyWith(
            status: TransactionStatus.success, hasMoreDown: false));
      }

      final updatedList = [...state.transactions, ...newTransactions];
      var newStartIndex = state.startIndex;
      int? targetJumpIndex; // We will calculate this
      double? jumpAlignment;

      // 2. Sliding Window Logic
      if (updatedList.length > state.windowSize) {
        final removeCount = updatedList.length - state.windowSize;

        // Remove from TOP
        updatedList.removeRange(0, removeCount);
        newStartIndex += removeCount;

        // 3. CALCULATE JUMP
        // Let's aim to keep the user looking at the item that WAS at the bottom
        // before we added new stuff.
        targetJumpIndex = (state.transactions.length - removeCount) - 1;
        if (targetJumpIndex < 0) targetJumpIndex = 0;
        jumpAlignment = 1.0; // 1.0 means align to bottom
      }

      // 4. Emit Data AND Jump Index together
      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: updatedList,
          startIndex: newStartIndex,
          hasMoreUp: true, // We removed items from top, so we can go up now
          hasMoreDown: newTransactions.isNotEmpty,
          jumpToIndex: targetJumpIndex, // <--- Send the command
          jumpToAlignment: jumpAlignment,
        ),
      );

      // 5. Clear the jump command immediately so it doesn't happen again
      emit(state.copyWith(jumpToIndex: null, jumpToAlignment: null));
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
      emit(state.copyWith(status: TransactionStatus.failure));
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
      emit(state.copyWith(status: TransactionStatus.failure));
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
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }
}