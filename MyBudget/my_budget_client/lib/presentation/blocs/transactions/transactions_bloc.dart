import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository _transactionRepository;

  TransactionsBloc({required TransactionRepository transactionRepository})
      : _transactionRepository = transactionRepository,
        super(TransactionsState()) {
    // UI events
    on<NonDateFiltersChanged>(_onNonDateFiltersChanged);
    on<DatePeriodNavigated>(_onDatePeriodNavigated);
    on<DateStepChanged>(_onDateStepChanged);
    on<FilterModeChanged>(_onFilterModeChanged);
    on<ActiveDateChanged>(_onActiveDateChanged);
    on<ActiveDateRangeChanged>(_onActiveDateRangeChanged);
    on<SortChanged>(_onSortChanged);

    // Data loading events
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

    // CUD events
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
  }

  // --- UI Event Handlers ---

  void _onNonDateFiltersChanged(
    NonDateFiltersChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(nonDateFilters: event.filters));
    add(const InnitialLoadTransactions());
  }

  void _onDatePeriodNavigated(
    DatePeriodNavigated event,
    Emitter<TransactionsState> emit,
  ) {
    if (state.filterMode == FilterMode.range) return;

    DateTime newDate;
    switch (state.dateStep) {
      case DateStep.day:
        newDate = state.activeDate.add(Duration(days: event.direction));
        break;
      case DateStep.month:
        newDate = DateTime(state.activeDate.year,
            state.activeDate.month + event.direction, state.activeDate.day);
        break;
      case DateStep.year:
        newDate = DateTime(state.activeDate.year + event.direction,
            state.activeDate.month, state.activeDate.day);
        break;
    }
    emit(state.copyWith(activeDate: newDate));
    add(const InnitialLoadTransactions());
  }

  void _onDateStepChanged(
    DateStepChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(dateStep: event.dateStep, filterMode: FilterMode.date));
    add(const InnitialLoadTransactions());
  }

  void _onFilterModeChanged(
    FilterModeChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(filterMode: event.filterMode));
    add(const InnitialLoadTransactions());
  }

  void _onActiveDateChanged(
    ActiveDateChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(activeDate: event.date, filterMode: FilterMode.date));
    add(const InnitialLoadTransactions());
  }

  void _onActiveDateRangeChanged(
    ActiveDateRangeChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(
        activeDateRange: () => event.dateRange, filterMode: FilterMode.range));
    add(const InnitialLoadTransactions());
  }

  void _onSortChanged(
    SortChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(sort: event.sort));
    add(const InnitialLoadTransactions());
  }

  // --- Data Loading Event Handlers ---

  Future<void> _onLoadTransactionsInital(
    InnitialLoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(state.copyWith(status: TransactionStatus.loading));
    try {
      final results = await Future.wait([
        _transactionRepository.getTransactionsWithFilters(
          limit: event.limit,
          offset: 0,
          filters: state.filters,
          sort: state.sort,
        ),
        _transactionRepository.getAllCount(), // Note: This count is not filtered
      ]);

      final transactions = results[0] as List<Transaction>;
      final totalCount = results[1] as int;

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: transactions,
          startIndex: 0,
          hasMoreUp: false,
          hasMoreDown: transactions.isNotEmpty,
          totalCount: totalCount,
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
      final offset =
          (state.startIndex - event.limit).clamp(0, double.infinity).toInt();
      final jumpToItemId = state.transactions.firstOrNull?.id;
      final newTransactions =
          await _transactionRepository.getTransactionsWithFilters(
        limit: event.limit,
        offset: offset,
        filters: state.filters,
        sort: state.sort,
      );

      if (newTransactions.isEmpty) {
        return emit(
            state.copyWith(status: TransactionStatus.success, hasMoreUp: false));
      }

      final updatedList = [...newTransactions, ...state.transactions];
      final newStartIndex = state.startIndex - newTransactions.length;
      double? jumpAlignment;

      if (updatedList.length > state.windowSize) {
        final removeCount = updatedList.length - state.windowSize;
        updatedList.removeRange(
            updatedList.length - removeCount, updatedList.length);
        jumpAlignment = 0.0; // 0.0 means align to top
      }

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: updatedList,
          startIndex: newStartIndex,
          hasMoreDown: true,
          hasMoreUp: newStartIndex > 0,
          jumpToItemId: jumpToItemId,
          jumpToAlignment: jumpAlignment,
        ),
      );

      emit(state.copyWith(jumpToItemId: null, jumpToAlignment: null));
    } catch (_) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onLoadTransactionsDown(
    LoadTransactionsDown event,
    Emitter<TransactionsState> emit,
  ) async {
    if (!state.hasMoreDown || state.status == TransactionStatus.loading) return;

    emit(state.copyWith(status: TransactionStatus.loading));

    try {
      final offset = state.startIndex + state.transactions.length;
      final jumpToItemId = state.transactions.lastOrNull?.id;
      final newTransactions =
          await _transactionRepository.getTransactionsWithFilters(
        limit: event.limit,
        offset: offset,
        filters: state.filters,
        sort: state.sort,
      );

      if (newTransactions.isEmpty) {
        return emit(state.copyWith(
            status: TransactionStatus.success, hasMoreDown: false));
      }

      final updatedList = [...state.transactions, ...newTransactions];
      var newStartIndex = state.startIndex;
      double? jumpAlignment;

      if (updatedList.length > state.windowSize) {
        final removeCount = updatedList.length - state.windowSize;
        updatedList.removeRange(0, removeCount);
        newStartIndex += removeCount;
        jumpAlignment = 1.0;
      }

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: updatedList,
          startIndex: newStartIndex,
          hasMoreUp: true,
          hasMoreDown: newTransactions.isNotEmpty,
          jumpToItemId: jumpToItemId,
          jumpToAlignment: jumpAlignment,
        ),
      );

      emit(state.copyWith(jumpToItemId: null, jumpToAlignment: null));
    } catch (_) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  // --- CUD Event Handlers ---

  Future<void> _onAddTransaction(
    AddTransaction event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      await _transactionRepository.addTransaction(event.transaction);
      add(const InnitialLoadTransactions());
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
      add(const InnitialLoadTransactions());
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
      add(const InnitialLoadTransactions());
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }
}