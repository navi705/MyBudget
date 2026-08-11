// The two account-row menu items that open the transaction form.
//
// "Add transaction" supplies the account, so what it can still be missing is a
// category: income and expense both require one and nothing seeds it, so with
// no categories the form opened onto a required picker with nothing in it.
//
// "Transfer" is the harder one: it needs *two* accounts, not one. Owning a
// single account is the normal state right after creating the first one, and
// the transfer form's second picker would then be empty — and both of its
// pickers drop asset accounts, so an account plus a gold holding is still only
// one usable account. Both counts are pinned below.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart'
    show AddEditCategoryDialog;
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';

import '../test_app.dart';

/// Stands in for the add/edit transaction route, which needs the DI container.
const String _formMarker = 'transaction form';

final _checking = Account(
  id: 'a1',
  name: 'Checking',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

final _savings = Account(
  id: 'a2',
  name: 'Savings',
  balance: 500,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

/// An asset holding: both pickers on the transfer form drop these, so it never
/// counts towards the two accounts a transfer needs.
final _gold = Account(
  id: 'a3',
  name: 'Gold',
  balance: 0,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
  assetId: 'xau',
  assetQuantity: 2,
);

final _groceries = Category(id: 'c1', name: 'Groceries');

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

CurrencyConverterBloc _converterBloc() {
  final bloc = MockCurrencyConverterBloc();
  whenListen(
    bloc,
    const Stream<CurrencyConverterState>.empty(),
    // Not a success state, so the total-balance summary stays collapsed.
    initialState: CurrencyConverterInitial(),
  );
  return bloc;
}

CategoriesState _categoriesLoaded(List<Category> categories) =>
    CategoriesLoadSuccess(
      allCategories: categories,
      hasReachedMax: true,
      activeDate: DateTime(2024, 1, 1),
    );

Future<AppLocalizations> _pumpAccounts(
  WidgetTester tester, {
  required List<Account> accounts,
  CategoriesState? categories,
}) async {
  setSurfaceSize(tester, const Size(900, 1200));

  final router = GoRouter(
    initialLocation: AppRoutes.accounts,
    routes: [
      GoRoute(
        path: AppRoutes.accounts,
        builder: (_, _) => const AccountsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addEditTransaction,
        builder: (_, _) => const Text(_formMarker),
      ),
    ],
  );
  addTearDown(router.dispose);

  // Above the app: the dialogs these refusals offer are pushed onto the root
  // navigator, where providers wrapped around the screen are invisible.
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
      accountsBloc: _accountsBloc(_accountsLoaded(accounts)),
      categoriesBloc: _categoriesBloc(
        categories ?? _categoriesLoaded([_groceries]),
      ),
      currencyConverterBloc: _converterBloc(),
    ),
  );
  await tester.pumpAndSettle();

  return loadL10n();
}

/// Opens the first account row's menu and picks [item].
Future<void> _pickFromRowMenu(WidgetTester tester, String item) async {
  await tester.tap(find.byIcon(Icons.more_vert).first);
  await tester.pumpAndSettle();

  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

/// Runs a showing SnackBar's display timer out; the binding fails any test that
/// ends with a pending timer.
Future<void> _runOutSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('AccountsScreen transfer menu item', () {
    testWidgets('refuses a transfer out of the only account', (tester) async {
      final l10n = await _pumpAccounts(tester, accounts: [_checking]);

      await _pickFromRowMenu(tester, l10n.contextMenuTransfer);

      expect(find.text(_formMarker), findsNothing);
      expect(
        find.text(l10n.addAccountBeforeTransactionDescription),
        findsOneWidget,
      );

      await _runOutSnackBar(tester);
    });

    // Two rows on screen, one usable account: the count that matters is the one
    // the form's pickers actually offer.
    testWidgets('refuses a transfer when the second account is an asset', (
      tester,
    ) async {
      final l10n = await _pumpAccounts(tester, accounts: [_checking, _gold]);

      await _pickFromRowMenu(tester, l10n.contextMenuTransfer);

      expect(find.text(_formMarker), findsNothing);
      expect(
        find.text(l10n.addAccountBeforeTransactionDescription),
        findsOneWidget,
      );

      await _runOutSnackBar(tester);
    });

    testWidgets('offers account creation from the refusal', (tester) async {
      final l10n = await _pumpAccounts(tester, accounts: [_checking]);

      await _pickFromRowMenu(tester, l10n.contextMenuTransfer);
      await tester.tap(find.text(l10n.accountsAddTooltip));
      await tester.pumpAndSettle();

      expect(find.byType(AddAccountDialog), findsOneWidget);
    });

    testWidgets('opens the transfer form once a second account exists', (
      tester,
    ) async {
      final l10n = await _pumpAccounts(tester, accounts: [_checking, _savings]);

      await _pickFromRowMenu(tester, l10n.contextMenuTransfer);

      expect(find.text(_formMarker), findsOneWidget);
    });
  });

  group('AccountsScreen add-transaction menu item', () {
    testWidgets('refuses the transaction form while no category exists', (
      tester,
    ) async {
      final l10n = await _pumpAccounts(
        tester,
        accounts: [_checking],
        categories: _categoriesLoaded(const []),
      );

      await _pickFromRowMenu(tester, l10n.contextMenuAddTransaction);

      expect(find.text(_formMarker), findsNothing);
      expect(find.text(l10n.noCategoriesCreated), findsOneWidget);

      await _runOutSnackBar(tester);
    });

    testWidgets('offers category creation from the refusal', (tester) async {
      final l10n = await _pumpAccounts(
        tester,
        accounts: [_checking],
        categories: _categoriesLoaded(const []),
      );

      await _pickFromRowMenu(tester, l10n.contextMenuAddTransaction);
      await tester.tap(find.text(l10n.addCategoryTooltip));
      await tester.pumpAndSettle();

      expect(find.byType(AddEditCategoryDialog), findsOneWidget);
    });

    testWidgets('opens the transaction form once a category exists', (
      tester,
    ) async {
      final l10n = await _pumpAccounts(tester, accounts: [_checking]);

      await _pickFromRowMenu(tester, l10n.contextMenuAddTransaction);

      expect(find.text(_formMarker), findsOneWidget);
    });

    testWidgets('keeps the transaction form while categories are loading', (
      tester,
    ) async {
      // CategoriesBloc is provided lazily, so an untouched app sits on
      // CategoriesInitial — which reports no categories without having looked.
      final l10n = await _pumpAccounts(
        tester,
        accounts: [_checking],
        categories: CategoriesInitial(),
      );

      await _pickFromRowMenu(tester, l10n.contextMenuAddTransaction);

      expect(find.text(_formMarker), findsOneWidget);
      expect(find.text(l10n.noCategoriesCreated), findsNothing);
    });
  });
}
