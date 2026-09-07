import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction, GroupedTransactionTotal;
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/data/repositories/local_db/local_account_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_asset_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_category_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_currency_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_inflation_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_transaction_repository.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';

/// Regression cover for the date-chevron lag on the accounts screen.
///
/// Tapping a chevron dispatches DatePeriodNavigated / ActiveDateChanged, which
/// both land in AccountsBloc._onLoadHistoricalBalances. That handler used to
/// pull `getTransactionsWithFilters(accountId: <every displayed account>)` with
/// no date bound — the entire transaction history — and walk it seven times in
/// Dart. drift runs the SQL on a background isolate, but every returned row is
/// serialized across the isolate port and rebuilt on the UI isolate, so the
/// cost of that call is the row count and nothing else.
///
/// Two things are pinned here:
///  1. how many rows the handler is allowed to pull (none at all for the
///     balances of non-asset accounts — those are a SQL sum);
///  2. that the numbers it produces did not move, for a fixture containing
///     both a fiat account and an asset account.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late RecordingTransactionRepository transactions;

  /// Wraps the real repository so a test can see exactly which reads a handler
  /// performed and how many rows each one shipped across the isolate port.
  /// Everything is delegated, so the bloc runs against real SQL throughout.

  AccountsBloc buildBloc() => AccountsBloc(
    accountRepository: LocalAccountRepository(db),
    settingsRepository: LocalSettingsRepository(db),
    currencyRepository: LocalCurrencyRepository(db),
    inflationRepository: LocalInflationRepository(db.inflationRatesDao),
    transactionRepository: transactions,
    assetRepository: LocalAssetRepository(db.assetEntriesDao),
    categoryRepository: LocalCategoryRepository(db),
    financeCalculator: FinanceCalculator(),
  );

  Future<AccountsLoadSuccess> nextLoad(AccountsBloc bloc) => bloc.stream
      .firstWhere((s) => s is AccountsLoadSuccess && !s.isHistorical)
      .then((s) => s as AccountsLoadSuccess);

  Future<AccountsLoadSuccess> nextHistorical(AccountsBloc bloc) => bloc.stream
      .firstWhere((s) => s is AccountsLoadSuccess && s.isHistorical)
      .then((s) => s as AccountsLoadSuccess);

  late String currencyCode;
  late String designationId;
  late String accountTypeId;
  late String categoryId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    transactions = RecordingTransactionRepository(
      LocalTransactionRepository(db),
    );

    final currencies = await db.select(db.currencies).get();
    currencyCode = currencies
        .firstWhere((c) => c.code == 'EUR', orElse: () => currencies.first)
        .code;
    designationId = (await db.select(db.currencyDesignations).get()).first.id;
    accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    categoryId = (await db.select(db.categories).get()).first.id;
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> insertAccount(
    String id,
    double balance, {
    String? assetId,
    double assetQuantity = 0.0,
    required DateTime creationDate,
  }) {
    return db
        .into(db.accounts)
        .insert(
          AccountsCompanion.insert(
            id: Value(id),
            name: id,
            balance: balance,
            currencyCode: currencyCode,
            currencyDesignationId: designationId,
            accountTypeId: accountTypeId,
            creationDate: Value(creationDate),
            assetId: Value(assetId),
            assetQuantity: Value(assetQuantity),
          ),
        );
  }

  Future<void> insertTx(
    String id,
    String accountId,
    double amount,
    DateTime date, {
    double fee = 0.0,
    String? linkedTransactionId,
  }) {
    return db
        .into(db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: Value(id),
            description: id,
            amount: amount,
            date: date,
            accountId: accountId,
            categoryId: categoryId,
            currencyCode: currencyCode,
            fee: Value(fee),
            linkedTransactionId: Value(linkedTransactionId),
          ),
        );
  }

  Future<void> insertAssetEntry(
    String id,
    String assetId,
    DateTime date,
    double value,
  ) {
    return db
        .into(db.assetEntries)
        .insert(
          AssetEntriesCompanion.insert(
            id: Value(id),
            assetId: assetId,
            name: assetId,
            date: date,
            value: value,
            currencyCode: currencyCode,
            source: 'test',
          ),
        );
  }

  group('non-asset accounts read no transaction rows for their balances', () {
    // 18 months of history on two plain fiat accounts, one transaction per
    // account per month. Nothing here is asset-backed, so the reverse-calc
    // balances are entirely derivable from SQL sums.
    const monthsOfHistory = 18;
    late DateTime target;

    setUp(() async {
      final now = DateTime.now();
      // End of last month: the date a single "previous period" chevron tap
      // lands on with the default month step.
      target = DateTime(now.year, now.month, 0, 23, 59, 59);

      await insertAccount(
        'A1',
        1000.0,
        creationDate: DateTime(now.year - 5, 1, 1),
      );
      await insertAccount(
        'A2',
        500.0,
        creationDate: DateTime(now.year - 5, 1, 1),
      );
      for (var i = 0; i < monthsOfHistory; i++) {
        final date = DateTime(now.year, now.month - i, 15, 12);
        await insertTx('a1-$i', 'A1', 10.0, date);
        await insertTx('a2-$i', 'A2', -5.0, date);
      }
      await db.backfillMinorUnits();
    });

    test(
      'navigating a period pulls only the period window, not the table',
      () async {
        expect(
          await db.transactionsDao.getAllCount(),
          monthsOfHistory * 2,
          reason: 'fixture sanity: the table really does hold a long history',
        );

        final bloc = buildBloc();
        bloc.add(LoadAccounts());
        await nextLoad(bloc);

        transactions.reset();
        bloc.add(ActiveDateChanged(target));
        await nextHistorical(bloc);

        // The old handler asked for every row belonging to every displayed
        // account. Nothing may do that any more: every row-returning read on this
        // path has to carry a date window.
        expect(
          transactions.unboundedRowReads,
          isEmpty,
          reason:
              'a row read with no date bound is the full-history fetch coming '
              'back: ${transactions.unboundedRowReads}',
        );
        expect(transactions.fullTableReads, 0);

        // Only the period stats need rows at all, and only for the visible period
        // plus the one before it: months -1 and -2, one transaction per account
        // per month.
        expect(
          transactions.rowsReturned,
          4,
          reason:
              'expected exactly the 4 rows inside prevPeriodStart..periodEnd, '
              'got ${transactions.rowsReturned} of ${monthsOfHistory * 2}',
        );

        // The balances themselves came from aggregates: two cutoffs (the target
        // date and the previous period end), each read as a double sum and as an
        // exact integer-minor sum.
        expect(transactions.futureSumCutoffs.length, 2);
        expect(transactions.futureSumMinorCutoffs.length, 2);

        await bloc.close();
      },
    );

    test('a superseded navigation is dropped, not recomputed', () async {
      // Holding a chevron down used to start a full run per tap under the
      // default `concurrent` transformer: N recomputes, N heavy emits, and no
      // guarantee they finished in the order they were fired — the grid could
      // settle on a date the app bar had already left.
      final bloc = buildBloc();
      bloc.add(LoadAccounts());
      await nextLoad(bloc);

      final seen = <AccountsLoadSuccess>[];
      final sub = bloc.stream
          .where((s) => s is AccountsLoadSuccess && s.isHistorical)
          .listen((s) => seen.add(s as AccountsLoadSuccess));

      transactions.reset();
      final firstDate = target;
      final secondDate = DateTime(target.year, target.month, 0, 23, 59, 59);
      bloc.add(ActiveDateChanged(firstDate));
      bloc.add(ActiveDateChanged(secondDate));

      await bloc.stream.firstWhere(
        (s) => s is AccountsLoadSuccess && s.isHistorical,
      );
      // Long enough for a second run to land if one were still coming, short
      // enough to stay clear of the 500ms change-signal debounce.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await sub.cancel();

      expect(seen.length, 1, reason: 'only the newest date may be emitted');
      expect(seen.single.activeDate, secondDate);
      // And the superseded run stopped at its first await instead of paying for
      // the aggregates and the calculator pass it would have thrown away.
      expect(
        transactions.futureSumCutoffs.length,
        2,
        reason: 'one surviving run reads two cutoffs; a second run would be 4',
      );

      await bloc.close();
    });

    test('balances still reverse-calc correctly off the SQL sums', () async {
      final bloc = buildBloc();
      bloc.add(LoadAccounts());
      await nextLoad(bloc);

      bloc.add(ActiveDateChanged(target));
      final s = await nextHistorical(bloc);

      double bal(String id) => s.accounts.firstWhere((a) => a.id == id).balance;
      // Only the current month's transaction (i == 0) falls after the target,
      // so exactly one transaction per account is undone.
      expect(bal('A1'), 1000.0 - 10.0);
      expect(bal('A2'), 500.0 + 5.0);

      await bloc.close();
    });
  });

  group('paging in more accounts', () {
    // One page is 500 accounts (AccountsState.limit), so 501 is the smallest
    // fixture that exercises the scroll-triggered LoadMoreAccounts path.
    const accountCount = 501;

    setUp(() async {
      final creation = DateTime(DateTime.now().year - 5, 1, 1);
      final future = DateTime.now().add(const Duration(days: 400));
      await db.batch((b) {
        for (var i = 0; i < accountCount; i++) {
          final id = 'ACC${i.toString().padLeft(4, '0')}';
          b.insert(
            db.accounts,
            AccountsCompanion.insert(
              id: Value(id),
              name: id,
              balance: 100.0,
              currencyCode: currencyCode,
              currencyDesignationId: designationId,
              accountTypeId: accountTypeId,
              creationDate: Value(creation),
            ),
          );
          // Dated well past today, so reverse calc has to undo it.
          b.insert(
            db.transactions,
            TransactionsCompanion.insert(
              id: Value('tx-$id'),
              description: 'tx-$id',
              amount: 10.0,
              date: future,
              accountId: id,
              categoryId: categoryId,
              currencyCode: currencyCode,
            ),
          );
        }
      });
      await db.backfillMinorUnits();
    });

    test('appends a page without reading its history', () async {
      final bloc = buildBloc();
      bloc.add(LoadAccounts());
      final first = await nextLoad(bloc);
      expect(first.accounts.length, 500);
      expect(first.hasReachedMax, isFalse);

      transactions.reset();
      bloc.add(LoadMoreAccounts());
      final more = await bloc.stream.firstWhere(
        (s) => s is AccountsLoadSuccess && s.accounts.length == accountCount,
      );
      final s = more as AccountsLoadSuccess;

      expect(s.hasReachedMax, isTrue);
      // Reverse calc: stored 100 minus the transaction dated after today.
      expect(
        s.accounts.every((a) => a.balance == 90.0),
        isTrue,
        reason:
            'every account, paged in or already loaded, reverse-calcs to 90',
      );

      // This path used to pull the whole history of the accounts it just
      // appended. There is nothing asset-backed here, so it should now ship no
      // transaction rows at all: the balances are sums, and the period window
      // holds nothing (the only transaction is 400 days out).
      expect(transactions.unboundedRowReads, isEmpty);
      expect(transactions.rowsReturned, 0);
      expect(transactions.futureSumCutoffs.length, 2);

      await bloc.close();
    });
  });

  group('fiat + asset fixture keeps its numbers', () {
    late DateTime target;
    late DateTime thisMonth;

    setUp(() async {
      final now = DateTime.now();
      thisMonth = DateTime(now.year, now.month, 1);
      target = DateTime(now.year, now.month, 0, 23, 59, 59);
      final creation = DateTime(now.year - 5, 1, 1);

      await insertAccount('CASH', 1000.0, creationDate: creation);
      await insertAccount(
        'GOLD',
        0.0,
        assetId: 'gold',
        assetQuantity: 2.0,
        creationDate: creation,
      );

      // Prices: one long before the target, one inside the target month, one
      // after it (which must not be picked for the target date).
      await insertAssetEntry(
        'p1',
        'gold',
        thisMonth.subtract(const Duration(days: 400)),
        100.0,
      );
      await insertAssetEntry(
        'p2',
        'gold',
        DateTime(now.year, now.month - 1, 6),
        150.0,
      );
      await insertAssetEntry(
        'p3',
        'gold',
        DateTime(now.year, now.month, 2),
        900.0,
      );

      // Cash movements, one on each side of the target date.
      await insertTx(
        'c1',
        'CASH',
        300.0,
        DateTime(now.year, now.month - 3, 15),
      );
      await insertTx(
        'c2',
        'CASH',
        -50.0,
        DateTime(now.year, now.month - 1, 10),
      );
      await insertTx('c3', 'CASH', 200.0, DateTime(now.year, now.month, 1, 12));

      // A buy: the quantity leg sits on the asset account, the cash leg it is
      // priced from sits on CASH.
      await insertTx(
        'g1',
        'GOLD',
        1.0,
        DateTime(now.year, now.month - 1, 3),
        fee: 5.0,
        linkedTransactionId: 'cash-leg',
      );
      await insertTx(
        'cash-leg',
        'CASH',
        -150.0,
        DateTime(now.year, now.month - 1, 3),
      );
      // A second buy, after the target date: must not move anything.
      await insertTx('g2', 'GOLD', 5.0, DateTime(now.year, now.month, 2, 12));

      await db.backfillMinorUnits();
    });

    test('golden balances and asset stats at a historical date', () async {
      final bloc = buildBloc();
      bloc.add(LoadAccounts());
      await nextLoad(bloc);

      bloc.add(ActiveDateChanged(target));
      final s = await nextHistorical(bloc);

      double bal(String id) => s.accounts.firstWhere((a) => a.id == id).balance;

      // Fiat: 1000 stored, minus the only transaction after the target (+200).
      expect(bal('CASH'), 800.0);
      // Asset: price 150 (the entry inside the target month, not the 900 after
      // it) times quantity 2 + 1 (the buy on the 3rd; the one after the target
      // is not counted).
      expect(bal('GOLD'), 450.0);

      // No inflation rates seeded, so real == nominal.
      expect(s.realBalances['CASH'], 800.0);
      expect(s.realBalances['GOLD'], 450.0);

      // Previous period = the month before the target's month. Cash movements
      // after its end are -50, -150 and +200, which cancel.
      expect(s.previousPeriodBalances['CASH'], 1000.0);
      // Gold at that cutoff: price 100, quantity still 2.
      expect(s.previousPeriodBalances['GOLD'], 200.0);

      final gold = s.assetStats['GOLD']!;
      expect(gold.nominalBalance, 450.0);
      // Cost basis comes off the linked cash leg, which lives on CASH — it is
      // fetched by id, so it counts even when the cash account is off screen.
      expect(gold.invested, 150.0);
      expect(gold.commissions, 5.0);

      await bloc.close();
    });

    test(
      'historical path agrees with the initial-load path for the same date',
      () async {
        // The two handlers derive the same figures through independently
        // written code; if the aggregate swap had changed either of them, the
        // screen would show one set of numbers on open and another after a
        // chevron tap that lands on the same date.
        final bloc = buildBloc();
        bloc.add(LoadAccounts());
        await nextLoad(bloc);

        bloc.add(ActiveDateChanged(target));
        final historical = await nextHistorical(bloc);

        // activeDate is now the target, so a plain reload recomputes there.
        bloc.add(LoadAccounts());
        final reloaded = await nextLoad(bloc);

        double bal(AccountsLoadSuccess s, String id) =>
            s.accounts.firstWhere((a) => a.id == id).balance;

        for (final id in ['CASH', 'GOLD']) {
          expect(bal(historical, id), bal(reloaded, id), reason: id);
          expect(historical.realBalances[id], reloaded.realBalances[id]);
          expect(
            historical.previousPeriodBalances[id],
            reloaded.previousPeriodBalances[id],
          );
          expect(
            historical.previousPeriodRealBalances[id],
            reloaded.previousPeriodRealBalances[id],
          );
          expect(historical.accountIncomes[id], reloaded.accountIncomes[id]);
          expect(historical.accountExpenses[id], reloaded.accountExpenses[id]);
        }

        final a = historical.assetStats['GOLD']!;
        final b = reloaded.assetStats['GOLD']!;
        expect(a.nominalBalance, b.nominalBalance);
        expect(a.netBalance, b.netBalance);
        expect(a.invested, b.invested);
        expect(a.realized, b.realized);
        expect(a.commissions, b.commissions);

        expect(historical.income, reloaded.income);
        expect(historical.expense, reloaded.expense);

        await bloc.close();
      },
    );
  });
}

