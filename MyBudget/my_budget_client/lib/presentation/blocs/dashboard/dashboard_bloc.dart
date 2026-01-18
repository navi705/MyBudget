import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
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
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
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

  // Parameters stream
  final _paramsSubject = BehaviorSubject<_DashboardParams>.seeded(
    _DashboardParams(
      activeTabIndex: 0,
      selectedDay: DateTime.now(),
      dateRangeStart: DateTime.now().subtract(const Duration(days: 30)),
      dateRangeEnd: DateTime.now(),
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

  DashboardBloc({
    required AccountRepository accountRepository,
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
    required StyleRepository styleRepository,
    required CurrencyRepository currencyRepository,
    required SettingsRepository settingsRepository,
  }) : _accountRepository = accountRepository,
       _transactionRepository = transactionRepository,
       _categoryRepository = categoryRepository,
       _styleRepository = styleRepository,
       _currencyRepository = currencyRepository,
       _settingsRepository = settingsRepository,
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

    final stream =
        Rx.combineLatest5(
          _accountRepository.watchAccounts(),
          _transactionRepository.watchTransactions(),
          _categoryRepository.watchCategories(),
          _styleRepository.watchAllStyles(),
          _paramsSubject.stream,
          (
            List<Account> accounts,
            List<Transaction> transactions,
            List<Category> categories,
            List<Style> styles,
            _DashboardParams params,
          ) {
            return _DashboardStreamData(
              accounts: accounts,
              transactions: transactions,
              categories: categories,
              styles: styles,
              params: params,
            );
          },
          // OPTIMIZATION: Reduced debounce from 300ms to 50ms
          // 300ms was adding noticeable delay, 50ms is enough to batch rapid changes
        ).debounceTime(const Duration(milliseconds: 50)).asyncMap((data) async {
          final accounts = data.accounts;
          final transactions = data.transactions;
          final categories = data.categories;
          final styles = data.styles;
          final params = data.params;

          // OPTIMIZATION: Run DB queries in parallel
          PerformanceLogger().start('Dashboard: balances, totals, settings');

          final parallelDbResults = await Future.wait([
            _accountRepository.getBalancesAtDate(params.selectedDay),
            _transactionRepository.getTransactionTotalsGrouped(
              dateFrom: params.dateRangeStart,
              dateTo: params.dateRangeEnd,
            ),
            _settingsRepository.getAllSettings(),
            _currencyRepository.getAllCurrencyDesignations(), // Added
          ]);

          final rawDayBalances = parallelDbResults[0] as Map<String, double>;
          final categoryTotals =
              parallelDbResults[1] as List<GroupedTransactionTotal>;
          final settingsMap = parallelDbResults[2] as Map<String, String>;
          final currencyDesignationsList =
              parallelDbResults[3] as List<CurrencyDesignation>; // Added

          final currencyDesignations = {
            for (final d in currencyDesignationsList) d.id: d,
          }; // Added

          final mainCurrencyCode = settingsMap['main_currency_code'] ?? 'USD';

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
          uniqueDates.add(
            DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
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
            print('CACHE HIT: Using cached rates and currencies');
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
            if (_cachedCurrencies == null) {
              _cachedCurrencies = results[idx++] as List<Currency>;
            }
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

            print('CACHE MISS: Fetched ${missingDates.length} new dates');
          }

          await PerformanceLogger().stop('Dashboard: Parallel Fetch');

          PerformanceLogger().start('Dashboard: compute');

          // OPTIMIZATION: Cache CurrencyConverter - only recreate when rates change
          if (_cachedConverter == null || missingDates.isNotEmpty) {
            _cachedConverter = CurrencyConverter(exchangeRates);
            print('CONVERTER: Created new (rates changed)');
          } else {
            print('CONVERTER: Using cached');
          }

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
            selectedDay: params.selectedDay,
            categoryTypeMap: categoryTypeMap,
            converter: _cachedConverter!, // Pass cached converter
          );

          // Convert balances ensuring all accounts are covered (even if outside net worth graph range)
          final convertedDayBalances = <String, double>{};
          for (final account in accounts) {
            final rawBalance = rawDayBalances[account.id] ?? 0.0;
            convertedDayBalances[account.id!] = _cachedConverter!.convert(
              amount: rawBalance,
              from: account.currencyCode,
              to: targetCurrency,
              date: DateTime.now(), // Current exchange rate
            );
          }

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

          // OPTIMIZATION: Run on main thread instead of compute() isolate
          // Reason: Actual work is only ~27ms, but compute() overhead is ~350ms
          // 27ms won't block the UI, so isolate is not justified
          final computeResults = _calculateDashboardData(computeParams);

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
            dayBalances: convertedDayBalances,
            categoryTotals: categoryTotals,
            categoryConvertedTotals: categoryConvertedTotals, // Added
            dailyIncomes: computeResults.dailyIncomes,
            dailyExpenses: computeResults.dailyExpenses,
            dailyNetWorth: computeResults.dailyNetWorth,
            availableCurrencies: availableCurrencies,
            currencyDesignations: currencyDesignations, // Added
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
    _paramsSubject.add(_paramsSubject.value.copyWith(selectedDay: event.day));
  }

  void _onToggleChartType(ToggleChartType event, Emitter<DashboardState> emit) {
    _paramsSubject.add(
      _paramsSubject.value.copyWith(isIncomeView: event.isIncome),
    );
  }

  void _onChangeDateStep(ChangeDateStep event, Emitter<DashboardState> emit) {
    _paramsSubject.add(_paramsSubject.value.copyWith(dateStep: event.step));
  }

  void _onChangeCurrency(ChangeCurrency event, Emitter<DashboardState> emit) {
    _paramsSubject.add(
      _paramsSubject.value.copyWith(selectedCurrency: event.currencyCode),
    );
  }

  @override
  Future<void> close() {
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

  _DashboardParams({
    required this.activeTabIndex,
    required this.selectedDay,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.dateStep,
    required this.selectedCurrency, // Added
    required this.isIncomeView,
  });

  _DashboardParams copyWith({
    int? activeTabIndex,
    DateTime? selectedDay,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    DateStep? dateStep,
    String? selectedCurrency, // Added
    bool? isIncomeView,
  }) {
    return _DashboardParams(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      selectedDay: selectedDay ?? this.selectedDay,
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      dateStep: dateStep ?? this.dateStep,
      selectedCurrency: selectedCurrency ?? this.selectedCurrency, // Added
      isIncomeView: isIncomeView ?? this.isIncomeView,
    );
  }
}

class _DashboardStreamData {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<Category> categories;
  final List<Style> styles;
  final _DashboardParams params;

  _DashboardStreamData({
    required this.accounts,
    required this.transactions,
    required this.categories,
    required this.styles,
    required this.params,
  });
}

class _DashboardComputeParams {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<ExchangeRateDomain> rates;
  final String mainCurrencyCode;
  final DateTime dateRangeStart;
  final DateTime selectedDay;
  final Map<String, CategoryType> categoryTypeMap;
  final CurrencyConverter converter; // OPTIMIZATION: Pre-built converter

  _DashboardComputeParams({
    required this.accounts,
    required this.transactions,
    required this.rates,
    required this.mainCurrencyCode,
    required this.dateRangeStart,
    required this.selectedDay,
    required this.categoryTypeMap,
    required this.converter,
  });
}

class _DashboardComputeResults {
  final Map<DateTime, double> dailyIncomes;
  final Map<DateTime, double> dailyExpenses;
  final Map<DateTime, double> dailyNetWorth;
  final Map<String, double> dayBalances; // Added
  final List<GroupedTransactionTotal>
  categoryTotals; // Added - wait, I need to add/ensure this is handled

  _DashboardComputeResults({
    required this.dailyIncomes,
    required this.dailyExpenses,
    required this.dailyNetWorth,
    required this.dayBalances,
    this.categoryTotals = const [], // Default for now if not computed
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
  print(
    'COMPUTE: CurrencyConverter (from cache): ${sectionStopwatch.elapsedMilliseconds}ms',
  );
  sectionStopwatch.reset();

  final dailyIncomes = <DateTime, double>{};
  final dailyExpenses = <DateTime, double>{};
  final dailyNetWorth = <DateTime, double>{};
  Map<String, double> dayBalances = {};

  final currentBalances = <String, double>{};
  final accountCurrencyMap = <String, String>{};
  final accountAssetMap = <String, bool>{};

  for (final account in params.accounts) {
    currentBalances[account.id!] = account.balance;
    accountCurrencyMap[account.id!] = account.currencyCode;
    accountAssetMap[account.id!] = account.assetId != null;
  }

  // Section 2: Income/Expense loop
  sectionStopwatch.start();
  for (final transaction in params.transactions) {
    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );

    final transactionCurrency = transaction.currencyCode;
    final convertedAmount = converter.convert(
      amount: transaction.amount,
      from: transactionCurrency,
      to: params.mainCurrencyCode,
      date: date,
    );

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
  print(
    'COMPUTE: Income/Expense loop (${params.transactions.length} txs): ${sectionStopwatch.elapsedMilliseconds}ms',
  );
  sectionStopwatch.reset();

  // Section 3: Pre-group transactions
  sectionStopwatch.start();
  final transactionsByDate = <DateTime, List<Transaction>>{};
  for (final transaction in params.transactions) {
    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    transactionsByDate.putIfAbsent(date, () => []).add(transaction);
  }
  print(
    'COMPUTE: Pre-group transactions: ${sectionStopwatch.elapsedMilliseconds}ms',
  );
  sectionStopwatch.reset();

  // Section 4: Net Worth walk-back (THE BOTTLENECK)
  sectionStopwatch.start();
  final today = DateTime.now();
  final start = params.dateRangeStart;

  var iterDate = DateTime(today.year, today.month, today.day);
  final historyLimit = DateTime(start.year, start.month, start.day);
  int daysIterated = 0;

  while (iterDate.isAfter(historyLimit) ||
      iterDate.isAtSameMomentAs(historyLimit)) {
    double totalNetWorth = 0.0;

    for (final account in params.accounts) {
      final balance = currentBalances[account.id!] ?? 0.0;
      totalNetWorth += converter.convert(
        amount: balance,
        from: account.currencyCode,
        to: params.mainCurrencyCode,
        date: conversionDate,
      );
    }

    dailyNetWorth[iterDate] = totalNetWorth;

    if (iterDate.year == params.selectedDay.year &&
        iterDate.month == params.selectedDay.month &&
        iterDate.day == params.selectedDay.day) {
      // Logic for dayBalances moved to main isolate to ensure coverage for all dates
    }

    final dayTransactions = transactionsByDate[iterDate] ?? [];
    for (final transaction in dayTransactions) {
      if (currentBalances.containsKey(transaction.accountId)) {
        currentBalances[transaction.accountId] =
            (currentBalances[transaction.accountId]!) - transaction.amount;
      }
    }

    iterDate = iterDate.subtract(const Duration(days: 1));
    daysIterated++;
  }
  print(
    'COMPUTE: Net Worth walk-back ($daysIterated days, ${params.accounts.length} accounts): ${sectionStopwatch.elapsedMilliseconds}ms',
  );

  totalStopwatch.stop();
  print('COMPUTE: TOTAL: ${totalStopwatch.elapsedMilliseconds}ms');

  return _DashboardComputeResults(
    dailyIncomes: dailyIncomes,
    dailyExpenses: dailyExpenses,
    dailyNetWorth: dailyNetWorth,
    dayBalances: dayBalances,
  );
}
