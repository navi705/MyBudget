// The categories screen has two views of the same data.
//
// The list answers "what did this cost me" and needs a full-width row per
// category to do it, which puts four or five candidates on a phone screen when
// the user has thirty. Picking where to book an expense is recognition, not
// reading, so the grid trades the per-row detail for four times the density.
// What is pinned here: the list stays the default, the toggle persists through
// settings rather than screen state, and the grid keeps the two things the list
// could do that a plain icon wall cannot — reaching sub-categories, and opening
// the transaction form on a category.
import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
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

import '../test_app.dart';

/// Stands in for the add/edit transaction route, which needs the DI container.
const String _formMarker = 'transaction form';

final _groceries = Category(
  id: 'c1',
  name: 'Groceries',
  type: CategoryType.expense,
);

final _home = Category(id: 'c2', name: 'Home', type: CategoryType.expense);

final _rent = Category(
  id: 'c3',
  name: 'Rent',
  type: CategoryType.expense,
  parentId: 'c2',
);

final _account = Account(
  id: 'a1',
  name: 'Checking',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

CategoriesState _categoriesLoaded() => CategoriesLoadSuccess(
  categoriesWithTotals: [
    CategoryWithTotal(category: _groceries, total: 12),
    CategoryWithTotal(category: _home, total: 500),
    CategoryWithTotal(category: _rent, total: 500),
  ],
  allCategories: [_groceries, _home, _rent],
  hasReachedMax: true,
  activeDate: DateTime(2024, 1, 1),
);

AccountsState _accountsLoaded() => AccountsLoadSuccess(
  accounts: [_account],
  accountTypes: const [],
  hasReachedMax: true,
  totalCount: 1,
  exchangeRates: const [],
  activeDate: DateTime(2024, 1, 1),
);

AccountsBloc _accountsBloc() {
  final bloc = MockAccountsBloc();
  whenListen(
    bloc,
    const Stream<AccountsState>.empty(),
    initialState: _accountsLoaded(),
  );
  return bloc;
}

CategoriesBloc _categoriesBloc() {
  final bloc = MockCategoriesBloc();
  whenListen(
    bloc,
    const Stream<CategoriesState>.empty(),
    initialState: _categoriesLoaded(),
  );
  return bloc;
}

/// A settings bloc that keeps what the screen dispatched at it.
///
/// The shared `MockSettingsBloc` swallows events and reading them back needs
/// `verify`, which lives in mocktail — a transitive dependency here, not one
/// this package declares.
class _RecordingSettingsBloc extends Bloc<SettingsEvent, SettingsState>
    implements SettingsBloc {
  _RecordingSettingsBloc(super.initialState) {
    on<SettingsEvent>((event, emit) => received.add(event));
  }

  final List<SettingsEvent> received = <SettingsEvent>[];
}

Future<SettingsBloc> _pumpCategories(
  WidgetTester tester, {
  required bool grid,
  SettingsBloc? settingsBlocOverride,
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  final settingsBloc =
      settingsBlocOverride ??
      createSettingsBloc(
        state: SettingsState(
          settings: grid
              ? const {kCategoriesViewModeSetting: 'grid'}
              : const {},
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
        builder: (_, _) => const Text(_formMarker),
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
      settingsBloc: settingsBloc,
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: _accountsBloc(),
      categoriesBloc: _categoriesBloc(),
    ),
  );
  await tester.pump();

  return settingsBloc;
}

void main() {
  testWidgets('the list is what an account with no preference saved gets', (
    tester,
  ) async {
    await _pumpCategories(tester, grid: false);

    expect(find.byType(CategoryListItem), findsWidgets);
    expect(find.byType(CategoryGrid), findsNothing);
  });

  testWidgets('the saved preference selects the grid', (tester) async {
    await _pumpCategories(tester, grid: true);

    expect(find.byType(CategoryGrid), findsOneWidget);
    expect(find.byType(CategoryListItem), findsNothing);
    expect(find.byKey(CategoryGrid.tileKey(_groceries.id!)), findsOneWidget);
    // Sub-categories are reached through their parent, so they must not also
    // sit loose at the top level.
    expect(find.byKey(CategoryGrid.tileKey(_rent.id!)), findsNothing);
  });

  testWidgets('the toggle writes the choice to settings, not to the screen', (
    tester,
  ) async {
    final settingsBloc = _RecordingSettingsBloc(const SettingsState());
    addTearDown(settingsBloc.close);
    await _pumpCategories(
      tester,
      grid: false,
      settingsBlocOverride: settingsBloc,
    );

    await tester.tap(find.byKey(_categoriesViewToggleKey));
    await tester.pump();

    expect(
      settingsBloc.received,
      contains(const UpdateSetting(kCategoriesViewModeSetting, 'grid')),
    );
  });

  testWidgets('a parent opens its children and comes back', (tester) async {
    await _pumpCategories(tester, grid: true);

    await tester.tap(find.byKey(CategoryGrid.tileKey(_home.id!)));
    await tester.pumpAndSettle();

    // The parent stays on screen inside itself: money can be booked against it
    // directly, exactly as the list's expansion tile allows.
    expect(find.byKey(CategoryGrid.tileKey(_home.id!)), findsOneWidget);
    expect(find.byKey(CategoryGrid.tileKey(_rent.id!)), findsOneWidget);
    expect(find.byKey(CategoryGrid.tileKey(_groceries.id!)), findsNothing);

    await tester.tap(find.byKey(CategoryGrid.backKey));
    await tester.pumpAndSettle();

    expect(find.byKey(CategoryGrid.tileKey(_groceries.id!)), findsOneWidget);
    expect(find.byKey(CategoryGrid.tileKey(_rent.id!)), findsNothing);
  });

  testWidgets('a childless tile opens the transaction form', (tester) async {
    await _pumpCategories(tester, grid: true);

    await tester.tap(find.byKey(CategoryGrid.tileKey(_groceries.id!)));
    await tester.pumpAndSettle();

    expect(find.text(_formMarker), findsOneWidget);
  });

  testWidgets('a child tile opens the transaction form', (tester) async {
    await _pumpCategories(tester, grid: true);

    await tester.tap(find.byKey(CategoryGrid.tileKey(_home.id!)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(CategoryGrid.tileKey(_rent.id!)));
    await tester.pumpAndSettle();

    expect(find.text(_formMarker), findsOneWidget);
  });
}

/// The toggle's key, which the screen keeps private.
const ValueKey<String> _categoriesViewToggleKey = ValueKey<String>(
  'categories-view-mode-toggle',
);
