import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/entities/transaction_type_filter.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/entities/transaction_category.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/category.dart';

part 'transactions_event.dart';
part 'transactions_state.dart';

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  final TransactionRepository _transactionRepository;
  final StyleRepository _styleRepository;
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;
  final CurrencyRepository _currencyRepository;

  TransactionsBloc({
    required TransactionRepository transactionRepository,
    required StyleRepository styleRepository,
    required CategoryRepository categoryRepository,
    required SettingsRepository settingsRepository,
    required CurrencyRepository currencyRepository,
  })  : _transactionRepository = transactionRepository,
        _styleRepository = styleRepository,
        _categoryRepository = categoryRepository,
        _settingsRepository = settingsRepository,
        _currencyRepository = currencyRepository,
        super(TransactionsState()) {
    on<NonDateFiltersChanged>(_onNonDateFiltersChanged);
    on<DatePeriodNavigated>(_onDatePeriodNavigated);
    on<DateStepChanged>(_onDateStepChanged);
    on<FilterModeChanged>(_onFilterModeChanged);
    on<ActiveDateChanged>(_onActiveDateChanged);
    on<ActiveDateRangeChanged>(_onActiveDateRangeChanged);
    on<SortChanged>(_onSortChanged);
    on<TransactionTypeFilterChanged>(_onTransactionTypeFilterChanged);
    on<InitialLoadTransactions>(
      _onLoadTransactionsInitial,
      transformer: droppable(),
    );
    on<LoadTransactionsUp>(_onLoadTransactionsUp, transformer: droppable());
    on<LoadTransactionsDown>(_onLoadTransactionsDown, transformer: droppable());
    on<AddTransaction>(_onAddTransaction);
    on<UpdateTransaction>(_onUpdateTransaction);
    on<DeleteTransaction>(_onDeleteTransaction);
    on<DeleteMultipleTransactions>(_onDeleteMultipleTransactions);
    on<UpdateDateForMultipleTransactions>(_onUpdateDateForMultipleTransactions);
    on<UpdateCategoryForMultipleTransactions>(
        _onUpdateCategoryForMultipleTransactions);
    on<ToggleSelectionMode>(_onToggleSelectionMode);
    on<ToggleTransactionSelection>(_onToggleTransactionSelection);
    on<SelectAllTransactions>(_onSelectAllTransactions);
    on<ClearSelection>(_onClearSelection);
  }


  Future<Map<DateTime, double>> _calculateDailyTotals(
      List<Transaction> transactions, String mainCurrencyCode) async {
    final Map<DateTime, double> dailyTotals = {};
    if (transactions.isEmpty) {
      return dailyTotals;
    }

    final uniqueDates = transactions
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet();

    final ratesByDateFutures = uniqueDates.map((date) async {
      final rates = await _currencyRepository.getLatestExchangeRates(date);
      return MapEntry(date, rates);
    });

    final ratesByDateEntries = await Future.wait(ratesByDateFutures);
    final ratesByDate = Map.fromEntries(ratesByDateEntries);

    final groupedTransactions = groupBy(transactions,
        (Transaction t) => DateTime(t.date.year, t.date.month, t.date.day));

    const baseCurrency = 'EUR';
    for (var date in groupedTransactions.keys) {
      double totalForDay = 0;
      final transactionsForDay = groupedTransactions[date]!;
      final ratesForDay = ratesByDate[date] ?? [];

      for (final transaction in transactionsForDay) {
        // Amount in base currency (EUR)
        double amountInBase;
        if (transaction.currencyCode == baseCurrency) {
          amountInBase = transaction.amount;
        } else {
          // Find rate from transaction currency TO base currency
          final toBaseRate = ratesForDay
              .firstWhereOrNull((r) =>
                  r.fromCurrencyCode == transaction.currencyCode &&
                  r.toCurrencyCode == baseCurrency)
              ?.rate;

          if (toBaseRate != null) {
            amountInBase = transaction.amount * toBaseRate;
          } else {
            // Try reverse: from base currency TO transaction currency
            final fromBaseRate = ratesForDay
                .firstWhereOrNull((r) =>
                    r.fromCurrencyCode == baseCurrency &&
                    r.toCurrencyCode == transaction.currencyCode)
                ?.rate;

            if (fromBaseRate != null && fromBaseRate != 0) {
              amountInBase = transaction.amount / fromBaseRate;
            } else {
              amountInBase = 0; // Fallback to 0 if no rate found
            }
          }
        }

        // Amount in main currency
        double amountInMain;
        if (mainCurrencyCode == baseCurrency) {
          amountInMain = amountInBase;
        } else {
          // Find rate from base currency TO main currency
          final fromBaseRate = ratesForDay
              .firstWhereOrNull((r) =>
                  r.fromCurrencyCode == baseCurrency &&
                  r.toCurrencyCode == mainCurrencyCode)
              ?.rate;

          if (fromBaseRate != null) {
            amountInMain = amountInBase * fromBaseRate;
          } else {
            // Try reverse: from main currency to base
            final toBaseRate = ratesForDay
                .firstWhereOrNull((r) =>
                    r.fromCurrencyCode == mainCurrencyCode &&
                    r.toCurrencyCode == baseCurrency)
                ?.rate;
            if (toBaseRate != null && toBaseRate != 0) {
              amountInMain = amountInBase / toBaseRate;
            } else {
              amountInMain = amountInBase; // Fallback to amount in base
            }
          }
        }
        totalForDay += amountInMain;
      }
      dailyTotals[date] = totalForDay;
    }
    return dailyTotals;
  }

  void _onTransactionTypeFilterChanged(
    TransactionTypeFilterChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(
        nonDateFilters: state.nonDateFilters
            .copyWith(transactionType: event.transactionType)));
    add(const InitialLoadTransactions());
  }

  void _onNonDateFiltersChanged(
    NonDateFiltersChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(nonDateFilters: event.filters));
    add(const InitialLoadTransactions());
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
        newDate = DateTime(
          state.activeDate.year,
          state.activeDate.month + event.direction,
          state.activeDate.day,
        );
        break;
      case DateStep.year:
        newDate = DateTime(
          state.activeDate.year + event.direction,
          state.activeDate.month,
          state.activeDate.day,
        );
        break;
    }
    emit(state.copyWith(activeDate: newDate));
    add(const InitialLoadTransactions());
  }

  void _onDateStepChanged(
    DateStepChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(dateStep: event.dateStep, filterMode: FilterMode.date));
    add(const InitialLoadTransactions());
  }

  void _onFilterModeChanged(
    FilterModeChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(filterMode: event.filterMode));
    add(const InitialLoadTransactions());
  }

  void _onActiveDateChanged(
    ActiveDateChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(activeDate: event.date, filterMode: FilterMode.date));
    add(const InitialLoadTransactions());
  }

  void _onActiveDateRangeChanged(
    ActiveDateRangeChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(
      state.copyWith(
        activeDateRange: () => event.dateRange,
        filterMode: FilterMode.range,
      ),
    );
    add(const InitialLoadTransactions());
  }

  void _onSortChanged(SortChanged event, Emitter<TransactionsState> emit) {
    emit(state.copyWith(sort: event.sort));
    add(const InitialLoadTransactions());
  }

  void _onToggleSelectionMode(
    ToggleSelectionMode event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(
      isSelectionModeActive: event.isSelectionModeActive,
      selectedTransactionIds:
          event.isSelectionModeActive ? state.selectedTransactionIds : {},
    ));
  }

  void _onToggleTransactionSelection(
    ToggleTransactionSelection event,
    Emitter<TransactionsState> emit,
  ) {
    final newSelectedIds = Set<String>.from(state.selectedTransactionIds);
    if (newSelectedIds.contains(event.transactionId)) {
      newSelectedIds.remove(event.transactionId);
    } else {
      newSelectedIds.add(event.transactionId);
    }
    emit(state.copyWith(selectedTransactionIds: newSelectedIds));
  }

  void _onSelectAllTransactions(
    SelectAllTransactions event,
    Emitter<TransactionsState> emit,
  ) {
    final allIds = state.transactions.map((t) => t.transaction.id!).toSet();
    emit(state.copyWith(selectedTransactionIds: allIds));
  }

  void _onClearSelection(
    ClearSelection event,
    Emitter<TransactionsState> emit,
  ) {
    emit(state.copyWith(selectedTransactionIds: {}));
  }

  Future<void> _onLoadTransactionsInitial(
    InitialLoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    emit(state.copyWith(status: TransactionStatus.loading));
    try {
      final mainCurrencySetting = await _settingsRepository.getSetting('main_currency_code');
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';

      final results = await Future.wait([
        _transactionRepository.getTransactionsWithFilters(
          limit: event.limit,
          offset: 0,
          filters: state.filters,
          sort: state.sort,
        ),
        _transactionRepository.getCountWithFilters(
          filters: state.filters,
        ),
        _currencyRepository.getAllCurrencyDesignations(),
      ]);

      final rawTransactions = results[0] as List<Transaction>;
      final totalCount = results[1] as int;
      final currencyDesignations = results[2] as List<CurrencyDesignation>;

      final dailyTotals =
          await _calculateDailyTotals(rawTransactions, mainCurrencyCode);

      final List<TransactionCategory> transactionsWithStyles = [];
      for (final transaction in rawTransactions) {
        Category? category;
        category = await _categoryRepository.getCategoryById(
          transaction.categoryId,
        );

        Style? style;
        if (category?.styleId != null) {
          style = await _styleRepository.getStyleById(category!.styleId!);
        }

        transactionsWithStyles.add(
          TransactionCategory(
            transaction: transaction,
            style: style ??
                Style(
                  id: 'default',
                  name: 'Default',
                  iconName: 'help',
                  colorHex: '#CCCCCC',
                  iconType: IconType.material,
                ),
          ),
        );
      }

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: transactionsWithStyles,
          startIndex: 0,
          hasMoreUp: false,
          hasMoreDown: transactionsWithStyles.isNotEmpty,
          totalCount: totalCount,
          currencyDesignations: currencyDesignations,
          dailyTotals: dailyTotals,
          mainCurrencyCode: mainCurrencyCode,
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
      final mainCurrencySetting = await _settingsRepository.getSetting('main_currency_code');
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';
      
      final offset =
          (state.startIndex - event.limit).clamp(0, double.infinity).toInt();
      final jumpToItemId = state.transactions.firstOrNull?.transaction.id;
      final newRawTransactions =
          await _transactionRepository.getTransactionsWithFilters(
        limit: event.limit,
        offset: offset,
        filters: state.filters,
        sort: state.sort,
      );

      if (newRawTransactions.isEmpty) {
        return emit(
          state.copyWith(status: TransactionStatus.success, hasMoreUp: false),
        );
      }

      final List<TransactionCategory> newTransactionsWithStyles = [];
      for (final transaction in newRawTransactions) {
        Category? category;

        category = await _categoryRepository.getCategoryById(
          transaction.categoryId,
        );

        Style? style;
        if (category?.styleId != null) {
          style = await _styleRepository.getStyleById(category!.styleId!);
        }

        newTransactionsWithStyles.add(
          TransactionCategory(
            transaction: transaction,
            style: style ??
                Style(
                  id: 'default',
                  name: 'Default',
                  iconName: 'help',
                  colorHex: '#CCCCCC',
                  iconType: IconType.material,
                ),
          ),
        );
      }

      final updatedList = [...newTransactionsWithStyles, ...state.transactions];
      final rawUpdatedList = updatedList.map((e) => e.transaction).toList();
      final dailyTotals =
          await _calculateDailyTotals(rawUpdatedList, mainCurrencyCode);

      final newStartIndex = state.startIndex - newTransactionsWithStyles.length;
      double? jumpAlignment;

      if (updatedList.length > state.windowSize) {
        final removeCount = updatedList.length - state.windowSize;
        updatedList.removeRange(
          updatedList.length - removeCount,
          updatedList.length,
        );
        jumpAlignment = 0.0;
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
          dailyTotals: dailyTotals,
          mainCurrencyCode: mainCurrencyCode,
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
      final mainCurrencySetting = await _settingsRepository.getSetting('main_currency_code');
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';

      final offset = state.startIndex + state.transactions.length;
      final jumpToItemId = state.transactions.lastOrNull?.transaction.id;
      final newRawTransactions =
          await _transactionRepository.getTransactionsWithFilters(
        limit: event.limit,
        offset: offset,
        filters: state.filters,
        sort: state.sort,
      );

      if (newRawTransactions.isEmpty) {
        return emit(
          state.copyWith(status: TransactionStatus.success, hasMoreDown: false),
        );
      }

      final List<TransactionCategory> newTransactionsWithStyles = [];
      for (final transaction in newRawTransactions) {
        Category? category;

        category = await _categoryRepository.getCategoryById(
          transaction.categoryId,
        );

        Style? style;
        if (category?.styleId != null) {
          style = await _styleRepository.getStyleById(category!.styleId!);
        }

        newTransactionsWithStyles.add(
          TransactionCategory(
            transaction: transaction,
            style: style ??
                Style(
                  id: 'default',
                  name: 'Default',
                  iconName: 'help',
                  colorHex: '#CCCCCC',
                  iconType: IconType.material,
                ),
          ),
        );
      }

      final updatedList = [...state.transactions, ...newTransactionsWithStyles];
      final rawUpdatedList = updatedList.map((e) => e.transaction).toList();
      final dailyTotals =
          await _calculateDailyTotals(rawUpdatedList, mainCurrencyCode);

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
          hasMoreDown: newTransactionsWithStyles.isNotEmpty,
          jumpToItemId: jumpToItemId,
          jumpToAlignment: jumpAlignment,
          dailyTotals: dailyTotals,
          mainCurrencyCode: mainCurrencyCode,
        ),
      );

      emit(state.copyWith(jumpToItemId: null, jumpToAlignment: null));
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
      add(const InitialLoadTransactions());
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
      add(const InitialLoadTransactions());
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
      add(const InitialLoadTransactions());
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onDeleteMultipleTransactions(
    DeleteMultipleTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      await _transactionRepository.deleteMultipleTransactions(event.ids);

      final newSelectedIds = Set<String>.from(state.selectedTransactionIds);
      newSelectedIds.removeWhere((id) => event.ids.contains(id));

      emit(state.copyWith(selectedTransactionIds: newSelectedIds));

      add(const InitialLoadTransactions());
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onUpdateDateForMultipleTransactions(
    UpdateDateForMultipleTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      await _transactionRepository.updateDateForMultipleTransactions(
          event.ids, event.newDate);
      add(const InitialLoadTransactions());
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onUpdateCategoryForMultipleTransactions(
    UpdateCategoryForMultipleTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    try {
      await _transactionRepository.updateCategoryForMultipleTransactions(
          event.ids, event.newCategoryId);
      add(const InitialLoadTransactions());
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }
}
