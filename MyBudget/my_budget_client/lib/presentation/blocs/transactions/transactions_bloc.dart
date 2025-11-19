import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository _transactionRepository;
  StreamSubscription? _transactionsSubscription;

  TransactionsBloc({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(TransactionsInitial()) {
    on<LoadTransactions>(_onLoadTransactions);
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<_TransactionsUpdated>(_onTransactionsUpdated);
  }

  void _onLoadTransactions(
    LoadTransactions event,
    Emitter<TransactionsState> emit,
  ) {
    emit(TransactionsLoadInProgress());
    _transactionsSubscription?.cancel();
    _transactionsSubscription = _transactionRepository.watchTransactions().listen(
          (transactions) => add(_TransactionsUpdated(transactions)),
          onError: (_) => emit(TransactionsLoadFailure()),
        );
  }

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    await _transactionRepository.addTransaction(event.transaction);
  }

  Future<void> _onUpdateTransaction(
    UpdateTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    await _transactionRepository.updateTransaction(event.transaction);
  }

  Future<void> _onDeleteTransaction(
    DeleteTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    await _transactionRepository.deleteTransaction(event.id);
  }

  void _onTransactionsUpdated(
    _TransactionsUpdated event,
    Emitter<TransactionsState> emit,
  ) {
    emit(TransactionsLoadSuccess(event.transactions));
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }
}
