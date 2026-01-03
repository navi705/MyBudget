import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' as foundation;
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
  }
  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    PerformanceLogger().start('Dashboard Screen Load');
    emit(DashboardLoadInProgress());

    final stream = Rx.combineLatest5(
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
      ) async {
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

        final now = DateTime.now();
        final exchangeRates = await _currencyRepository
            .getLatestExchangeRatesByList(
              _getDateRangeList(params.dateRangeStart, now),
            );

        // Offload heavy data processing to background isolate
        final computeResults = await foundation.compute(
          _calculateDashboardData,
          _DashboardComputeParams(
            accounts: accounts,
            transactions: transactions,
            exchangeRates: exchangeRates,
            mainCurrencyCode: mainCurrencyCode,
            dateRangeStart: params.dateRangeStart,
          ),
        );

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
          isIncomeView: params.isIncomeView,
          dayBalances: dayBalances,
          categoryTotals: categoryTotals,
          dailyIncomes: computeResults.dailyIncomes,
          dailyExpenses: computeResults.dailyExpenses,
          dailyNetWorth: computeResults.dailyNetWorth,
        );
      },
    ).flatMap((future) => Stream.fromFuture(future));

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
  final bool isIncomeView;

  _DashboardParams({
    required this.activeTabIndex,
    required this.selectedDay,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.isIncomeView,
  });

  _DashboardParams copyWith({
    int? activeTabIndex,
    DateTime? selectedDay,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    bool? isIncomeView,
  }) {
    return _DashboardParams(
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      selectedDay: selectedDay ?? this.selectedDay,
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      isIncomeView: isIncomeView ?? this.isIncomeView,
    );
  }
}

class _DashboardComputeParams {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<ExchangeRateDomain> exchangeRates;
  final String mainCurrencyCode;
  final DateTime dateRangeStart;

  _DashboardComputeParams({
    required this.accounts,
    required this.transactions,
    required this.exchangeRates,
    required this.mainCurrencyCode,
    required this.dateRangeStart,
  });
}

class _DashboardComputeResults {
  final Map<DateTime, double> dailyIncomes;
  final Map<DateTime, double> dailyExpenses;
  final Map<DateTime, double> dailyNetWorth;

  _DashboardComputeResults({
    required this.dailyIncomes,
    required this.dailyExpenses,
    required this.dailyNetWorth,
  });
}

_DashboardComputeResults _calculateDashboardData(
  _DashboardComputeParams params,
) {
  final dailyIncomes = <DateTime, double>{};
  final dailyExpenses = <DateTime, double>{};
  final dailyNetWorth = <DateTime, double>{};

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

    for (final account in params.accounts) {
      final balance = currentBalances[account.id!] ?? 0.0;
      if (account.currencyCode == params.mainCurrencyCode) {
        totalNetWorth += balance;
      } else {
        final rate = _getRateForDateIsolate(
          params.exchangeRates,
          account.currencyCode,
          params.mainCurrencyCode,
          iterDate,
        );
        totalNetWorth += balance * rate;
      }
    }

    dailyNetWorth[iterDate] = totalNetWorth;

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

  return _DashboardComputeResults(
    dailyIncomes: dailyIncomes,
    dailyExpenses: dailyExpenses,
    dailyNetWorth: dailyNetWorth,
  );
}

double _getRateForDateIsolate(
  List<ExchangeRateDomain> rates,
  String from,
  String to,
  DateTime date,
) {
  if (from == to) return 1.0;
  final d = DateTime(date.year, date.month, date.day);

  // Note: Using a simple find here, but could be optimized if rates list is large
  for (final r in rates) {
    if (r.fromCurrencyCode == from &&
        r.toCurrencyCode == to &&
        DateTime(r.date.year, r.date.month, r.date.day).isAtSameMomentAs(d)) {
      return r.rate;
    }
    if (r.fromCurrencyCode == to &&
        r.toCurrencyCode == from &&
        DateTime(r.date.year, r.date.month, r.date.day).isAtSameMomentAs(d)) {
      return 1.0 / r.rate;
    }
  }

  return 1.0;
}
