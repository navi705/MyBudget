// Where a transfer is filed when the system transfer category cannot be made.
//
// Both legs of a transfer are written against a category named by
// `AppConstants.systemTransferCategoryName`, created on first use. When that
// creation failed the fallback took whichever category happened to be first -
// so a transfer was filed under "Salary" and turned up in that category's
// totals - and on an empty list it read `.first` of nothing, throwing out of
// the very catch that existed to stop a throw.
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

class _RecordingTransactionRepository extends Fake
    implements TransactionRepository {
  final List<Transaction> added = [];

  @override
  Future<void> addTransaction(Transaction transaction) async =>
      added.add(transaction);

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

/// Hands out [categories] and refuses to create anything, which is the state a
/// write-protected or full database leaves the form in.
class _UncreatableCategoryRepository extends Fake
    implements CategoryRepository {
  _UncreatableCategoryRepository(this.categories);

  final List<Category> categories;

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      categories;

  @override
  Future<void> addCategory(Category category) async =>
      throw Exception('database is read-only');

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();
}

/// Creation works, and the created category shows up on the next read - the
/// ordinary first-transfer-ever path.
class _CreatingCategoryRepository extends Fake implements CategoryRepository {
  final List<Category> categories = [_salary];

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      List.of(categories);

  @override
  Future<void> addCategory(Category category) async => categories.add(
    Category(
      id: 'transfer-cat',
      name: category.name,
      type: category.type,
    ),
  );

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
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
  Future<List<Currency>> getCurrencies() async => const [_eur];
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Future<List<Account>> getAccounts({bool includeArchived = false}) async => [
    _wallet,
    _savings,
  ];

  @override
  Stream<List<Account>> watchAccounts({bool includeArchived = false}) =>
      const Stream.empty();
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;
}

class _FakeAssetRepository extends Fake implements AssetRepository {}

const _eur = Currency(
  name: 'Euro',
  code: 'EUR',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

final _salary = Category(
  id: 'salary-cat',
  name: 'Salary',
  type: CategoryType.income,
);

final _wallet = Account(
  id: 'a1',
  name: 'Wallet',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

final _savings = Account(
  id: 'a2',
  name: 'Savings',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'eur',
  accountTypeId: 'cash',
  creationDate: DateTime(2025, 1, 1),
);

/// 100 EUR moving between two accounts of the same currency, so nothing but
/// the category stands between this state and two written legs.
AddEditTransactionState get _transfer => AddEditTransactionState(
  selectedAccount: _wallet,
  linkedAccount: _savings,
  selectedCurrency: _eur,
  isTransferMode: true,
  amount: '100',
  date: DateTime(2025, 3, 15),
  mainCurrencyCode: 'EUR',
);

void main() {
  late _RecordingTransactionRepository transactionRepository;

  AddEditTransactionBloc build(CategoryRepository categoryRepository) {
    transactionRepository = _RecordingTransactionRepository();
    return AddEditTransactionBloc(
      transactionRepository: transactionRepository,
      accountRepository: _FakeAccountRepository(),
      categoryRepository: categoryRepository,
      currencyRepository: _FakeCurrencyRepository(),
      settingsRepository: _FakeSettingsRepository(),
      assetRepository: _FakeAssetRepository(),
    );
  }

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a transfer is not filed under an unrelated category when the system one '
    'cannot be created',
    build: () => build(_UncreatableCategoryRepository([_salary])),
    seed: () => _transfer,
    act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
    verify: (bloc) {
      expect(
        transactionRepository.added,
        isEmpty,
        reason: 'a transfer filed under "Salary" corrupts that category',
      );
      expect(bloc.state.validationError, isNotNull);
      expect(bloc.state.isSaving, isFalse);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a transfer with no categories at all reports instead of throwing',
    build: () => build(_UncreatableCategoryRepository([])),
    seed: () => _transfer,
    act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
    errors: () => isEmpty,
    verify: (bloc) {
      expect(transactionRepository.added, isEmpty);
      expect(bloc.state.validationError, isNotNull);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'the transfer form still opens when the category cannot be created',
    // The same lookup runs while the form loads, and a failure there used to
    // abort the whole initialisation - no accounts, no pickers, an empty
    // screen - for a problem that only matters at save time and that only the
    // save path can report.
    build: () => build(_UncreatableCategoryRepository([])),
    act: (bloc) => bloc.add(const AddEditTransactionLoad(isTransfer: true)),
    errors: () => isEmpty,
    verify: (bloc) {
      expect(bloc.state.isTransferMode, isTrue);
      expect(bloc.state.selectedAccount, isNotNull);
      expect(bloc.state.selectedCategory, isNull);
    },
  );

  blocTest<AddEditTransactionBloc, AddEditTransactionState>(
    'a transfer is written against the category that was just created',
    build: () => build(_CreatingCategoryRepository()),
    seed: () => _transfer,
    act: (bloc) => bloc.add(const AddEditTransactionSubmitted()),
    verify: (_) {
      expect(transactionRepository.added, hasLength(2));
      for (final t in transactionRepository.added) {
        expect(
          t.categoryId,
          'transfer-cat',
          reason: 'both legs belong to ${AppConstants.systemTransferCategoryName}',
        );
      }
    },
  );
}
