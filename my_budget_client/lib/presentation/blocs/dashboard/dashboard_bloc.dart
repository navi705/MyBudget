import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:my_budget_client/core/enums/filter_enums.dart'; // Added
import 'package:my_budget_client/core/utils/currency_converter.dart'; // Added
import 'package:my_budget_client/core/utils/performance_logger.dart';

import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart'; // Added
import 'package:my_budget_client/domain/entities/currency_designation.dart'; // Added
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/category_type.dart'; // Added
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart'; // Added
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart'; // Added
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart'; // Added for asset balance calculation
import 'package:rxdart/rxdart.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final AccountRepository _accountRepository;
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final StyleRepository _styleRepository;
  final CurrencyRepository _currencyRepository;
  final SettingsRepository _settingsRepository;
  final AssetRepository _assetRepository; // Added

  // Parameters stream
  final _paramsSubject = BehaviorSubject<_DashboardParams>.seeded(
    _DashboardParams(
      activeTabIndex: 0,
      selectedDay: DateTime.now(),
      // FIX: Use month boundaries for initial range (matching dateStep: month)
      dateRangeStart: DateTime(DateTime.now().year, DateTime.now().month, 1),
      dateRangeEnd: DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
      dateStep: DateStep.month,
      selectedCurrency: '', // Seed with empty, will resolve to main
      isIncomeView: false,
    ),
  );

  // OPTIMIZATION: Cache for exchange rates and currencies
  // These don't change during a session, so we cache them
  List<ExchangeRateDomain>? _cachedExchangeRates;
  Set<DateTime> _cachedDates = {};
  List<Currency>? _cachedCurrencies;
  CurrencyConverter? _cachedConverter;

  // OPTIMIZATION: Cache for settings and currency designations
  // These rarely change — fetched once per session, not on every stream update
  Map<String, String>? _cachedSettings;
  List<CurrencyDesignation>? _cachedCurrencyDesignations;

  // OPTIMIZATION: Styles and categories cached outside the reactive stream.
  // Previously in combineLatest6 — every style/category change triggered a full
  // dashboard recompute. Now loaded once at init, updated via separate subscriptions.
  List<Style> _cachedStyles = [];
  List<Category> _cachedCategories = [];
  StreamSubscription<List<Style>>? _stylesSubscription;
  StreamSubscription<List<Category>>? _categoriesSubscription;

  // OPTIMIZATION: Memoize _calculateDashboardData results.
  // The walk-back loop is the bottleneck (~27ms). When only UI params change
  // (tab, isIncomeView) but data lists are identical objects, skip recompute.
  _DashboardComputeParams? _lastComputeParams;
  _DashboardComputeResults? _lastComputeResults;

  DashboardBloc({
    required AccountRepository accountRepository,
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
    required StyleRepository styleRepository,
    required CurrencyRepository currencyRepository,
    required SettingsRepository settingsRepository,
    required AssetRepository assetRepository, // Added
  }) : _accountRepository = accountRepository,
       _transactionRepository = transactionRepository,
       _categoryRepository = categoryRepository,
       _styleRepository = styleRepository,
       _currencyRepository = currencyRepository,
       _settingsRepository = settingsRepository,
       _assetRepository = assetRepository, // Added
       super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<ChangeTab>(_onChangeTab);
    on<ChangeDateRange>(_onChangeDateRange);
    on<SelectDay>(_onSelectDay);
    on<ToggleChartType>(_onToggleChartType);
    on<ChangeDateStep>(_onChangeDateStep);
    on<ChangeCurrency>(_onChangeCurrency);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    PerformanceLogger().start('Dashboard Screen Load');
    emit(DashboardLoadInProgress());

    // Invalidate all caches on reload (e.g., after restore backup).
    // Without this, stale cached data (settings, rates, currencies) would be
    // used on the first visit after restore, showing incorrect dashboard data.
    // _cachedStyles/_cachedCategories are re-fetched below — clear the rest here.
    _cachedSettings = null;
    _cachedCurrencyDesignations = null;
    _cachedExchangeRates = null;
    _cachedCurrencies = null;
    _cachedConverter = null;
    _cachedDates = {};
    _lastComputeParams = null;
    _lastComputeResults = null;

    // OPTIMIZATION: Load styles and categories once at init.
    // They change rarely — subscribing them to combineLatest caused unnecessary
    // full recomputes on every style/category DB change.
    _cachedStyles = await _styleRepository.watchAllStyles().first;
    _cachedCategories = await _categoryRepository.getCategories();

    // Subscribe to style/category changes separately.
    // When they change, update the cache and trigger a recompute via _paramsSubject
    // (by incrementing dataVersion). The debounce(50ms) batches rapid changes.
    _stylesSubscription?.cancel();
    _stylesSubscription = _styleRepository.watchAllStyles().skip(1).listen((
      styles,
    ) {
      _cachedStyles = styles;
      _paramsSubject.add(
        _paramsSubject.value.copyWith(
          dataVersion: _paramsSubject.value.dataVersion + 1,
        ),
      );
    });

    _categoriesSubscription?.cancel();
    _categoriesSubscription = _categoryRepository
        .watchCategories()
        .skip(1)
        .listen((categories) {
          _cachedCategories = categories;
          _paramsSubject.add(
            _paramsSubject.value.copyWith(
              dataVersion: _paramsSubject.value.dataVersion + 1,
            ),
          );
        });

    // OPTIMIZATION: Filtered transaction stream — re-subscribes only when
    // dateRangeStart changes (not on tab/currency/etc. changes).
    // This avoids loading the full transaction history on every stream update.
    final transactionStream = _paramsSubject.stream
        .map((p) => p.dateRangeStart)
        .distinct()
        .switchMap(
          (from) => _transactionRepository.watchTransactions(from: from),
        );

    // OPTIMIZATION: Reduced from combineLatest6 to combineLatest4.
    // Styles and categories removed — now cached and updated via separate subscriptions.
    final stream =
        Rx.combineLatest4(
          _accountRepository.watchAccounts(),
          transactionStream,
          _assetRepository.watchAssetData(limit: 10000),
          _paramsSubject.stream,
          (
            List<Account> accounts,
            List<Transaction> transactions,
            List<AssetDataDomain> assetData,
            _DashboardParams params,
          ) {
            return _DashboardStreamData(
              accounts: accounts,
              transactions: transactions,
              assetData: assetData,
              params: params,
            );
          },
          // OPTIMIZATION: Reduced debounce from 300ms to 50ms
          // 300ms was adding noticeable delay, 50ms is enough to batch rapid changes
        ).debounceTime(const Duration(milliseconds: 50)).asyncMap((data) async {
          final accounts = data.accounts;
          final transactions = data.transactions;
          final categories = _cachedCategories; // Use cached (not from stream)
          final styles = _cachedStyles; // Use cached (not from stream)
          final params = data.params;

          // GUARD: Skip computation if categories haven't loaded yet
          // This prevents transfers from being counted as income/expense
          // if (categories.isEmpty) {
          //   print('DEBUG: Skipping compute - categories empty');
          //   return DashboardLoadInProgress();
          // }

          // OPTIMIZATION: Run DB queries in parallel
          PerformanceLogger().start('Dashboard: balances, totals, settings');

          // OPTIMIZATION: Settings and currency designations are cached after
          // the first fetch — they rarely change during a session.
          // Invalidate by calling _cachedSettings = null externally if needed.
          _cachedSettings ??= await _settingsRepository.getAllSettings();
          _cachedCurrencyDesignations ??=
              await _currencyRepository.getAllCurrencyDesignations();

          // OPTIMIZATION: Removed getBalancesAtDate from Future.wait.
          // The result (rawDayBalances) was never used — dayBalances is computed
          // directly by the walk-back in _calculateDashboardData.
          final categoryTotals =
              await _transactionRepository.getTransactionTotalsGrouped(
                dateFrom: params.dateRangeStart,
                dateTo: params.dateRangeEnd,
              );

          final settingsMap = _cachedSettings!;
          final currencyDesignationsList = _cachedCurrencyDesignations!;
          final assetData = data.assetData; // From stream

          final currencyDesignations = {
            for (final d in currencyDesignationsList) d.id: d,
          }; // Added

          final mainCurrencyCode = settingsMap['main_currency_code'] ?? 'EUR';

          final targetCurrency = params.selectedCurrency.isEmpty
              ? mainCurrencyCode
              : params.selectedCurrency;

          await PerformanceLogger().stop(
            'Dashboard: balances, totals, settings',
          );

          // OPTIMIZATION: Use cached data when available
          PerformanceLogger().start('Dashboard: Parallel Fetch');

          final uniqueDates = transactions
              .map((t) => DateTime(t.date.year, t.date.month, t.date.day))
              .toSet();
          uniqueDates.add(DateTime(DateTime.now().year, DateTime.now().month));
          uniqueDates.add(
            DateTime(
              params.selectedDay.year,
              params.selectedDay.month,
              params.selectedDay.day,
            ),
          );

          // Check which dates need to be fetched (not in cache)
          final missingDates = uniqueDates
              .where((d) => !_cachedDates.contains(d))
              .toList();

          List<ExchangeRateDomain> exchangeRates;
          List<Currency> availableCurrencies;

          if (missingDates.isEmpty &&
              _cachedExchangeRates != null &&
              _cachedCurrencies != null) {
            // Use fully cached data - instant!
            exchangeRates = _cachedExchangeRates!;
            availableCurrencies = _cachedCurrencies!;
          } else {
            // Need to fetch missing data
            final futures = <Future>[];

            // Fetch currencies if not cached
            if (_cachedCurrencies == null) {
              futures.add(_currencyRepository.getCurrencies());
            }

            // Fetch exchange rates for missing dates (or all if first load)
            if (_cachedExchangeRates == null) {
              futures.add(
                _currencyRepository.getLatestExchangeRatesByList(
                  uniqueDates.toList(),
                ),
              );
            } else if (missingDates.isNotEmpty) {
              futures.add(
                _currencyRepository.getLatestExchangeRatesByList(missingDates),
              );
            }

            final results = await Future.wait(futures);
            int idx = 0;

            // Process currencies
            _cachedCurrencies ??= results[idx++] as List<Currency>;
            availableCurrencies = _cachedCurrencies!;

            // Process exchange rates
            if (_cachedExchangeRates == null) {
              _cachedExchangeRates = results[idx++] as List<ExchangeRateDomain>;
              _cachedDates = uniqueDates;
            } else if (missingDates.isNotEmpty) {
              final newRates = results[idx++] as List<ExchangeRateDomain>;
              _cachedExchangeRates = [..._cachedExchangeRates!, ...newRates];
              _cachedDates.addAll(missingDates);
            }
            exchangeRates = _cachedExchangeRates!;
          }

          await PerformanceLogger().stop('Dashboard: Parallel Fetch');

          PerformanceLogger().start('Dashboard: compute');

          // OPTIMIZATION: Cache CurrencyConverter - only recreate when rates change
          if (_cachedConverter == null || missingDates.isNotEmpty) {
            _cachedConverter = CurrencyConverter(exchangeRates);
          } else {}

          // Build Category Type Map for filtering (Isolate safe: String -> Enum)
          final categoryTypeMap = {
            for (final c in categories)
              if (c.id != null) c.id!: c.type,
          };

          final computeParams = _DashboardComputeParams(
            accounts: accounts,
            transactions: transactions,
            rates: exchangeRates,
            mainCurrencyCode: targetCurrency,
            dateRangeStart: params.dateRangeStart,
            dateRangeEnd: params.dateRangeEnd, // Added
            selectedDay: params.selectedDay,
            categoryTypeMap: categoryTypeMap,
            converter: _cachedConverter!, // Pass cached converter
            assetData: assetData, // Added for asset-linked accounts
            dateStep: params.dateStep, // OPTIMIZATION: for yearly granularity
          );

          // Converted balances are now computed in _calculateDashboardData to match historical state exactly

          // Convert category totals
          final categoryConvertedTotals = <String, double>{}; // Added
          for (final total in categoryTotals) {
            final convertedAmount = _cachedConverter!.convert(
              amount: total.total,
              from: total.currencyCode,
              to: targetCurrency,
              date: total.date,
            );
            categoryConvertedTotals.update(
              total.categoryId,
              (value) => value + convertedAmount,
              ifAbsent: () => convertedAmount,
            );
          }

          // OPTIMIZATION: Memoize walk-back results.
          // Uses identical() to check if list objects are the same reference —
          // Drift streams reuse the same list object when only params change
          // (e.g. tab switch, currency change). In those cases, skip the ~27ms
          // walk-back and return the cached result.
          _DashboardComputeResults computeResults;
          if (_lastComputeParams != null &&
              _lastComputeResults != null &&
              _lastComputeParams!.mainCurrencyCode ==
                  computeParams.mainCurrencyCode &&
              _lastComputeParams!.dateRangeStart ==
                  computeParams.dateRangeStart &&
              _lastComputeParams!.dateRangeEnd == computeParams.dateRangeEnd &&
              _lastComputeParams!.selectedDay == computeParams.selectedDay &&
              _lastComputeParams!.dateStep == computeParams.dateStep &&
              identical(
                _lastComputeParams!.transactions,
                computeParams.transactions,
              ) &&
              identical(
                _lastComputeParams!.accounts,
                computeParams.accounts,
              ) &&
              identical(
                _lastComputeParams!.assetData,
                computeParams.assetData,
              ) &&
              identical(_lastComputeParams!.rates, computeParams.rates)) {
            debugPrint('COMPUTE: Cache hit — reusing previous walk-back results');
            computeResults = _lastComputeResults!;
          } else {
            // OPTIMIZATION: Run on main thread instead of compute() isolate
            // Reason: Actual work is only ~27ms, but compute() overhead is ~350ms
            // 27ms won't block the UI, so isolate is not justified
            computeResults = _calculateDashboardData(computeParams);
            _lastComputeParams = computeParams;
            _lastComputeResults = computeResults;
          }

          await PerformanceLogger().stop('Dashboard: compute');

          await PerformanceLogger().stop('Dashboard Screen Load');

          return DashboardLoadSuccess(
            accounts: accounts,
            transactions: transactions,
            categories: categories,
            styles: styles,
            activeTabIndex: params.activeTabIndex,
            selectedDay: params.selectedDay,
            dateRangeStart: params.dateRangeStart,
            dateRangeEnd: params.dateRangeEnd,
            dateStep: params.dateStep,
            selectedCurrency: targetCurrency,
            isIncomeView: params.isIncomeView,
            dayBalances: computeResults.dayBalances,
            categoryTotals: categoryTotals,
            categoryConvertedTotals: categoryConvertedTotals, // Added
            dailyIncomes: computeResults.dailyIncomes,
            dailyExpenses: computeResults.dailyExpenses, // Restored
            dailyNetWorth: computeResults.dailyNetWorth,
            dailyAccountBalances: computeResults.dailyAccountBalances,
            currencyBreakdown: computeResults.currencyBreakdown, // Added
            accountBreakdown: computeResults.accountBreakdown, // Added
            availableCurrencies: availableCurrencies,
            currencyDesignations: currencyDesignations,
          );
        });

    await emit.forEach<DashboardState>(
      stream,
      onData: (state) => state,
      onError: (e, st) {
        PerformanceLogger().stop('Dashboard Screen Load');
        return DashboardLoadFailure();
      },
    );
  }

  void _onChangeTab(ChangeTab event, Emitter<DashboardState> emit) {
    _paramsSubject.add(
      _paramsSubject.value.copyWith(activeTabIndex: event.index),
    );
  }

  void _onChangeDateRange(ChangeDateRange event, Emitter<DashboardState> emit) {
    _paramsSubject.add(
      _paramsSubject.value.copyWith(
        dateRangeStart: event.start,
        dateRangeEnd: event.end,
      ),
    );
  }

  void _onSelectDay(SelectDay event, Emitter<DashboardState> emit) {
    final currentStep = _paramsSubject.value.dateStep;
    DateTime start;
    DateTime end;

    if (currentStep == DateStep.month) {
      start = DateTime(event.day.year, event.day.month, 1);
      end = DateTime(event.day.year, event.day.month + 1, 0);
    } else if (currentStep == DateStep.year) {
      start = DateTime(event.day.year, 1, 1);
      end = DateTime(event.day.year, 12, 31);
    } else {
      // Keep existing range relative to selection? Or just center?
      // For now, let's keep the existing range if possible, or default to day
      start = event.day;
      end = event.day;
    }

    _paramsSubject.add(
      _paramsSubject.value.copyWith(
        selectedDay: event.day,
        dateRangeStart: start,
        dateRangeEnd: end,
      ),
    );
  }

  void _onToggleChartType(ToggleChartType event, Emitter<DashboardState> emit) {
    _paramsSubject.add(
      _paramsSubject.value.copyWith(isIncomeView: event.isIncome),
    );
  }

  void _onChangeDateStep(ChangeDateStep event, Emitter<DashboardState> emit) {
    // When changing step, we need to adjust the range to match the CURRENT selected day
    final selectedDay = _paramsSubject.value.selectedDay;
    DateTime start;
    DateTime end;

    if (event.step == DateStep.month) {
      start = DateTime(selectedDay.year, selectedDay.month, 1);
      end = DateTime(selectedDay.year, selectedDay.month + 1, 0);
    } else if (event.step == DateStep.year) {
      start = DateTime(selectedDay.year, 1, 1);
      end = DateTime(selectedDay.year, 12, 31);
    } else {
      start = selectedDay;
      end = selectedDay;
    }

    _paramsSubject.add(
      _paramsSubject.value.copyWith(
        dateStep: event.step,
        dateRangeStart: start,
        dateRangeEnd: end,
      ),
    );
  }

  void _onChangeCurrency(ChangeCurrency event, Emitter<DashboardState> emit) {
    _paramsSubject.add(
      _paramsSubject.value.copyWith(selectedCurrency: event.currencyCode),
    );
  }

  @override
  Future<void> close() {
    _stylesSubscription?.cancel();
    _categoriesSubscription?.cancel();
    _paramsSubject.close();
    return super.close();
  }
}