/// A record of one row-returning read: what it asked for and what it cost.
class RowRead {
  final TransactionFilters? filters;
  final int limit;
  final int rowsReturned;
  final String method;

  RowRead(this.method, this.filters, this.limit, this.rowsReturned);

  @override
  String toString() =>
      '$method(dateFrom: ${filters?.dateFrom}, dateTo: ${filters?.dateTo}, '
      'accounts: ${filters?.accountId?.length}, limit: $limit) -> $rowsReturned rows';
}

/// Delegating [TransactionRepository] that records the reads a bloc performed.
///
/// The point of the recording is the row counts: with drift on a background
/// connection, every row a query returns is serialized across the isolate port
/// and rebuilt on the UI isolate, so "how many rows" is the cost model.
class RecordingTransactionRepository implements TransactionRepository {
  final TransactionRepository _inner;

  RecordingTransactionRepository(this._inner);

  final List<RowRead> rowReads = [];
  final List<DateTime> futureSumCutoffs = [];
  final List<DateTime> futureSumMinorCutoffs = [];
  int fullTableReads = 0;

  void reset() {
    rowReads.clear();
    futureSumCutoffs.clear();
    futureSumMinorCutoffs.clear();
    fullTableReads = 0;
  }

  int get rowsReturned =>
      rowReads.fold<int>(0, (sum, r) => sum + r.rowsReturned);

