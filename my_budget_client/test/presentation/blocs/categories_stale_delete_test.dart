// Deleting a category the list no longer holds.
//
// The list a screen shows is a snapshot. A selection made against it outlives
// the sync pull that removes the row it names, and the delete handler looked
// that id up with a bare `firstWhere`. That throws `StateError: No element`
// out of the handler - an unhandled bloc error and a dead screen - where the
// honest outcome is that there is nothing left to delete.
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  _FakeCategoryRepository(this.categories);

  final List<Category> categories;
  final deleted = <String>[];

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      List.of(categories);

  @override
  Future<List<Category>> getCategoriesByIds(List<String> ids) async =>
      categories.where((c) => ids.contains(c.id)).toList();

  @override
  Future<void> deleteCategory(String id) async {
    deleted.add(id);
    categories.removeWhere((c) => c.id == id);
  }

  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();

  @override
  Future<Map<String, double>> getCategoryTotalsInMainCurrency({
    DateTime? dateFrom,
    DateTime? dateTo,
    required String mainCurrencyCode,
  }) async => const {};

  /// No category has transactions, so the delete takes the soft-delete branch
  /// rather than asking for confirmation.
  @override
  Future<List<Transaction>> getTransactionsWithFilters({
    int limit = 10,
    int offset = 0,
    Sort sort = Sort.descending,
    TransactionFilters? filters,
  }) async => const [];
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;

  @override
  Future<void> saveSetting(String key, String value) async {}
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations() async =>
      const [];
}

/// Records what the bloc reports through `onError`, which is where an
/// exception thrown by an event handler ends up.
class _RecordingBloc extends CategoriesBloc {
  _RecordingBloc({
    required super.categoryRepository,
    required super.settingsRepository,
    required super.transactionRepository,
    required super.currencyRepository,
  });

  final errors = <Object>[];

  @override
  void onError(Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(error, stackTrace);
  }
}

Category _category(String id, String name) =>
    Category(id: id, name: name, type: CategoryType.expense);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeCategoryRepository repository;
  late _RecordingBloc bloc;

  setUp(() async {
    repository = _FakeCategoryRepository([
      _category('1', 'Groceries'),
      _category('2', 'Rent'),
    ]);
    bloc = _RecordingBloc(
      categoryRepository: repository,
      settingsRepository: _FakeSettingsRepository(),
      transactionRepository: _FakeTransactionRepository(),
      currencyRepository: _FakeCurrencyRepository(),
    );

    final loaded = bloc.stream
        .where((s) => s is CategoriesLoadSuccess)
        .first
        .timeout(const Duration(seconds: 5));
    bloc.add(LoadCategories());
    await loaded;
  });

  tearDown(() => bloc.close());

  test('deleting a category the list no longer holds reports no error', () async {
    // The id was on the list when the user picked it and is gone by the time
    // the event arrives, which is what a pull between the two leaves behind.
    bloc.add(const DeleteCategory('gone'));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(
      bloc.errors,
      isEmpty,
      reason: 'a row that is already gone is not a crash',
    );
    expect(repository.deleted, isEmpty);
  });

  test('deleting a category that is still there still deletes it', () async {
    // The guard has to remove the crash, not the feature.
    bloc.add(const DeleteCategory('1'));
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(bloc.errors, isEmpty);
    expect(repository.deleted, ['1']);
  });
}