class _DashboardParams {
  final int activeTabIndex;
  final DateTime selectedDay;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final DateStep dateStep;
  final String selectedCurrency; // Added
  final bool isIncomeView;
  // OPTIMIZATION: Increments when styles/categories change to trigger recompute
  // via _paramsSubject without including them in combineLatest.
  final int dataVersion;

  _DashboardParams({
    required this.activeTabIndex,
    required this.selectedDay,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.dateStep,
    required this.selectedCurrency, // Added
    required this.isIncomeView,
    this.dataVersion = 0,
  });

  _DashboardParams copyWith({
    int? activeTabIndex,
    DateTime? selectedDay,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    DateStep? dateStep,
    String? selectedCurrency, // Added
    bool? isIncomeView,
    int? dataVersion,
  }) {
    return _DashboardParams(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      selectedDay: selectedDay ?? this.selectedDay,
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      dateStep: dateStep ?? this.dateStep,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency, // Added
      isIncomeView: isIncomeView ?? this.isIncomeView,
      dataVersion: dataVersion ?? this.dataVersion,
    );
  }
}

// OPTIMIZATION: Removed categories and styles fields — now cached in the bloc.
// combineLatest4 instead of combineLatest6.
class _DashboardStreamData {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<AssetDataDomain> assetData; // Added
  final _DashboardParams params;