  /// Reads that could return the whole history: a filtered fetch with no date
  /// window on it. Fetch-by-id is excluded — it is bounded by the ids it is
  /// given, which is how the linked cash legs are chased.
  List<RowRead> get unboundedRowReads => rowReads
      .where(
        (r) =>
            r.method == 'getTransactionsWithFilters' &&
            (r.filters?.dateFrom == null || r.filters?.dateTo == null),
      )
      .toList();

  @override
  Future<List<Transaction>> getTransactionsWithFilters({
    int limit = 10,
    int offset = 0,
    Sort sort = Sort.descending,
    TransactionFilters? filters,
  }) async {
    final rows = await _inner.getTransactionsWithFilters(
      limit: limit,
      offset: offset,
      sort: sort,
      filters: filters,
    );
    rowReads.add(
      RowRead('getTransactionsWithFilters', filters, limit, rows.length),
    );
    return rows;
  }

  @override
  Future<String?> linkOffsettingTransfer(String transactionId) =>
      _inner.linkOffsettingTransfer(transactionId);

  @override
  Future<List<Transaction>> getTransactionsByIds(List<String> ids) async {
    final rows = await _inner.getTransactionsByIds(ids);
    rowReads.add(
      RowRead('getTransactionsByIds', null, ids.length, rows.length),
    );
    return rows;
  }

