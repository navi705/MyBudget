// Every mutation in AccountsBloc used to swallow its exception into a
// `debugPrint`: a failed save closed its screen, a failed delete still put the
// "deleted / Undo" SnackBar on screen, and the account was still there after
// the list reloaded. Worse, the delete handlers looked the row up with a bare
// `firstWhere` outside any try, so deleting an account that was not in the
// loaded page threw StateError before the repository was ever called.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/domain/entities/category.dart';

/// Fails every write, and records what it was asked to write.
///
/// Anything the bloc does not call stays unimplemented on purpose - a call that
/// was not meant to happen should fail the test loudly, not return a default.
class _FailingAccountRepository extends Fake implements AccountRepository {
  _FailingAccountRepository(this.failure);

  final Object failure;
  final deleted = <String>[];
  final reassigned = <String>[];
  final restored = <Account>[];

  @override
  Future<void> addAccount(Account account) async => throw failure;

  @override
  Future<void> updateAccount(Account account) async => throw failure;

  @override
  Future<List<String>> deleteAccountWithTransactions(String id) async {
    deleted.add(id);
    throw failure;
  }

  @override
  Future<List<String>> deleteAccountAndReassignTransactions(
    String accountId,
    String newAccountId,
  ) async {
    reassigned.add(accountId);
    throw failure;
  }

  @override
  Future<void> restoreAccount(
    Account account, {
    List<String> tombstonedTransactionIds = const [],
    List<String> movedTransactionIds = const [],
  }) async {
    restored.add(account);
    throw failure;
  }

  @override
  Stream<List<Account>> watchAccounts() => const Stream.empty();
}

/// The bloc subscribes to this in its constructor; an empty stream keeps the
/// reload it triggers out of these tests.
class _QuietTransactionRepository extends Fake
    implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream<void>.empty();
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {}

class _FakeInflationRepository extends Fake implements InflationRepository {}

class _FakeAssetRepository extends Fake implements AssetRepository {}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();
}

class _FakeFinanceCalculator extends Fake implements FinanceCalculator {}

Account _account(String id, String name) => Account(
  id: id,
  name: name,
  balance: 100,
  currencyCode: 'USD',
  currencyDesignationId: 'usd',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

AccountsLoadSuccess _loaded({
  List<Account> accounts = const [],
  Account? recentlyDeletedAccount,
}) => AccountsLoadSuccess(
  accounts: accounts,
  accountTypes: const [],
  hasReachedMax: true,
  totalCount: accounts.length,
  activeDate: DateTime(2025, 3, 15),
  exchangeRates: const [],
  recentlyDeletedAccount: recentlyDeletedAccount,
);

void main() {
  late _FailingAccountRepository accountRepository;

  final failure = Exception('database is locked');

  AccountsBloc build() {
    accountRepository = _FailingAccountRepository(failure);
    return AccountsBloc(
      accountRepository: accountRepository,
      settingsRepository: _FakeSettingsRepository(),
      currencyRepository: _FakeCurrencyRepository(),
      inflationRepository: _FakeInflationRepository(),
      transactionRepository: _QuietTransactionRepository(),
      assetRepository: _FakeAssetRepository(),
      categoryRepository: _FakeCategoryRepository(),
      financeCalculator: _FakeFinanceCalculator(),
    );
  }

  Matcher reportsFailure({Object? recentlyDeletedAccountId}) =>
      isA<AccountsState>()
          .having((s) => s.error, 'error', contains('database is locked'))
          .having(
            (s) => s.recentlyDeletedAccount?.id,
            'recentlyDeletedAccount',
            recentlyDeletedAccountId,
          );

  final loadedOne = _loaded(accounts: [_account('a1', 'Wallet')]);

  blocTest<AccountsBloc, AccountsState>(
    'a failed delete reports the error and offers no Undo',
    build: build,
    seed: () => loadedOne,
    act: (bloc) => bloc.add(const DeleteAccount('a1')),
    expect: () => [reportsFailure()],
    verify: (_) => expect(accountRepository.deleted, ['a1']),
  );

  blocTest<AccountsBloc, AccountsState>(
    'deleting an account outside the loaded page reaches the repository '
    'instead of throwing StateError',
    build: build,
    // The account exists in the database but not on this page - the old
    // `firstWhere` threw here, before the delete was even attempted.
    seed: () => loadedOne,
    act: (bloc) => bloc.add(const DeleteAccountWithTransactions('a2')),
    expect: () => [reportsFailure()],
    verify: (_) => expect(accountRepository.deleted, ['a2']),
  );

  blocTest<AccountsBloc, AccountsState>(
    'a failed reassign-and-delete reports the error',
    build: build,
    seed: () => loadedOne,
    act: (bloc) => bloc.add(const DeleteAccountAndReassign('a1', 'a9')),
    expect: () => [reportsFailure()],
    verify: (_) => expect(accountRepository.reassigned, ['a1']),
  );

  blocTest<AccountsBloc, AccountsState>(
    'a failed add reports the error',
    build: build,
    seed: () => loadedOne,
    act: (bloc) => bloc.add(AddAccount(_account('a2', 'Savings'))),
    expect: () => [reportsFailure()],
  );

  blocTest<AccountsBloc, AccountsState>(
    'a failed update reports the error',
    build: build,
    seed: () => loadedOne,
    act: (bloc) => bloc.add(UpdateAccount(_account('a1', 'Renamed'))),
    expect: () => [reportsFailure()],
  );

  blocTest<AccountsBloc, AccountsState>(
    'a failed undo keeps the account so the user can try again',
    build: build,
    seed: () => _loaded(recentlyDeletedAccount: _account('a1', 'Wallet')),
    act: (bloc) => bloc.add(UndoDeleteAccount()),
    expect: () => [reportsFailure(recentlyDeletedAccountId: 'a1')],
    verify: (_) => expect(accountRepository.restored.single.id, 'a1'),
  );

  blocTest<AccountsBloc, AccountsState>(
    'a second identical failure is emitted again so the message can reappear',
    build: build,
    seed: () => loadedOne,
    act: (bloc) => bloc
      ..add(const DeleteAccount('a1'))
      ..add(const DeleteAccount('a1')),
    // The second failure carries the same message, so on its own it would be
    // an equal state and bloc would drop it - the SnackBar would show once and
    // never again. The handler clears `error` first to make it visible.
    expect: () => [
      reportsFailure(),
      isA<AccountsState>().having((s) => s.error, 'error', isNull),
      reportsFailure(),
    ],
    verify: (_) => expect(accountRepository.deleted, ['a1', 'a1']),
  );
}
