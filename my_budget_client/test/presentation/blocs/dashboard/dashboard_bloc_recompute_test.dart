import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';

/// What makes the dashboard recompute, and how many pipelines do it.
///
/// Neither is visible in the emitted states on their own: a memoized walk-back
/// is indistinguishable from a fresh one until the inputs it was keyed on
/// diverge, and a stacked second pipeline emits the same values as a single
/// one. The fakes below therefore expose what the real repositories cannot —
/// a live subscription count per stream, and a call count for the query every
/// pipeline pass issues — so both are asserted rather than inferred.
///
/// Repositories are faked rather than built on a real AppDatabase because the
/// database seeds ~283k exchange rates per test; nothing here needs a rate
/// table, every amount is already in the target currency.

/// A stream that stays open until its subscriber cancels, counting both.
///
/// `Stream.value` would close immediately and let the bloc's combineLatest
/// finish, which is exactly what must not happen while measuring how long a
/// pipeline stays attached. Each call to [stream] hands out a fresh
/// controller, so the counts are of subscriptions, not of calls.
class _LiveStream<T> {
  _LiveStream(this._value);

  T _value;
  final List<StreamController<T>> _controllers = [];

  int listens = 0;
  int cancels = 0;

  /// Subscriptions still attached right now.
  int get live => listens - cancels;

  T get value => _value;

  Stream<T> stream() {
    late final StreamController<T> controller;
    controller = StreamController<T>(
      onListen: () {
        listens++;
        _controllers.add(controller);
        controller.add(_value);
      },
      onCancel: () {
        cancels++;
        _controllers.remove(controller);
      },
    );
    return controller.stream;
  }

  /// Pushes [next] to every live subscriber, as a repository watch would after
  /// the underlying row changed.
  void emit(T next) {
    _value = next;
    for (final controller in List.of(_controllers)) {
      controller.add(next);
    }
  }
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository(this.accounts);

  final _LiveStream<List<Account>> accounts;

  @override
  Stream<List<Account>> watchAccounts() => accounts.stream();
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  _FakeTransactionRepository(this.transactions);

  final _LiveStream<List<Transaction>> transactions;

  /// One call per pipeline pass — the cheapest proof of how many passes ran.
  int totalsCalls = 0;

  @override
  Stream<List<Transaction>> watchTransactions({DateTime? from}) =>
      transactions.stream();

  @override
  Future<List<GroupedTransactionTotal>> getTransactionTotalsGrouped({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    totalsCalls++;
    return const [];
  }

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  _FakeCategoryRepository(this.categories);

  final _LiveStream<List<Category>> categories;

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      categories.stream();

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      categories.value;
}

class _FakeStyleRepository extends Fake implements StyleRepository {
  _FakeStyleRepository(this.styles);

  final _LiveStream<List<Style>> styles;

  @override
  Stream<List<Style>> watchAllStyles() => styles.stream();
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<Currency>> getCurrencies() async => const [];

  @override
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations() async =>
      const [];

  @override
  Future<List<ExchangeRateDomain>> getLatestExchangeRatesByList(
    List<DateTime> date, {
    Set<String>? currencyCodes,
  }) async => const [];

  @override
  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations() =>
      const Stream.empty();

  @override
  Stream<void> watchExchangeRateChanges() => const Stream.empty();
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Map<String, String>> getAllSettings() async => const {
    'main_currency_code': 'EUR',
  };

  @override
  Stream<List<Settings>> watchAllSettings() => const Stream.empty();
}

class _FakeAssetRepository extends Fake implements AssetRepository {
  _FakeAssetRepository(this.assetData);

  final _LiveStream<List<AssetDataDomain>> assetData;

  @override
  Stream<List<AssetDataDomain>> watchAssetData({
    int limit = 50,
    int offset = 0,
    String? assetId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? name,
    List<String>? assetTypes,
    String? description,
    List<String>? currencyCodes,
    List<String>? sources,
    List<int>? presets,
    double? minValue,
    double? maxValue,
    bool sortAscending = false,
  }) => assetData.stream();
}

final _now = DateTime.now();
final _today = DateTime(_now.year, _now.month, _now.day);

Category _category(CategoryType type) =>
    Category(id: 'c1', name: 'Groceries', type: type);

/// Long enough to clear the pipeline's 50ms debounce plus the awaits around it.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 250));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _LiveStream<List<Account>> accounts;
  late _LiveStream<List<Transaction>> transactions;
  late _LiveStream<List<Category>> categories;
  late _LiveStream<List<Style>> styles;
  late _LiveStream<List<AssetDataDomain>> assetData;
  late _FakeTransactionRepository transactionRepository;
  late List<DashboardState> emitted;