  @override
  Future<Map<String, double>> getFutureSumsExact(DateTime cutoff) {
    futureSumCutoffs.add(cutoff);
    return _inner.getFutureSumsExact(cutoff);
  }

  @override
  Future<Map<String, int>> getFutureSumsExactMinor(DateTime cutoff) {
    futureSumMinorCutoffs.add(cutoff);
    return _inner.getFutureSumsExactMinor(cutoff);
  }

  @override
  Future<List<Transaction>> getTransactions() {
    fullTableReads++;
    return _inner.getTransactions();
  }

  @override
  Future<List<Transaction>> getTransactionsPaginated({
    int limit = 10,
    int offset = 0,
  }) {
    fullTableReads++;
    return _inner.getTransactionsPaginated(limit: limit, offset: offset);
  }

  // --- Everything below is straight delegation. ---

  @override
  Stream<List<Transaction>> watchTransactions({DateTime? from}) =>
      _inner.watchTransactions(from: from);

  @override
  Stream<void> watchTransactionChanges() => _inner.watchTransactionChanges();

  @override
  Future<List<Transaction>> getTransactionsByCategoryId(String categoryId) =>
      _inner.getTransactionsByCategoryId(categoryId);

  @override
  Future<Transaction?> getTransactionById(String id) =>
      _inner.getTransactionById(id);

