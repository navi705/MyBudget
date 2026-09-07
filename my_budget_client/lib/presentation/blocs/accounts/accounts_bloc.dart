import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:collection/collection.dart';
import 'package:my_budget_client/core/utils/calendar_day.dart';
import 'package:my_budget_client/core/utils/performance_logger.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:rxdart/rxdart.dart';

import 'package:equatable/equatable.dart';
// import 'package:my_budget_client/core/utils/device_utils.dart';
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
import 'package:my_budget_client/domain/entities/category_type.dart';

import 'package:my_budget_client/domain/services/finance_calculator.dart'; // Added
import 'package:my_budget_client/domain/value_objects/currency_precision.dart';

import '../bloc_lifecycle.dart';

part 'accounts_event.dart';
part 'accounts_state.dart';

class ClearRecentlyDeletedAccount extends AccountsEvent {
  const ClearRecentlyDeletedAccount();
  @override
  List<Object> get props => [];
}

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

class AccountsBloc extends Bloc<AccountsEvent, AccountsState>
    with BlocShutdownGuard<AccountsEvent, AccountsState> {
  final AccountRepository _accountRepository;
  final SettingsRepository _settingsRepository;
  final CurrencyRepository _currencyRepository;
  final InflationRepository _inflationRepository;
  final TransactionRepository _transactionRepository;
  final AssetRepository _assetRepository;
  final CategoryRepository _categoryRepository; // Added
  final FinanceCalculator _financeCalculator; // Added

  /// "However many match" — the transaction fetches below feed sums that are
  /// wrong if a single row is missing, so there is no smaller honest number.
  ///
  /// `getTransactionsWithFilters` takes a paging limit and offers no way to say
  /// "all", which is why a literal 1000000 was scattered through this file with
  /// nothing to explain it. Naming it at least says out loud that the bound is
  /// not a product decision. The real fix is to stop shipping the rows across
  /// the isolate port at all and have SQL return the aggregate — see the
  /// per-call notes below for what each fetch actually reduces to.
  static const int _allMatchingRows = 1000000;

  /// Every asset price entry, not the newest page of them.
  ///
  /// [AssetRepository.getAssetData] defaults to `limit: 50` and every call site
  /// in this file used to take that default. The calculator needs an asset's
  /// *earliest* entry (to know the asset did not exist yet at the target date)
  /// and the entry closest at or before the target date; the default handed it
  /// the 50 most recent entries across ALL assets instead. Past 50 entries the
  /// asset accounts' balances and asset stats were silently wrong — an account
  /// whose prices were all older than the newest 50 rows read as "asset did not
  /// exist", i.e. a balance of 0 — and moving the date backwards made it worse,
  /// because the further back the target date, the more of the entries that
  /// bracket it had been paged away.
  static const int _allAssetEntries = 1000000;

  // What the last account delete took with it, so Undo can put it back: the
  // transactions it tombstoned, or the ones it handed to another account. Not
  // in AccountsState - the SnackBar needs the account and nothing else, and
  // these would have to be threaded through all three state subclasses to sit
  // beside it. Kept with the id of the account they belong to so a payload
  // left over from an earlier delete cannot be applied to a different one.
  String? _undoAccountId;
  List<String> _undoTombstonedTxIds = const [];
  List<String> _undoMovedTxIds = const [];

  StreamSubscription<void>? _transactionsSubscription;
  // The accounts table itself, not only the transactions posted against it.
  // The screen no longer reloads on every mount (the shell route remounts it
  // on each tab switch), so a write from outside this bloc — a sync, a restore
  // — has to reach the list through here.
  StreamSubscription<List<Account>>? _accountsSubscription;

  // Optimization: Cache rate map to avoid rebuilding on every sort
  Map<String, double>? _cachedRateMap;
  List<ExchangeRateDomain>? _cachedRates;

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
    // The one handler on this bloc that is both expensive and pure: it reads,
    // recomputes and re-emits, and writes nothing. Under the default
    // `concurrent` transformer, holding a chevron down (or repeating the
    // hotkey) started a full run per tap and let them finish in whatever order
    // the database happened to return — so the grid could settle on the
    // balances for a date the app bar had already navigated away from, and the
    // only way back was to nudge the date again. `restartable` makes the newest
    // date win, and the runs it supersedes were pure waste anyway.
    //
    // Deliberately NOT applied to anything that writes (Add/Update/Delete/Undo
    // and the bulk variants): those must all reach the repository even when the
    // user fires them in quick succession, and a cancelled write is a lost one.
    on<LoadHistoricalBalances>(
      _onLoadHistoricalBalances,
      transformer: restartable(),
    );
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
    on<ClearRecentlyDeletedAccount>(_onClearRecentlyDeletedAccount);

    _transactionsSubscription = _transactionRepository
        .watchTransactionChanges()
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => add(LoadAccounts()));

    // skip(1): the stream opens with the current table, which the first
    // LoadAccounts is already fetching.
    _accountsSubscription = _accountRepository
        .watchAccounts()
        .skip(1)
        .debounceTime(const Duration(milliseconds: 500))
        .listen((_) => add(LoadAccounts()));
  }

  @override
  Future<void> close() async {
    markClosing();
    // Awaited: the listener above calls add(), and adding after the event
    // controller is closed throws. Cancelling without awaiting leaves that
    // race open on every screen dismissal.
    await _transactionsSubscription?.cancel();
    await _accountsSubscription?.cancel();
    return super.close();
  }

  /// Reverse-calc nominal balance for a standard (non-asset) account.
  /// For a fiat account with an exact [Account.balanceMinor], compute in integer
  /// minor units (no floating-point drift over the summed history) and divide by
  /// the currency scale once at the end. Crypto/commodity or accounts missing a
  /// minor anchor fall back to the double sums.
  double _nominalBalance(
    Account account,
    Map<String, double> majorSums,
    Map<String, int> minorSums,
  ) {
    final minorAnchor = account.balanceMinor;
    if (minorAnchor != null &&
        CurrencyPrecision.isMinorUnitCode(account.currencyCode)) {
      final scale = CurrencyPrecision.scaleFor(
        CurrencyPrecision.decimalsFor(account.currencyCode),
      );
      return (minorAnchor - (minorSums[account.id] ?? 0)) / scale;
    }
    return account.balance - (majorSums[account.id] ?? 0.0);
  }

  /// The visible period for [date]/[step].
  ///
  /// Scoping a transaction fetch to a period means knowing the period's bounds
  /// *before* the fetch, while the calculator only exposes them off a fully
  /// built [FinancialSnapshot]. Deriving them from an empty snapshot rather
  /// than re-deriving them by hand is what keeps the fetch window and the
  /// window [FinanceCalculator.calculatePeriodStats] later filters on from
  /// drifting apart: a hand-rolled bound that is even a second short drops real
  /// transactions out of the period stats and nothing reports it.
  DatePeriod _periodFor(DateTime date, DateStep step) => FinancialSnapshot(
    accounts: const [],
    transactions: const [],
    assetData: const [],
    categories: const [],
    exchangeRates: const [],
    inflationRates: const [],
    date: date,
    dateStep: step,
    baseCurrency: 'EUR',
  ).currentPeriod;

  void _onDatePeriodNavigated(
    DatePeriodNavigated event,
    Emitter<AccountsState> emit,
  ) {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess) return;

    debugPrint(
      'DEBUG DatePeriodNavigated: direction=${event.direction}, currentDate=${currentState.activeDate}, dateStep=${currentState.dateStep}',
    );

    DateTime newDate;
    switch (currentState.dateStep) {
      case DateStep.day:
        newDate = addDays(currentState.activeDate, event.direction);
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
    debugPrint('DEBUG DatePeriodNavigated: newDate=$newDate');
    // Two emits per gesture, and the first one is deliberate: it carries
    // nothing but the new date, so the app bar moves on the tap instead of
    // after the read. The second carries the recomputed figures and cannot be
    // folded into it without holding the date back until the database answers.
    //
    // What the second emit no longer does is repeat itself: LoadHistoricalBalances
    // is registered `restartable`, so a held-down chevron now costs one date
    // emit per tap and a single recompute at the end, not a full recompute and
    // a full rebuild per tap. See the handler registration above.
    emit(currentState.copyWith(activeDate: newDate));
    add(LoadHistoricalBalances(newDate));
  }

  void _onDateStepChanged(DateStepChanged event, Emitter<AccountsState> emit) {
    final currentState = state;
    if (currentState is AccountsLoadSuccess) {
      DateTime newDate = currentState.activeDate;
      debugPrint(
        'DEBUG DateStepChanged: from ${currentState.dateStep} to ${event.dateStep}',
      );
      debugPrint('DEBUG DateStepChanged: currentDate=$newDate');

      // When switching to Month or Year, snap to the end of that period
      // to show the "Result" of the period (e.g. End of Month Balance).
      if (event.dateStep == DateStep.month) {
        newDate = DateTime(newDate.year, newDate.month + 1, 0, 23, 59, 59);
      } else if (event.dateStep == DateStep.year) {
        newDate = DateTime(newDate.year, 12, 31, 23, 59, 59);
      }

      debugPrint('DEBUG DateStepChanged: newDate=$newDate');

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
      debugPrint(
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
    if (currentState is! AccountsLoadSuccess) {
      emit(
        AccountsLoadInProgress(
          recentlyDeletedAccount: currentState.recentlyDeletedAccount,
          activeDate: currentState.activeDate,
          dateStep: currentState.dateStep,
          filters: currentState.filters,
        ),
      );
    }
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
        // Include assets in initial fetch. Explicitly unbounded: the default
        // `limit: 50` silently truncated the price history feeding every asset
        // balance and every asset stat — see [_allAssetEntries].
        _assetRepository.getAssetData(limit: _allAssetEntries),
        _categoryRepository.getCategories(), // Added
        // Every account, with no AccountFilters applied. The paginated fetch
        // above is what the grid shows, so counting it answers "how many match
        // the filter" - screens that refuse to open a form until an account
        // exists need "how many exist", which an active filter must not change.
        // Runs inside this same Future.wait, so it costs no extra latency.
        _accountRepository.getAccounts(),
      ]);
      await PerformanceLogger().stop('Accounts: Future.wait');

      final accountTypes = results[0] as List<AccountType>;
      final accounts = results[1] as List<Account>;
      final totalCount = results[2] as int;
      final exchangeRates = results[3] as List<ExchangeRateDomain>;
      final inflationRates = results[4] as List<InflationRateDomain>;
      final assets = results[5] as List<AssetDataDomain>;
      final categories = results[6] as List<Category>; // Added
      final unfilteredAccounts = results[7] as List<Account>;

      // Only the two counts are kept: the list itself would be a second copy of
      // data the grid already holds, and the guards only ever ask "any?" and
      // "at least two transferable?".
      final unfilteredAccountCount = unfilteredAccounts.length;
      final unfilteredTransferableAccountCount = unfilteredAccounts
          .where((a) => a.assetId == null)
          .length;

      // Transaction loading is scoped to exactly what each calculation needs,
      // instead of pulling the full history into Dart:
      //  * standard-account balances come from SQL future-sum aggregates
      //    (storedBalance - SUM(amount after cutoff)) computed in the DB;
      //  * asset accounts still need their own transaction history (quantity
      //    accumulation) plus any linked cash transactions for asset stats;
      //  * period stats only need transactions within the visible period range.

      final defaultCountrySetting = await _settingsRepository.getSetting(
        'default_inflation_country',
      );
      final defaultCountry =
          defaultCountrySetting?.value ?? 'SRB'; // Default to Serbia

      // --- Period boundaries (depend only on activeDate + dateStep) ---
      DateTime periodStart;
      DateTime periodEnd;
      switch (currentState.dateStep) {
        case DateStep.day:
          periodStart = currentState.activeDate;
          periodEnd = currentState.activeDate;
          break;
        case DateStep.month:
          periodStart = DateTime(
            currentState.activeDate.year,
            currentState.activeDate.month,
            1,
          );
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

      DateTime prevStart;
      DateTime prevEnd;
      switch (currentState.dateStep) {
        case DateStep.day:
          prevStart = previousDay(periodStart);
          prevEnd = prevStart;
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

      final assetAccountIds = accounts
          .where((a) => a.assetId != null && a.id != null)
          .map((a) => a.id!)
          .toList();

      // Transfers and rows on asset accounts are thrown away by
      // [FinanceCalculator.calculatePeriodStats] the moment it looks at them,
      // and the period fetch below exists only to feed that call. Every row it
      // ships costs a serialization across drift's isolate port whether the
      // calculator keeps it or not, so the two discards moved into SQL. The
      // predicates are the calculator's own, read off the same two lists the
      // snapshot hands it, so what survives is unchanged row for row.
      //
      // A category id missing from [categories] stays in the result on purpose:
      // the calculator cannot type such a row either, and treats it as spend.
      final transferCategoryIds = categories
          .where((c) => c.type == CategoryType.transfer && c.id != null)
          .map((c) => c.id!)
          .toList();

      // --- Targeted transaction loads (replace the full-history fetch) ---
      //
      // Nothing here reads anything another one of them produces, yet they used
      // to be awaited one at a time. Each is its own hop to the database
      // isolate and back, so the screen paid six latencies end to end where it
      // only ever needed the slowest. The linked-cash chase below is the one
      // read that genuinely has to wait — it is keyed by ids that only exist
      // once the asset rows have come back.
      PerformanceLogger().start('Accounts: getTransactionsWithFilters');
      final txResults = await Future.wait([
        _transactionRepository.getFutureSumsExact(currentState.activeDate),
        _transactionRepository.getFutureSumsExact(prevEnd),
        // Exact integer-minor counterparts (fiat only) — used to derive
        // drift-free balances; crypto accounts fall back to the double sums.
        _transactionRepository.getFutureSumsExactMinor(currentState.activeDate),
        _transactionRepository.getFutureSumsExactMinor(prevEnd),
        // Period-range transactions cover both current and previous period
        // (prevStart..periodEnd); used for income/expense stats only.
        _transactionRepository.getTransactionsWithFilters(
          filters: TransactionFilters(
            dateFrom: prevStart,
            dateTo: periodEnd,
            excludeAccountId: assetAccountIds,
            excludeCategoryId: transferCategoryIds,
          ),
          limit: _allMatchingRows,
        ),
        // Asset accounts need their own history for asset stats; the linked
        // cash legs (which may live on other accounts) are chased below.
        if (assetAccountIds.isNotEmpty)
          _transactionRepository.getTransactionsWithFilters(
            filters: TransactionFilters(accountId: assetAccountIds),
            limit: _allMatchingRows,
          ),
      ]);

      final futureSums = txResults[0] as Map<String, double>;
      final prevFutureSums = txResults[1] as Map<String, double>;
      final futureSumsMinor = txResults[2] as Map<String, int>;
      final prevFutureSumsMinor = txResults[3] as Map<String, int>;
      final periodTransactions = txResults[4] as List<Transaction>;

      List<Transaction> assetTransactions = const [];
      if (assetAccountIds.isNotEmpty) {
        assetTransactions = txResults[5] as List<Transaction>;
        final linkedIds = assetTransactions
            .map((t) => t.linkedTransactionId)
            .whereType<String>()
            .toList();
        if (linkedIds.isNotEmpty) {
          final linked = await _transactionRepository.getTransactionsByIds(
            linkedIds,
          );
          assetTransactions = [...assetTransactions, ...linked];
        }
      }
      await PerformanceLogger().stop('Accounts: getTransactionsWithFilters');

      // Snapshots carry only the transactions each calculation actually reads.
      final baseSnapshot = FinancialSnapshot(
        accounts: accounts,
        transactions: const [],
        assetData: assets,
        categories: categories,
        exchangeRates: exchangeRates,
        inflationRates: inflationRates,
        date: currentState.activeDate,
        dateStep: currentState.dateStep,
        baseCurrency: 'EUR', // Should likely get this from User Settings
      );
      final assetSnapshot = baseSnapshot.copyWith(
        transactions: assetTransactions,
      );
      final periodSnapshot = baseSnapshot.copyWith(
        transactions: periodTransactions,
      );

      PerformanceLogger().start('FinanceCalculator: Calculations');

      // 1. Nominal balances.
      //    Standard accounts: storedBalance - SUM(amount strictly after the
      //    active date), computed by SQL — exactly the reverse-calc rule, with
      //    no history walked in Dart.
      //    Asset accounts: keep the FinanceCalculator asset valuation, fed only
      //    the asset accounts' own transactions.
      final nominalBalances = <String, double>{};
      for (final account in accounts) {
        if (account.assetId == null) {
          nominalBalances[account.id!] = _nominalBalance(
            account,
            futureSums,
            futureSumsMinor,
          );
        }
      }
      if (assetAccountIds.isNotEmpty) {
        final assetBalances = _financeCalculator.calculateBalances(
          assetSnapshot,
        );
        for (final id in assetAccountIds) {
          nominalBalances[id] = assetBalances[id] ?? 0.0;
        }
      }

      // FIX: Force 0 balance for accounts not created yet
      for (final account in accounts) {
        if (baseSnapshot.date.isBefore(account.creationDate)) {
          nominalBalances[account.id!] = 0.0;
        }
      }

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

      // 2. Calculate Real Balances (Inflation Adjusted) — reuse nominal map.
      final realBalances = _financeCalculator.calculateRealBalances(
        baseSnapshot,
        defaultCountry: defaultCountry,
        balances: nominalBalances,
      );

      // FIX: Force 0 real balance for accounts not created yet
      for (final account in accounts) {
        if (baseSnapshot.date.isBefore(account.creationDate)) {
          realBalances[account.id!] = 0.0;
        }
      }

      // 3. Asset Stats — asset accounts only, fed asset + linked transactions.
      final assetStats = _financeCalculator.calculateAssetStats(
        assetSnapshot,
        balances: nominalBalances,
      );

      // 4. Period Stats (current + previous) from the period-range transactions.
      //    Period boundaries were computed above (before the targeted loads).
      final currentStats = _financeCalculator.calculatePeriodStats(
        periodSnapshot,
        DatePeriod(periodStart, periodEnd),
        defaultCountry: defaultCountry,
      );

      final prevStats = _financeCalculator.calculatePeriodStats(
        periodSnapshot,
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

      // Previous Period Balances (at prevEnd) — same standard/asset split:
      // standard via SQL future-sums at prevEnd, asset via FinanceCalculator.
      final prevBalances = <String, double>{};
      for (final account in accounts) {
        if (account.assetId == null) {
          prevBalances[account.id!] = _nominalBalance(
            account,
            prevFutureSums,
            prevFutureSumsMinor,
          );
        }
      }
      if (assetAccountIds.isNotEmpty) {
        final prevAssetBalances = _financeCalculator.calculateBalances(
          assetSnapshot.copyWith(date: prevEnd),
        );
        for (final id in assetAccountIds) {
          prevBalances[id] = prevAssetBalances[id] ?? 0.0;
        }
      }
      final prevRealBalances = _financeCalculator.calculateRealBalances(
        baseSnapshot.copyWith(date: prevEnd),
        defaultCountry: defaultCountry,
        balances: prevBalances,
      );

      // FIX: Force 0 previous balances for accounts not created yet
      for (final account in accounts) {
        if (prevEnd.isBefore(account.creationDate)) {
          prevBalances[account.id!] = 0.0;
          prevRealBalances[account.id!] = 0.0;
        }
      }

      double income = currentStats.totalIncome;
      double expense = currentStats.totalExpense;

      debugPrint(
        '[SnackBarDebug] AccountsBloc Emitting Success. recentlyDeletedAccount: ${currentState is AccountsLoadSuccess ? currentState.recentlyDeletedAccount?.name : 'null'} -> ${currentState is AccountsLoadSuccess ? currentState.recentlyDeletedAccount?.name : 'null'}',
      );
      emit(
        AccountsLoadSuccess(
          accounts: sortedAccounts,
          accountTypes: accountTypes,
          hasReachedMax: accounts.length >= totalCount,
          totalCount: totalCount,
          sortAscending: filters.sort == Sort.ascending,
          filters: filters,
          activeDate: currentState.activeDate,
          isSelectionModeActive: false,
          selectedAccountIds: {},
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
          recentlyDeletedAccount: state.recentlyDeletedAccount,
          // The only place an AccountsLoadSuccess is built from scratch; every
          // other emit goes through copyWith, which carries these forward.
          unfilteredAccountCount: unfilteredAccountCount,
          unfilteredTransferableAccountCount:
              unfilteredTransferableAccountCount,
        ),
      );
      await PerformanceLogger().stop('Accounts Screen Load');
    } catch (e) {
      PerformanceLogger().stop('Accounts Screen Load');
      emit(
        AccountsLoadFailure(
          recentlyDeletedAccount: state.recentlyDeletedAccount,
          activeDate: state.activeDate,
          dateStep: state.dateStep,
          filters: state.filters,
        ),
      );
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
        if (state is AccountsLoadSuccess) {
          emit((state as AccountsLoadSuccess).copyWith(hasReachedMax: true));
        }
        PerformanceLogger().stop('Accounts Screen Load More');
      } else {
        // Everything the calculator needs for the newly paged-in accounts:
        // unrelated reads that were awaited one after another, on the scroll
        // gesture that appends a page. Only the transaction fetch depends on
        // anything at hand (the ids of the accounts just returned), and those
        // ids are already known here, so they can all go at once.
        //
        // That transaction fetch used to be `accountId: newAccountIds` with no
        // date bound — the complete history of every account the scroll had
        // just appended, serialized row by row across the isolate port, on a
        // gesture that fires at every 90% of the list. Reduced the same way the
        // historical-balance path is (see _onLoadHistoricalBalances): standard
        // accounts are a SQL sum and need no rows at all, only asset accounts
        // genuinely need their history, and the period stats never look outside
        // the visible period and the one before it.
        final newAccountIds = accounts.map((e) => e.id!).toList();
        final newAssetAccountIds = accounts
            .where((a) => a.assetId != null && a.id != null)
            .map((a) => a.id!)
            .toList();
        final hasAssetAccounts = newAssetAccountIds.isNotEmpty;

        // Transfers and rows on asset accounts are thrown away by
        // [FinanceCalculator.calculatePeriodStats] the moment it looks at them,
        // and the period fetch below exists only to feed that call. Every row it
        // ships costs a serialization across drift's isolate port whether the
        // calculator keeps it or not, so the two discards moved into SQL. The
        // predicates are the calculator's own, read off the same two lists the
        // snapshot hands it, so what survives is unchanged row for row.
        //
        // A category id missing from [categories] stays in the result on purpose:
        // the calculator cannot type such a row either, and treats it as spend.
        final transferCategoryIds = currentState.categories
            .where((c) => c.type == CategoryType.transfer && c.id != null)
            .map((c) => c.id!)
            .toList();

        // Period boundaries have to be known before the fetch, since they bound
        // it. Same values snapshotForNew.currentPeriod would produce below —
        // they are built from the same date and step.
        final period = _periodFor(
          currentState.activeDate,
          currentState.dateStep,
        );

        // Previous Period Stats for New
        DateTime prevStart;
        DateTime prevEnd;
        // Kept as-is rather than swapped for DatePeriod.previousFor: for a day
        // step this collapses the previous period to the single instant of its
        // midnight, and that quirk is what the numbers on screen have always
        // been. Changing it here would change displayed values under cover of
        // a performance fix.
        switch (currentState.dateStep) {
          case DateStep.day:
            prevStart = previousDay(period.start);
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

        final moreResults = await Future.wait<Object?>([
          _inflationRepository.getInflationRates(),
          _settingsRepository.getSetting('default_inflation_country'),
          _transactionRepository.getFutureSumsExact(currentState.activeDate),
          _transactionRepository.getFutureSumsExact(prevEnd),
          _transactionRepository.getFutureSumsExactMinor(
            currentState.activeDate,
          ),
          _transactionRepository.getFutureSumsExactMinor(prevEnd),
          _transactionRepository.getTransactionsWithFilters(
            filters: TransactionFilters(
              accountId: newAccountIds,
              dateFrom: prevStart,
              dateTo: period.end,
              excludeAccountId: newAssetAccountIds,
              excludeCategoryId: transferCategoryIds,
            ),
            limit: _allMatchingRows,
          ),
          if (hasAssetAccounts) ...[
            _transactionRepository.getTransactionsWithFilters(
              filters: TransactionFilters(accountId: newAssetAccountIds),
              limit: _allMatchingRows,
            ),
            // Only read when a newly paged account is actually asset-backed.
            _assetRepository.getAssetData(limit: _allAssetEntries),
          ],
        ]);

        final inflationRates = moreResults[0] as List<InflationRateDomain>;
        final defaultCountrySetting = moreResults[1] as Settings?;
        final defaultCountry = defaultCountrySetting?.value ?? 'SRB';
        final futureSums = moreResults[2] as Map<String, double>;
        final prevFutureSums = moreResults[3] as Map<String, double>;
        final futureSumsMinor = moreResults[4] as Map<String, int>;
        final prevFutureSumsMinor = moreResults[5] as Map<String, int>;
        final periodTransactions = moreResults[6] as List<Transaction>;

        List<Transaction> assetTransactions = const [];
        List<AssetDataDomain> assets = const [];
        if (hasAssetAccounts) {
          assetTransactions = moreResults[7] as List<Transaction>;
          assets = moreResults[8] as List<AssetDataDomain>;
          // The cash leg of a trade lives on the cash account, which is not
          // necessarily in this page — chase it by id, as _onLoadAccounts does.
          final linkedIds = assetTransactions
              .map((t) => t.linkedTransactionId)
              .whereType<String>()
              .toList();
          if (linkedIds.isNotEmpty) {
            final linked = await _transactionRepository.getTransactionsByIds(
              linkedIds,
            );
            assetTransactions = [...assetTransactions, ...linked];
          }
        }

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

        // We probably need transaction history for existing accounts to maintain TOTAL stats?
        // State has 'accountIncomes', 'realBalances' etc.
        // We can just ADD new entries to these maps.

        // 1. Calculate for NEW accounts
        // We need a snapshot. But snapshot usually expects the full list of accounts/txs to be consistent?
        // FinanceCalculator.calculateBalances iterates data.transactions.
        // If we only pass new accounts and new transactions, we get balances for new accounts.

        final snapshotForNew = FinancialSnapshot(
          accounts: accounts,
          transactions: const [],
          assetData: assets,
          categories: currentState.categories, // Added
          exchangeRates: currentState.exchangeRates,
          inflationRates: inflationRates,
          date: currentState.activeDate,
          dateStep: currentState.dateStep,
          baseCurrency: 'EUR',
        );
        final assetSnapshotForNew = snapshotForNew.copyWith(
          transactions: assetTransactions,
        );
        final periodSnapshotForNew = snapshotForNew.copyWith(
          transactions: periodTransactions,
        );

        // Standard accounts: storedBalance - SUM(amount after activeDate),
        // straight from SQL. Asset accounts keep the calculator.
        final newNominalBalances = <String, double>{};
        for (final account in accounts) {
          if (account.assetId == null) {
            newNominalBalances[account.id!] = _nominalBalance(
              account,
              futureSums,
              futureSumsMinor,
            );
          }
        }
        if (hasAssetAccounts) {
          final assetBalances = _financeCalculator.calculateBalances(
            assetSnapshotForNew,
          );
          for (final id in newAssetAccountIds) {
            newNominalBalances[id] = assetBalances[id] ?? 0.0;
          }
        }
        final newRealBalances = _financeCalculator.calculateRealBalances(
          snapshotForNew,
          defaultCountry: defaultCountry,
          balances: newNominalBalances,
        );

        // FIX: Force 0 for new accounts if not created yet
        for (final account in accounts) {
          if (snapshotForNew.date.isBefore(account.creationDate)) {
            newNominalBalances[account.id!] = 0.0;
            newRealBalances[account.id!] = 0.0;
          }
        }

        final newAssetStats = _financeCalculator.calculateAssetStats(
          assetSnapshotForNew,
          balances: newNominalBalances,
        );

        // Period Stats for New — boundaries were resolved before the fetch,
        // and the fetch was bounded by them.
        final newCurrentStats = _financeCalculator.calculatePeriodStats(
          periodSnapshotForNew,
          period,
          defaultCountry: defaultCountry,
        );

        final snapshotPrev = snapshotForNew.copyWith(
          date: prevEnd,
        ); // Date doesn't affect stats as much as period param, but good practice
        final newPrevStats = _financeCalculator.calculatePeriodStats(
          periodSnapshotForNew.copyWith(date: prevEnd),
          DatePeriod(prevStart, prevEnd),
          defaultCountry: defaultCountry,
        );

        // Same standard/asset split as above, one cutoff earlier.
        final prevNominalBalances = <String, double>{};
        for (final account in accounts) {
          if (account.assetId == null) {
            prevNominalBalances[account.id!] = _nominalBalance(
              account,
              prevFutureSums,
              prevFutureSumsMinor,
            );
          }
        }
        if (hasAssetAccounts) {
          final prevAssetBalances = _financeCalculator.calculateBalances(
            assetSnapshotForNew.copyWith(date: prevEnd),
          );
          for (final id in newAssetAccountIds) {
            prevNominalBalances[id] = prevAssetBalances[id] ?? 0.0;
          }
        }
        final prevRealBalances = _financeCalculator.calculateRealBalances(
          snapshotPrev,
          defaultCountry: defaultCountry,
          balances: prevNominalBalances,
        );

        // FIX: Force 0 for prev period if not created yet
        for (final account in accounts) {
          if (snapshotPrev.date.isBefore(account.creationDate)) {
            prevNominalBalances[account.id!] = 0.0;
            prevRealBalances[account.id!] = 0.0;
          }
        }

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
          (state as AccountsLoadSuccess).copyWith(
            accounts: sortedAccounts,
            realBalances: updatedRealBalances,
            inflationLosses: updatedInflationLosses,
            accountIncomes: updatedIncomes,
            accountExpenses: updatedExpenses,
            accountRealIncomes: updatedRealIncomes,
            accountRealExpenses: updatedRealExpenses,
            assetValues: updatedNominalBalances,
            assetStats: updatedAssetStats,
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

  /// Deletes that reported nothing when they failed are the reason every
  /// handler below now emits [AccountsState.error]: the account stayed on
  /// screen, the "deleted / Undo" SnackBar was shown anyway, and the only
  /// trace was a `debugPrint` nobody reads in a release build.
  ///
  /// [base] is the state the mutation started from, so a failure never keeps
  /// half-applied optimistic changes.
  void _emitFailure(
    Emitter<AccountsState> emit,
    AccountsState base,
    Object error,
  ) {
    final message = error.toString();
    // Retrying and failing the same way emits an equal state, which bloc drops
    // - the message would appear once and never again. Clear it first so the
    // second attempt is just as visible as the first.
    if (base.error == message) {
      emit(base.copyWith(clearError: true));
    }
    emit(base.copyWith(error: message));
  }

  Future<void> _onAddAccount(
    AddAccount event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      await _accountRepository.addAccount(event.account);
    } catch (e) {
      if (isShuttingDown) return;
      _emitFailure(emit, state, e);
      return;
    }
    if (isShuttingDown) return;
    emit(state.copyWith(clearError: true));
    add(LoadAccounts()); // Reload list
  }

  Future<void> _onUpdateAccount(
    UpdateAccount event,
    Emitter<AccountsState> emit,
  ) async {
    try {
      await _accountRepository.updateAccount(event.account);
    } catch (e) {
      if (isShuttingDown) return;
      _emitFailure(emit, state, e);
      return;
    }
    if (isShuttingDown) return;
    emit(state.copyWith(clearError: true));
    add(LoadAccounts()); // Reload list
  }

  Future<void> _onDeleteAccount(
    DeleteAccount event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess) return;

    // Look the row up while it is still loaded, but announce nothing until the
    // repository confirms it is gone - `firstWhereOrNull` because an account
    // outside the loaded page is a miss, not a crash.
    final accountToDelete = currentState.accounts.firstWhereOrNull(
      (acc) => acc.id == event.id,
    );
    try {
      _rememberUndo(
        event.id,
        tombstoned: await _accountRepository.deleteAccountWithTransactions(
          event.id,
        ),
      );
    } catch (e) {
      debugPrint('ERROR deleting account: $e');
      if (isShuttingDown) return;
      _emitFailure(emit, currentState, e);
      return;
    }
    if (isShuttingDown) return;
    emit(
      currentState.copyWith(
        recentlyDeletedAccount: accountToDelete,
        clearRecentlyDeletedAccount: accountToDelete == null,
        clearError: true,
      ),
    );
    add(LoadAccounts());
  }

  Future<void> _onDeleteAccountWithTransactions(
    DeleteAccountWithTransactions event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess) return;

    final accountToDelete = currentState.accounts.firstWhereOrNull(
      (acc) => acc.id == event.accountId,
    );
    try {
      _rememberUndo(
        event.accountId,
        tombstoned: await _accountRepository.deleteAccountWithTransactions(
          event.accountId,
        ),
      );
    } catch (e) {
      debugPrint('[AccountsBloc] ERROR deleting account: $e');
      if (isShuttingDown) return;
      _emitFailure(emit, currentState, e);
      return;
    }
    if (isShuttingDown) return;
    emit(
      currentState.copyWith(
        recentlyDeletedAccount: accountToDelete,
        clearRecentlyDeletedAccount: accountToDelete == null,
        clearError: true,
      ),
    );
    add(LoadAccounts());
  }

  Future<void> _onDeleteAccountAndReassign(
    DeleteAccountAndReassign event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess) return;

    final accountToDelete = currentState.accounts.firstWhereOrNull(
      (acc) => acc.id == event.accountId,
    );
    try {
      _rememberUndo(
        event.accountId,
        moved: await _accountRepository.deleteAccountAndReassignTransactions(
          event.accountId,
          event.newAccountId,
        ),
      );
    } catch (e) {
      debugPrint('[AccountsBloc] ERROR reassigning and deleting account: $e');
      if (isShuttingDown) return;
      _emitFailure(emit, currentState, e);
      return;
    }
    if (isShuttingDown) return;
    emit(
      currentState.copyWith(
        recentlyDeletedAccount: accountToDelete,
        clearRecentlyDeletedAccount: accountToDelete == null,
        clearError: true,
      ),
    );
    add(LoadAccounts());
  }

  Future<void> _onUndoDeleteAccount(
    UndoDeleteAccount event,
    Emitter<AccountsState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AccountsLoadSuccess ||
        currentState.recentlyDeletedAccount == null) {
      return;
    }
    final account = currentState.recentlyDeletedAccount!;
    // Only the payload recorded for this very account: anything left over from
    // an earlier delete names rows that have nothing to do with it.
    final forThisAccount = _undoAccountId == account.id;
    try {
      await _accountRepository.restoreAccount(
        account,
        tombstonedTransactionIds: forThisAccount
            ? _undoTombstonedTxIds
            : const [],
        movedTransactionIds: forThisAccount ? _undoMovedTxIds : const [],
      );
    } catch (e) {
      debugPrint('[AccountsBloc] ERROR restoring account: $e');
      if (isShuttingDown) return;
      // The account is kept in state: a failed Undo is one the user may retry.
      _emitFailure(emit, currentState, e);
      return;
    }
    if (isShuttingDown) return;
    _forgetUndo();
    emit(
      currentState.copyWith(
        clearRecentlyDeletedAccount: true,
        clearError: true,
      ),
    );
    add(LoadAccounts()); // Reload list
  }

  /// Records what a delete of [accountId] took with it, for [UndoDeleteAccount].
  void _rememberUndo(
    String accountId, {
    List<String> tombstoned = const [],
    List<String> moved = const [],
  }) {
    _undoAccountId = accountId;
    _undoTombstonedTxIds = tombstoned;
    _undoMovedTxIds = moved;
  }

  void _forgetUndo() {
    _undoAccountId = null;
    _undoTombstonedTxIds = const [];
    _undoMovedTxIds = const [];
  }

  void _onClearRecentlyDeletedAccount(
    ClearRecentlyDeletedAccount event,
    Emitter<AccountsState> emit,
  ) {
    debugPrint(
      '[SnackBarDebug] AccountsBloc: Clearing recentlyDeletedAccount (Explicit Clear)',
    );
    _forgetUndo();
    emit(state.copyWith(clearRecentlyDeletedAccount: true));
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
      await _settingsRepository.saveSetting(
        'account_filters',
        event.filters.toJsonString(),
      );
      if (isShuttingDown) return;
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
        _categoryRepository.getCategories(), // Added
        _settingsRepository.getSetting('default_inflation_country'),
      ]);
      // Superseded by a newer date before the first hop even returned: the
      // remaining reads and the whole calculator pass below would be thrown
      // away by the emitter anyway, so stop paying for them here.
      if (emit.isDone) return;

      final accounts = results[0] as List<Account>;
      final exchangeRates = results[1] as List<ExchangeRateDomain>;
      final inflationRates = results[2] as List<InflationRateDomain>;
      final categories = results[3] as List<Category>; // Added
      final defaultCountrySetting = results[4] as Settings?;
      final defaultCountry = defaultCountrySetting?.value ?? 'SRB';

      final accountIds = accounts.map((e) => e.id).whereType<String>().toList();
      final assetAccountIds = accounts
          .where((a) => a.assetId != null && a.id != null)
          .map((a) => a.id!)
          .toList();
      final hasAssetAccounts = assetAccountIds.isNotEmpty;

      // The period this date lands in, plus the one before it. Both are needed
      // before the fetch below, because they are what bounds it.
      final period = _periodFor(event.date, currentState.dateStep);
      final previous = period.previousFor(currentState.dateStep);
      final prevStart = previous.start;
      final prevEnd = previous.end;

      // --- Targeted reads (this used to be the whole transaction table) ---
      //
      // Every tap on a date chevron pulled `getTransactionsWithFilters(
      // accountId: <every displayed account>)` with no date bound — the entire
      // history of every account on screen — and then walked it seven times in
      // Dart. drift runs the SQL off the UI isolate, but each returned row is
      // serialized across the isolate port and re-materialized here, so the
      // cost of that fetch is the row count, and the row count grows forever
      // while the answer it feeds does not. That is the lag the chevrons had.
      //
      // What the rows were actually for, and what each part now costs:
      //  * standard-account balances: reverse calc, balanceAt(cutoff) ==
      //    storedBalance - SUM(amount after cutoff). SQL can return the sum, so
      //    these accounts need ZERO rows — same aggregates _onLoadAccounts
      //    already uses.
      //  * asset accounts: genuinely need rows (quantity accumulates per
      //    transaction, fees are per row, cost basis reads the linked cash
      //    leg), so they still get theirs — and only theirs.
      //  * period stats: only ever look at transactions inside
      //    prevStart..period.end, and discard the rest.
      //
      // The account filter is kept on the period fetch on purpose: these stats
      // have always been scoped to the accounts on screen here, and dropping
      // that would silently fold hidden accounts into the header totals.
      // Transfers and rows on asset accounts are thrown away by
      // [FinanceCalculator.calculatePeriodStats] the moment it looks at them,
      // and the period fetch below exists only to feed that call. Every row it
      // ships costs a serialization across drift's isolate port whether the
      // calculator keeps it or not, so the two discards moved into SQL. The
      // predicates are the calculator's own, read off the same two lists the
      // snapshot hands it, so what survives is unchanged row for row.
      //
      // A category id missing from [categories] stays in the result on purpose:
      // the calculator cannot type such a row either, and treats it as spend.
      final transferCategoryIds = categories
          .where((c) => c.type == CategoryType.transfer && c.id != null)
          .map((c) => c.id!)
          .toList();

      PerformanceLogger().start('Accounts: getTransactionsWithFilters');
      final txResults = await Future.wait<Object?>([
        _transactionRepository.getFutureSumsExact(event.date),
        _transactionRepository.getFutureSumsExact(prevEnd),
        // Exact integer-minor counterparts (fiat only) — used to derive
        // drift-free balances; crypto/commodity accounts have a null
        // amountMinor and fall back to the double sums.
        _transactionRepository.getFutureSumsExactMinor(event.date),
        _transactionRepository.getFutureSumsExactMinor(prevEnd),
        _transactionRepository.getTransactionsWithFilters(
          filters: TransactionFilters(
            accountId: accountIds,
            dateFrom: prevStart,
            dateTo: period.end,
            excludeAccountId: assetAccountIds,
            excludeCategoryId: transferCategoryIds,
          ),
          limit: _allMatchingRows,
        ),
        if (hasAssetAccounts) ...[
          _transactionRepository.getTransactionsWithFilters(
            filters: TransactionFilters(accountId: assetAccountIds),
            limit: _allMatchingRows,
          ),
          // Only read when something on screen is actually asset-backed: with
          // no asset account the entries are dead weight that nothing indexes.
          _assetRepository.getAssetData(limit: _allAssetEntries),
        ],
      ]);
      await PerformanceLogger().stop('Accounts: getTransactionsWithFilters');
      if (emit.isDone) return;

      final futureSums = txResults[0] as Map<String, double>;
      final prevFutureSums = txResults[1] as Map<String, double>;
      final futureSumsMinor = txResults[2] as Map<String, int>;
      final prevFutureSumsMinor = txResults[3] as Map<String, int>;
      final periodTransactions = txResults[4] as List<Transaction>;

      List<Transaction> assetTransactions = const [];
      List<AssetDataDomain> assets = const [];
      if (hasAssetAccounts) {
        assetTransactions = txResults[5] as List<Transaction>;
        assets = txResults[6] as List<AssetDataDomain>;
        // Cost basis reads the cash leg of each trade, and that leg lives on
        // the cash account, not the asset one. The old full-history fetch was
        // filtered to the *displayed* accounts, so a trade paid from an account
        // the filter or the page boundary hid contributed nothing to invested /
        // realized — the same chase _onLoadAccounts does, for the same reason.
        final linkedIds = assetTransactions
            .map((t) => t.linkedTransactionId)
            .whereType<String>()
            .toList();
        if (linkedIds.isNotEmpty) {
          final linked = await _transactionRepository.getTransactionsByIds(
            linkedIds,
          );
          if (emit.isDone) return;
          assetTransactions = [...assetTransactions, ...linked];
        }
      }

      // 2. Construct Snapshots at Target Date — each carries only the
      // transactions the calculation reading it actually looks at.
      final snapshot = FinancialSnapshot(
        accounts: accounts,
        transactions: const [],
        assetData: assets,
        categories: categories, // Added
        exchangeRates: exchangeRates,
        inflationRates: inflationRates,
        date: event.date, // Target Date
        dateStep: currentState.dateStep,
        baseCurrency: 'EUR',
      );
      final assetSnapshot = snapshot.copyWith(transactions: assetTransactions);
      final periodSnapshot = snapshot.copyWith(
        transactions: periodTransactions,
      );

      PerformanceLogger().start('FinanceCalculator: Calculations');

      // 1. Nominal Balances.
      //    Standard accounts: storedBalance - SUM(amount strictly after the
      //    target date), straight from SQL — the same rule calculateBalances
      //    applies, with no history walked in Dart.
      //    Asset accounts: still the calculator, fed only their own rows.
      final nominalBalances = <String, double>{};
      for (final account in accounts) {
        if (account.assetId == null) {
          nominalBalances[account.id!] = _nominalBalance(
            account,
            futureSums,
            futureSumsMinor,
          );
        }
      }
      if (hasAssetAccounts) {
        final assetBalances = _financeCalculator.calculateBalances(
          assetSnapshot,
        );
        for (final id in assetAccountIds) {
          nominalBalances[id] = assetBalances[id] ?? 0.0;
        }
      }

      // FIX: Force 0 balance for accounts not created yet
      for (final account in accounts) {
        if (snapshot.date.isBefore(account.creationDate)) {
          nominalBalances[account.id!] = 0.0;
        }
      }

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
        balances: nominalBalances,
      );

      // FIX: Force 0 real balance for accounts not created yet
      for (final account in accounts) {
        if (snapshot.date.isBefore(account.creationDate)) {
          realBalances[account.id!] = 0.0;
        }
      }

      // 3. Asset Stats (Added) — asset accounts only, so the asset snapshot
      // holds everything it reads.
      final assetStats = _financeCalculator.calculateAssetStats(
        assetSnapshot,
        balances: nominalBalances,
      );

      // 3. Period Stats (Current) — period boundaries were resolved before the
      // fetch, and the fetch was bounded by them.
      final currentStats = _financeCalculator.calculatePeriodStats(
        periodSnapshot,
        period,
        defaultCountry: defaultCountry,
      );

      // 4. Period Stats (Previous)
      final prevSnapshot = snapshot.copyWith(date: prevEnd);
      final prevStats = _financeCalculator.calculatePeriodStats(
        periodSnapshot.copyWith(date: prevEnd),
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

      // 6. Previous Period Balances — same standard/asset split as above, one
      // cutoff earlier.
      final prevBalances = <String, double>{};
      for (final account in accounts) {
        if (account.assetId == null) {
          prevBalances[account.id!] = _nominalBalance(
            account,
            prevFutureSums,
            prevFutureSumsMinor,
          );
        }
      }
      if (hasAssetAccounts) {
        final prevAssetBalances = _financeCalculator.calculateBalances(
          assetSnapshot.copyWith(date: prevEnd),
        );
        for (final id in assetAccountIds) {
          prevBalances[id] = prevAssetBalances[id] ?? 0.0;
        }
      }
      final prevRealBalances = _financeCalculator.calculateRealBalances(
        prevSnapshot,
        defaultCountry: defaultCountry,
        balances: prevBalances,
      );

      // FIX: Force 0 previous balances for accounts not created yet
      for (final account in accounts) {
        if (prevSnapshot.date.isBefore(account.creationDate)) {
          prevBalances[account.id!] = 0.0;
          prevRealBalances[account.id!] = 0.0;
        }
      }

      await PerformanceLogger().stop('FinanceCalculator: Calculations');

      double income = currentStats.totalIncome;
      double expense = currentStats.totalExpense;

      emit(
        (state as AccountsLoadSuccess).copyWith(
          accounts: sortedAccounts,
          realBalances: realBalances,
          inflationLosses: inflationLosses,
          accountIncomes: currentStats.income,
          accountExpenses: currentStats.expense,
          accountRealIncomes: currentStats.realIncome,
          accountRealExpenses: currentStats.realExpense,
          assetValues: nominalBalances,
          assetStats: assetStats,
          previousPeriodBalances: prevBalances,
          previousPeriodRealBalances: prevRealBalances,
          previousAccountIncomes: prevStats.income,
          previousAccountExpenses: prevStats.expense,
          previousAccountRealIncomes: prevStats.realIncome,
          previousAccountRealExpenses: prevStats.realExpense,
          income: income,
          expense: expense,
          categories: categories,
          isHistorical: true,
          activeDate: event.date,
        ),
      );
    } catch (e) {
      // Keep old state if error, maybe show snackbar?
      debugPrint('HistoricalLoad Error: $e');
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
    if (isShuttingDown) return;
    emit(
      (state as AccountsLoadSuccess).copyWith(
        selectedAccountIds: {},
        isSelectionModeActive: false,
      ),
    );
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
    if (isShuttingDown) return;
    emit(
      (state as AccountsLoadSuccess).copyWith(
        selectedAccountIds: {},
        isSelectionModeActive: false,
      ),
    );
    add(LoadAccounts());
  }

  List<Account> _sortAccounts(
    List<Account> accounts,
    List<ExchangeRateDomain> rates,
    bool ascending,
  ) {
    // Optimization: Only rebuild rate map if rates have changed
    if (_cachedRates != rates || _cachedRateMap == null) {
      _cachedRateMap = {for (var r in rates) r.toCurrencyCode: r.rate};
      _cachedRateMap!['EUR'] = 1.0;
      _cachedRates = rates;
    }

    final rateMap = _cachedRateMap!;

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