  setUp(() {
    accounts = _LiveStream<List<Account>>([
      Account(
        id: 'a1',
        name: 'Cash',
        balance: 1000.0,
        currencyCode: 'EUR',
        currencyDesignationId: 'd1',
        accountTypeId: 'at1',
        creationDate: DateTime(_now.year - 1, 1, 1),
      ),
    ]);
    // Dated today so it lands inside the seeded range (the current month), and
    // negative so it shows up as an expense once its category allows it to.
    transactions = _LiveStream<List<Transaction>>([
      Transaction(
        id: 'tx1',
        description: 'groceries',
        amount: -50.0,
        date: DateTime(_now.year, _now.month, _now.day, 12),
        accountId: 'a1',
        categoryId: 'c1',
        currencyCode: 'EUR',
      ),
    ]);
    categories = _LiveStream<List<Category>>([
      _category(CategoryType.transfer),
    ]);
    styles = _LiveStream<List<Style>>(const []);
    assetData = _LiveStream<List<AssetDataDomain>>(const []);
    transactionRepository = _FakeTransactionRepository(transactions);
    emitted = [];
  });

  DashboardBloc buildBloc() => DashboardBloc(
    accountRepository: _FakeAccountRepository(accounts),
    transactionRepository: transactionRepository,
    categoryRepository: _FakeCategoryRepository(categories),
    styleRepository: _FakeStyleRepository(styles),
    currencyRepository: _FakeCurrencyRepository(),
    settingsRepository: _FakeSettingsRepository(),
    assetRepository: _FakeAssetRepository(assetData),
  );

  group('DashboardBloc compute memo', () {
    blocTest<DashboardBloc, DashboardState>(
      'flipping a category type re-computes income, expense and net worth',
      build: buildBloc,
      act: (bloc) async {
        // The pipeline's other inputs stay the same objects across this act,
        // so the category type is the only thing the memo can key on.
        bloc.stream.listen(emitted.add);
        bloc.add(LoadDashboard());
        await _settle();
        categories.emit([_category(CategoryType.expense)]);
        await _settle();
      },
      expect: () => [
        isA<DashboardLoadInProgress>(),
        // A transfer is excluded from both indicators.
        isA<DashboardLoadSuccess>()
            .having((s) => s.dailyExpenses, 'dailyExpenses', isEmpty)
            .having((s) => s.dailyIncomes, 'dailyIncomes', isEmpty)
            .having((s) => s.dailyNetWorth[_today], 'net worth today', 1000.0),
        // Same transaction, same everything else, expense now.
        isA<DashboardLoadSuccess>()
            .having((s) => s.dailyExpenses, 'dailyExpenses', {_today: 50.0})
            .having((s) => s.dailyIncomes, 'dailyIncomes', isEmpty)
            .having((s) => s.dailyNetWorth[_today], 'net worth today', 1000.0),
      ],
      verify: (_) {
        final successes = emitted.whereType<DashboardLoadSuccess>().toList();
        // Net worth does not depend on the category type, so equal values
        // would prove nothing; distinct map objects prove the walk-back was
        // actually re-run rather than served from the memo.
        expect(
          identical(
            successes.first.dailyNetWorth,
            successes.last.dailyNetWorth,
          ),
          isFalse,
        );
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'a tab change with untouched data still hits the memo',
      build: buildBloc,
      act: (bloc) async {
        bloc.stream.listen(emitted.add);
        bloc.add(LoadDashboard());
        await _settle();
        bloc.add(const ChangeTab(1));
        await _settle();
      },
      verify: (_) {
        final successes = emitted.whereType<DashboardLoadSuccess>().toList();
        expect(successes, hasLength(2));
        expect(
          identical(
            successes.first.dailyNetWorth,
            successes.last.dailyNetWorth,
          ),
          isTrue,
        );
      },
    );
  });

  group('DashboardBloc pipeline ownership', () {
    blocTest<DashboardBloc, DashboardState>(
      'a second LoadDashboard replaces the pipeline instead of stacking on it',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(LoadDashboard());
        await _settle();
        expect(accounts.live, 1);

        bloc.add(LoadDashboard());
        await _settle();
        expect(accounts.live, 1);
        expect(transactions.live, 1);
        expect(assetData.live, 1);
        // The style/category watches the load attaches directly.
        expect(categories.live, 1);
        expect(styles.live, 1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'two loads back to back leave a single pipeline',
      build: buildBloc,
      act: (bloc) async {
        // No settle between them: the second load supersedes the first while
        // it is still awaiting its initial style/category reads.
        bloc.add(LoadDashboard());
        bloc.add(LoadDashboard());
        await _settle();
        expect(accounts.live, 1);
        expect(transactions.live, 1);
        expect(assetData.live, 1);
        expect(categories.live, 1);
        expect(styles.live, 1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'a change after two loads is computed once, not once per load',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(LoadDashboard());
        await _settle();
        bloc.add(LoadDashboard());
        await _settle();

        final before = transactionRepository.totalsCalls;
        bloc.add(const ChangeTab(1));
        await _settle();

        expect(transactionRepository.totalsCalls - before, 1);
      },
    );

    blocTest<DashboardBloc, DashboardState>(
      'close() leaves nothing subscribed',
      build: buildBloc,
      act: (bloc) async {
        bloc.add(LoadDashboard());
        await _settle();
        bloc.add(LoadDashboard());
        await _settle();
      },
      // blocTest closes the bloc before verify runs.
      verify: (_) async {
        // Cancellation propagates upstream over a microtask, so let it land
        // before counting.
        await pumpEventQueue();
        expect(accounts.live, 0);
        expect(transactions.live, 0);
        expect(assetData.live, 0);
        expect(categories.live, 0);
        expect(styles.live, 0);
      },
    );
  });
}
