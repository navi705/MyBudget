// Picking a category on the entry form pre-fills the account that category is
// usually paid from. It is the single most repeated correction in the app: the
// form opens on whatever account it opened on, and the user changes it to the
// same one every single time for a given category.
//
// The whole risk of the feature is a suggestion overwriting an answer, so most
// of what is pinned here is when it must NOT fire: an account the user picked,
// a saved transaction being edited (changing its account moves two balances),
// and transfer mode (the account is the source leg the destination is checked
// against).
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';

/// Answers the suggestion query, and records what it was asked - the window is
/// part of the contract: a category paid from an account the user abandoned
/// months ago must stop being suggested.
class _FakeTransactionRepository extends Fake implements TransactionRepository {
  _FakeTransactionRepository({this.answer, this.fail = false});

  final String? answer;
  final bool fail;
  final List<String> asked = [];
  DateTime? askedSince;
  Transaction? updated;

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();

  @override
  Future<String?> getMostUsedAccountForCategory(
    String categoryId, {
    required DateTime since,
  }) async {
    asked.add(categoryId);
    askedSince = since;
    if (fail) throw StateError('the database refused the read');
    return answer;
  }

  @override
  Future<void> updateTransaction(Transaction transaction) async {
    updated = transaction;
  }
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Stream<List<Account>> watchAccounts() => const Stream.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {}

class _FakeSettingsRepository extends Fake implements SettingsRepository {}

class _FakeAssetRepository extends Fake implements AssetRepository {}

final _wallet = Account(
  id: 'acc-wallet',
  name: 'Wallet',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

final _card = Account(
  id: 'acc-card',
  name: 'Card',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

// Holds a quantity rather than a sum: selecting one turns the form into an
// asset transaction, which is never something a category pick should do.
final _assetAccount = Account(
  id: 'acc-asset',
  name: 'Gold',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'asset',
  assetId: 'asset-1',
  creationDate: DateTime(2025, 1, 1),
);

final _groceries = Category(
  id: 'cat-groceries',
  name: 'Groceries',
  type: CategoryType.expense,
);

/// A new entry, opened on the wallet, with both accounts loaded. No currency is
/// selected, so no rate fetch runs and the suggestion is what the test sees.
AddEditTransactionState _newEntry() => AddEditTransactionState(
  accounts: [_wallet, _card, _assetAccount],
  selectedAccount: _wallet,
  date: DateTime(2025, 3, 15),
  mainCurrencyCode: 'EUR',
);

void main() {
  late _FakeTransactionRepository transactionRepository;

  AddEditTransactionBloc build() => AddEditTransactionBloc(
    transactionRepository: transactionRepository,
    accountRepository: _FakeAccountRepository(),
    categoryRepository: _FakeCategoryRepository(),
    currencyRepository: _FakeCurrencyRepository(),
    settingsRepository: _FakeSettingsRepository(),
    assetRepository: _FakeAssetRepository(),
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'picking a category fills in the account that category is usually paid '
    'from',
    setUp: () {
      transactionRepository = _FakeTransactionRepository(answer: 'acc-card');
    },
    build: build,
    seed: _newEntry,
    act: (bloc) => bloc.add(AddEditTransactionCategoryChanged(_groceries)),
    verify: (bloc) {
      expect(bloc.state.selectedCategory, _groceries);
      expect(bloc.state.selectedAccount, _card);
      expect(transactionRepository.asked, ['cat-groceries']);
      // A month back: one billing cycle, so a category used weekly has a clear
      // winner and an account dropped two months ago is already gone.
      final since = transactionRepository.askedSince!;
      expect(
        DateTime.now().difference(since).inDays,
        inInclusiveRange(29, 31),
      );
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'an account the user picked is not overwritten by a later category',
    setUp: () {
      transactionRepository = _FakeTransactionRepository(answer: 'acc-card');
    },
    build: build,
    seed: _newEntry,
    act: (bloc) async {
      bloc.add(AddEditTransactionAccountChanged(_wallet));
      await Future<void>.delayed(Duration.zero);
      bloc.add(AddEditTransactionCategoryChanged(_groceries));
    },
    verify: (bloc) {
      expect(bloc.state.selectedAccount, _wallet);
      expect(
        transactionRepository.asked,
        isEmpty,
        reason: 'nothing to suggest once the question has been answered',
      );
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a saved transaction being edited keeps the account it was written on',
    setUp: () {
      transactionRepository = _FakeTransactionRepository(answer: 'acc-card');
    },
    build: build,
    seed: () => _newEntry().copyWith(
      initialTransaction: Transaction(
        id: 'tx-1',
        description: 'Shop',
        amount: -10,
        date: DateTime(2025, 3, 1),
        accountId: 'acc-wallet',
        categoryId: 'cat-other',
        currencyCode: 'EUR',
      ),
    ),
    act: (bloc) => bloc.add(AddEditTransactionCategoryChanged(_groceries)),
    verify: (bloc) {
      // Re-pointing a saved row at another account moves two balances, and
      // recategorising an imported transaction is exactly what the review
      // queue asks the user to do.
      expect(bloc.state.selectedAccount, _wallet);
      expect(transactionRepository.asked, isEmpty);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'transfer mode is left alone',
    setUp: () {
      transactionRepository = _FakeTransactionRepository(answer: 'acc-card');
    },
    build: build,
    seed: () => _newEntry().copyWith(isTransferMode: true),
    act: (bloc) => bloc.add(AddEditTransactionCategoryChanged(_groceries)),
    verify: (bloc) {
      // Here the account is the source leg, and the destination picker is
      // validated against it.
      expect(bloc.state.selectedAccount, _wallet);
      expect(transactionRepository.asked, isEmpty);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'an asset account is never suggested',
    setUp: () {
      transactionRepository = _FakeTransactionRepository(answer: 'acc-asset');
    },
    build: build,
    seed: _newEntry,
    act: (bloc) => bloc.add(AddEditTransactionCategoryChanged(_groceries)),
    verify: (bloc) => expect(bloc.state.selectedAccount, _wallet),
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a category with no history in the window leaves the account alone',
    setUp: () {
      transactionRepository = _FakeTransactionRepository();
    },
    build: build,
    seed: _newEntry,
    act: (bloc) => bloc.add(AddEditTransactionCategoryChanged(_groceries)),
    verify: (bloc) {
      expect(bloc.state.selectedAccount, _wallet);
      expect(bloc.state.selectedCategory, _groceries);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a failed lookup still records the category the user picked',
    setUp: () {
      transactionRepository = _FakeTransactionRepository(fail: true);
    },
    build: build,
    seed: _newEntry,
    act: (bloc) => bloc.add(AddEditTransactionCategoryChanged(_groceries)),
    verify: (bloc) {
      // A convenience must not be able to stop the form from working.
      expect(bloc.state.selectedCategory, _groceries);
      expect(bloc.state.selectedAccount, _wallet);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'saving an imported transaction takes it out of the review queue',
    setUp: () {
      transactionRepository = _FakeTransactionRepository();
    },
    build: build,
    seed: () => _newEntry().copyWith(
      amount: '12.50',
      description: 'C MARKET',
      selectedCategory: _groceries,
      initialTransaction: Transaction(
        id: 'tx-imported',
        description: 'C MARKET',
        amount: -12.50,
        date: DateTime(2025, 3, 1),
        accountId: 'acc-wallet',
        categoryId: 'cat-other',
        currencyCode: 'EUR',
        needsReview: true,
      ),
    ),
    act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
    verify: (bloc) {
      // Saving the form IS the review: the user has looked at the row and
      // confirmed or corrected what the import guessed. Nothing else clears
      // the flag, so without this the queue would only ever grow.
      final saved = transactionRepository.updated;
      expect(saved, isNotNull);
      expect(saved!.id, 'tx-imported');
      expect(saved.needsReview, isFalse);
      expect(saved.categoryId, 'cat-groceries');
    },
  );
}
