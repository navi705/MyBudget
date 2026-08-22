// A category with a broken parent link still has to be on the screen.
//
// `parent_id` is a plain nullable column and three ordinary things leave it
// pointing at a row the screen cannot see: deleting a parent soft-deletes the
// parent alone, the page-at-a-time load can hand over a child before its
// parent, and two devices reparenting in opposite directions merge into a loop
// that neither of them made. The screen drew a category at the top level only
// when `parentId == null`, so in all three cases the row was drawn nowhere:
// not in the list, not in the grid, and out of reach of the context menu that
// could have repaired it - while its money went on counting in every total.
//
// These are the screen-level halves of the rule; `test/core/utils/
// category_tree_test.dart` pins the tree itself.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';
import 'package:my_budget_client/presentation/widgets/category_grid.dart';
import 'package:my_budget_client/presentation/widgets/category_list_item.dart';
import 'package:bloc_test/bloc_test.dart';

import '../test_app.dart';

Category category(String id, String name, {String? parent}) =>
    Category(id: id, name: name, type: CategoryType.expense, parentId: parent);

/// A child whose parent is not in the list: the shape left behind by deleting
/// the parent, and by a page that has not reached it yet.
final _orphan = category('c3', 'Rent', parent: 'deleted-parent');
final _plain = category('c1', 'Groceries');

/// The merge case. Each update is valid on its own; together they are a loop.
final _loopA = category('a', 'Travel', parent: 'b');
final _loopB = category('b', 'Flights', parent: 'a');

/// One account, which is all the screen needs to let a category tap through to
/// the transaction form.
AccountsBloc _accountsBloc() {
  final bloc = MockAccountsBloc();
  whenListen(
    bloc,
    const Stream<AccountsState>.empty(),
    initialState: AccountsLoadSuccess(
      accounts: [
        Account(
          id: 'a1',
          name: 'Checking',
          balance: 100,
          currencyCode: 'EUR',
          currencyDesignationId: 'd1',
          accountTypeId: 't1',
          creationDate: DateTime(2024, 1, 1),
        ),
      ],
      accountTypes: const [],
      hasReachedMax: true,
      totalCount: 1,
      exchangeRates: const [],
      activeDate: DateTime(2024, 1, 1),
    ),
  );
  return bloc;
}

Future<void> _pump(
  WidgetTester tester, {
  required List<Category> categories,
  required bool grid,
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  final bloc = MockCategoriesBloc();
  whenListen(
    bloc,
    const Stream<CategoriesState>.empty(),
    initialState: CategoriesLoadSuccess(
      categoriesWithTotals: [
        for (final c in categories) CategoryWithTotal(category: c, total: 1),
      ],
      allCategories: categories,
      hasReachedMax: true,
      activeDate: DateTime(2024, 1, 1),
    ),
  );

  final router = GoRouter(
    initialLocation: AppRoutes.categories,
    routes: [
      GoRoute(
        path: AppRoutes.categories,
        builder: (_, _) => const CategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.addEditTransaction,
        builder: (_, _) => const Text('transaction form'),
      ),
    ],
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
      settingsBloc: createSettingsBloc(
        state: SettingsState(
          settings: grid
              ? const {kCategoriesViewModeSetting: 'grid'}
              : const {},
        ),
      ),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: _accountsBloc(),
      categoriesBloc: bloc,
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('the list shows a category whose parent was deleted', (
    tester,
  ) async {
    await _pump(tester, categories: [_plain, _orphan], grid: false);

    expect(find.text('Rent'), findsOneWidget);
    expect(find.byType(CategoryListItem), findsNWidgets(2));
  });

  testWidgets('the grid shows a category whose parent was deleted', (
    tester,
  ) async {
    await _pump(tester, categories: [_plain, _orphan], grid: true);

    expect(find.byKey(CategoryGrid.tileKey(_orphan.id!)), findsOneWidget);
  });

  testWidgets('a loop leaves both categories reachable in the list', (
    tester,
  ) async {
    // Neither has `parentId == null`, so under the old rule the screen was
    // simply empty - with no way to edit either row back into shape.
    await _pump(tester, categories: [_loopA, _loopB], grid: false);

    expect(tester.takeException(), isNull);
    // The lower id is where the loop is cut, so Travel is the root and Flights
    // hangs under it, one level deep and not one level deeper on every tap.
    expect(find.text('Travel'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsOneWidget);

    // The tile itself books a transaction against the category; the arrow is
    // what opens it.
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();

    expect(find.text('Flights'), findsOneWidget);
    expect(find.byType(ExpansionTile), findsOneWidget);
  });

  testWidgets('a loop leaves both categories reachable in the grid', (
    tester,
  ) async {
    await _pump(tester, categories: [_loopA, _loopB], grid: true);

    expect(tester.takeException(), isNull);
    expect(find.byKey(CategoryGrid.tileKey('a')), findsOneWidget);
    expect(find.byKey(CategoryGrid.tileKey('b')), findsNothing);

    await tester.tap(find.byKey(CategoryGrid.tileKey('a')));
    await tester.pumpAndSettle();

    // Drilled in: the parent, then its child - and the parent listed once, not
    // once as itself and once as its own child.
    expect(find.byKey(CategoryGrid.tileKey('a')), findsOneWidget);
    expect(find.byKey(CategoryGrid.tileKey('b')), findsOneWidget);
  });

  testWidgets('a category that parents itself is drawn once, at the top', (
    tester,
  ) async {
    final self = category('c9', 'Self', parent: 'c9');
    await _pump(tester, categories: [_plain, self], grid: false);

    expect(tester.takeException(), isNull);
    expect(find.text('Self'), findsOneWidget);
    // Its own child would mean an ExpansionTile that never bottoms out.
    expect(find.byType(ExpansionTile), findsNothing);
  });
}
