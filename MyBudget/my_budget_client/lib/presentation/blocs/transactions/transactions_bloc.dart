import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository _transactionRepository;

  TransactionsBloc({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<LoadMoreTransactions>(_onLoadMoreTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  Future<void> _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(TransactionsLoadInProgress());
    try {
      final transactions =
          await _transactionRepository.getTransactionsPaginated(limit: 50, offset: 0);
      emit(TransactionsLoadSuccess(
        transactions: transactions,
        hasReachedMax: transactions.length < 50,
      ));
    } catch (_) {
      emit(TransactionsLoadFailure());
    }
  }

  Future<void> _onLoadMoreTransactions(
    LoadMoreTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    if (state is! TransactionsLoadSuccess) return;
    final currentState = state as TransactionsLoadSuccess;
    if (currentState.hasReachedMax) return;

    try {
      final transactions = await _transactionRepository.getTransactionsPaginated(
        offset: currentState.transactions.length,
        limit: 50,
      );
      if (transactions.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true));
      } else {
        emit(
          currentState.copyWith(
            transactions: List.of(currentState.transactions)..addAll(transactions),
            hasReachedMax: transactions.length < 50,
          ),
        );
      }
    } catch (_) {
      // In case of error, just keep the current state.
      // Optionally, you could emit a state to show a "retry" button.
    }
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    await _transactionRepository.addTransaction(event.transaction);
    add(LoadTransactions()); // Reload the list
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    await _transactionRepository.updateTransaction(event.transaction);
    add(LoadTransactions()); // Reload the list
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    await _transactionRepository.deleteTransaction(event.id);
    add(LoadTransactions()); // Reload the list
  }
}
