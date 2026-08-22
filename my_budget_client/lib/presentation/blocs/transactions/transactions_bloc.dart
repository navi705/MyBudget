import 'dart:async';

import 'package:rxdart/rxdart.dart';
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

  // One normalised DateTime per distinct day, shared by every row on that day.
  // The rate set for a fifty-row page runs to twenty thousand rows once the
  // bundled history is in the table, and constructing a local DateTime is not
  // cheap - it consults the platform's timezone rules. `DateTime` compares and
  // hashes by value, so handing out the same instance changes nothing but the
  // allocation count.
  final dayCache = <int, DateTime>{};
  DateTime dayOf(DateTime d) {
    final key = (d.year * 100 + d.month) * 100 + d.day;
    return dayCache[key] ??= DateTime(d.year, d.month, d.day);
  }

  for (var rate in params.rates) {
    final dateKey = dayOf(rate.date);
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
          .map((t) => dayOf(t.date))
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
        category: category,
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

    // FIX: Exclude transfers from dailyTotals.
    // Transfers are internal movements between accounts — including them
    // causes the daily summary to show incorrect net amounts.
    // Detection: linkedTransactionId is set for both sides of a transfer.
    final isTransfer =
        transaction.linkedTransactionId != null &&
        transaction.linkedTransactionId!.isNotEmpty;
    if (isTransfer) {
      continue; // Skip transfers — don't include in daily totals
    }

    if (!totalsByDateAndCurrency.containsKey(date)) {
      totalsByDateAndCurrency[date] = {};
    }
    final currentSum =
        totalsByDateAndCurrency[date]![transaction.currencyCode] ?? 0.0;
    totalsByDateAndCurrency[date]![transaction.currencyCode] =
        currentSum + transaction.amount;
  }

  // Build global fallback: most recent rate for each currency pair across ALL dates.
  // Root cause of the 0-EUR bug: ratesMapsByDate[date] can exist (so ratesMapEmpty=false)
  // but be missing a specific pair (e.g., EUR_RSD) if that pair was only added to the DB
  // after some transaction dates. The binary search only copies the whole map from the
  // closest date — if that date also lacks the pair, conversion returns 0.
  // Fix: merge all date maps in chronological order so the latest rate for each pair wins.
  final globalFallback = <String, double>{};
  {
    final sortedRateDates = ratesMapsByDate.keys.toList()..sort();
    for (final d in sortedRateDates) {
      globalFallback.addAll(ratesMapsByDate[d]!);
    }
  }

  final Map<DateTime, double> finalDailyTotals = {};

  for (var date in totalsByDateAndCurrency.keys) {
    double totalForDayInMain = 0;
    final currencySubtotals = totalsByDateAndCurrency[date]!;
    final ratesMap = ratesMapsByDate[date] ?? {};

    // DIAG: log if ratesMap is empty for this date
    if (ratesMap.isEmpty) {
      debugPrint(
        '[DIAG dailyTotals] NO RATES for date=$date — total will be 0',
      );
    }

    for (var entry in currencySubtotals.entries) {
      final currencyCode = entry.key;
      final totalAmount = entry.value;

      double amountInBase;

      if (currencyCode == baseCurrency) {
        amountInBase = totalAmount;
      } else {
        // FIX: Use globalFallback when the date's rates map lacks the pair.
        // Scenario: EUR_RSD rate first appeared on Apr 10; Apr 9/8/6 maps exist
        // (from partial DB records) but don't contain EUR_RSD → toBase/fromBase = null → 0.
        final toBase =
            ratesMap[getRateKey(currencyCode, baseCurrency)] ??
            globalFallback[getRateKey(currencyCode, baseCurrency)];
        if (toBase != null) {
          amountInBase = totalAmount * toBase;
        } else {
          final fromBase =
              ratesMap[getRateKey(baseCurrency, currencyCode)] ??
              globalFallback[getRateKey(baseCurrency, currencyCode)];
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
            ratesMap[getRateKey(baseCurrency, params.mainCurrencyCode)] ??
            globalFallback[getRateKey(baseCurrency, params.mainCurrencyCode)];
        if (toMain != null) {
          amountInMain = amountInBase * toMain;
        } else {
          final fromMain =
              ratesMap[getRateKey(params.mainCurrencyCode, baseCurrency)] ??
              globalFallback[getRateKey(params.mainCurrencyCode, baseCurrency)];
          amountInMain = (fromMain != null && fromMain != 0)
              ? amountInBase / fromMain
              : amountInBase;
        }
      }
      totalForDayInMain += amountInMain;
    }

    // DIAG: log zero totals with extended info
    if (totalForDayInMain == 0.0 && currencySubtotals.isNotEmpty) {
      debugPrint(
        '[DIAG dailyTotals] ZERO total for date=$date '
        'rawSubtotals=$currencySubtotals ratesMapEmpty=${ratesMap.isEmpty} '
        'ratesMapKeys=${ratesMap.keys.toList()} '
        'globalFallbackHasEUR_RSD=${globalFallback.containsKey(getRateKey("EUR", "RSD"))} '
        'globalFallbackEUR_RSD=${globalFallback[getRateKey("EUR", "RSD")]}',
      );
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

  // The codes those rates were fetched for. They are read back filtered to the
  // codes on the page, so the cache is only good for those.
  Set<String>? _rateCacheCodes;

  // The screen only loads from a cold state now (the shell route remounts it
  // on every tab switch, and a reload there redid the whole pipeline), so a
  // write from outside this bloc — a sync, an SMS import, a restore — has to
  // reach the list through here.
  StreamSubscription<void>? _transactionsSubscription;
  StreamSubscription<void>? _exchangeRatesSubscription;

  // Started by the bloc's own write events. Their handlers reload the list
  // themselves, so the table signal they cause is theirs to swallow — without
  // this every add or delete would run the load twice.
  //
  // A stopwatch rather than a plain flag because a write that ends in its
  // catch block writes nothing and so causes no signal at all. The flag stayed
  // armed for as long as the screen was open, and the next signal it swallowed
  // was a pull's — the peer's transactions then stayed off the list until
  // something else happened to write. An echo that never came simply runs out
  // of [ownWriteEcho] instead.
  final Stopwatch _sinceOwnWrite = Stopwatch();

  /// How long after one of this bloc's own writes a table signal still counts
  /// as that write's own echo.
  ///
  /// A constructor parameter for tests only, which cannot afford to wait out
  /// the production value; the default is the production value. It only has to
  /// cover the listener's own 500ms debounce plus the write itself, and erring
  /// short costs one redundant reload while erring long costs a missed one.
  final Duration ownWriteEcho;

  TransactionsBloc({
    required TransactionRepository transactionRepository,
    required StyleRepository styleRepository,
    required CategoryRepository categoryRepository,
    required SettingsRepository settingsRepository,
    required CurrencyRepository currencyRepository,
    required AccountRepository accountRepository, // Added
    this.ownWriteEcho = const Duration(seconds: 3),
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
    on<ClearRecentlyDeletedTransactions>(_onClearRecentlyDeletedTransactions);
    on<UndoDeleteTransactions>(_onUndoDeleteTransactions);

    // Rates land in bulk (the fetch service writes a day at a time), so this
    // waits for the writing to stop rather than reloading per batch. Without
    // it the cached rates lived for the life of the process: a page opened
    // before the rates arrived kept pricing its rows with what it had.
    _exchangeRatesSubscription = _currencyRepository
        .watchExchangeRateChanges()
        .debounceTime(const Duration(seconds: 2))
        .listen((_) {
          _exchangeRateCache.clear();
          _rateCacheCodes = null;
          add(const InitialLoadTransactions());
        });

    _transactionsSubscription = _transactionRepository
        .watchTransactionChanges()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) {
          if (_sinceOwnWrite.isRunning && _sinceOwnWrite.elapsed < ownWriteEcho) {
            _sinceOwnWrite.stop();
            return;
          }
          add(const InitialLoadTransactions());
        });
  }

  @override
  void onEvent(TransactionsEvent event) {
    if (event is TransactionWrite) {
      _sinceOwnWrite
        ..reset()
        ..start();
    }
    super.onEvent(event);
  }

  @override
  Future<void> close() async {
    // Awaited: the listener above calls add(), and adding after the event
    // controller is closed throws.
    await _transactionsSubscription?.cancel();
    await _exchangeRatesSubscription?.cancel();
    return super.close();
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

    // 2. Fetch Missing Styles
    PerformanceLogger().start('Transactions: fetch styles');
    final stylesToFetchIds = _categoryCache.values
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

    // 3. Fetch Exchange Rates
    PerformanceLogger().start('Transactions: fetch exchange rates');
    final uniqueDates = transactions
        .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
        .toSet()
        .toList();

    // Only the codes this page is actually priced in. The table holds a row
    // per currency pair per day — 341 currencies over 870 days is near 300k
    // rows on the phone here — and reading all of them back to convert fifty
    // rows was most of the load.
    final currencyCodes = <String>{
      mainCurrencyCode,
      for (final transaction in transactions) transaction.currencyCode,
      for (final account in _accountCache.values) account.currencyCode,
    };

    // A code the cached rates were never fetched for cannot be filled in by
    // fetching the missing dates — those rows were left out for every date.
    if (_rateCacheCodes != null &&
        !currencyCodes.every(_rateCacheCodes!.contains)) {
      _exchangeRateCache.clear();
    }
    _rateCacheCodes = {...?_rateCacheCodes, ...currencyCodes};

    final missingDates = uniqueDates
        .where((d) => !_exchangeRateCache.containsKey(d))
        .toList();

    if (missingDates.isNotEmpty) {
      final newRates = await _currencyRepository.getLatestExchangeRatesByList(
        missingDates,
        currencyCodes: _rateCacheCodes,
      );

      // FIX: Store rates under the REQUESTED date, not the rate's actual date.
      // Bug: DB returns rates dated e.g. 2026-04-10 for a request of 2026-04-12.
      // Old code stored under 2026-04-10 → lookup by 2026-04-12 returned empty → total = 0.
      //
      // Group fetched rates by their actual date first
      final ratesByActualDate = <DateTime, List<ExchangeRateDomain>>{};
      // One normalised instance per day rather than one per row: `newRates`
      // carries every currency pair for every day asked about, so this loop
      // runs tens of thousands of times for a fifty-row page and a local
      // DateTime costs a timezone lookup to build.
      final rateDayCache = <int, DateTime>{};
      for (final rate in newRates) {
        final d = rate.date;
        final dateKey = rateDayCache[(d.year * 100 + d.month) * 100 + d.day] ??=
            DateTime(d.year, d.month, d.day);
        ratesByActualDate.putIfAbsent(dateKey, () => []).add(rate);
      }

      // For each requested date, find the closest available rate date
      // and cache under the REQUESTED date
      final sortedActualDates = ratesByActualDate.keys.toList()..sort();
      for (final requestedDate in missingDates) {
        if (ratesByActualDate.containsKey(requestedDate)) {
          _exchangeRateCache[requestedDate] = ratesByActualDate[requestedDate]!;
        } else if (sortedActualDates.isNotEmpty) {
          // Binary search for closest actual date
          int left = 0, right = sortedActualDates.length;
          while (left < right) {
            final mid = (left + right) ~/ 2;
            if (sortedActualDates[mid].isBefore(requestedDate)) {
              left = mid + 1;
            } else {
              right = mid;
            }
          }
          DateTime? closestDate;
          int minDiff = -1;
          if (left < sortedActualDates.length) {
            final diff = sortedActualDates[left]
                .difference(requestedDate)
                .inDays
                .abs();
            minDiff = diff;
            closestDate = sortedActualDates[left];
          }
          if (left > 0) {
            final diff = sortedActualDates[left - 1]
                .difference(requestedDate)
                .inDays
                .abs();
            if (minDiff == -1 || diff < minDiff) {
              closestDate = sortedActualDates[left - 1];
            }
          }
          if (closestDate != null) {
            _exchangeRateCache[requestedDate] = ratesByActualDate[closestDate]!;
          }
        }
      }
    }

    List<ExchangeRateDomain> rates = [];
    for (final date in uniqueDates) {
      rates.addAll(_exchangeRateCache[date] ?? []);
    }

    // FALLBACK: Baseline of most recent rates if none found for many dates
    if (rates.isEmpty) {
      PerformanceLogger().start('Transactions: fetch latest baseline rates');
      final latestBaseline = await _currencyRepository.getLatestExchangeRates(
        DateTime.now(),
      );
      rates.addAll(latestBaseline);
      await PerformanceLogger().stop(
        'Transactions: fetch latest baseline rates',
      );
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
      final linkedTransactions = await _transactionRepository
          .getTransactionsByIds(linkedIds);
      for (var tx in linkedTransactions) {
        linkedTransactionsMap[tx.id!] = tx;
      }
    }
    await PerformanceLogger().stop('Transactions: fetch linked transactions');

    // 5. Fetch Missing Accounts (Main + Linked)
    PerformanceLogger().start('Transactions: fetch accounts');
    final accountIds = {
      ...transactions.map((t) => t.accountId),
      ...linkedTransactionsMap.values.map((t) => t.accountId),
    }.where((id) => !_accountCache.containsKey(id)).toList();

    if (accountIds.isNotEmpty) {
      final newAccounts = await _accountRepository.getAccountsByIds(accountIds);
      for (var account in newAccounts) {
        if (account.id != null) {
          _accountCache[account.id!] = account;
        }
      }
    }
    await PerformanceLogger().stop('Transactions: fetch accounts');

    // 6. Processing
    PerformanceLogger().start('Transactions: processing data');
    final result = await _processTransactionsData(
      _ProcessDataParams(
        transactions: transactions,
        rates: rates,
        mainCurrencyCode: mainCurrencyCode,
        categories: _categoryCache.values.toList(),
        styles: _styleCache.values.toList(),
        accounts: _accountCache,
        linkedTransactions: linkedTransactionsMap,
      ),
    );
    await PerformanceLogger().stop('Transactions: processing data');

    return result;
  }

  Future<void> _onLoadTransactionsInitial(
    InitialLoadTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    PerformanceLogger().start('Transactions Screen Initial Load');
    emit(
      state.copyWith(
        status: TransactionStatus.loading,
        recentlyDeletedTransactions: state.recentlyDeletedTransactions,
      ),
    );
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
          isSelectionModeActive: false,
          selectedTransactionIds: {},
        ),
      );
      debugPrint(
        '[SnackBarDebug] TransactionsBloc Emitting Success. Count: ${processResult.transactionsWithStyles.length}, recentlyDeleted: ${state.recentlyDeletedTransactions?.length ?? 0}',
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
    emit(
      state.copyWith(
        status: TransactionStatus.loading,
        recentlyDeletedTransactions: state.recentlyDeletedTransactions,
      ),
    );

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
    emit(
      state.copyWith(
        status: TransactionStatus.loading,
        recentlyDeletedTransactions: state.recentlyDeletedTransactions,
      ),
    );

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
      final txToDelete = state.transactions
          .firstWhereOrNull((t) => t.transaction.id == event.id)
          ?.transaction;

      if (txToDelete != null) {
        debugPrint(
          '[SnackBarDebug] TransactionsBloc: Setting recentlyDeletedTransactions (Single): ${txToDelete.description}',
        );
        emit(state.copyWith(recentlyDeletedTransactions: [txToDelete]));
      }

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
      final txsToDelete = state.transactions
          .where((t) => event.ids.contains(t.transaction.id))
          .map((t) => t.transaction)
          .toList();

      if (txsToDelete.isNotEmpty) {
        debugPrint(
          '[SnackBarDebug] TransactionsBloc: Setting recentlyDeletedTransactions. Count: ${txsToDelete.length}',
        );
        emit(state.copyWith(recentlyDeletedTransactions: txsToDelete));
      }

      await _transactionRepository.deleteMultipleTransactions(event.ids);

      emit(
        state.copyWith(
          selectedTransactionIds: {},
          isSelectionModeActive: false,
        ),
      );

      add(const InitialLoadTransactions());
    } catch (e) {
      emit(state.copyWith(status: TransactionStatus.failure));
    }
  }

  Future<void> _onUndoDeleteTransactions(
    UndoDeleteTransactions event,
    Emitter<TransactionsState> emit,
  ) async {
    final txs = state.recentlyDeletedTransactions;
    if (txs != null && txs.isNotEmpty) {
      try {
        debugPrint(
          '[SnackBarDebug] TransactionsBloc: Undoing delete for ${txs.length} transactions',
        );
        await _transactionRepository.restoreTransactions(txs);
        debugPrint(
          '[SnackBarDebug] TransactionsBloc: Clearing recentlyDeletedTransactions (Undo Success)',
        );
        emit(state.copyWith(clearRecentlyDeletedTransactions: true));
        add(const InitialLoadTransactions());
      } catch (e) {
        emit(state.copyWith(status: TransactionStatus.failure));
      }
    }
  }

  void _onClearRecentlyDeletedTransactions(
    ClearRecentlyDeletedTransactions event,
    Emitter<TransactionsState> emit,
  ) {
    debugPrint(
      '[SnackBarDebug] TransactionsBloc: Clearing recentlyDeletedTransactions (Explicit Clear)',
    );
    emit(state.copyWith(clearRecentlyDeletedTransactions: true));
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
      emit(
        state.copyWith(
          selectedTransactionIds: {},
          isSelectionModeActive: false,
        ),
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
      emit(
        state.copyWith(
          selectedTransactionIds: {},
          isSelectionModeActive: false,
        ),
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
