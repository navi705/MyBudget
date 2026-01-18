import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:my_budget_client/core/utils/performance_logger.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';

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
import 'package:my_budget_client/domain/repositories/asset_repository.dart'; // Added
import 'package:my_budget_client/domain/repositories/category_repository.dart'; // Added
import 'package:my_budget_client/domain/entities/asset_data.dart'; // Added
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/category.dart'; // Added

import 'package:my_budget_client/domain/services/finance_calculator.dart'; // Added

part 'accounts_event.dart';
part 'accounts_state.dart';

class DeleteAccountWithTransactions extends AccountsEvent {
  final String accountId;
  const DeleteAccountWithTransactions(this.accountId);
  @override
  List<Object> get props => [accountId];
}

class DeleteAccountAndReassign extends AccountsEvent {
  final String accountId;
  final String newAccountId;
  const DeleteAccountAndReassign(this.accountId, this.newAccountId);
  @override
  List<Object> get props => [accountId, newAccountId];
}

class AccountsBloc extends Bloc<AccountsEvent, AccountsState> {
  final AccountRepository _accountRepository;
  final SettingsRepository _settingsRepository;
  final CurrencyRepository _currencyRepository;
  final InflationRepository _inflationRepository;
  final TransactionRepository _transactionRepository;
  final AssetRepository _assetRepository;
  final CategoryRepository _categoryRepository; // Added
  final FinanceCalculator _financeCalculator; // Added

  StreamSubscription<List<Transaction>>? _transactionsSubscription;

  AccountsBloc({
    required AccountRepository accountRepository,
    required SettingsRepository settingsRepository,
    required CurrencyRepository currencyRepository,
    required InflationRepository inflationRepository,
    required TransactionRepository transactionRepository,
    required AssetRepository assetRepository,
    required CategoryRepository categoryRepository, // Added
    required FinanceCalculator financeCalculator, // Added
  }) : _accountRepository = accountRepository,
       _settingsRepository = settingsRepository,
       _currencyRepository = currencyRepository,
       _inflationRepository = inflationRepository,
       _transactionRepository = transactionRepository,
       _assetRepository = assetRepository,
       _categoryRepository = categoryRepository, // Added
       _financeCalculator = financeCalculator, // Added
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
    on<DeleteAccountWithTransactions>(_onDeleteAccountWithTransactions);
    on<DeleteAccountAndReassign>(_onDeleteAccountAndReassign);
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

  void _onDatePeriodNavigated(
    DatePeriodNavigated event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess) return;

    print(
      'DEBUG DatePeriodNavigated: direction=${event.direction}, currentDate=${currentState.activeDate}, dateStep=${currentState.dateStep}',
    );

