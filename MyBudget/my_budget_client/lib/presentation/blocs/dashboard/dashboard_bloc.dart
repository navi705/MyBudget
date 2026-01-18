import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart'; // Added
import 'package:my_budget_client/core/utils/performance_logger.dart';

import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
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
        ).debounceTime(const Duration(milliseconds: 300)).asyncMap((
          data,
        ) async {
          final accounts = data.accounts;
          final transactions = data.transactions;
          final categories = data.categories;
          final styles = data.styles;
          final params = data.params;

          PerformanceLogger().start('Dashboard: balances, totals, settings');
          final dayBalances = await _accountRepository.getBalancesAtDate(
            params.selectedDay,
          );
          final categoryTotals = await _transactionRepository
              .getTransactionTotalsGrouped(
                dateFrom: params.dateRangeStart,
                dateTo: params.dateRangeEnd,
              );

          final settingsMap = await _settingsRepository.getAllSettings();
          final mainCurrencyCode = settingsMap['main_currency_code'] ?? 'USD';

          final targetCurrency = params.selectedCurrency.isEmpty
              ? mainCurrencyCode
              : params.selectedCurrency;

          await PerformanceLogger().stop(
            'Dashboard: balances, totals, settings',
          );

          PerformanceLogger().start('Dashboard: getLatestExchangeRatesByList');
          final now = DateTime.now();
          final exchangeRates = await _currencyRepository
              .getLatestExchangeRatesByList(
                _getDateRangeList(params.dateRangeStart, now),
              );
          await PerformanceLogger().stop(
            'Dashboard: getLatestExchangeRatesByList',
          );

          PerformanceLogger().start('Dashboard: compute');

          // Optimize: Pre-build Rate Map
          final rateMap = _buildRateMap(exchangeRates);

          final computeParams = _DashboardComputeParams(
            accounts: accounts,
            transactions: transactions,
            rateMap: rateMap,
            mainCurrencyCode: targetCurrency,
            dateRangeStart: params.dateRangeStart,
            selectedDay: params.selectedDay,
          );
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
            dayBalances: dayBalances,
            categoryTotals: categoryTotals,
            dailyIncomes: computeResults.dailyIncomes,
            dailyExpenses: computeResults.dailyExpenses,
            dailyNetWorth: computeResults.dailyNetWorth,
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

  List<DateTime> _getDateRangeList(DateTime start, DateTime end) {
    final list = <DateTime>[];
    var current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);
    while (current.isBefore(last) || current.isAtSameMomentAs(last)) {
      list.add(current);
      current = current.add(const Duration(days: 1));
    }
    return list;
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
  final Map<String, Map<String, Map<int, double>>> rateMap;
  final String mainCurrencyCode;
  final DateTime dateRangeStart;
  final DateTime selectedDay; // Added parameter definition

  _DashboardComputeParams({
    required this.accounts,
    required this.transactions,
    required this.rateMap,
    required this.mainCurrencyCode,
    required this.dateRangeStart,
    required this.selectedDay, // Added
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

Map<String, Map<String, Map<int, double>>> _buildRateMap(
  List<ExchangeRateDomain> rates,
) {
  final map = <String, Map<String, Map<int, double>>>{};
  for (final r in rates) {
    final dateKey = DateTime(
      r.date.year,
      r.date.month,
      r.date.day,
    ).millisecondsSinceEpoch;

    // Forward
    map
            .putIfAbsent(r.fromCurrencyCode, () => {})
            .putIfAbsent(r.toCurrencyCode, () => {})[dateKey] =
        r.rate;

    // Reverse (1/rate)
    if (r.rate != 0) {
      map
              .putIfAbsent(r.toCurrencyCode, () => {})
              .putIfAbsent(r.fromCurrencyCode, () => {})[dateKey] =
          1.0 / r.rate;
    }
  }
  return map;
}

_DashboardComputeResults _calculateDashboardData(
  _DashboardComputeParams params,
) {
  final dailyIncomes = <DateTime, double>{};
  final dailyExpenses = <DateTime, double>{};
  final dailyNetWorth = <DateTime, double>{};
  Map<String, double> dayBalances = {}; // Initialize

  for (final transaction in params.transactions) {
    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    if (transaction.amount > 0) {
      dailyIncomes.update(
        date,
        (v) => v + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    } else if (transaction.amount < 0) {
      dailyExpenses.update(
        date,
        (v) => v + transaction.amount.abs(),
        ifAbsent: () => transaction.amount.abs(),
      );
    }
  }

  final currentBalances = <String, double>{};
  for (final account in params.accounts) {
    currentBalances[account.id!] = account.balance;
  }

  // Pre-group transactions by date for faster lookup during net worth walk-back
  final transactionsByDate = <DateTime, List<Transaction>>{};
  for (final transaction in params.transactions) {
    final date = DateTime(
      transaction.date.year,
      transaction.date.month,
      transaction.date.day,
    );
    transactionsByDate.putIfAbsent(date, () => []).add(transaction);
  }

  final today = DateTime.now();
  final start = params.dateRangeStart;

  var iterDate = DateTime(today.year, today.month, today.day);
  final historyLimit = DateTime(start.year, start.month, start.day);

  while (iterDate.isAfter(historyLimit) ||
      iterDate.isAtSameMomentAs(historyLimit)) {
    double totalNetWorth = 0.0;
    final dateKey = iterDate.millisecondsSinceEpoch;

    for (final account in params.accounts) {
      final balance = currentBalances[account.id!] ?? 0.0;
      if (account.currencyCode == params.mainCurrencyCode) {
        totalNetWorth += balance;
      } else {
        final rate = _getRateFromMap(
          params.rateMap,
          account.currencyCode,
          params.mainCurrencyCode,
          dateKey,
        );
        totalNetWorth += balance * rate;
      }
    }

    dailyNetWorth[iterDate] = totalNetWorth;

    // Capture dayBalances if this is the selected day
    if (iterDate.year == params.selectedDay.year &&
        iterDate.month == params.selectedDay.month &&
        iterDate.day == params.selectedDay.day) {
      for (final account in params.accounts) {
        final balance = currentBalances[account.id!] ?? 0.0;
        double convertedHelper = balance;
        if (account.currencyCode != params.mainCurrencyCode) {
          convertedHelper =
              balance *
              _getRateFromMap(
                params.rateMap,
                account.currencyCode,
                params.mainCurrencyCode,
                dateKey,
              );
        }
        dayBalances[account.id!] = convertedHelper;
      }
    }

    // Use pre-grouped transactions for better performance
    final dayTransactions = transactionsByDate[iterDate] ?? [];
    for (final transaction in dayTransactions) {
      if (currentBalances.containsKey(transaction.accountId)) {
        currentBalances[transaction.accountId] =
            (currentBalances[transaction.accountId]!) - transaction.amount;
      }
    }

    iterDate = iterDate.subtract(const Duration(days: 1));
  }

  // If selectedDay was NOT found (e.g. today or future relative to loop context, or very old),
  // we might need fallback. But loop starts at 'today'.
  // If params.selectedDay is 'today', it should match first iteration.

  return _DashboardComputeResults(
    dailyIncomes: dailyIncomes,
    dailyExpenses: dailyExpenses,
    dailyNetWorth: dailyNetWorth,
    dayBalances: dayBalances,
  );
}

double _getRateFromMap(
  Map<String, Map<String, Map<int, double>>> map,
  String from,
  String to,
  int dateKey,
) {
  if (from == to) return 1.0;
  final ratesFrom = map[from];
  if (ratesFrom != null) {
    final ratesTo = ratesFrom[to];
    if (ratesTo != null) {
      final rate = ratesTo[dateKey];
      if (rate != null) return rate;
    }
  }
  return 1.0;
}
