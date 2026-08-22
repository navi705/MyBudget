// `_onAccountsUpdated` resolved the still-open form's `selectedAccount` and
// `linkedAccount` against the freshly pushed account list with
// `firstWhereOrNull` and passed the results straight to `copyWith`.
// `firstWhereOrNull` returns null when the account is no longer in the list -
// it was deleted, typically on another device and pulled in by sync while the
// form sat open - and `copyWith` reads a null argument as "no change", so the
// deleted account stayed selected.
//
// Deleting an account soft-deletes every transaction on it, so the user has
// already said "remove this account and everything on it", and every list,
// total and net-worth figure filters deleted accounts out:
//
// - linkedAccount, transfers: the outgoing leg lands on the From account and
//   the balance drops by 500 EUR, the incoming leg is written to the deleted
//   row. Net worth falls by 500 EUR and no account gained anything. An asset
//   buy inverts it: 0.5 BTC arrives, the deleted cash account "pays", and net
//   worth jumps by 30,000 EUR out of nothing.
// - selectedAccount: a 240 EUR expense shows up in the transactions list and
//   in every category report (those queries filter deleted transactions, not
//   deleted accounts) while the balance adjustment lands on the hidden row.
//   The monthly spending total is 240 EUR larger than the sum of what the
//   accounts actually lost, and the row has no account name to search by.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';

/// The account feed the bloc subscribes to in `_onLoad`. `push` is the sync
/// arriving: whatever list the repository hands over next becomes the whole
/// truth about which accounts still exist.
///
/// Everything unimplemented on the other fakes is left that way on purpose:
/// a call the handler was not meant to make should fail loudly instead of
/// quietly returning a default that would change what the test proves.
class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository(this._initialAccounts);

  final List<Account> _initialAccounts;
  final StreamController<List<Account>> _controller =
      StreamController<List<Account>>.broadcast();

  @override
  Future<List<Account>> getAccounts() async => _initialAccounts;

  @override
  Stream<List<Account>> watchAccounts() => _controller.stream;

  void push(List<Account> accounts) => _controller.add(accounts);

  Future<void> dispose() => _controller.close();
}

class _FakeTransactionRepository extends Fake
    implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      const [];

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream<List<Category>>.empty();
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<Currency>> getCurrencies() async => const [_eur];
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;
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

// EUR is also the main currency the fake settings fall back to, so the rate
// section never comes alive and nothing in these tests depends on rates.
const _eur = Currency(
  name: 'Euro',
  code: 'EUR',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

final _fromAccount = Account(
  id: 'a1',
  name: 'Wallet',
  balance: 1000,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

final _toAccount = Account(
  id: 'a2',
  name: 'Savings',
  balance: 2000,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

const _selectedAccountDeletedMessage =
    'The account you selected has been deleted';
const _linkedAccountDeletedMessage =
    'The linked account you selected has been deleted';

/// A transfer form filled in far enough to be saveable: `_fromAccount` is the
/// account the transaction is written to, `_toAccount` is the other leg.
/// `_onLoad` re-derives `selectedAccount` as `accounts.first`, which is
/// `_fromAccount`, and leaves `linkedAccount` untouched - so the seeded pair
/// survives the load and the only thing that can disturb it is the push.
AddEditTransactionState _seed() => AddEditTransactionState(
  accounts: [_fromAccount, _toAccount],
  selectedAccount: _fromAccount,
  linkedAccount: _toAccount,
  date: DateTime(2025, 3, 15),
  mainCurrencyCode: 'EUR',
);

void main() {
  late _FakeAccountRepository accountRepository;

  AddEditTransactionBloc build() {
    accountRepository = _FakeAccountRepository([_fromAccount, _toAccount]);
    return AddEditTransactionBloc(
      transactionRepository: _FakeTransactionRepository(),
      accountRepository: accountRepository,
      categoryRepository: _FakeCategoryRepository(),
      currencyRepository: _FakeCurrencyRepository(),
      settingsRepository: _FakeSettingsRepository(),
      assetRepository: _FakeAssetRepository(),
    );
  }

  tearDown(() async {
    await accountRepository.dispose();
  });

  /// Runs the real load so the bloc is really subscribed to the account feed,
  /// then asserts the seeded pair is still in place - without this the tests
  /// below could pass on a form that never had a selection to lose.
  Future<void> loadAndConfirmSeed(AddEditTransactionBloc bloc) async {
    bloc.add(const AddEditTransactionLoad());
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(bloc.state.selectedAccount, _fromAccount);
    expect(bloc.state.linkedAccount, _toAccount);
    expect(bloc.state.validationError, isNull);
  }

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'an accounts push that dropped the selected account clears it and says so',
    build: build,
    seed: _seed,
    act: (bloc) async {
      await loadAndConfirmSeed(bloc);

      // The sync arrives: 'a1' was deleted on another device, so it is simply
      // absent from the new list.
      accountRepository.push([_toAccount]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      // Sanity: the push landed at all.
      expect(bloc.state.accounts, [_toAccount]);

      expect(bloc.state.selectedAccount, isNull);
      expect(bloc.state.validationError, _selectedAccountDeletedMessage);

      // The other leg was never deleted and must not be collateral damage.
      expect(bloc.state.linkedAccount, _toAccount);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'an accounts push that dropped the linked account clears it and says so',
    build: build,
    seed: _seed,
    act: (bloc) async {
      await loadAndConfirmSeed(bloc);

      // 'a2' - the To account of the transfer - was deleted.
      accountRepository.push([_fromAccount]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.accounts, [_fromAccount]);

      expect(bloc.state.linkedAccount, isNull);
      expect(bloc.state.validationError, _linkedAccountDeletedMessage);

      // The account the transaction is written to is untouched.
      expect(bloc.state.selectedAccount, _fromAccount);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'an accounts push that still contains both leaves both selections alone '
    'and raises no error',
    build: build,
    seed: _seed,
    act: (bloc) async {
      await loadAndConfirmSeed(bloc);

      // A routine push - a balance changed elsewhere, nothing was deleted.
      // Clearing here would empty a form the user is in the middle of filling
      // in and pop a SnackBar about a deletion that never happened.
      accountRepository.push([_fromAccount.copyWith(balance: 900), _toAccount]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.accounts, hasLength(2));
      // Sanity: this really is a new list, not the old one echoed back.
      expect(bloc.state.accounts.first.balance, 900);

      expect(bloc.state.selectedAccount?.id, _fromAccount.id);
      expect(bloc.state.linkedAccount, _toAccount);
      expect(bloc.state.validationError, isNull);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a form with no linked account at all is not treated as one that lost it',
    build: build,
    seed: () => AddEditTransactionState(
      accounts: [_fromAccount, _toAccount],
      selectedAccount: _fromAccount,
      date: DateTime(2025, 3, 15),
      mainCurrencyCode: 'EUR',
    ),
    act: (bloc) async {
      bloc.add(const AddEditTransactionLoad());
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // Sanity: a plain expense form, no second leg to lose.
      expect(bloc.state.selectedAccount, _fromAccount);
      expect(bloc.state.linkedAccount, isNull);

      accountRepository.push([_fromAccount, _toAccount]);
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
    verify: (bloc) {
      expect(bloc.state.accounts, hasLength(2));
      expect(bloc.state.selectedAccount, _fromAccount);
      expect(bloc.state.linkedAccount, isNull);
      // "There was never a selection" is not "the selection was deleted".
      expect(bloc.state.validationError, isNull);
    },
  );
}
