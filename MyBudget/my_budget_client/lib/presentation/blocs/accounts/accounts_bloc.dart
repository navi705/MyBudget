import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:bloc/bloc.dart';
import 'package:my_budget_client/core/utils/performance_logger.dart';

import 'package:equatable/equatable.dart';
import 'package:my_budget_client/core/utils/device_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final AccountRepository _accountRepository;
  final SettingsRepository _settingsRepository;
  final CurrencyRepository _currencyRepository;
  final InflationRepository _inflationRepository;
  final TransactionRepository _transactionRepository;

  StreamSubscription<List<Transaction>>? _transactionsSubscription;

  AccountsBloc({
    required AccountRepository accountRepository,
    required SettingsRepository settingsRepository,
    required CurrencyRepository currencyRepository,
    required InflationRepository inflationRepository,
    required TransactionRepository transactionRepository,
  }) : _accountRepository = accountRepository,
       _settingsRepository = settingsRepository,
       _currencyRepository = currencyRepository,
       _inflationRepository = inflationRepository,
       _transactionRepository = transactionRepository,
       super(AccountsInitial()) {
    on<LoadAccounts>(_onLoadAccounts);
    on<LoadMoreAccounts>(_onLoadMoreAccounts);
    on<AddAccount>(_onAddAccount);
    on<UpdateAccount>(_onUpdateAccount);
    on<DeleteAccount>(_onDeleteAccount);
    on<UndoDeleteAccount>(_onUndoDeleteAccount);
    on<SortAccounts>(_onSortAccounts);
    on<FiltersChanged>(_onFiltersChanged);
    on<LoadHistoricalBalances>(_onLoadHistoricalBalances);
    on<ClearHistoricalBalances>(_onClearHistoricalBalances);
    on<ToggleSelectionMode>(_onToggleSelectionMode);
    on<ToggleAccountSelection>(_onToggleAccountSelection);
    on<SelectAllAccounts>(_onSelectAllAccounts);
    on<ClearSelection>(_onClearSelection);
    on<DeleteMultipleAccounts>(_onDeleteMultipleAccounts);
    on<UpdateAccountTypeForMultipleAccounts>(
      _onUpdateAccountTypeForMultipleAccounts,
    );
    on<DatePeriodNavigated>(_onDatePeriodNavigated);
    on<DateStepChanged>(_onDateStepChanged);
    on<ActiveDateChanged>(_onActiveDateChanged);

    _transactionsSubscription = _transactionRepository
        .watchTransactions()
        .listen((_) => add(LoadAccounts()));
  }

  @override
  Future<void> close() {
    _transactionsSubscription?.cancel();
    return super.close();
  }

  List<Account> _sortAccounts(
    List<Account> accounts,
    List<ExchangeRateDomain> rates,
    bool ascending,
  ) {
    final Map<String, double> rateMap = {
      for (var r in rates) r.toCurrencyCode: r.rate,
    };
    rateMap['EUR'] = 1.0; // Assume EUR is the base and has a rate of 1.0

    accounts.sort((a, b) {
      final aRate = rateMap[a.currencyCode];
      final bRate = rateMap[b.currencyCode];

      if (aRate == null || aRate == 0) {
        return 1; // move a to the end
      }
      if (bRate == null || bRate == 0) {
        return -1; // move b to the end
      }

      final aValueInBase = a.balance / aRate;
      final bValueInBase = b.balance / bRate;

      final comparison = aValueInBase.compareTo(bValueInBase);
      return ascending ? comparison : -comparison;
    });
    return accounts;
  }

  void _onDatePeriodNavigated(
    DatePeriodNavigated event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess) return;

    DateTime newDate;
    switch (currentState.dateStep) {
      case DateStep.day:
        newDate = currentState.activeDate.add(Duration(days: event.direction));
        break;
      case DateStep.month:
        newDate = DateTime(
          currentState.activeDate.year,
          currentState.activeDate.month + event.direction,
          currentState.activeDate.day,
        );
        break;
      case DateStep.year:
        newDate = DateTime(
          currentState.activeDate.year + event.direction,
          currentState.activeDate.month,
          currentState.activeDate.day,
        );
        break;
    }
    emit(currentState.copyWith(activeDate: newDate));
    add(LoadHistoricalBalances(newDate));
  }

  void _onDateStepChanged(DateStepChanged event, Emitter<AccountsState> emit) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(currentState.copyWith(dateStep: event.dateStep));
      add(LoadHistoricalBalances(currentState.activeDate));
    }
  }

  void _onActiveDateChanged(
    ActiveDateChanged event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(currentState.copyWith(activeDate: event.date));
      add(LoadHistoricalBalances(event.date));
    }
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    PerformanceLogger().start('Accounts Screen Load');
    final currentState = state;
    emit(AccountsLoadInProgress());
    try {
      var filters = currentState.filters;
      final savedFilters = await _settingsRepository.getSetting(
        'account_filters',
      );
      if (savedFilters != null) {
        filters = AccountFilters.fromJsonString(savedFilters.value);
      }

      PerformanceLogger().start('Accounts: Future.wait');
      final results = await Future.wait([
        _accountRepository.getAccountTypes(),
        _accountRepository.getAccountsPaginatedFiltered(
          limit: currentState.limit,
          offset: 0,
          accountFilters: filters,
        ),
        _accountRepository.getCountWithFilters(
          accountTypeIds: filters.accountTypeIds,
        ),
        _currencyRepository.getLatestExchangeRates(DateTime.now()),
        _inflationRepository.getInflationRates(),
      ]);
      await PerformanceLogger().stop('Accounts: Future.wait');

      final accountTypes = results[0] as List<AccountType>;
      final accounts = results[1] as List<Account>;
      final totalCount = results[2] as int;
      final exchangeRates = results[3] as List<ExchangeRateDomain>;
      final inflationRates = results[4] as List<InflationRateDomain>;

      final sortedAccounts = _sortAccounts(
        accounts,
        exchangeRates,
        filters.sort == Sort.ascending,
      );

      final accountIds = sortedAccounts
          .map((e) => e.id)
          .whereType<String>()
          .toList();

      PerformanceLogger().start('Accounts: getTransactionsWithFilters');
      final allTransactions = await _transactionRepository
          .getTransactionsWithFilters(
            filters: TransactionFilters(accountId: accountIds),
            limit: 1000000,
          );
      await PerformanceLogger().stop('Accounts: getTransactionsWithFilters');

      final defaultCountrySetting = await _settingsRepository.getSetting(
        'default_inflation_country',
      );
      final defaultCountry = defaultCountrySetting?.value ?? 'SRB';

      PerformanceLogger().start('Accounts: compute inflation');
      // Skip compute overhead for small datasets - run inline instead
      final inflationParams = _InflationParams(
        accounts: sortedAccounts,
        transactions: allTransactions,
        inflationRates: inflationRates,
        defaultCountry: defaultCountry,
      );
      final inflationResults = allTransactions.length < 100000
          ? _calculateInflationForAccounts(inflationParams)
          : await compute(_calculateInflationForAccounts, inflationParams);
      await PerformanceLogger().stop('Accounts: compute inflation');

      DateTime previousDate;
      switch (currentState.dateStep) {
        case DateStep.day:
          previousDate = currentState.activeDate.subtract(
            const Duration(days: 1),
          );
          break;
        case DateStep.month:
          previousDate = DateTime(
            currentState.activeDate.year,
            currentState.activeDate.month - 1,
            currentState.activeDate.day,
          );
          break;
        case DateStep.year:
          previousDate = DateTime(
            currentState.activeDate.year - 1,
            currentState.activeDate.month,
            currentState.activeDate.day,
          );
          break;
      }

      final previousPeriodBalances = await _accountRepository.getBalancesAtDate(
        previousDate,
      );
      final previousPeriodTransactions = await _transactionRepository
          .getTransactionsWithFilters(
            filters: TransactionFilters(
              accountId: accountIds,
              dateTo: previousDate,
            ),
            limit: 1000000,
          );

      final prevInflationParams = _InflationParams(
        accounts: sortedAccounts,
        transactions: previousPeriodTransactions,
        inflationRates: inflationRates,
        defaultCountry: defaultCountry,
      );

      final prevInflationResults = previousPeriodTransactions.length < 100000
          ? _calculateInflationForAccounts(prevInflationParams)
          : await compute(_calculateInflationForAccounts, prevInflationParams);

      DateTime p2Date;
      switch (currentState.dateStep) {
        case DateStep.day:
          p2Date = previousDate.subtract(const Duration(days: 1));
          break;
        case DateStep.month:
          p2Date = DateTime(
            previousDate.year,
            previousDate.month - 1,
            previousDate.day,
          );
          break;
        case DateStep.year:
          p2Date = DateTime(
            previousDate.year - 1,
            previousDate.month,
            previousDate.day,
          );
          break;
      }

      final currentPeriodTx = allTransactions
          .where(
            (tx) =>
                tx.date.isAfter(previousDate) &&
                    tx.date.isBefore(currentState.activeDate) ||
                tx.date.isAtSameMomentAs(currentState.activeDate),
          ) // Inclusive end? Usually exclusive start, inclusive end
          .toList();

      final previousPeriodTx = allTransactions
          .where(
            (tx) =>
                tx.date.isAfter(p2Date) && tx.date.isBefore(previousDate) ||
                tx.date.isAtSameMomentAs(previousDate),
          )
          .toList();

      final currentStats = _calculatePeriodStats(
        _InflationParams(
          accounts: sortedAccounts,
          transactions: currentPeriodTx,
          inflationRates: inflationRates,
          defaultCountry: defaultCountry,
        ),
      );

      final previousStats = _calculatePeriodStats(
        _InflationParams(
          accounts: sortedAccounts,
          transactions: previousPeriodTx,
          inflationRates: inflationRates,
          defaultCountry: defaultCountry,
        ),
      );

      // Sum totals from account stats
      double income = currentStats.income.values.fold(0, (sum, v) => sum + v);
      double expense = currentStats.expense.values.fold(0, (sum, v) => sum + v);

      await PerformanceLogger().stop('Accounts Screen Load');

      emit(
        AccountsLoadSuccess(
          accounts: sortedAccounts,
          accountTypes: accountTypes,
          hasReachedMax: accounts.length >= totalCount,
          totalCount: totalCount,
          sortAscending: filters.sort == Sort.ascending,
          filters: filters,
          activeDate: currentState.activeDate,
          isSelectionModeActive: currentState.isSelectionModeActive,
          selectedAccountIds: currentState.selectedAccountIds,
          dateStep: currentState.dateStep,
          exchangeRates: exchangeRates,
          realBalances: inflationResults.realBalances,
          inflationLosses: inflationResults.inflationLosses,
          previousPeriodBalances: previousPeriodBalances,
          previousPeriodRealBalances: prevInflationResults.realBalances,
          accountIncomes: currentStats.income,
          accountExpenses: currentStats.expense,
          accountRealIncomes: currentStats.realIncome,
          accountRealExpenses: currentStats.realExpense,
          previousAccountIncomes: previousStats.income,
          previousAccountExpenses: previousStats.expense,
          previousAccountRealIncomes: previousStats.realIncome,
          previousAccountRealExpenses: previousStats.realExpense,
          income: income,
          expense: expense,
        ),
      );
    } catch (e) {
      PerformanceLogger().stop('Accounts Screen Load');
      emit(AccountsLoadFailure());
    }
  }

  Future<void> _onLoadMoreAccounts(
    LoadMoreAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess || currentState.hasReachedMax) {
      return;
    }

    PerformanceLogger().start('Accounts Screen Load More');

    try {
      final accounts = await _accountRepository.getAccountsPaginatedFiltered(
        offset: currentState.accounts.length,
        limit: currentState.limit,
        accountFilters: currentState.filters,
      );
      if (accounts.isEmpty) {
        emit(currentState.copyWith(hasReachedMax: true));
        PerformanceLogger().stop('Accounts Screen Load More');
      } else {
        final newAccountList = List.of(currentState.accounts)..addAll(accounts);
        final sortedAccounts = _sortAccounts(
          newAccountList,
          currentState.exchangeRates,
          currentState.sortAscending,
        );

        final inflationRates = await _inflationRepository.getInflationRates();
        final accountIds = sortedAccounts
            .map((e) => e.id)
            .whereType<String>()
            .toList();

        final allTransactions = await _transactionRepository
            .getTransactionsWithFilters(
              filters: TransactionFilters(accountId: accountIds),
              limit: 1000000,
            );

        final defaultCountrySetting = await _settingsRepository.getSetting(
          'default_inflation_country',
        );
        final defaultCountry = defaultCountrySetting?.value ?? 'SRB';

        final inflationResults = await compute(
          _calculateInflationForAccounts,
          _InflationParams(
            accounts: sortedAccounts,
            transactions: allTransactions,
            inflationRates: inflationRates,
            defaultCountry: defaultCountry,
          ),
        );

        // Period Stats Calculation (Duplicated from _onLoadAccounts for now)
        DateTime previousDate;
        switch (currentState.dateStep) {
          case DateStep.day:
            previousDate = currentState.activeDate.subtract(
              const Duration(days: 1),
            );
            break;
          case DateStep.month:
            previousDate = DateTime(
              currentState.activeDate.year,
              currentState.activeDate.month - 1,
              currentState.activeDate.day,
            );
            break;
          case DateStep.year:
            previousDate = DateTime(
              currentState.activeDate.year - 1,
              currentState.activeDate.month,
              currentState.activeDate.day,
            );
            break;
        }

        DateTime p2Date;
        switch (currentState.dateStep) {
          case DateStep.day:
            p2Date = previousDate.subtract(const Duration(days: 1));
            break;
          case DateStep.month:
            p2Date = DateTime(
              previousDate.year,
              previousDate.month - 1,
              previousDate.day,
            );
            break;
          case DateStep.year:
            p2Date = DateTime(
              previousDate.year - 1,
              previousDate.month,
              previousDate.day,
            );
            break;
        }

        final currentPeriodTx = allTransactions
            .where(
              (tx) =>
                  tx.date.isAfter(previousDate) &&
                      tx.date.isBefore(currentState.activeDate) ||
                  tx.date.isAtSameMomentAs(currentState.activeDate),
            )
            .toList();

        final previousPeriodTx = allTransactions
            .where(
              (tx) =>
                  tx.date.isAfter(p2Date) && tx.date.isBefore(previousDate) ||
                  tx.date.isAtSameMomentAs(previousDate),
            )
            .toList();

        final currentStats = _calculatePeriodStats(
          _InflationParams(
            accounts: sortedAccounts,
            transactions: currentPeriodTx,
            inflationRates: inflationRates,
            defaultCountry: defaultCountry,
          ),
        );

        final previousStats = _calculatePeriodStats(
          _InflationParams(
            accounts: sortedAccounts,
            transactions: previousPeriodTx,
            inflationRates: inflationRates,
            defaultCountry: defaultCountry,
          ),
        );

        await PerformanceLogger().stop('Accounts Screen Load More');

        emit(
          currentState.copyWith(
            accounts: sortedAccounts,
            realBalances: inflationResults.realBalances,
            inflationLosses: inflationResults.inflationLosses,
            accountIncomes: currentStats.income,
            accountExpenses: currentStats.expense,
            accountRealIncomes: currentStats.realIncome,
            accountRealExpenses: currentStats.realExpense,
            previousAccountIncomes: previousStats.income,
            previousAccountExpenses: previousStats.expense,
            previousAccountRealIncomes: previousStats.realIncome,
            previousAccountRealExpenses: previousStats.realExpense,
            hasReachedMax:
                (currentState.accounts.length + accounts.length) >=
                currentState.totalCount,
          ),
        );
      }
    } catch (_) {
      PerformanceLogger().stop('Accounts Screen Load More');
    }
  }

  Future<void> _onAddAccount(
    AddAccount event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.addAccount(event.account);
    add(LoadAccounts()); // Reload list
  }

  Future<void> _onUpdateAccount(
    UpdateAccount event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.updateAccount(event.account);
    add(LoadAccounts()); // Reload list
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      try {
        final accountToDelete = currentState.accounts.firstWhere(
          (acc) => acc.id == event.id,
        );
        emit(currentState.copyWith(recentlyDeletedAccount: accountToDelete));
        await _accountRepository.deleteAccount(event.id);
        add(LoadAccounts()); // Reload list
      } catch (e) {
        // Handle case where account is not found or other errors
      }
    }
  }

  Future<void> _onUndoDeleteAccount(
    UndoDeleteAccount event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess &&
        currentState.recentlyDeletedAccount != null) {
      await _accountRepository.restoreAccount(
        currentState.recentlyDeletedAccount!,
      );
      add(LoadAccounts()); // Reload list
    }
  }

  void _onSortAccounts(SortAccounts event, Emitter<AccountsState> emit) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final newSortAscending = event.sortAscending;
      final newFilters = currentState.filters.copyWith(
        sort: newSortAscending ? Sort.ascending : Sort.descending,
      );

      final sortedAccounts = _sortAccounts(
        List.of(currentState.accounts),
        currentState.exchangeRates,
        newSortAscending,
      );

      emit(
        currentState.copyWith(
          accounts: sortedAccounts,
          sortAscending: newSortAscending,
          filters: newFilters,
        ),
      );
    }
  }

  Future<void> _onFiltersChanged(
    FiltersChanged event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final deviceName = await getDeviceName();
      await _settingsRepository.setSetting(
        Settings(
          key: 'account_filters',
          value: event.filters.toJsonString(),
          device: deviceName,
        ),
      );
      emit(currentState.copyWith(filters: event.filters));
      add(LoadAccounts());
    }
  }

  Future<void> _onLoadHistoricalBalances(
    LoadHistoricalBalances event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final historicalBalances = await _accountRepository.getBalancesAtDate(
        event.date,
      );

      final updatedAccounts = currentState.accounts.map((account) {
        return account.copyWith(balance: historicalBalances[account.id] ?? 0.0);
      }).toList();

      final sortedAccounts = _sortAccounts(
        updatedAccounts,
        currentState.exchangeRates,
        currentState.sortAscending,
      );

      emit(
        currentState.copyWith(
          accounts: sortedAccounts,
          historicalBalances: historicalBalances,
          isHistorical: true,
        ),
      );
    }
  }

  void _onClearHistoricalBalances(
    ClearHistoricalBalances event,
    Emitter<AccountsState> emit,
  ) {
    add(LoadAccounts());
  }

  void _onToggleSelectionMode(
    ToggleSelectionMode event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(
        currentState.copyWith(
          isSelectionModeActive: event.isSelectionModeActive,
          selectedAccountIds: event.isSelectionModeActive
              ? currentState.selectedAccountIds
              : {},
        ),
      );
    }
  }

  void _onToggleAccountSelection(
    ToggleAccountSelection event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final newSelectedIds = Set<String>.from(currentState.selectedAccountIds);
      if (newSelectedIds.contains(event.accountId)) {
        newSelectedIds.remove(event.accountId);
      } else {
        newSelectedIds.add(event.accountId);
      }
      emit(currentState.copyWith(selectedAccountIds: newSelectedIds));
    }
  }

  void _onSelectAllAccounts(
    SelectAllAccounts event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final allIds = currentState.accounts.map((acc) => acc.id!).toSet();
      emit(currentState.copyWith(selectedAccountIds: allIds));
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<AccountsState> emit) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      emit(currentState.copyWith(selectedAccountIds: {}));
    }
  }

  Future<void> _onDeleteMultipleAccounts(
    DeleteMultipleAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.deleteMultipleAccounts(event.accountIds);
    add(LoadAccounts());
  }

  Future<void> _onUpdateAccountTypeForMultipleAccounts(
    UpdateAccountTypeForMultipleAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    await _accountRepository.updateAccountTypeForMultipleAccounts(
      event.accountIds,
      event.accountTypeId,
    );
    add(LoadAccounts());
  }
}