  @override
  Future<Transaction?> findExistingImportedTransaction({
    required String accountId,
    required DateTime date,
    required double amount,
  }) => _inner.findExistingImportedTransaction(
    accountId: accountId,
    date: date,
    amount: amount,
  );

  @override
  Future<void> addTransaction(Transaction transaction) =>
      _inner.addTransaction(transaction);

  @override
  Future<void> addTransactions(List<Transaction> transactions) =>
      _inner.addTransactions(transactions);

  @override
  Future<void> updateTransaction(Transaction transaction) =>
      _inner.updateTransaction(transaction);

  @override
  Future<void> deleteTransaction(String id) => _inner.deleteTransaction(id);

  @override
  Future<void> deleteMultipleTransactions(List<String> ids) =>
      _inner.deleteMultipleTransactions(ids);

  @override
  Future<void> updateDateForMultipleTransactions(
    List<String> ids,
    DateTime newDate,
  ) => _inner.updateDateForMultipleTransactions(ids, newDate);

  @override
  Future<void> updateCategoryForMultipleTransactions(
    List<String> ids,
    String newCategoryId,
  ) => _inner.updateCategoryForMultipleTransactions(ids, newCategoryId);

  @override
  Future<int> getCountWithFilters({TransactionFilters? filters}) =>
      _inner.getCountWithFilters(filters: filters);

  @override
  Future<int> getAllCount() => _inner.getAllCount();

  @override
  Future<List<GroupedTransactionTotal>> getTransactionTotalsGrouped({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) => _inner.getTransactionTotalsGrouped(dateFrom: dateFrom, dateTo: dateTo);

  @override
  Future<Map<String, double>> getCategoryTotalsInMainCurrency({
    DateTime? dateFrom,
    DateTime? dateTo,
    required String mainCurrencyCode,
  }) => _inner.getCategoryTotalsInMainCurrency(
    dateFrom: dateFrom,
    dateTo: dateTo,
    mainCurrencyCode: mainCurrencyCode,
  );

  @override
  Future<String?> getMostUsedAccountForCategory(
    String categoryId, {
    required DateTime since,
  }) => _inner.getMostUsedAccountForCategory(categoryId, since: since);

  @override
  Future<String?> getLastUsedAccountId() => _inner.getLastUsedAccountId();

  @override
  Future<void> restoreTransactions(List<Transaction> transactions) =>
      _inner.restoreTransactions(transactions);
}