  _DashboardStreamData({
    required this.accounts,
    required this.transactions,
    required this.assetData, // Added
    required this.params,
  });
}

class _DashboardComputeParams {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<ExchangeRateDomain> rates;
  final String mainCurrencyCode;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd; // Added
  final DateTime selectedDay;
  final Map<String, CategoryType> categoryTypeMap;
  final CurrencyConverter converter; // OPTIMIZATION: Pre-built converter
  final List<AssetDataDomain> assetData; // Added for asset-linked accounts
  final DateStep dateStep; // OPTIMIZATION: for yearly granularity

  _DashboardComputeParams({
    required this.accounts,
    required this.transactions,
    required this.rates,
    required this.mainCurrencyCode,
    required this.dateRangeStart,
    required this.dateRangeEnd, // Added
    required this.selectedDay,
    required this.categoryTypeMap,
    required this.converter,
    required this.assetData, // Added for asset-linked accounts
    required this.dateStep, // OPTIMIZATION: for yearly granularity
  });
}

class _DashboardComputeResults {
  final Map<DateTime, double> dailyIncomes;
  final Map<DateTime, double> dailyExpenses;
  final Map<DateTime, double> dailyNetWorth;
  final Map<String, double> dayBalances;
  final Map<DateTime, Map<String, double>> dailyAccountBalances;
  final Map<String, double> currencyBreakdown; // Added
  final Map<String, double> accountBreakdown; // Added
  final List<GroupedTransactionTotal> categoryTotals;

