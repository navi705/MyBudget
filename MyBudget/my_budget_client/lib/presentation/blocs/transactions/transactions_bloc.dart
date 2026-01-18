import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/core/utils/performance_logger.dart';
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
import 'package:my_budget_client/domain/repositories/account_repository.dart'; // Added
import 'package:my_budget_client/domain/entities/account.dart'; // Added

part 'transactions_event.dart';
part 'transactions_state.dart';

class _ProcessDataParams {
  final List<Transaction> transactions;
  final List<ExchangeRateDomain> rates;
  final List<Category> categories;
  final List<Style> styles;
  final String mainCurrencyCode;
  final Map<String, Transaction> linkedTransactions;
  final Map<String, Account> accounts; // Added

  _ProcessDataParams({
    required this.transactions,
    required this.rates,
    required this.categories,
    required this.styles,
    required this.mainCurrencyCode,
    required this.linkedTransactions,
    required this.accounts, // Added
  });
}

class _ProcessDataResult {
  final List<TransactionCategory> transactionsWithStyles;
  final Map<DateTime, double> dailyTotals;

  _ProcessDataResult({
    required this.transactionsWithStyles,
    required this.dailyTotals,
  });
}

Future<_ProcessDataResult> _processTransactionsData(
  _ProcessDataParams params,
) async {
  const baseCurrency = 'EUR';

  final ratesMapsByDate = <DateTime, Map<String, double>>{};

  String getRateKey(String from, String to) => '${from}_$to';

  for (var rate in params.rates) {
    final dateKey = DateTime(rate.date.year, rate.date.month, rate.date.day);
    if (!ratesMapsByDate.containsKey(dateKey)) {
      ratesMapsByDate[dateKey] = {};
    }
    ratesMapsByDate[dateKey]![getRateKey(
          rate.fromCurrencyCode,
          rate.toCurrencyCode,
        )] =
        rate.rate;
  }

  final transactionDates =
      params.transactions
          .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
          .toSet()
          .toList()
        ..sort((a, b) => a.compareTo(b));

  final availableRateDates = ratesMapsByDate.keys.toList()
    ..sort((a, b) => a.compareTo(b));

  // Optimize closest date lookup: find insertion point with binary search, then check neighbors
  if (availableRateDates.isNotEmpty) {
    for (var date in transactionDates) {
      if (!ratesMapsByDate.containsKey(date)) {
        // Binary search for insertion point
        int left = 0;
        int right = availableRateDates.length;
        while (left < right) {
          int mid = (left + right) ~/ 2;
          if (availableRateDates[mid].isBefore(date)) {
            left = mid + 1;
          } else {
            right = mid;
          }
        }

        // Find closest date among insertion point and its neighbors
        DateTime? closestDate;
        int minDiff = -1;

        // Check the element at insertion point (if exists)
        if (left < availableRateDates.length) {
          final diff = availableRateDates[left].difference(date).inDays.abs();
          minDiff = diff;
          closestDate = availableRateDates[left];
        }

        // Check the element before insertion point (if exists)
        if (left > 0) {
          final diff = availableRateDates[left - 1]
              .difference(date)
              .inDays
              .abs();
          if (minDiff == -1 || diff < minDiff) {
            minDiff = diff;
            closestDate = availableRateDates[left - 1];
          }
        }

        if (closestDate != null) {
          ratesMapsByDate[date] = Map.from(ratesMapsByDate[closestDate]!);
        }
      }
    }
  }

  final categoryMap = {for (var item in params.categories) item.id: item};
  final styleMap = {for (var item in params.styles) item.id: item};
  final defaultStyle = Style(
    id: 'default',
    name: 'Default',
    iconName: 'help',
    colorHex: '#CCCCCC',
    iconType: IconType.material,
  );

  final List<TransactionCategory> transactionsWithStyles = [];
  final Map<DateTime, Map<String, double>> totalsByDateAndCurrency = {};

  for (var transaction in params.transactions) {
    final category = categoryMap[transaction.categoryId];
    Style? foundStyle;
    if (category != null && category.styleId != null) {
      foundStyle = styleMap[category.styleId];
    }
    transactionsWithStyles.add(
      TransactionCategory(
        transaction: transaction,
        style: foundStyle ?? defaultStyle,
        isAssetTransaction:
            params.accounts[transaction.accountId]?.assetId?.isNotEmpty == true,
        isLinkedAssetTransaction:
            transaction.linkedTransactionId != null &&
                params.linkedTransactions[transaction.linkedTransactionId] !=
                    null
            ? params
                      .accounts[params
                          .linkedTransactions[transaction.linkedTransactionId]!
                          .accountId]
                      ?.assetId
                      ?.isNotEmpty ==
                  true
            : false,
        linkedTransaction: transaction.linkedTransactionId != null
            ? params.linkedTransactions[transaction.linkedTransactionId]
            : null,
      ),
    );

    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    if (!totalsByDateAndCurrency.containsKey(date)) {
      totalsByDateAndCurrency[date] = {};
    }
    final currentSum =
        totalsByDateAndCurrency[date]![transaction.currencyCode] ?? 0.0;
    totalsByDateAndCurrency[date]![transaction.currencyCode] =
        currentSum + transaction.amount;
  }

  final Map<DateTime, double> finalDailyTotals = {};

  for (var date in totalsByDateAndCurrency.keys) {
    double totalForDayInMain = 0;
    final currencySubtotals = totalsByDateAndCurrency[date]!;
    final ratesMap = ratesMapsByDate[date] ?? {};

    for (var entry in currencySubtotals.entries) {
      final currencyCode = entry.key;
      final totalAmount = entry.value;

      double amountInBase;

      if (currencyCode == baseCurrency) {
        amountInBase = totalAmount;
      } else {
        final toBase = ratesMap[getRateKey(currencyCode, baseCurrency)];
        if (toBase != null) {
          amountInBase = totalAmount * toBase;
        } else {
          final fromBase = ratesMap[getRateKey(baseCurrency, currencyCode)];
          amountInBase = (fromBase != null && fromBase != 0)
              ? totalAmount / fromBase
              : 0;
        }
      }

      double amountInMain;
      if (params.mainCurrencyCode == baseCurrency) {
        amountInMain = amountInBase;
      } else {
        final toMain =
            ratesMap[getRateKey(baseCurrency, params.mainCurrencyCode)];
        if (toMain != null) {
          amountInMain = amountInBase * toMain;
        } else {
          final fromMain =
              ratesMap[getRateKey(params.mainCurrencyCode, baseCurrency)];
          amountInMain = (fromMain != null && fromMain != 0)
              ? amountInBase / fromMain
              : amountInBase;
        }
      }
      totalForDayInMain += amountInMain;
    }
    finalDailyTotals[date] = totalForDayInMain;
  }

  return _ProcessDataResult(
    transactionsWithStyles: transactionsWithStyles,
    dailyTotals: finalDailyTotals,
  );
}