class _InflationParams {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<InflationRateDomain> inflationRates;
  final String defaultCountry;

  _InflationParams({
    required this.accounts,
    required this.transactions,
    required this.inflationRates,
    required this.defaultCountry,
  });
}

class _InflationResults {
  final Map<String, double> realBalances;
  final Map<String, double> inflationLosses;

  _InflationResults({
    required this.realBalances,
    required this.inflationLosses,
  });
}

_InflationResults _calculateInflationForAccounts(_InflationParams params) {
  final Map<String, double> realBalances = {};
  final Map<String, double> inflationLosses = {};

  // Group inflation rates by country for faster access
  // Map<CountryCode, List<InflationRateDomain>>
  final ratesByCountry = <String, List<InflationRateDomain>>{};
  // Ensure rates are sorted by date
  final sortedRates = List<InflationRateDomain>.from(params.inflationRates)
    ..sort((a, b) => a.date.compareTo(b.date));

  for (final rate in sortedRates) {
    if (rate.country != null) {
      ratesByCountry.putIfAbsent(rate.country!, () => []).add(rate);
    }
  }

  PerformanceLogger().start('PutIfAbsent');
  final transactionsByAccount = <String, List<Transaction>>{};
  for (final tx in params.transactions) {
    transactionsByAccount.putIfAbsent(tx.accountId, () => []).add(tx);
  }
  PerformanceLogger().stop('PutIfAbsent');

  final now = DateTime.now();
  final target = DateTime(now.year, now.month);

  // Cache multipliers: Map<Country, Map<DateTime, double>>
  final multiplierCache = <String, Map<DateTime, double>>{};

  double getMultiplier(DateTime date, String country) {
    final monthDate = DateTime(date.year, date.month);

    // Check cache
    if (multiplierCache.containsKey(country) &&
        multiplierCache[country]!.containsKey(monthDate)) {
      return multiplierCache[country]![monthDate]!;
    }

    final countryRates = ratesByCountry[country] ?? [];
    if (countryRates.isEmpty) return 1.0;

    double cumulativeMultiplier = 1.0;
    DateTime current = monthDate;

    // Limit loop to avoid infinite loops if something goes wrong, though dates should advance
    int safeguard = 0;
    while (current.isBefore(target) && safeguard < 1200) {
      // 100 years max
      safeguard++;
      final rate = countryRates.firstWhere(
        (r) => r.date.year == current.year,
        orElse: () =>
            InflationRateDomain(percent: 0.0, date: DateTime(0), preset: 1),
      );

      if (rate.percent != 0.0) {
        // Assume annual rate is effectively for the year, convert to monthly component
        // 1 + annual = (1 + monthly)^12  => monthly = (1+annual)^(1/12) - 1
        final monthlyRate = pow(1 + rate.percent / 100, 1 / 12) - 1;
        cumulativeMultiplier *= (1 + monthlyRate);
      }
      current = DateTime(current.year, current.month + 1);
    }

    multiplierCache.putIfAbsent(country, () => {});
    multiplierCache[country]![monthDate] = cumulativeMultiplier;
    return cumulativeMultiplier;
  }

  PerformanceLogger().start('for');
  for (final account in params.accounts) {
    if (account.id != null) {
      final transactions = transactionsByAccount[account.id] ?? [];
      double realBalance = 0;

      // Determine effective country for this account
      final effectiveCountry = account.country ?? params.defaultCountry;

      for (final tx in transactions) {
        realBalance += tx.amount / getMultiplier(tx.date, effectiveCountry);
      }

      realBalances[account.id!] = realBalance;
      if (account.balance != 0) {
        inflationLosses[account.id!] =
            (account.balance - realBalance) / account.balance * 100;
      } else {
        inflationLosses[account.id!] = 0;
      }
    }
  }
  PerformanceLogger().stop('for');

  return _InflationResults(
    realBalances: realBalances,
    inflationLosses: inflationLosses,
  );
}

