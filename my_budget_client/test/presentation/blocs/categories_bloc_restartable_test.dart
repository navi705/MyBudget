import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';

/// `LoadCategories` runs a per-category aggregate over the whole transaction
/// table, and every date control on the screen adds one. Under the default
/// `concurrent` transformer a held chevron started one per tap and let them
/// all finish, so the grid could settle on the totals of a month the app bar
/// had already left.
///
/// These tests hold the aggregate open on a gate, which is the only way the
/// overlap is observable: without one, each load finishes before the next
/// event is dispatched and `concurrent` looks identical to `restartable`.
class _GatedTransactionRepository extends Fake
    implements TransactionRepository {
  final List<Completer<Map<String, double>>> gates = [];
  final List<DateTime?> dateFromSeen = [];

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();

  @override
  Future<Map<String, double>> getCategoryTotalsInMainCurrency({
    DateTime? dateFrom,
    DateTime? dateTo,
    required String mainCurrencyCode,
  }) {
    dateFromSeen.add(dateFrom);
    final gate = Completer<Map<String, double>>();
    gates.add(gate);
    return gate.future;
  }
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      const Stream.empty();

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async => [
    Category(id: 'c1', name: 'Groceries'),
  ];
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations() async => [];
}

void main() {
  // PerformanceLogger reaches for ServicesBinding; without this the logs
  // bury the test output in binding errors that have nothing to do with the
  // behaviour under test.
  TestWidgetsFlutterBinding.ensureInitialized();

  late _GatedTransactionRepository transactions;
  late CategoriesBloc bloc;

  setUp(() {
    transactions = _GatedTransactionRepository();
    bloc = CategoriesBloc(
      categoryRepository: _FakeCategoryRepository(),
      settingsRepository: _FakeSettingsRepository(),
      transactionRepository: transactions,
      currencyRepository: _FakeCurrencyRepository(),
    );
  });

  tearDown(() async => bloc.close());

  /// Lets the event loop run far enough for a handler to reach its first
  /// await, without completing any gate.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('a superseded load emits nothing', () async {
    final emitted = <CategoriesState>[];
    final subscription = bloc.stream.listen(emitted.add);
    addTearDown(subscription.cancel);

    bloc.add(LoadCategories());
    await settle();
    bloc.add(LoadCategories());
    await settle();

    expect(
      transactions.gates.length,
      2,
      reason: 'the second load never started, so nothing was superseded',
    );

    // Finish the first (cancelled) load last, so a bloc that still listened to
    // it would emit its stale result after the newer one.
    transactions.gates[1].complete({'c1': 20.0});
    await settle();
    transactions.gates[0].complete({'c1': 10.0});
    await settle();
    await settle();

    final successes = emitted.whereType<CategoriesLoadSuccess>().toList();
    expect(successes, hasLength(1));
    expect(successes.single.categoriesWithTotals.single.total, 20.0);
  });

  test('a date change supersedes the load already in flight', () async {
    bloc.add(LoadCategories());
    await settle();
    transactions.gates.first.complete({'c1': 1.0});
    await settle();

    // Two chevron taps in a row, the second before the first load resolves.
    bloc.add(const DatePeriodNavigated(1));
    await settle();
    bloc.add(const DatePeriodNavigated(1));
    await settle();

    for (final gate in transactions.gates.skip(1)) {
      if (!gate.isCompleted) gate.complete({'c1': 2.0});
    }
    await settle();
    await settle();

    final state = bloc.state as CategoriesLoadSuccess;
    // The window that reached the screen is the one belonging to the last tap,
    // not the one whose query happened to finish last.
    expect(state.activeDate.month, transactions.dateFromSeen.last!.month);
  });

  test('close() during a load does not throw', () async {
    bloc.add(LoadCategories());
    await settle();

    final closing = bloc.close();
    transactions.gates.first.complete({'c1': 5.0});
    await expectLater(closing, completes);
  });
}
