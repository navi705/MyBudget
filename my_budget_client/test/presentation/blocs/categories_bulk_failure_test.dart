import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';

/// Pins the reporting of failed bulk category operations.
///
/// The regression: both bulk handlers ran their writes in a loop inside a
/// `try` whose `catch` was empty, and dispatched the reload after the loop.
/// A throw halfway therefore left part of the selection written, cleared the
/// selection, showed nothing, and skipped the reload - so the list on screen
/// did not even reveal what had actually happened.
class _FakeCategoryRepository extends Fake implements CategoryRepository {
  _FakeCategoryRepository(this.categories);

  /// Mutated by the writes below, so a reload shows the real post-operation
  /// state rather than a canned one.
  final List<Category> categories;

  /// Ids whose write throws. Every other id is written for real.
  final Set<String> failingIds = {};

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      List.of(categories);

  @override
  Future<List<Category>> getCategoriesByIds(List<String> ids) async =>
      categories.where((c) => ids.contains(c.id)).toList();

  @override
  Future<void> deleteCategory(String id) async {
    if (failingIds.contains(id)) throw Exception('delete failed for $id');
    categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> updateCategory(Category category) async {
    if (failingIds.contains(category.id)) {
      throw Exception('update failed for ${category.id}');
    }
    categories[categories.indexWhere((c) => c.id == category.id)] = category;
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

Category _category(String id, String name) =>
    Category(id: id, name: name, type: CategoryType.expense);

/// Waits for the loaded state that satisfies [test], or fails on timeout.
///
/// A bulk handler emits its outcome and only then dispatches `LoadCategories`,
/// so neither the failure nor the reload is reliably the last state - they
/// cannot be asserted by reading `bloc.state` after an `await`.
Future<CategoriesLoadSuccess> _firstSuccessWhere(
  CategoriesBloc bloc,
  bool Function(CategoriesLoadSuccess) test,
) async => await bloc.stream
    .where((s) => s is CategoriesLoadSuccess)
    .cast<CategoriesLoadSuccess>()
    .firstWhere(test)
    .timeout(const Duration(seconds: 5));

void main() {
  group('a failed categories bulk operation reaches the UI', () {
    late _FakeCategoryRepository repository;
    late CategoriesBloc bloc;

    setUp(() async {
      repository = _FakeCategoryRepository([
        _category('1', 'Groceries'),
        _category('2', 'Rent'),
        _category('3', 'Fuel'),
      ]);
      bloc = CategoriesBloc(
        categoryRepository: repository,
        settingsRepository: _FakeSettingsRepository(),
        transactionRepository: _FakeTransactionRepository(),
        currencyRepository: _FakeCurrencyRepository(),
      );

      final loaded = _firstSuccessWhere(
        bloc,
        (s) => s.categoriesWithTotals.length == 3,
      );
      bloc.add(LoadCategories());
      await loaded;
    });

    tearDown(() => bloc.close());

    test(
      'a bulk delete that throws carries the error into the state',
      () async {
        repository.failingIds.add('2');

        final failed = _firstSuccessWhere(bloc, (s) => s.error != null);
        bloc.add(const DeleteMultipleCategories(['1', '2', '3']));

        expect((await failed).error, contains('delete failed for 2'));
      },
    );

    test('a bulk delete that throws still reloads the list', () async {
      repository.failingIds.add('2');

      // Category 1 is already deleted by the time the loop throws on 2.
      final reloaded = _firstSuccessWhere(
        bloc,
        (s) => s.categoriesWithTotals.length == 2,
      );
      bloc.add(const DeleteMultipleCategories(['1', '2', '3']));

      expect(
        (await reloaded).categoriesWithTotals.map((c) => c.category.id),
        unorderedEquals(['2', '3']),
      );
    });

    test(
      'a bulk type change that throws carries the error into the state',
      () async {
        repository.failingIds.add('3');

        final failed = _firstSuccessWhere(bloc, (s) => s.error != null);
        bloc.add(
          const UpdateCategoryTypeForMultipleCategories([
            '1',
            '2',
            '3',
          ], CategoryType.income),
        );

        expect((await failed).error, contains('update failed for 3'));
      },
    );

    test('a bulk type change that throws still reloads the list', () async {
      repository.failingIds.add('3');

      final reloaded = _firstSuccessWhere(
        bloc,
        (s) =>
            s.error == null &&
            s.allCategories.any((c) => c.type == CategoryType.income),
      );
      bloc.add(
        const UpdateCategoryTypeForMultipleCategories([
          '1',
          '2',
          '3',
        ], CategoryType.income),
      );

      expect(
        (await reloaded).allCategories
            .where((c) => c.type == CategoryType.income)
            .map((c) => c.id),
        unorderedEquals(['1', '2']),
        reason: 'the two writes that landed before the throw must be on screen',
      );
    });

    test('the reload clears the error the failure left behind', () async {
      repository.failingIds.add('2');

      final failed = _firstSuccessWhere(bloc, (s) => s.error != null);
      bloc.add(const DeleteMultipleCategories(['2']));
      await failed;

      // The reload the handler queues is what recovers the state; a message
      // that survives it would be reported again as if it were new.
      expect(
        (await _firstSuccessWhere(bloc, (s) => s.error == null)).error,
        isNull,
      );
    });
  });
}