class _PeriodStats {
  final Map<String, double> income;
  final Map<String, double> expense;
  final Map<String, double> realIncome;
  final Map<String, double> realExpense;

  _PeriodStats({
    required this.income,
    required this.expense,
    required this.realIncome,
    required this.realExpense,
  });
}

_PeriodStats _calculatePeriodStats(_InflationParams params) {
  final Map<String, double> income = {};
  final Map<String, double> expense = {};
  final Map<String, double> realIncome = {};
  final Map<String, double> realExpense = {};

  final ratesByCountry = <String, List<InflationRateDomain>>{};
  final sortedRates = List<InflationRateDomain>.from(params.inflationRates)
    ..sort((a, b) => a.date.compareTo(b.date));

  for (final rate in sortedRates) {
    if (rate.country != null) {
      ratesByCountry.putIfAbsent(rate.country!, () => []).add(rate);
    }
  }

  // Helper for multiplier
  // Note: Optimally we should reuse the cache logic from _calculateInflationForAccounts
  // But since this is a separate isolate function (potentially), we duplicate or refactor.
  // For simplicity and correctness in this scope, I'll duplicate the helper logic or just inline simple lookups.
  // Given we process period transactions (usually few), full caching might be overkill but robust.

  final multiplierCache = <String, Map<DateTime, double>>{};
  final now = DateTime.now();
  final target = DateTime(now.year, now.month + 1); // Safety bounds

  double getMultiplier(DateTime date, String country) {
    final monthDate = DateTime(date.year, date.month);
    if (multiplierCache.containsKey(country) &&
        multiplierCache[country]!.containsKey(monthDate)) {
      return multiplierCache[country]![monthDate]!;
    }

    final countryRates = ratesByCountry[country] ?? [];
    if (countryRates.isEmpty) return 1.0;

    double cumulativeMultiplier = 1.0;
    DateTime current = monthDate;
    int safeguard = 0;

    // We only need multiplier FROM transaction date TO now (or target).
    while (current.isBefore(target) && safeguard < 1200) {
      safeguard++;
      final rate = countryRates.firstWhere(
        (r) => r.date.year == current.year,
        orElse: () =>
            InflationRateDomain(percent: 0.0, date: DateTime(0), preset: 1),
      );

      if (rate.percent != 0.0) {
        final monthlyRate = pow(1 + rate.percent / 100, 1 / 12) - 1;
        cumulativeMultiplier *= (1 + monthlyRate);
      }
      current = DateTime(current.year, current.month + 1);
    }

    multiplierCache.putIfAbsent(country, () => {});
    multiplierCache[country]![monthDate] = cumulativeMultiplier;
    return cumulativeMultiplier;
  }

  for (final account in params.accounts) {
    if (account.id == null) continue;

    // Filter transactions for this account
    // Note: params.transactions passed here should ALREADY be filtered for the period
    // But we need to filter by accountId
    final accountTx = params.transactions.where(
      (tx) => tx.accountId == account.id,
    );

    double accIncome = 0;
    double accExpense = 0;
    double accRealIncome = 0;
    double accRealExpense = 0;

    final effectiveCountry = account.country ?? params.defaultCountry;

    for (final tx in accountTx) {
      final multiplier = getMultiplier(tx.date, effectiveCountry);
      final realAmount = tx.amount / multiplier;

      if (tx.amount > 0) {
        accIncome += tx.amount;
        accRealIncome += realAmount;
      } else {
        accExpense += tx.amount;
        accRealExpense += realAmount;
      }
    }

    income[account.id!] = accIncome;
    expense[account.id!] = accExpense;
    realIncome[account.id!] = accRealIncome;
    realExpense[account.id!] = accRealExpense;
  }

  return _PeriodStats(
    income: income,
    expense: expense,
    realIncome: realIncome,
    realExpense: realExpense,
  );
}
