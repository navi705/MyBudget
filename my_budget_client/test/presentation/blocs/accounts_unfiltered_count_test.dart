// AccountsState.accounts is the list *after* AccountFilters are applied, so it
// cannot answer "does this user own an account". The cold-start guards on the
// accounts, categories and transactions screens ask exactly that, and reading
// the filtered list made them refuse to open a form whenever a type/currency/
// name filter happened to hide the accounts that do exist.
//
// This file pins the two unfiltered counts the bloc now carries: that they come
// from the whole table rather than from the filtered page, and that a plain
// copyWith emit does not drop them.
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';

/// Serves two different answers on purpose: [all] is the whole table and
/// [filteredPage] is what the grid's paginated, filtered query returns.
///
/// Everything the bloc does not call stays unimplemented - a call that was not
/// meant to happen should fail the test loudly rather than return a default.
class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository({required this.all, required this.filteredPage});

  final List<Account> all;
  final List<Account> filteredPage;

  /// Which filters the grid query was handed, to prove the two calls really are
  /// the filtered and the unfiltered read.
  final filtersSeen = <AccountFilters?>[];

  @override
  Future<List<Account>> getAccounts() async => all;

  @override
  Future<List<Account>> getAccountsPaginatedFiltered({
    int limit = 10,
    int offset = 0,
    AccountFilters? accountFilters,
  }) async {
    filtersSeen.add(accountFilters);
    return offset == 0 ? filteredPage : const [];
  }

  @override
  Future<int> getCountWithFilters({List<String>? accountTypeIds}) async =>
      filteredPage.length;

  @override
  Future<List<AccountType>> getAccountTypes() async => const [];

  @override
  Stream<List<Account>> watchAccounts() => const Stream.empty();
}

/// Replays [accountFilters] as the persisted `account_filters` setting, which
/// is how a filter survives a restart and reaches a cold-start guard.
class _FakeSettingsRepository extends Fake implements SettingsRepository {
  _FakeSettingsRepository(this.accountFilters);

  final AccountFilters? accountFilters;

  @override
  Future<Settings?> getSetting(String key) async {
    final filters = accountFilters;
    if (key == 'account_filters' && filters != null) {
      return Settings(key: key, value: filters.toJsonString(), device: 'test');
    }
    return null;
  }

  @override
  Future<void> saveSetting(String key, String value) async {}
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<ExchangeRateDomain>> getLatestExchangeRates(
    DateTime date,
  ) async => const [];
}

class _FakeInflationRepository extends Fake implements InflationRepository {
  @override
  Future<List<InflationRateDomain>> getInflationRates() async => const [];
}

class _FakeAssetRepository extends Fake implements AssetRepository {
  @override
  Future<List<AssetDataDomain>> getAssetData({
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
  }) async => const [];
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      const [];

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();
}

/// No transactions at all: this file is about counting accounts, and the
/// balance engine is characterized elsewhere.
class _FakeTransactionRepository extends Fake implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream<void>.empty();

  @override
  Future<Map<String, double>> getFutureSumsExact(DateTime cutoff) async =>
      const {};

  @override
  Future<Map<String, int>> getFutureSumsExactMinor(DateTime cutoff) async =>
      const {};

  @override
  Future<List<Transaction>> getTransactionsWithFilters({
    int limit = 10,
    int offset = 0,
    Sort sort = Sort.descending,
    TransactionFilters? filters,
  }) async => const [];
}

Account _account(String id, String name, {String? assetId}) => Account(
  id: id,
  name: name,
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
  assetId: assetId,
  assetQuantity: 2,
);

final _checking = _account('a1', 'Checking');
final _savings = _account('a2', 'Savings');
final _gold = _account('a3', 'Gold', assetId: 'xau');

