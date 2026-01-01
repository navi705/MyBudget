import 'dart:async';
import 'dart:developer' as developer;
import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
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
  }) : _transactionRepository = transactionRepository,
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
      _onUpdateCategoryForMultipleTransactions,
    );
    on<ToggleSelectionMode>(_onToggleSelectionMode);
    on<ToggleTransactionSelection>(_onToggleTransactionSelection);
    on<SelectAllTransactions>(_onSelectAllTransactions);
    on<ClearSelection>(_onClearSelection);
  }

  Future<Map<DateTime, double>> _calculateDailyTotals(
    List<Transaction> transactions,
    String mainCurrencyCode,
  ) async {
    if (transactions.isEmpty) return {};

    const baseCurrency = 'EUR';

    // 1. Group transactions by Date AND Currency (Same as before)
    final Map<DateTime, Map<String, double>> totalsByDateAndCurrency = {};

    for (var t in transactions) {
      // Strip time to ensure correct matching
      final date = DateTime(t.date.year, t.date.month, t.date.day);

      if (!totalsByDateAndCurrency.containsKey(date)) {
        totalsByDateAndCurrency[date] = {};
      }
      final currentSum = totalsByDateAndCurrency[date]![t.currencyCode] ?? 0.0;
      totalsByDateAndCurrency[date]![t.currencyCode] = currentSum + t.amount;
    }

    // --- CHANGED PART STARTS HERE ---

    // 2. Fetch ALL rates in ONE database call
    final uniqueDates = totalsByDateAndCurrency.keys.toList();

    // New optimized method
    final List<ExchangeRateDomain> allRatesList = await _currencyRepository
        .getLatestExchangeRatesByList(uniqueDates);

    // 3. Convert the flat list into a nested Map for O(1) lookup
    // Structure: Map<Date, Map<"USD_EUR", Rate>>
    final ratesMapsByDate = <DateTime, Map<String, double>>{};

    for (var rate in allRatesList) {
      // Ensure we match the stripped date format used in Step 1
      final dateKey = DateTime(rate.date.year, rate.date.month, rate.date.day);

      if (!ratesMapsByDate.containsKey(dateKey)) {
        ratesMapsByDate[dateKey] = {};
      }

      // Create the lookup key: "FROM_TO"
      ratesMapsByDate[dateKey]!['${rate.fromCurrencyCode}_${rate.toCurrencyCode}'] =
          rate.rate;
    }

    // --- CHANGED PART ENDS HERE ---

    final Map<DateTime, double> finalDailyTotals = {};

    // 4. Calculate Totals (Logic remains the same, but lookup is faster)
    for (var date in totalsByDateAndCurrency.keys) {
      double totalForDayInMain = 0;
      final currencySubtotals = totalsByDateAndCurrency[date]!;
      // Get the specific rates map for this date (or empty map if none found)
      final ratesMap = ratesMapsByDate[date] ?? {};

      for (var entry in currencySubtotals.entries) {
        final currencyCode = entry.key;
        final totalAmount = entry.value;

        double amountInBase;

        // Step A: Convert to Base (EUR)
        if (currencyCode == baseCurrency) {
          amountInBase = totalAmount;
        } else {
          final toBase = ratesMap['${currencyCode}_$baseCurrency'];
          if (toBase != null) {
            amountInBase = totalAmount * toBase;
          } else {
            final fromBase = ratesMap['${baseCurrency}_$currencyCode'];
            amountInBase = (fromBase != null && fromBase != 0)
                ? totalAmount / fromBase
                : 0;
          }
        }

        // Step B: Convert Base (EUR) -> Main
        double amountInMain;
        if (mainCurrencyCode == baseCurrency) {
          amountInMain = amountInBase;
        } else {
          final toMain = ratesMap['${baseCurrency}_$mainCurrencyCode'];
          if (toMain != null) {
            amountInMain = amountInBase * toMain;
          } else {
            final fromMain = ratesMap['${mainCurrencyCode}_$baseCurrency'];
            amountInMain = (fromMain != null && fromMain != 0)
                ? amountInBase / fromMain
                : amountInBase;
          }
        }

        totalForDayInMain += amountInMain;
      }
      finalDailyTotals[date] = totalForDayInMain;
    }

    return finalDailyTotals;
  }

  void _onTransactionTypeFilterChanged(
    TransactionTypeFilterChanged event,
    Emitter<TransactionsState> emit,
  ) {
    emit(
      state.copyWith(
        nonDateFilters: state.nonDateFilters.copyWith(
          transactionType: event.transactionType,
        ),
      ),
    );
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
    emit(
      state.copyWith(
        isSelectionModeActive: event.isSelectionModeActive,
        selectedTransactionIds: event.isSelectionModeActive
            ? state.selectedTransactionIds
            : {},
      ),
    );
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
      final mainCurrencySetting = await _settingsRepository.getSetting(
        'main_currency_code',
      );
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';

      final transactionStopwatch = Stopwatch()..start();
      final results = await Future.wait([
        _transactionRepository.getTransactionsWithFilters(
          limit: event.limit,
          offset: 0,
          filters: state.filters,
          sort: state.sort,
        ),
        _transactionRepository.getCountWithFilters(filters: state.filters),
        _currencyRepository.getAllCurrencyDesignations(),
      ]);
      developer.log(
        'In-memory transaction took: ${transactionStopwatch.elapsed}',
      );

      final rawTransactions = results[0] as List<Transaction>;
      final totalCount = results[1] as int;
      final currencyDesignations = results[2] as List<CurrencyDesignation>;

      final calculateStopwatch = Stopwatch()..start();
      final dailyTotals = await _calculateDailyTotals(
        rawTransactions,
        mainCurrencyCode,
      );
      developer.log(
        'In-memory calculate daily took: ${calculateStopwatch.elapsed}',
      );

      final List<TransactionCategory> transactionsWithStyles = [];

      final styleStopwatch = Stopwatch()..start();

      final categoriesListIds = rawTransactions
          .map((u) => u.categoryId)
          .toSet()
          .toList();
      final listCategories = await _categoryRepository.getCategoriesByIds(
        categoriesListIds,
      );

      final List<String> stylesListIds = listCategories
          .map((u) => u.styleId)
          .whereType<String>()
          .toSet()
          .toList();
      final List<Style> stylesList = await _styleRepository.getStylesByIds(
        stylesListIds,
      );

      // --- OPTIMIZATION START ---

      // 2. Create Maps for instant lookup O(1)
      // Map<String, Category>
      final categoryMap = {for (var item in listCategories) item.id: item};

      // Map<String, Style>
      final styleMap = {for (var item in stylesList) item.id: item};

      // 3. Define the Default Style once (optimization)
      final defaultStyle = Style(
        id: 'default',
        name: 'Default',
        iconName: 'help',
        colorHex: '#CCCCCC',
        iconType: IconType.material,
      );

      // 4. Loop through transactions and stitch data together
      for (var transaction in rawTransactions) {
        // A. Find the category instantly
        final category = categoryMap[transaction.categoryId];

        // B. Find the style instantly (if category exists)
        Style? foundStyle;
        if (category != null && category.styleId != null) {
          foundStyle = styleMap[category.styleId];
        }

        // C. Add to result
        transactionsWithStyles.add(
          TransactionCategory(
            transaction: transaction,
            // If foundStyle is null, use default
            style: foundStyle ?? defaultStyle,
          ),
        );
      }
      developer.log('In-memory style daily took: ${styleStopwatch.elapsed}');

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
      final mainCurrencySetting = await _settingsRepository.getSetting(
        'main_currency_code',
      );
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';

      final offset = (state.startIndex - event.limit)
          .clamp(0, double.infinity)
          .toInt();
      final jumpToItemId = state.transactions.firstOrNull?.transaction.id;
      final newRawTransactions = await _transactionRepository
          .getTransactionsWithFilters(
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
            style:
                style ??
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
      final dailyTotals = await _calculateDailyTotals(
        rawUpdatedList,
        mainCurrencyCode,
      );

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
      final mainCurrencySetting = await _settingsRepository.getSetting(
        'main_currency_code',
      );
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';

      final offset = state.startIndex + state.transactions.length;
      final jumpToItemId = state.transactions.lastOrNull?.transaction.id;
      final newRawTransactions = await _transactionRepository
          .getTransactionsWithFilters(
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
            style:
                style ??
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
      final dailyTotals = await _calculateDailyTotals(
        rawUpdatedList,
        mainCurrencyCode,
      );

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
        event.ids,
        event.newDate,
      );
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
        event.ids,
        event.newCategoryId,
      );
      add(const InitialLoadTransactions());
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }
}
