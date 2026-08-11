// What a category row does on a fresh install.
//
// Tapping a category is a shortcut into the transaction form with that category
// pre-filled — but the form also requires an Account, and nothing seeds one. The
// row used to push the form anyway, so the first thing a new user tapped opened
// a page that could never be saved and whose only exit was Back.
//
// Both doors into that push (the row itself and the row's context menu) go
// through one guard, so both are pinned here, together with the two states that
// must NOT be refused: accounts present, and accounts still loading — every
// AccountsState reports an empty list until the load lands.
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
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';

import '../test_app.dart';

/// Stands in for the add/edit transaction route, which needs the DI container.
const String _formMarker = 'transaction form';

final _groceries = Category(
  id: 'c1',
  name: 'Groceries',
  type: CategoryType.expense,
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
  categoriesWithTotals: [CategoryWithTotal(category: _groceries, total: 0)],
  allCategories: [_groceries],
  hasReachedMax: true,
  activeDate: DateTime(2024, 1, 1),
);

AccountsState _accountsLoaded(List<Account> accounts) => AccountsLoadSuccess(
  accounts: accounts,
  accountTypes: const [],
  hasReachedMax: true,
  totalCount: accounts.length,
  exchangeRates: const [],
  activeDate: DateTime(2024, 1, 1),
);

AccountsBloc _accountsBloc(AccountsState state) {
  final bloc = MockAccountsBloc();
  whenListen(bloc, const Stream<AccountsState>.empty(), initialState: state);
  return bloc;
}

CategoriesBloc _categoriesBloc(CategoriesState state) {
  final bloc = MockCategoriesBloc();
  whenListen(bloc, const Stream<CategoriesState>.empty(), initialState: state);
  return bloc;
}

/// Pumps CategoriesScreen with one category and the given account state.
///
/// The blocs sit above the app because the add-account dialog is pushed onto
/// the root navigator, where providers wrapped around the screen are invisible
/// — the same reason `AppProviders` sits above the app in production.
Future<AppLocalizations> _pumpCategories(
  WidgetTester tester, {
  required AccountsState accounts,
}) async {
  setSurfaceSize(tester, const Size(900, 900));

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
      settingsBloc: createSettingsBloc(),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: _accountsBloc(accounts),
      categoriesBloc: _categoriesBloc(_categoriesLoaded()),
    ),
  );
  await tester.pump();

  return loadL10n();
}

/// Opens the row's context menu and picks "add transaction".
Future<void> _pickAddTransactionFromMenu(
  WidgetTester tester,
  AppLocalizations l10n,
) async {
  await tester.longPress(find.text(_groceries.name));
  await tester.pumpAndSettle();

  await tester.tap(find.text(l10n.contextMenuAddTransaction));
  await tester.pumpAndSettle();
}

/// Runs a showing SnackBar's display timer out.
///
/// The binding fails any test that ends with a pending timer, and
/// `pumpAndSettle` returns before the SnackBar's four seconds are up.
Future<void> _runOutSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('CategoriesScreen row tap', () {
    testWidgets('refuses the transaction form while no account exists', (
      tester,
    ) async {
      final l10n = await _pumpCategories(
        tester,
        accounts: _accountsLoaded(const []),
      );

      await tester.tap(find.text(_groceries.name));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsNothing);
      expect(
        find.text(l10n.addAccountBeforeTransactionDescription),
        findsOneWidget,
      );

      await _runOutSnackBar(tester);
    });

    testWidgets('offers account creation from the refusal', (tester) async {
      final l10n = await _pumpCategories(
        tester,
        accounts: _accountsLoaded(const []),
      );

      await tester.tap(find.text(_groceries.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.accountsAddTooltip));
      await tester.pumpAndSettle();

      expect(find.byType(AddAccountDialog), findsOneWidget);
    });

    testWidgets('opens the transaction form once an account exists', (
      tester,
    ) async {
      await _pumpCategories(tester, accounts: _accountsLoaded([_account]));

      await tester.tap(find.text(_groceries.name));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });

    testWidgets('keeps the transaction form while accounts are loading', (
      tester,
    ) async {
      // The empty list here means "not loaded yet". Refusing on it would refuse
      // the first taps of every launch.
      final l10n = await _pumpCategories(
        tester,
        accounts: AccountsLoadInProgress(activeDate: DateTime(2024, 1, 1)),
      );

      await tester.tap(find.text(_groceries.name));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
      expect(
        find.text(l10n.addAccountBeforeTransactionDescription),
        findsNothing,
      );
    });
  });

  group('CategoriesScreen context menu', () {
    testWidgets('refuses the transaction form while no account exists', (
      tester,
    ) async {
      final l10n = await _pumpCategories(
        tester,
        accounts: _accountsLoaded(const []),
      );

      await _pickAddTransactionFromMenu(tester, l10n);

      expect(find.text(_formMarker), findsNothing);
      expect(
        find.text(l10n.addAccountBeforeTransactionDescription),
        findsOneWidget,
      );

      await _runOutSnackBar(tester);
    });

    testWidgets('opens the transaction form once an account exists', (
      tester,
    ) async {
      final l10n = await _pumpCategories(
        tester,
        accounts: _accountsLoaded([_account]),
      );

      await _pickAddTransactionFromMenu(tester, l10n);

      expect(find.text(_formMarker), findsOneWidget);
    });
  });
}