void main() {
  // The bloc's PerformanceLogger reaches for ServicesBinding.instance.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeAccountRepository accountRepository;

  /// A bloc whose grid query returns [filteredPage] while the table holds [all].
  AccountsBloc build({
    required List<Account> all,
    required List<Account> filteredPage,
    AccountFilters? savedFilters,
  }) {
    accountRepository = _FakeAccountRepository(
      all: all,
      filteredPage: filteredPage,
    );
    return AccountsBloc(
      accountRepository: accountRepository,
      settingsRepository: _FakeSettingsRepository(savedFilters),
      currencyRepository: _FakeCurrencyRepository(),
      inflationRepository: _FakeInflationRepository(),
      transactionRepository: _FakeTransactionRepository(),
      assetRepository: _FakeAssetRepository(),
      categoryRepository: _FakeCategoryRepository(),
      financeCalculator: FinanceCalculator(),
    );
  }

  Future<AccountsLoadSuccess> load(AccountsBloc bloc) async {
    bloc.add(LoadAccounts());
    return await bloc.stream.firstWhere((s) => s is AccountsLoadSuccess)
        as AccountsLoadSuccess;
  }

  // The filter that hides everything: a name nothing matches. This is the shape
  // of the bug - three accounts in the table, a grid showing none of them.
  const hidesEverything = AccountFilters(
    name: 'nothing matches this',
    sort: Sort.descending,
  );

  test(
    'a filter that hides every account leaves the unfiltered count intact',
    () async {
      final bloc = build(
        all: [_checking, _savings, _gold],
        filteredPage: const [],
        savedFilters: hidesEverything,
      );
      final state = await load(bloc);

      expect(state.accounts, isEmpty, reason: 'the grid shows nothing');
      expect(state.unfilteredAccountCount, 3);

      // And the filter really was applied to the grid query only.
      expect(accountRepository.filtersSeen.single?.name, hidesEverything.name);

      await bloc.close();
    },
  );

  test('transferable accounts are counted across the whole table', () async {
    final bloc = build(
      all: [_checking, _savings, _gold],
      // A filter narrow enough to leave a single row on screen.
      filteredPage: [_checking],
      savedFilters: const AccountFilters(name: 'Check', sort: Sort.descending),
    );
    final state = await load(bloc);

    expect(state.accounts.single.id, 'a1');
    // Two of the three are transferable; the gold holding never counts because
    // both pickers on the transfer form drop asset accounts.
    expect(state.unfilteredTransferableAccountCount, 2);

    await bloc.close();
  });

  test('an empty table reports no accounts', () async {
    final bloc = build(all: const [], filteredPage: const []);
    final state = await load(bloc);

    expect(state.unfilteredAccountCount, 0);
    expect(state.unfilteredTransferableAccountCount, 0);

    await bloc.close();
  });

  test('a copyWith emit carries the counts forward', () async {
    final bloc = build(
      all: [_checking, _savings, _gold],
      filteredPage: const [],
      savedFilters: hidesEverything,
    );
    await load(bloc);

    // SortAccounts is a pure copyWith emit - no reload behind it - so it is
    // where a forgotten field would surface as a silent zero.
    bloc.add(const SortAccounts(true));
    final sorted = await bloc.stream.first as AccountsLoadSuccess;

    expect(sorted.sortAscending, isTrue);
    expect(sorted.unfilteredAccountCount, 3);
    expect(sorted.unfilteredTransferableAccountCount, 2);

    await bloc.close();
  });

  group('AccountsLoadSuccess without the counts', () {
    AccountsLoadSuccess loaded(List<Account> accounts) => AccountsLoadSuccess(
      accounts: accounts,
      accountTypes: const [],
      hasReachedMax: true,
      totalCount: accounts.length,
      exchangeRates: const [],
      activeDate: DateTime(2024, 1, 1),
    );

    // A state built by hand knows nothing about the table, so the honest
    // fallback is the list it does have - the behaviour the guards had before
    // the counts existed, rather than a claim that the user owns nothing.
    test('falls back to its own list', () {
      expect(loaded([_checking, _gold]).unfilteredAccountCount, 2);
      expect(loaded([_checking, _gold]).unfilteredTransferableAccountCount, 1);
    });

    test('keeps tracking the list it is copied with', () {
      final copied = loaded([
        _checking,
      ]).copyWith(accounts: [_checking, _savings]);

      expect(copied.unfilteredAccountCount, 2);
      expect(copied.unfilteredTransferableAccountCount, 2);
    });
  });
}