  _DashboardComputeResults({
    required this.dailyIncomes,
    required this.dailyExpenses,
    required this.dailyNetWorth,
    required this.dayBalances,
    required this.dailyAccountBalances,
    required this.currencyBreakdown, // Added
    required this.accountBreakdown, // Added
    required this.categoryTotals,
  });
}

_DashboardComputeResults _calculateDashboardData(
  _DashboardComputeParams params,
) {
  final totalStopwatch = Stopwatch()..start();
  final sectionStopwatch = Stopwatch();

  // OPTIMIZATION: Use pre-built converter from params (cached in Bloc)
  sectionStopwatch.start();
  final converter = params.converter;
  final conversionDate = DateTime.now();

  sectionStopwatch.reset();

  final dailyIncomes = <DateTime, double>{};
  final dailyExpenses = <DateTime, double>{};
  final dailyNetWorth = <DateTime, double>{};
  final dailyAccountBalances = <DateTime, Map<String, double>>{};
  Map<String, double> dayBalances = {};
  Map<String, double> currencyBreakdown = {}; // Added
  Map<String, double> accountBreakdown = {}; // Added

  final currentBalances = <String, double>{};
  final accountCurrencyMap = <String, String>{};
  final accountAssetMap = <String, bool>{};

  for (final account in params.accounts) {
    currentBalances[account.id!] = account.balance;
    accountCurrencyMap[account.id!] = account.currencyCode;
    accountAssetMap[account.id!] = account.assetId != null;
  }

  // Section 2: Calculate daily data and net worth history
  sectionStopwatch.start();
  if (kDebugMode) {
    debugPrint(
      'DEBUG: Calc Data. Range: ${params.dateRangeStart} - ${params.dateRangeEnd}',
    );
    debugPrint('DEBUG: Transactions: ${params.transactions.length}');
  }

  for (final transaction in params.transactions) {
    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );

    final transactionCurrency = transaction.currencyCode;

    // Exclude transfers from Income/Expense indicators
    // Check both linkedTransactionId (for account transfers) AND category type
    // This ensures ALL transfer transactions are excluded, regardless of how they were created
    final categoryType = params.categoryTypeMap[transaction.categoryId];

    if (categoryType == CategoryType.transfer ||
        (transaction.linkedTransactionId != null &&
            transaction.linkedTransactionId!.isNotEmpty)) {
      // DEBUG: Log transfer detection — wrapped in kDebugMode to avoid
      // 1000+ debugPrint calls in hot path with many transfer transactions
      if (kDebugMode) {
        debugPrint(
          'DEBUG TRANSFER EXCLUDED: ${transaction.description}, '
          'categoryType=$categoryType, linkedTransactionId=${transaction.linkedTransactionId}, '
          'amount=${transaction.amount}',
        );
      }
      continue;
    }

    final convertedAmount = converter.convert(
      amount: transaction.amount,
      from: transactionCurrency,
      to: params.mainCurrencyCode,
      date: date,
    );

    // Pre-calculate Daily Incomes/Expenses for the WHOLE period
    // (Independent of the net-worth walk-back which handles balances)
    final isInRange =
        date.isAfter(params.dateRangeStart.subtract(const Duration(days: 1))) &&
        date.isBefore(params.dateRangeEnd.add(const Duration(days: 1)));

    // if (isInRange) debugPrint('DEBUG: Incl Tx ${transaction.date} $convertedAmount');

    if (isInRange) {
      if (convertedAmount > 0) {
        dailyIncomes.update(
          date,
          (v) => v + convertedAmount,
          ifAbsent: () => convertedAmount,
        );
      } else if (convertedAmount < 0) {
        dailyExpenses.update(
          date,
          (v) => v + convertedAmount.abs(),
          ifAbsent: () => convertedAmount.abs(),
        );
      }
    }
  }

  sectionStopwatch.reset();

  // Section 3: Pre-group transactions
  sectionStopwatch.start();
  final transactionsByDate = <DateTime, List<Transaction>>{};
  // We already iterated transactions above for category totals and income/expense.
  // We can reuse the loop? Or just iterate again for 'transactionsByDate' needed for balance walk-back.
  // Actually, 'params.transactions' iteration above (lines 538-588) was doing Category Totals AND Income/Expense.
  // To keep it clean, let's just group them by date here.
  for (final transaction in params.transactions) {
    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    transactionsByDate.putIfAbsent(date, () => []).add(transaction);
  }
  sectionStopwatch.reset();

  // Section 4: Net Worth walk-back (THE BOTTLENECK)
  sectionStopwatch.start();
  final today = DateTime.now();
  final start = params.dateRangeStart;

  var iterDate = DateTime(today.year, today.month, today.day);
  final historyLimit = DateTime(start.year, start.month, start.day);
  final selectedDayNormalized = DateTime(
    params.selectedDay.year,
    params.selectedDay.month,
    params.selectedDay.day,
  );

  // SPECIAL CASE: If selected day is in the future (after today),
  // use FinanceCalculator directly since walk-back won't reach it
  if (selectedDayNormalized.isAfter(iterDate)) {
    final financeCalc = FinanceCalculator();
    final snapshot = FinancialSnapshot(
      accounts: params.accounts,
      transactions: params.transactions,
      assetData: params.assetData,
      categories: [], // Not needed for balance calc
      exchangeRates: params.rates,
      inflationRates: [], // Not needed for balance calc
      date: params.selectedDay,
      dateStep: DateStep.day,
      baseCurrency: params.mainCurrencyCode,
    );

    // For future dates, calculate balances using FinanceCalculator
    // This handles both standard accounts (with future transactions if any)
    // and asset-linked accounts (with last known price)
    dayBalances = financeCalc.calculateBalances(snapshot);

    // FIX: Force 0 balance for accounts not yet created (Consistency for future dates)
    for (final account in params.accounts) {
      final creationDate = DateTime(
        account.creationDate.year,
        account.creationDate.month,
        account.creationDate.day,
      );
      // Use selectedDayNormalized which is the date projected
      if (selectedDayNormalized.isBefore(creationDate)) {
        dayBalances[account.id!] = 0.0;
      }
    }
  }

  int daysIterated = 0;

  // Pre-create FinanceCalculator and reusable snapshot base
  final financeCalc = FinanceCalculator();
  final hasAssetAccounts = params.accounts.any((a) => a.assetId != null);

  // OPTIMIZATION: Pre-build a single FinancialSnapshot for asset accounts.
  // Inside the loop, use copyWith(date: iterDate) to avoid re-allocating
  // all the same list references on every iteration that needs a recompute.
  final baseSnapshot = hasAssetAccounts
      ? FinancialSnapshot(
          accounts: params.accounts,
          transactions: params.transactions,
          assetData: params.assetData,
          categories: [],
          exchangeRates: params.rates,
          inflationRates: [],
          date: DateTime.now(), // Placeholder; overridden per-iteration via copyWith
          dateStep: DateStep.day,
          baseCurrency: params.mainCurrencyCode,
        )
      : null;

  // OPTIMIZATION: Pre-compute sets of dates with changes to enable skipping
  // days where nothing changed (avoids expensive FinancialSnapshot creation).
  // Logic: when walking backwards from D+1 to D, if D+1 had no transactions
  // and no asset price changes, then calculateBalances(D) == calculateBalances(D+1).
  final transactionDates = <DateTime>{};
  for (final tx in params.transactions) {
    transactionDates.add(DateTime(tx.date.year, tx.date.month, tx.date.day));
  }

  final assetDataDates = <DateTime>{};
  if (hasAssetAccounts) {
    for (final ad in params.assetData) {
      assetDataDates.add(DateTime(ad.date.year, ad.date.month, ad.date.day));
    }
  }

  // Cache for asset balances: reuse when no transactions or asset price changes occurred
  Map<String, double>? cachedAssetBalances;
  DateTime? prevIterDate; // The date of the previous (next-day) iteration

  // Normalize dateRangeEnd for breakdown calculation
  final dateRangeEndNormalized = DateTime(
    params.dateRangeEnd.year,
    params.dateRangeEnd.month,
    params.dateRangeEnd.day,
  );

  while (iterDate.isAfter(historyLimit) ||
      iterDate.isAtSameMomentAs(historyLimit)) {
    double totalNetWorth = 0.0;
    Map<String, double> balancesForDay;

    if (hasAssetAccounts) {
      // OPTIMIZATION: Skip expensive FinancialSnapshot creation when nothing changed.
      // calculateBalances(D) == calculateBalances(D+1) when D+1 had no transactions
      // and no asset price entries (since both use the same latest price up to D).
      final prevDayHadTransaction =
          prevIterDate != null && transactionDates.contains(prevIterDate);
      final prevDayHadAssetPrice =
          prevIterDate != null && assetDataDates.contains(prevIterDate);

      if (cachedAssetBalances != null &&
          !prevDayHadTransaction &&
          !prevDayHadAssetPrice) {
        // Reuse cached balances — nothing changed between this day and the next
        balancesForDay = Map.of(cachedAssetBalances);
      } else {
        // OPTIMIZATION: Reuse pre-built snapshot; only override the date.
        // This avoids re-allocating all the same list references on every iteration.
        final snapshot = baseSnapshot!.copyWith(date: iterDate);
        balancesForDay = financeCalc.calculateBalances(snapshot);
        cachedAssetBalances = Map.of(balancesForDay);
      }
    } else {
      // Use walk-back logic for standard accounts (faster)
      balancesForDay = Map.of(currentBalances);
    }

    // FIX: Force 0 balance for accounts not yet created
    // This handles the "Initial Balance" issue where walk-back preserves
    // the initial amount into the past before the account existed.
    for (final account in params.accounts) {
      final creationDate = DateTime(
        account.creationDate.year,
        account.creationDate.month,
        account.creationDate.day,
      );
      if (iterDate.isBefore(creationDate)) {
        balancesForDay[account.id!] = 0.0;
      }
    }

    // Calculate total net worth with converted values
    for (final account in params.accounts) {
      final balance = balancesForDay[account.id!] ?? 0.0;
      totalNetWorth += converter.convert(
        amount: balance,
        from: account.currencyCode,
        to: params.mainCurrencyCode,
        date: conversionDate,
      );
    }

    // OPTIMIZATION: For yearly view, only store monthly data points (last day of each month).
    // Walk-back still iterates daily for balance accuracy, but chart only needs 12 points.
    // Always store: selectedDay, dateRangeEnd, and last day of each month (for yearly).
    final isSelectedDay = iterDate.year == params.selectedDay.year &&
        iterDate.month == params.selectedDay.month &&
        iterDate.day == params.selectedDay.day;
    final isDateRangeEnd = iterDate.isAtSameMomentAs(dateRangeEndNormalized);
    final isLastDayOfMonth =
        iterDate.add(const Duration(days: 1)).day == 1;
    final shouldStoreChartPoint = params.dateStep != DateStep.year ||
        isLastDayOfMonth ||
        isSelectedDay ||
        isDateRangeEnd ||
        iterDate.isAtSameMomentAs(historyLimit);

    if (shouldStoreChartPoint) {
      dailyNetWorth[iterDate] = totalNetWorth;
      dailyAccountBalances[iterDate] = balancesForDay;
    }

    // Capture balances for the selectedDay (for DayBalanceDetails)
    if (isSelectedDay) {
      dayBalances = Map.of(balancesForDay);
    }

    // Capture breakdowns at dateRangeEnd (for pie charts showing period-end state)
    if (iterDate.isAtSameMomentAs(dateRangeEndNormalized) ||
        (iterDate.isBefore(dateRangeEndNormalized) &&
            currencyBreakdown.isEmpty)) {
      // Compute breakdowns with CONVERTED values
      for (final account in params.accounts) {
        final accountId = account.id!;
        final nativeBalance = balancesForDay[accountId] ?? 0.0;
        final currency = account.currencyCode;

        if (nativeBalance > 0) {
          final convertedValue = converter.convert(
            amount: nativeBalance,
            from: currency,
            to: params.mainCurrencyCode,
            date: iterDate,
          );

          // Currency Breakdown
          currencyBreakdown.update(
            currency,
            (v) => v + convertedValue,
            ifAbsent: () => convertedValue,
          );

          // Account Breakdown
          accountBreakdown[accountId] = convertedValue;
        }
      }
    }

    // Walk-back for non-asset accounts (update currentBalances for next iteration)
    if (!hasAssetAccounts) {
      final dayTransactions = transactionsByDate[iterDate] ?? [];
      for (final transaction in dayTransactions) {
        if (currentBalances.containsKey(transaction.accountId)) {
          currentBalances[transaction.accountId] =
              (currentBalances[transaction.accountId]!) - transaction.amount;
        }
      }
    }

    prevIterDate = iterDate; // Track for next iteration's skip optimization
    iterDate = iterDate.subtract(const Duration(days: 1));
    daysIterated++;
  }
  debugPrint(
    'COMPUTE: Net Worth walk-back ($daysIterated days, ${params.accounts.length} accounts): ${sectionStopwatch.elapsedMilliseconds}ms',
  );

  totalStopwatch.stop();
  debugPrint('COMPUTE: TOTAL: ${totalStopwatch.elapsedMilliseconds}ms');

  return _DashboardComputeResults(
    dailyIncomes: dailyIncomes,
    dailyExpenses: dailyExpenses,
    dailyNetWorth: dailyNetWorth,
    dayBalances: dayBalances,
    dailyAccountBalances: dailyAccountBalances,
    currencyBreakdown: currencyBreakdown, // Added
    accountBreakdown: accountBreakdown, // Added
    categoryTotals: [],
  );
}
