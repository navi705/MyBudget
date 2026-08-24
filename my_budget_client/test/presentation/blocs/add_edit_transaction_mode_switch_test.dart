// Turning an ordinary entry into a transfer without leaving the form.
//
// The form has had a transfer mode since it was written, and exactly one thing
// could turn it on: `AddEditTransactionLoad(isTransfer: true)`, sent from the
// accounts screen's per-row context menu. From the transactions screen, the
// dashboard or the "+" hotkey a transfer was unreachable - the user had to
// leave the screen they were entering data on, find the source account and
// come back through its menu, which on a phone is the row's overflow button.
//
// The mode is a property of the entry being written, so the form now carries
// its own switch. What that switch has to get right is everything the load
// path was already doing: the system transfer category (which no picker
// offers), the currency lock to the account the money leaves, the destination
// when there is only one it could be, and the reverse - putting all of that
// back the way an ordinary transaction needs it.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';

const _usd = Currency(
  name: 'US Dollar',
  code: 'USD',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

const _eur = Currency(
  name: 'Euro',
  code: 'EUR',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

final _euroAccount = Account(
  id: 'a1',
  name: 'Wallet',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

final _dollarAccount = Account(
  id: 'a2',
  name: 'Savings',
  balance: 0,
  currencyCode: 'USD',
  currencyDesignationId: 'usd',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

/// Holds a quantity, not money: neither picker on the transfer form offers it.
final _bitcoinAccount = Account(
  id: 'a3',
  name: 'BTC',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'asset',
  assetId: 'btc',
  creationDate: DateTime(2025, 1, 1),
);

final _groceries = Category(
  id: 'cat-groceries',
  name: 'Groceries',
  type: CategoryType.expense,
);

final _transferCategory = Category(
  id: 'transfer-cat',
  name: AppConstants.systemTransferCategoryName,
  type: CategoryType.transfer,
);

/// The transfer category is a system one, so it is in the table but not in the
/// list any picker is built from - which is the whole reason the mode has to
/// select it for the user.
class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      includeSystem ? [_groceries, _transferCategory] : [_groceries];

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();
}

/// No transfer category anywhere, and creating one fails: the form still has
/// to come up and switch, because saving is what tells the user.
class _CategorylessRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async => [
    _groceries,
  ];

  @override
  Future<void> addCategory(Category category) async =>
      throw StateError('no writes here');

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository(this.accounts);

  final List<Account> accounts;

  @override
  Future<List<Account>> getAccounts({bool includeArchived = false}) async =>
      accounts;

  @override
  Stream<List<Account>> watchAccounts({bool includeArchived = false}) =>
      const Stream.empty();
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<ExchangeRateDomain>> getExchangeRatesFiltered({
    int limit = 100,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? fromCurrency,
    String? toCurrency,
    List<int>? presets,
    bool sortAscending = false,
  }) async => const [];

  @override
  Future<List<Currency>> getCurrencies() async => const [_usd, _eur];
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();

  @override
  Future<Transaction?> getTransactionById(String id) async => null;
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;
}

class _FakeAssetRepository extends Fake implements AssetRepository {}

void main() {
  AddEditTransactionBloc build({
    List<Account>? accounts,
    CategoryRepository? categories,
  }) => AddEditTransactionBloc(
    transactionRepository: _FakeTransactionRepository(),
    accountRepository: _FakeAccountRepository(
      accounts ?? [_euroAccount, _dollarAccount],
    ),
    categoryRepository: categories ?? _FakeCategoryRepository(),
    currencyRepository: _FakeCurrencyRepository(),
    settingsRepository: _FakeSettingsRepository(),
    assetRepository: _FakeAssetRepository(),
  );

  /// A form opened the ordinary way - the "+" on the transactions screen, with
  /// no account and no mode named.
  Future<void> openBlank(AddEditTransactionBloc bloc) async {
    bloc.add(const AddEditTransactionLoad());
    await bloc.stream.firstWhere(
      (s) => s.status == AddEditTransactionStatus.success,
    );
  }

  group('switching an entry to a transfer', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'reaches the same state the accounts screen route arrives in',
      build: build,
      act: (bloc) async {
        await openBlank(bloc);
        bloc.add(const AddEditTransactionTransferModeChanged(true));
      },
      verify: (bloc) {
        final state = bloc.state;
        expect(state.isTransferMode, isTrue);
        // The category no picker offers.
        expect(state.selectedCategory?.id, _transferCategory.id);
        // Two accounts, so the destination is the only one it could be.
        expect(state.linkedAccount?.id, _dollarAccount.id);
        // Locked to the account the money leaves, the way
        // `_onAccountChanged` keeps it locked afterwards.
        expect(state.selectedCurrency?.code, _euroAccount.currencyCode);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'leaves the destination empty when there is more than one it could be',
      build: () => build(
        accounts: [_euroAccount, _dollarAccount, _bitcoinAccount, _thirdCash],
      ),
      act: (bloc) async {
        await openBlank(bloc);
        bloc.add(const AddEditTransactionTransferModeChanged(true));
      },
      verify: (bloc) {
        // A guessed destination looks like an answered field, and a transfer
        // into the wrong account is invisible afterwards: both legs balance.
        expect(bloc.state.linkedAccount, isNull);
        expect(bloc.state.isTransferMode, isTrue);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'moves off an asset account, which cannot be one end of a transfer',
      build: () =>
          build(accounts: [_bitcoinAccount, _euroAccount, _dollarAccount]),
      act: (bloc) async {
        await openBlank(bloc);
        // The blank form landed on the asset account, so this is the Buy/Sell
        // form asking to become a transfer.
        expect(bloc.state.isAssetTransaction, isTrue);
        bloc.add(const AddEditTransactionTransferModeChanged(true));
      },
      verify: (bloc) {
        expect(bloc.state.isTransferMode, isTrue);
        expect(bloc.state.isAssetTransaction, isFalse);
        expect(bloc.state.selectedAccount?.assetId, isNull);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'still switches when the transfer category cannot be made, because '
      'saving is what reports that',
      build: () => build(categories: _CategorylessRepository()),
      act: (bloc) async {
        await openBlank(bloc);
        bloc.add(const AddEditTransactionTransferModeChanged(true));
      },
      verify: (bloc) => expect(bloc.state.isTransferMode, isTrue),
    );
  });

  group('switching a transfer back to an entry', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'takes the transfer apart instead of leaving half of it behind',
      build: build,
      act: (bloc) async {
        await openBlank(bloc);
        bloc.add(const AddEditTransactionTransferModeChanged(true));
        await bloc.stream.firstWhere((s) => s.linkedAccount != null);
        bloc.add(const AddEditTransactionTransferModeChanged(false));
      },
      verify: (bloc) {
        final state = bloc.state;
        expect(state.isTransferMode, isFalse);
        // A destination account on an expense is a second leg nothing writes.
        expect(state.linkedAccount, isNull);
        // The transfer category is a system one: left selected, the category
        // field would show a value its own picker does not contain.
        expect(state.selectedCategory?.id, _groceries.id);
      },
    );

    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'drops the rate, which belonged to a pair of accounts that is gone',
      build: build,
      seed: () => AddEditTransactionState(
        status: AddEditTransactionStatus.success,
        accounts: [_euroAccount, _dollarAccount],
        categories: [_groceries],
        currencies: const [_usd, _eur],
        selectedAccount: _dollarAccount,
        linkedAccount: _euroAccount,
        selectedCategory: _transferCategory,
        selectedCurrency: _usd,
        isTransferMode: true,
        manualExchangeRate: '0.9',
        manualRateIsHistorical: true,
        date: DateTime(2025, 3, 15),
        mainCurrencyCode: 'EUR',
      ),
      act: (bloc) =>
          bloc.add(const AddEditTransactionTransferModeChanged(false)),
      verify: (bloc) {
        expect(bloc.state.manualExchangeRate, isEmpty);
        expect(bloc.state.manualRateIsHistorical, isFalse);
        expect(bloc.state.selectedExchangeRate, isNull);
      },
    );
  });

  group('an entry that is already saved', () {
    blocTest<AddEditTransactionBloc, AddEditTransactionState>(
      'is not converted in place',
      build: build,
      seed: () => AddEditTransactionState(
        status: AddEditTransactionStatus.success,
        accounts: [_euroAccount, _dollarAccount],
        categories: [_groceries],
        currencies: const [_usd, _eur],
        initialTransaction: Transaction(
          id: 't1',
          description: 'Coffee',
          amount: -3,
          date: DateTime(2025, 3, 15),
          accountId: _euroAccount.id!,
          categoryId: _groceries.id!,
          currencyCode: 'EUR',
        ),
        selectedAccount: _euroAccount,
        selectedCategory: _groceries,
        selectedCurrency: _eur,
        date: DateTime(2025, 3, 15),
        mainCurrencyCode: 'EUR',
      ),
      act: (bloc) =>
          bloc.add(const AddEditTransactionTransferModeChanged(true)),
      // A saved transfer is a linked pair of rows and a saved transaction is
      // one row; converting either way is a rewrite of the other leg, so the
      // switch is not offered - and the bloc does not do it if asked.
      expect: () => const <AddEditTransactionState>[],
    );
  });
}

/// A third cash account, so "which account does this go to" has more than one
/// answer.
final _thirdCash = Account(
  id: 'a4',
  name: 'Cash',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);