class TransactionsBloc extends Bloc<TransactionsEvent, TransactionsState> {
  // ... (Repository fields same as before)
  final TransactionRepository _transactionRepository;
  final StyleRepository _styleRepository;
  final CategoryRepository _categoryRepository;
  final SettingsRepository _settingsRepository;
  final CurrencyRepository _currencyRepository;
  final AccountRepository _accountRepository; // Added

  final Map<String, Category> _categoryCache = {};
  final Map<String, Style> _styleCache = {};
  final Map<String, Account> _accountCache = {};
  // OPTIMIZATION: Cache exchange rates to avoid repeated DB queries
  final Map<DateTime, List<ExchangeRateDomain>> _exchangeRateCache = {};

  TransactionsBloc({
    required TransactionRepository transactionRepository,
    required StyleRepository styleRepository,
    required CategoryRepository categoryRepository,
    required SettingsRepository settingsRepository,
    required CurrencyRepository currencyRepository,
    required AccountRepository accountRepository, // Added
  }) : _transactionRepository = transactionRepository,
       _styleRepository = styleRepository,
       _categoryRepository = categoryRepository,
       _settingsRepository = settingsRepository,
       _currencyRepository = currencyRepository,
       _accountRepository = accountRepository, // Added
       super(TransactionsState()) {
    // ... (Event handlers same as before)
    on<NonDateFiltersChanged>(
      _onNonDateFiltersChanged,
      transformer: restartable(),
    );
    on<DatePeriodNavigated>(_onDatePeriodNavigated, transformer: restartable());
    on<DateStepChanged>(_onDateStepChanged, transformer: restartable());
    on<FilterModeChanged>(_onFilterModeChanged, transformer: restartable());
    on<ActiveDateChanged>(_onActiveDateChanged, transformer: restartable());
    on<ActiveDateRangeChanged>(
      _onActiveDateRangeChanged,
      transformer: restartable(),
    );
    on<SortChanged>(_onSortChanged, transformer: restartable());
    on<TransactionTypeFilterChanged>(
      _onTransactionTypeFilterChanged,
      transformer: restartable(),
    );
    on<InitialLoadTransactions>(
      _onLoadTransactionsInitial,
      transformer: restartable(),
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

  // Helper method to fetch dependencies and run compute
  Future<_ProcessDataResult> _fetchAndProcess(
    List<Transaction> transactions,
    String mainCurrencyCode,
  ) async {
    if (transactions.isEmpty) {
      return _ProcessDataResult(transactionsWithStyles: [], dailyTotals: {});
    }

    // 1. Fetch Missing Categories
    PerformanceLogger().start('Transactions: fetch categories');
    final categoriesListIds = transactions
        .map((u) => u.categoryId)
        .where((id) => !_categoryCache.containsKey(id))
        .toSet()
        .toList();

    if (categoriesListIds.isNotEmpty) {
      final newCategories = await _categoryRepository.getCategoriesByIds(
        categoriesListIds,
      );
      for (var cat in newCategories) {
        _categoryCache[cat.id!] = cat;
      }
    }
    await PerformanceLogger().stop('Transactions: fetch categories');

    // 1.5. Fetch Missing Accounts (OPTIMIZED: bulk query instead of loop)
    PerformanceLogger().start('Transactions: fetch accounts');
    final accountIds = transactions
        .map((t) => t.accountId)
        .where((id) => !_accountCache.containsKey(id))
        .toSet()
        .toList();

    if (accountIds.isNotEmpty) {
      // OPTIMIZATION: Use bulk fetch instead of O(n) sequential calls
      final newAccounts = await _accountRepository.getAccountsByIds(accountIds);
      for (var account in newAccounts) {
        if (account.id != null) {
          _accountCache[account.id!] = account;
        }
      }
    }
    await PerformanceLogger().stop('Transactions: fetch accounts');

    final categories = transactions
        .map((t) => _categoryCache[t.categoryId])
        .whereType<Category>()
        .toList();

    // 2. Fetch Missing Styles
    PerformanceLogger().start('Transactions: fetch styles');
    final stylesToFetchIds = categories
        .map((u) => u.styleId)
        .whereType<String>()
        .where((id) => !_styleCache.containsKey(id))
        .toSet()
        .toList();

    if (stylesToFetchIds.isNotEmpty) {
      final newStyles = await _styleRepository.getStylesByIds(stylesToFetchIds);
      for (var style in newStyles) {
        _styleCache[style.id!] = style;
      }
    }
    await PerformanceLogger().stop('Transactions: fetch styles');

    final styles = _styleCache.values.toList();

    // 3. Fetch Rates (OPTIMIZED: with caching)
    PerformanceLogger().start('Transactions: fetch exchange rates');
    final uniqueDates = transactions
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .toList();

    // Check cache for missing dates
    final missingDates = uniqueDates
        .where((d) => !_exchangeRateCache.containsKey(d))
        .toList();

    List<ExchangeRateDomain> rates = [];
    if (missingDates.isNotEmpty) {
      final newRates = await _currencyRepository.getLatestExchangeRatesByList(
        missingDates,
      );
      // Cache new rates by date
      for (final rate in newRates) {
        final dateKey = DateTime(
          rate.date.year,
          rate.date.month,
          rate.date.day,
        );
        _exchangeRateCache.putIfAbsent(dateKey, () => []).add(rate);
      }
    }
    // Collect all rates from cache
    for (final date in uniqueDates) {
      rates.addAll(_exchangeRateCache[date] ?? []);
    }
    await PerformanceLogger().stop('Transactions: fetch exchange rates');

    // 4. Fetch Linked Transactions
    PerformanceLogger().start('Transactions: fetch linked transactions');
    final linkedIds = transactions
        .map((t) => t.linkedTransactionId)
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final linkedTransactionsMap = <String, Transaction>{};
    if (linkedIds.isNotEmpty) {
      // Optimization: If repository supports multiple fetch, use it.
      // Otherwise parallel singular fetch.
      // We assume _transactionRepository is safe for parallel calls.
      final futures = linkedIds
          .map((id) => _transactionRepository.getTransactionById(id))
          .toList();
      final results = await Future.wait(futures);
      for (var tx in results) {
        if (tx != null) {
          linkedTransactionsMap[tx.id!] = tx;
        }
      }
    }
    await PerformanceLogger().stop('Transactions: fetch linked transactions');

    // 4.5 Fetch Missing Accounts for Linked Transactions
    if (linkedTransactionsMap.isNotEmpty) {
      final linkedAccountIds = linkedTransactionsMap.values
          .map((t) => t.accountId)
          .where((id) => !_accountCache.containsKey(id))
          .toSet()
          .toList();

      if (linkedAccountIds.isNotEmpty) {
        // OPTIMIZATION: Use bulk fetch instead of O(n) sequential calls
        final newAccounts = await _accountRepository.getAccountsByIds(
          linkedAccountIds,
        );
        for (var account in newAccounts) {
          if (account.id != null) {
            _accountCache[account.id!] = account;
          }
        }
      }
    }

    PerformanceLogger().start('Transactions: compute processing');
    final result = await _processTransactionsData(
      _ProcessDataParams(
        transactions: transactions,
        rates: rates,
        categories: categories,
        styles: styles,
        mainCurrencyCode: mainCurrencyCode,
        linkedTransactions: linkedTransactionsMap,
        accounts: _accountCache, // Added
      ),
    );
    await PerformanceLogger().stop('Transactions: compute processing');

    return result;
  }

  Future<void> _onLoadTransactionsInitial(
    InitialLoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    PerformanceLogger().start('Transactions Screen Initial Load');
    emit(state.copyWith(status: TransactionStatus.loading));
    try {
      PerformanceLogger().start('Transactions: getSetting');
      final mainCurrencySetting = await _settingsRepository.getSetting(
        'main_currency_code',
      );
      await PerformanceLogger().stop('Transactions: getSetting');
      final mainCurrencyCode = mainCurrencySetting?.value ?? 'EUR';

      PerformanceLogger().start('Transactions: prepare DB queries');
      final getTransactionsFuture = _transactionRepository
          .getTransactionsWithFilters(
            limit: event.limit,
            offset: 0,
            filters: state.filters,
            sort: state.sort,
          );
      final getCountFuture = _transactionRepository.getCountWithFilters(
        filters: state.filters,
      );
      final getCurrenciesFuture = _currencyRepository
          .getAllCurrencyDesignations();
      await PerformanceLogger().stop('Transactions: prepare DB queries');

      PerformanceLogger().start(
        'Transactions: await all DB queries (parallel)',
      );
      final results = await Future.wait([
        getTransactionsFuture,
        getCountFuture,
        getCurrenciesFuture,
      ]);
      await PerformanceLogger().stop(
        'Transactions: await all DB queries (parallel)',
      );

      PerformanceLogger().start('Transactions: extract results');
      final rawTransactions = results[0] as List<Transaction>;
      final totalCount = results[1] as int;
      final currencyDesignations = results[2] as List<CurrencyDesignation>;
      await PerformanceLogger().stop('Transactions: extract results');

      PerformanceLogger().start('Transactions: fetchAndProcess total');
      final processResult = await _fetchAndProcess(
        rawTransactions,
        mainCurrencyCode,
      );
      await PerformanceLogger().stop('Transactions: fetchAndProcess total');

      PerformanceLogger().start('Transactions: emit state');
      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: processResult.transactionsWithStyles,
          startIndex: 0,
          hasMoreUp: false,
          hasMoreDown: processResult.transactionsWithStyles.isNotEmpty,
          totalCount: totalCount,
          currencyDesignations: currencyDesignations,
          dailyTotals: processResult.dailyTotals,
          mainCurrencyCode: mainCurrencyCode,
        ),
      );
      await PerformanceLogger().stop('Transactions: emit state');

      await PerformanceLogger().stop('Transactions Screen Initial Load');
    } catch (_) {
      PerformanceLogger().stop('Transactions Screen Initial Load');
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onLoadTransactionsUp(
    LoadTransactionsUp event,
    Emitter<TransactionsState> emit,
  ) async {
    if (!state.hasMoreUp || state.status == TransactionStatus.loading) return;
    PerformanceLogger().start('Transactions Window Load Up');
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
        PerformanceLogger().stop('Transactions Window Load Up');
        return emit(
          state.copyWith(status: TransactionStatus.success, hasMoreUp: false),
        );
      }

      final processResult = await _fetchAndProcess(
        newRawTransactions,
        mainCurrencyCode,
      );

      final updatedList = [
        ...processResult.transactionsWithStyles,
        ...state.transactions,
      ];

      final Map<DateTime, double> updatedTotals = Map.from(state.dailyTotals);
      for (final entry in processResult.dailyTotals.entries) {
        updatedTotals[entry.key] =
            (updatedTotals[entry.key] ?? 0) + entry.value;
      }

      final newStartIndex =
          state.startIndex - processResult.transactionsWithStyles.length;
      double? jumpAlignment;

      if (updatedList.length > state.windowSize) {
        final removeCount = updatedList.length - state.windowSize;
        updatedList.removeRange(
          updatedList.length - removeCount,
          updatedList.length,
        );
        jumpAlignment = 0.0;
      }

      await PerformanceLogger().stop('Transactions Window Load Up');

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: updatedList,
          startIndex: newStartIndex,
          hasMoreDown: true,
          hasMoreUp: newStartIndex > 0,
          jumpToItemId: jumpToItemId,
          jumpToAlignment: jumpAlignment,
          dailyTotals: updatedTotals,
          mainCurrencyCode: mainCurrencyCode,
        ),
      );
      emit(state.copyWith(jumpToItemId: null, jumpToAlignment: null));
    } catch (_) {
      PerformanceLogger().stop('Transactions Window Load Up');
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onLoadTransactionsDown(
    LoadTransactionsDown event,
    Emitter<TransactionsState> emit,
  ) async {
    if (!state.hasMoreDown || state.status == TransactionStatus.loading) return;
    PerformanceLogger().start('Transactions Window Load Down');
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
        PerformanceLogger().stop('Transactions Window Load Down');
        return emit(
          state.copyWith(status: TransactionStatus.success, hasMoreDown: false),
        );
      }

      final processResult = await _fetchAndProcess(
        newRawTransactions,
        mainCurrencyCode,
      );

      final updatedList = [
        ...state.transactions,
        ...processResult.transactionsWithStyles,
      ];

      // Merge totals
      final Map<DateTime, double> updatedTotals = Map.from(state.dailyTotals);
      for (final entry in processResult.dailyTotals.entries) {
        updatedTotals[entry.key] =
            (updatedTotals[entry.key] ?? 0) + entry.value;
      }

      var newStartIndex = state.startIndex;
      double? jumpAlignment;

      if (updatedList.length > state.windowSize) {
        final removeCount = updatedList.length - state.windowSize;
        updatedList.removeRange(0, removeCount);
        newStartIndex += removeCount;
        jumpAlignment = 1.0;
      }

      await PerformanceLogger().stop('Transactions Window Load Down');

      emit(
        state.copyWith(
          status: TransactionStatus.success,
          transactions: updatedList,
          startIndex: newStartIndex,
          hasMoreUp: true,
          hasMoreDown: processResult.transactionsWithStyles.isNotEmpty,
          jumpToItemId: jumpToItemId,
          jumpToAlignment: jumpAlignment,
          dailyTotals: updatedTotals,
          mainCurrencyCode: mainCurrencyCode,
        ),
      );
      emit(state.copyWith(jumpToItemId: null, jumpToAlignment: null));
    } catch (_) {
      PerformanceLogger().stop('Transactions Window Load Down');
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  // ... (Other event handlers same as before: Add/Update/Delete/Filter/etc methods)
  // Since I am replacing until line 710, I need to keep the rest, but the tool cuts off.
  // I will just implement the handlers I need to changes, and keep the others if they haven't changed.
  // Actually, I am replacing from line 25.
  // I need to ensure the other handlers (_onAddTransaction etc) are preserved or re-implemented.
  // They call `add(const InitialLoadTransactions())` so they are safe if that handler is updated.
  // The implementations I provided above cover the complex loading logic.
  // The simple CRUD handlers are missing from the ReplacementContent if I overwrite the whole class body.
  // I should provide them.

  // ... (Rest of the class)
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
}