    DateTime newDate;
    switch (currentState.dateStep) {
      case DateStep.day:
        newDate = currentState.activeDate.add(Duration(days: event.direction));
        break;
      case DateStep.month:
        // Move to target month, then snap to end of that month
        final targetMonth = DateTime(
          currentState.activeDate.year,
          currentState.activeDate.month + event.direction,
          1,
        );
        newDate = DateTime(
          targetMonth.year,
          targetMonth.month + 1,
          0,
          23,
          59,
          59,
        );
        break;
      case DateStep.year:
        // Move to target year, then snap to end of that year
        final targetYear = DateTime(
          currentState.activeDate.year + event.direction,
          1,
          1,
        );
        newDate = DateTime(targetYear.year, 12, 31, 23, 59, 59);
        break;
    }
    print('DEBUG DatePeriodNavigated: newDate=$newDate');
    emit(currentState.copyWith(activeDate: newDate));
    add(LoadHistoricalBalances(newDate));
  }

  void _onDateStepChanged(DateStepChanged event, Emitter<AccountsState> emit) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      DateTime newDate = currentState.activeDate;
      print(
        'DEBUG DateStepChanged: from ${currentState.dateStep} to ${event.dateStep}',
      );
      print('DEBUG DateStepChanged: currentDate=$newDate');

      // When switching to Month or Year, snap to the end of that period
      // to show the "Result" of the period (e.g. End of Month Balance).
      if (event.dateStep == DateStep.month) {
        newDate = DateTime(newDate.year, newDate.month + 1, 0, 23, 59, 59);
      } else if (event.dateStep == DateStep.year) {
        newDate = DateTime(newDate.year, 12, 31, 23, 59, 59);
      }

      print('DEBUG DateStepChanged: newDate=$newDate');

      emit(
        currentState.copyWith(dateStep: event.dateStep, activeDate: newDate),
      );
      add(LoadHistoricalBalances(newDate));
    }
  }

  void _onActiveDateChanged(
    ActiveDateChanged event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      print(
        'DEBUG ActiveDateChanged: oldDate=${currentState.activeDate} newDate=${event.date} newStep=${event.dateStep}',
      );

      // Update both date and step atomically if step is provided
      if (event.dateStep != null) {
        emit(
          currentState.copyWith(
            activeDate: event.date,
            dateStep: event.dateStep,
          ),
        );
      } else {
        emit(currentState.copyWith(activeDate: event.date));
      }
      add(LoadHistoricalBalances(event.date));
    }
  }

  Future<void> _onLoadAccounts(
    LoadAccounts event,
    Emitter<AccountsState> emit,
  ) async {
    PerformanceLogger().start('Accounts Screen Load');
    final currentState = state;
    emit(
      AccountsLoadInProgress(
        activeDate: currentState.activeDate,
        dateStep: currentState.dateStep,
        filters: currentState.filters,
      ),
    );
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
        _assetRepository.getAssetData(), // Include assets in initial fetch
        _categoryRepository.getCategories(), // Added
      ]);
      await PerformanceLogger().stop('Accounts: Future.wait');

      final accountTypes = results[0] as List<AccountType>;
      final accounts = results[1] as List<Account>;
      final totalCount = results[2] as int;
      final exchangeRates = results[3] as List<ExchangeRateDomain>;
      final inflationRates = results[4] as List<InflationRateDomain>;
      final assets = results[5] as List<AssetDataDomain>;
      final categories = results[6] as List<Category>; // Added

      // Fetch ALL transactions for proper calculation (FinanceCalculator needs history)
      // Note: For large datasets we might need optimization, but FinanceCalculator is designed for full history.
      // However, we can optimize by only fetching if standard account logic triggers.
      // But FinanceCalculator expects the full snapshot.

      final sortedAccountsTemp = _sortAccounts(
        accounts,
        exchangeRates,
        filters.sort == Sort.ascending,
      );

      final accountIds = sortedAccountsTemp
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
      final defaultCountry =
          defaultCountrySetting?.value ?? 'SRB'; // Default to Serbia

      // Construct Snapshot
      final snapshot = FinancialSnapshot(
        accounts: accounts,
        transactions: allTransactions,
        assetData: assets,
        categories: categories, // Added
        exchangeRates: exchangeRates,
        inflationRates: inflationRates,
        date: currentState.activeDate,
        dateStep: currentState.dateStep,
        baseCurrency: 'EUR', // Should likely get this from User Settings
      );

      PerformanceLogger().start('FinanceCalculator: Calculations');

      // 1. Calculate Nominal Balances (handles Asset Binding)
      final nominalBalances = _financeCalculator.calculateBalances(snapshot);

      // Update Account Objects with Calculated Balances (for Grid)
      final accountsWithBalances = accounts.map((a) {
        if (nominalBalances.containsKey(a.id)) {
          return a.copyWith(balance: nominalBalances[a.id]!);
        }
        return a;
      }).toList();

      // Sort with updated balances
      final sortedAccounts = _sortAccounts(
        accountsWithBalances,
        exchangeRates,
        filters.sort == Sort.ascending,
      );

      // 2. Calculate Real Balances (Inflation Adjusted)
      final realBalances = _financeCalculator.calculateRealBalances(
        snapshot,
        defaultCountry: defaultCountry,
      );

      // 3. Asset Stats (Added)
      final assetStats = _financeCalculator.calculateAssetStats(snapshot);

      // 3. Asset Values (Already computed in calculateBalances logic, but AccountsState expects a separate map)
      // We can reuse nominalBalances for this if account is asset-bound.
      // Or we can ask Calculator for specific asset breakdown?
      // FinanceCalculator doesn't expose asset map directly, but calculateBalances returns AccountId -> Value.
      // For legacy compatibility, we can pass nominalBalances as assetValues for asset-bound accounts.

      // 4. Period Stats (Current)
      // We need to define the period manually if snapshot doesn't auto-derive from DateStep
      // FinanceCalculator helper needed? 'calculatePeriodStats' takes a DatePeriod.

      DateTime periodStart;
      DateTime periodEnd = currentState.activeDate; // Inclusive end usually?

      switch (currentState.dateStep) {
        case DateStep.day:
          periodStart = currentState.activeDate;
          break;
        case DateStep.month:
          periodStart = DateTime(
            currentState.activeDate.year,
            currentState.activeDate.month,
            1,
          );
          // Set end to last second of month? Or just strict range.
          // FinanceCalculator logic: start <= t < end or start <= t <= end.
          // Let's rely on standard period construction.
          periodEnd = DateTime(
            currentState.activeDate.year,
            currentState.activeDate.month + 1,
            0,
            23,
            59,
            59,
          );
          break;
        case DateStep.year:
          periodStart = DateTime(currentState.activeDate.year, 1, 1);
          periodEnd = DateTime(
            currentState.activeDate.year,
            12,
            31,
            23,
            59,
            59,
          );
          break;
      }
      // Override periodEnd to 'activeDate' if we want 'upto now'?
      // Usually "Period Stats" means "For this entire Month".
      // Let's use the full natural period for the step.

      final currentStats = _financeCalculator.calculatePeriodStats(
        snapshot,
        DatePeriod(periodStart, periodEnd),
        defaultCountry: defaultCountry,
      );

      // 5. Period Stats (Previous)
      DateTime prevStart;
      DateTime prevEnd;

      switch (currentState.dateStep) {
        case DateStep.day:
          prevStart = periodStart.subtract(const Duration(days: 1));
          prevEnd = prevStart; // Single day
          break;
        case DateStep.month:
          final p = DateTime(periodStart.year, periodStart.month - 1, 1);
          prevStart = p;
          prevEnd = DateTime(p.year, p.month + 1, 0, 23, 59, 59);
          break;
        case DateStep.year:
          prevStart = DateTime(periodStart.year - 1, 1, 1);
          prevEnd = DateTime(periodStart.year - 1, 12, 31, 23, 59, 59);
          break;
      }

      final prevStats = _financeCalculator.calculatePeriodStats(
        snapshot,
        DatePeriod(prevStart, prevEnd),
        defaultCountry: defaultCountry,
      );
      // 6. Inflation Losses
      // This is a specific map <AccountId, Loss>.
      // FinanceCalculator.calculateRealBalances returns the *Balance*.
      // Loss = Real - Nominal? Or Real(t) - Real(t-1)?
      // The Legacy logic calculated "Loss due to inflation" over the period.
      // Use calculatePeriodStats().realIncome vs income?
      // Or we can just calculate Loss = Nominal - Real? No, that's cumulative devaluation.
      // If the UI expects "Loss this month", use stats.
      // If UI expects "Total Loss", use Nominal - Real (at current date).
      final inflationLosses = <String, double>{};
      for (var id in realBalances.keys) {
        final nom = nominalBalances[id] ?? 0.0;
        final real = realBalances[id] ?? 0.0;
        inflationLosses[id] = real - nom; // Usually negative
      }

      await PerformanceLogger().stop('FinanceCalculator: Calculations');

      // Previous Period Balances (Snapshot at T-1)
      // We need a new snapshot for previous date reference?
      // Or just use calculateBalances with a different date override?
      // FinanceCalculator doesn't allow 'date' override in methods efficiently without recreating snapshot.
      // We can Re-create snapshot or add 'date' param to calculateBalances?
      // Defined: calculateBalances(FinancialSnapshot data). Data has .date.
      final prevSnapshot = snapshot.copyWith(
        date: prevEnd,
      ); // Use end of prev period
      final prevBalances = _financeCalculator.calculateBalances(prevSnapshot);
      final prevRealBalances = _financeCalculator.calculateRealBalances(
        prevSnapshot,
        defaultCountry: defaultCountry,
      );

      double income = currentStats.totalIncome;
      double expense = currentStats.totalExpense;

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
          realBalances: realBalances,
          inflationLosses: inflationLosses,
          previousPeriodBalances: prevBalances,
          previousPeriodRealBalances: prevRealBalances,
          accountIncomes: currentStats.income,
          accountExpenses: currentStats.expense,
          accountRealIncomes: currentStats.realIncome,
          accountRealExpenses: currentStats.realExpense,
          assetValues: nominalBalances,
          assetStats: assetStats, // Added
          previousAccountIncomes: prevStats.income,
          previousAccountExpenses: prevStats.expense,
          previousAccountRealIncomes: prevStats.realIncome,
          previousAccountRealExpenses: prevStats.realExpense,
          income: income,
          expense: expense,
        ),
      );
      await PerformanceLogger().stop('Accounts Screen Load');
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
        // Fetch Assets early
        final assets = await _assetRepository.getAssetData();

        // Load additional data needed for Calculator
        final inflationRates = await _inflationRepository.getInflationRates();
        final defaultCountrySetting = await _settingsRepository.getSetting(
          'default_inflation_country',
        );
        final defaultCountry = defaultCountrySetting?.value ?? 'SRB';

        // Merge new accounts with existing for full sort and calc
        // (FinanceCalculator usually needs full context for sorting,
        //  but inflation/asset calc is per account usually.
        //  Real balance relative to others affects sort.)

        // Simplest strategy: Combine lists, re-run full calc.
        // Optimization: Run calc only on NEW accounts, then merge?
        // Sorting depends on real/nominal balances.

        final combinedAccounts = List.of(currentState.accounts)
          ..addAll(accounts);

        // Fetch transactions for ALL combined accounts?
        // Or just fetch for new, and merge with old transactions?
        // To be safe and simpler: Fetch for new accounts, merge with existing 'allTransactions' if we had them.
        // But we don't store 'allTransactions' in state, only derived stats.
        // So we might need to fetch for new accounts, calculate their stats, and merge into state maps.

        final newAccountIds = accounts.map((e) => e.id!).toList();
        final newTransactions = await _transactionRepository
            .getTransactionsWithFilters(
              filters: TransactionFilters(accountId: newAccountIds),
              limit: 1000000,
            );

        // We probably need transaction history for existing accounts to maintain TOTAL stats?
        // State has 'accountIncomes', 'realBalances' etc.
        // We can just ADD new entries to these maps.

        // 1. Calculate for NEW accounts
        // We need a snapshot. But snapshot usually expects the full list of accounts/txs to be consistent?
        // FinanceCalculator.calculateBalances iterates data.transactions.
        // If we only pass new accounts and new transactions, we get balances for new accounts.

        final snapshotForNew = FinancialSnapshot(
          accounts: accounts,
          transactions: newTransactions,
          assetData: assets,
          categories: currentState.categories, // Added
          exchangeRates: currentState.exchangeRates,
          inflationRates: inflationRates,
          date: currentState.activeDate,
          dateStep: currentState.dateStep,
          baseCurrency: 'EUR',
        );

        final newNominalBalances = _financeCalculator.calculateBalances(
          snapshotForNew,
        );
        final newRealBalances = _financeCalculator.calculateRealBalances(
          snapshotForNew,
          defaultCountry: defaultCountry,
        );

        final newAssetStats = _financeCalculator.calculateAssetStats(
          snapshotForNew,
        );

        // Period Stats for New
        final period = snapshotForNew.currentPeriod;
        final newCurrentStats = _financeCalculator.calculatePeriodStats(
          snapshotForNew,
          period,
          defaultCountry: defaultCountry,
        );

        // Previous Period Stats for New
        DateTime prevStart;
        DateTime prevEnd;
        // Replicate logic or use helper if we exposed one.
        // Since we didn't expose 'getPreviousPeriod', manual again or just ignore if load more?
        // Let's implement correctly.
        switch (currentState.dateStep) {
          case DateStep.day:
            prevStart = period.start.subtract(const Duration(days: 1));
            prevEnd = prevStart; // Single day
            break;
          case DateStep.month:
            final p = DateTime(period.start.year, period.start.month - 1, 1);
            prevStart = p;
            prevEnd = DateTime(p.year, p.month + 1, 0, 23, 59, 59);
            break;
          case DateStep.year:
            prevStart = DateTime(period.start.year - 1, 1, 1);
            prevEnd = DateTime(period.start.year - 1, 12, 31, 23, 59, 59);
            break;
        }

        final snapshotPrev = snapshotForNew.copyWith(
          date: prevEnd,
        ); // Date doesn't affect stats as much as period param, but good practice
        final newPrevStats = _financeCalculator.calculatePeriodStats(
          snapshotPrev,
          DatePeriod(prevStart, prevEnd),
          defaultCountry: defaultCountry,
        );

        final prevNominalBalances = _financeCalculator.calculateBalances(
          snapshotPrev,
        );
        final prevRealBalances = _financeCalculator.calculateRealBalances(
          snapshotPrev,
          defaultCountry: defaultCountry,
        );

        // Merge Results
        final updatedNominalBalances = Map<String, double>.from(
          currentState.assetValues,
        )..addAll(newNominalBalances);

        final updatedAssetStats = Map<String, AssetStats>.from(
          currentState.assetStats,
        )..addAll(newAssetStats); // Added
        // Note: state.assetValues is acting as nominalBalances map.

        final updatedRealBalances = Map<String, double>.from(
          currentState.realBalances,
        )..addAll(newRealBalances);
        final updatedPrevBalances = Map<String, double>.from(
          currentState.previousPeriodBalances,
        )..addAll(prevNominalBalances);
        final updatedPrevRealBalances = Map<String, double>.from(
          currentState.previousPeriodRealBalances,
        )..addAll(prevRealBalances);

        final updatedIncomes = Map<String, double>.from(
          currentState.accountIncomes,
        )..addAll(newCurrentStats.income);
        final updatedExpenses = Map<String, double>.from(
          currentState.accountExpenses,
        )..addAll(newCurrentStats.expense);
        final updatedRealIncomes = Map<String, double>.from(
          currentState.accountRealIncomes,
        )..addAll(newCurrentStats.realIncome);
        final updatedRealExpenses = Map<String, double>.from(
          currentState.accountRealExpenses,
        )..addAll(newCurrentStats.realExpense);

        final updatedPrevIncomes = Map<String, double>.from(
          currentState.previousAccountIncomes,
        )..addAll(newPrevStats.income);
        final updatedPrevExpenses = Map<String, double>.from(
          currentState.previousAccountExpenses,
        )..addAll(newPrevStats.expense);
        final updatedPrevRealIncomes = Map<String, double>.from(
          currentState.previousAccountRealIncomes,
        )..addAll(newPrevStats.realIncome);
        final updatedPrevRealExpenses = Map<String, double>.from(
          currentState.previousAccountRealExpenses,
        )..addAll(newPrevStats.realExpense);

        final updatedInflationLosses = Map<String, double>.from(
          currentState.inflationLosses,
        );
        for (var id in newRealBalances.keys) {
          final nom = newNominalBalances[id] ?? 0.0;
          final real = newRealBalances[id] ?? 0.0;
          if (nom != 0) {
            updatedInflationLosses[id] = (nom - real) / nom * 100;
          } else {
            updatedInflationLosses[id] = 0.0;
          }
        }

        // Update Account Objects with Balances
        final accountsWithBalances = combinedAccounts.map((a) {
          if (updatedNominalBalances.containsKey(a.id)) {
            return a.copyWith(balance: updatedNominalBalances[a.id]!);
          }
          return a;
        }).toList();

        final sortedAccounts = _sortAccounts(
          accountsWithBalances,
          currentState.exchangeRates,
          currentState.sortAscending,
        );

        // Recalculate totals by adding new stats to existing totals
        double totalIncome = currentState.income + newCurrentStats.totalIncome;
        double totalExpense =
            currentState.expense + newCurrentStats.totalExpense;

        await PerformanceLogger().stop('Accounts Screen Load More');

        emit(
          currentState.copyWith(
            accounts: sortedAccounts,
            realBalances: updatedRealBalances,
            inflationLosses: updatedInflationLosses,
            accountIncomes: updatedIncomes,
            accountExpenses: updatedExpenses,
            accountRealIncomes: updatedRealIncomes,
            accountRealExpenses: updatedRealExpenses,
            assetValues: updatedNominalBalances,
            assetStats: updatedAssetStats, // Added
            previousPeriodBalances: updatedPrevBalances,
            previousPeriodRealBalances: updatedPrevRealBalances,
            previousAccountIncomes: updatedPrevIncomes,
            previousAccountExpenses: updatedPrevExpenses,
            previousAccountRealIncomes: updatedPrevRealIncomes,
            previousAccountRealExpenses: updatedPrevRealExpenses,
            income: totalIncome,
            expense: totalExpense,
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
        await _accountRepository.deleteAccountWithTransactions(event.id);
        add(LoadAccounts());
      } catch (e) {
        // Handle case where account is not found or other errors
      }
    }
  }

  Future<void> _onDeleteAccountWithTransactions(
    DeleteAccountWithTransactions event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final accountToDelete = currentState.accounts.firstWhere(
        (acc) => acc.id == event.accountId,
      );
      emit(currentState.copyWith(recentlyDeletedAccount: accountToDelete));
      await _accountRepository.deleteAccountWithTransactions(event.accountId);
      add(LoadAccounts());
    }
  }

  Future<void> _onDeleteAccountAndReassign(
    DeleteAccountAndReassign event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      final accountToDelete = currentState.accounts.firstWhere(
        (acc) => acc.id == event.accountId,
      );
      emit(currentState.copyWith(recentlyDeletedAccount: accountToDelete));
      await _accountRepository.deleteAccountAndReassignTransactions(
        event.accountId,
        event.newAccountId,
      );
      add(LoadAccounts());
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
    if (currentState is! AccountsLoadSuccess) return;

    try {
      // 1. Fetch Fresh Data (Needed to ensure we have "Latest" balances for Reverse Calc)
      // We must reload ALL currently displayed accounts.
      final currentCount = currentState.accounts.length;
      final limit = currentCount > currentState.limit
          ? currentCount
          : currentState.limit;

      final results = await Future.wait([
        _accountRepository.getAccountsPaginatedFiltered(
          limit: limit,
          offset: 0,
          accountFilters: currentState.filters,
        ),
        _currencyRepository.getLatestExchangeRates(DateTime.now()),
        _inflationRepository.getInflationRates(),
        _assetRepository.getAssetData(),
        _categoryRepository.getCategories(), // Added
      ]);

      final accounts = results[0] as List<Account>;
      final exchangeRates = results[1] as List<ExchangeRateDomain>;
      final inflationRates = results[2] as List<InflationRateDomain>;
      final assets = results[3] as List<AssetDataDomain>;
      final categories = results[4] as List<Category>; // Added

      // Fetch ALL transactions (FinanceCalculator needs history)
      final sortedAccountsTemp = _sortAccounts(
        accounts,
        exchangeRates,
        currentState.filters.sort == Sort.ascending,
      );
      final accountIds = sortedAccountsTemp
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

      // 2. Construct Snapshot at Target Date
      final snapshot = FinancialSnapshot(
        accounts: accounts,
        transactions: allTransactions,
        assetData: assets,
        categories: categories, // Added
        exchangeRates: exchangeRates,
        inflationRates: inflationRates,
        date: event.date, // Target Date
        dateStep: currentState.dateStep,
        baseCurrency: 'EUR',
      );

      PerformanceLogger().start('FinanceCalculator: Calculations');

      // 1. Nominal Balances
      final nominalBalances = _financeCalculator.calculateBalances(snapshot);

      // Update Accounts
      final accountsWithBalances = accounts.map((a) {
        if (nominalBalances.containsKey(a.id)) {
          return a.copyWith(balance: nominalBalances[a.id]!);
        }
        return a;
      }).toList();

      final sortedAccounts = _sortAccounts(
        accountsWithBalances,
        exchangeRates,
        currentState.filters.sort == Sort.ascending,
      );

      // 2. Real Balances
      final realBalances = _financeCalculator.calculateRealBalances(
        snapshot,
        defaultCountry: defaultCountry,
      );

      // 3. Asset Stats (Added)
      final assetStats = _financeCalculator.calculateAssetStats(snapshot);

      // 3. Period Stats (Current)
      final period = snapshot.currentPeriod;
      final currentStats = _financeCalculator.calculatePeriodStats(
        snapshot,
        period,
        defaultCountry: defaultCountry,
      );

      // 4. Period Stats (Previous)
      DateTime prevStart;
      DateTime prevEnd;

      switch (currentState.dateStep) {
        case DateStep.day:
          prevStart = period.start.subtract(const Duration(days: 1));
          prevEnd = prevStart;
          break;
        case DateStep.month:
          final p = DateTime(period.start.year, period.start.month - 1, 1);
          prevStart = p;
          prevEnd = DateTime(p.year, p.month + 1, 0, 23, 59, 59);
          break;
        case DateStep.year:
          prevStart = DateTime(period.start.year - 1, 1, 1);
          prevEnd = DateTime(period.start.year - 1, 12, 31, 23, 59, 59);
          break;
      }

      final prevSnapshot = snapshot.copyWith(date: prevEnd);
      final prevStats = _financeCalculator.calculatePeriodStats(
        prevSnapshot,
        DatePeriod(prevStart, prevEnd),
        defaultCountry: defaultCountry,
      );

      // 5. Inflation Losses
      final inflationLosses = <String, double>{};
      for (var id in realBalances.keys) {
        final nom = nominalBalances[id] ?? 0.0;
        final real = realBalances[id] ?? 0.0;
        if (nom != 0) {
          inflationLosses[id] = (nom - real) / nom * 100;
        } else {
          inflationLosses[id] = 0.0;
        }
      }

      // 6. Previous Period Balances
      final prevBalances = _financeCalculator.calculateBalances(prevSnapshot);
      final prevRealBalances = _financeCalculator.calculateRealBalances(
        prevSnapshot,
        defaultCountry: defaultCountry,
      );

      await PerformanceLogger().stop('FinanceCalculator: Calculations');

      double income = currentStats.totalIncome;
      double expense = currentStats.totalExpense;

      emit(
        currentState.copyWith(
          accounts: sortedAccounts,
          realBalances: realBalances,
          inflationLosses: inflationLosses,
          accountIncomes: currentStats.income,
          accountExpenses: currentStats.expense,
          accountRealIncomes: currentStats.realIncome,
          accountRealExpenses: currentStats.realExpense,
          assetValues: nominalBalances,
          assetStats: assetStats, // Added
          previousPeriodBalances: prevBalances,
          previousPeriodRealBalances: prevRealBalances,
          previousAccountIncomes: prevStats.income,
          previousAccountExpenses: prevStats.expense,
          previousAccountRealIncomes: prevStats.realIncome,
          previousAccountRealExpenses: prevStats.realExpense,
          income: income,
          expense: expense,
          categories: categories,
          isHistorical: true, // Set to true when historical data is loaded
          activeDate: event.date, // Set the active date to the historical date
        ),
      );
    } catch (e) {
      // Keep old state if error, maybe show snackbar?
      print('HistoricalLoad Error: $e');
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
    // Loop through IDs and delete each with transactions to ensure safety from FK crashes.
    // Using simple loop for now as we don't have a bulk cascading delete in repo/DAO yet.
    for (final id in event.accountIds) {
      await _accountRepository.deleteAccountWithTransactions(id);
    }
    // Note: We aren't setting recentlyDeletedAccount for bulk delete because UI doesn't usually undo bulk.
    // Undo only supports single account for now based on state model.
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

  List<Account> _sortAccounts(
    List<Account> accounts,
    List<ExchangeRateDomain> rates,
    bool ascending,
  ) {
    final Map<String, double> rateMap = {
      for (var r in rates) r.toCurrencyCode: r.rate,
    };
    rateMap['EUR'] = 1.0;

    accounts.sort((a, b) {
      final aRate = rateMap[a.currencyCode];
      final bRate = rateMap[b.currencyCode];

      if (aRate == null || aRate == 0) return 1;
      if (bRate == null || bRate == 0) return -1;

      final aValueInBase = a.balance / aRate;
      final bValueInBase = b.balance / bRate;

      final comparison = aValueInBase.compareTo(bValueInBase);
      return ascending ? comparison : -comparison;
    });
    return accounts;
  }
}
