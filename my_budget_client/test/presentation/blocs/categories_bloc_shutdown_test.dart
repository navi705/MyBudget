import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';

/// Pins the shutdown-race fix in [CategoriesBloc]'s handlers.
///
/// Same mechanism as accounts_bloc_shutdown_test.dart /
/// sms_bloc_shutdown_test.dart: `Bloc.close()` closes its event controller
/// synchronously, well before `isClosed` flips, so a handler resuming from
/// an `await` after close() has started must check `isShuttingDown` — a
/// bare `isClosed` check still reads false and lets `add()` through, which
/// throws.
class _FakeCategoryRepository extends Fake implements CategoryRepository {
  _FakeCategoryRepository({required this.addCategoryGate});

  final Completer<void> addCategoryGate;

  @override
  Future<void> addCategory(Category category) => addCategoryGate.future;
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {}

void main() {
  group('CategoriesBloc shutdown race', () {
    test(
      'an add-category in flight when close() starts does not throw',
      () async {
        final addCategoryGate = Completer<void>();
        final bloc = CategoriesBloc(
          categoryRepository: _FakeCategoryRepository(
            addCategoryGate: addCategoryGate,
          ),
          settingsRepository: _FakeSettingsRepository(),
          transactionRepository: _FakeTransactionRepository(),
          currencyRepository: _FakeCurrencyRepository(),
        );

        final category = Category(
          name: 'Groceries',
          type: CategoryType.expense,
        );

        bloc.add(AddCategory(category));
        await pumpEventQueue(); // handler suspended on addCategoryGate

        final zoneErrors = <Object>[];
        await runZonedGuarded(() async {
          final closeFuture = bloc.close();
          addCategoryGate.complete();
          await pumpEventQueue();
          await closeFuture;
          await pumpEventQueue();
        }, (error, stack) => zoneErrors.add(error));

        expect(
          zoneErrors,
          isEmpty,
          reason:
              'the resumed handler must bail via isShuttingDown instead of '
              'calling add(LoadCategories()) on a bloc whose event controller '
              'is already closed',
        );
      },
    );
  });
}
