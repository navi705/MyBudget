// The cold-start guards, seen through an active account filter.
//
// `AccountsLoadSuccess.accounts` is the accounts grid's page *after* its
// type/currency/name filter, so a user who filters down to "Savings" - or to
// nothing at all - has a state whose account list is short or empty while the
// accounts themselves are untouched. The guards read that list, so filtering
// made the app refuse to open a transaction or a transfer that it had every
// reason to open. They read the unfiltered counts now, and this file pins both
// directions: the filter must not refuse, and a genuinely empty table must.
import 'package:bloc_test/bloc_test.dart';
// `show`: foundation also exports a `Category`, which collides with the domain
// entity of that name.
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/transaction_category.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart'
    show CategoriesScreen;
import 'package:my_budget_client/presentation/widgets/transaction_list.dart';

import '../test_app.dart';

/// Stands in for the add/edit transaction route, which needs the DI container.
const String _formMarker = 'transaction form';

const String _listRoute = '/list';

Account _account(String id, String name, {String? assetId}) => Account(
  id: id,
  name: name,
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
  assetId: assetId,
  assetQuantity: 2,
);

final _checking = _account('a1', 'Checking');

final _groceries = Category(id: 'c1', name: 'Groceries');

final _groceriesTyped = Category(
  id: 'c1',
  name: 'Groceries',
  type: CategoryType.expense,
);

final _entry = TransactionCategory(
  transaction: Transaction(
    id: 't1',
    description: 'Bread',
    amount: -12,
    date: DateTime(2024, 1, 1),
    accountId: 'a1',
    categoryId: 'c1',
    currencyCode: 'EUR',
  ),
  style: Style(
    id: 's1',
    name: 'Default',
    iconName: 'help_outline',
    colorHex: '#808080',
    iconType: IconType.material,
  ),
  category: _groceries,
);

/// A loaded state whose visible list and whose real table disagree.
///
/// [accounts] is what the filter left on screen; [unfilteredAccountCount] and
/// [unfilteredTransferableAccountCount] are what the database actually holds.
/// Passing them separately is the whole point - it is the only way to write a
/// state that the pre-fix guards get wrong.
AccountsState _filteredDownTo(
  List<Account> accounts, {
  required int unfilteredAccountCount,
  required int unfilteredTransferableAccountCount,
}) => AccountsLoadSuccess(
  accounts: accounts,
  accountTypes: const [],
  hasReachedMax: true,
  totalCount: accounts.length,
  exchangeRates: const [],
  activeDate: DateTime(2024, 1, 1),
  unfilteredAccountCount: unfilteredAccountCount,
  unfilteredTransferableAccountCount: unfilteredTransferableAccountCount,
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

CategoriesState _categoriesLoaded() => CategoriesLoadSuccess(
  categoriesWithTotals: [
    CategoryWithTotal(category: _groceriesTyped, total: 0),
  ],
  allCategories: [_groceriesTyped],
  hasReachedMax: true,
  activeDate: DateTime(2024, 1, 1),
);

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

/// One transaction, so the list renders rows rather than its empty view.
TransactionsBloc _transactionsBloc() {
  final bloc = MockTransactionsBloc();
  whenListen(
    bloc,
    const Stream<TransactionsState>.empty(),
    initialState: TransactionsState(
      status: TransactionStatus.success,
      transactions: [_entry],
      hasMoreDown: false,
      totalCount: 1,
      activeDate: DateTime(2024, 1, 1),
    ),
  );
  return bloc;
}

/// Pumps [home] with the blocs above the app, which is where the refusals'
/// dialogs (root navigator) can still see them.
Future<AppLocalizations> _pump(
  WidgetTester tester, {
  required String route,
  required Widget Function() home,
  required AccountsState accounts,
  CategoriesBloc? categories,
  TransactionsBloc? transactions,
  CurrencyConverterBloc? converter,
  Size surfaceSize = const Size(900, 900),
}) async {
  setSurfaceSize(tester, surfaceSize);

  final router = GoRouter(
    initialLocation: route,
    routes: [
      GoRoute(path: route, builder: (_, _) => home()),
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
      categoriesBloc: categories,
      transactionsBloc: transactions,
      currencyConverterBloc: converter,
    ),
  );
  await tester.pumpAndSettle();

  return loadL10n();
}

/// Right-clicks [finder]; the transaction row's menu is desktop-only.
///
/// The platform override is put back immediately rather than in a tear-down:
/// the binding fails any test that *ends* with a foundation debug variable set.
Future<void> _secondaryTap(WidgetTester tester, Finder finder) async {
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  try {
    final gesture = await tester.startGesture(
      tester.getCenter(finder),
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
  await tester.pumpAndSettle();
}

/// Runs a showing SnackBar's display timer out; the binding fails any test that
/// ends with a pending timer.
Future<void> _runOutSnackBar(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

void main() {
  group('AccountsScreen transfer through a filter', () {
    // The bug, at its sharpest: two ordinary accounts in the database, a filter
    // that leaves one of them on screen, and a transfer between them refused.
    testWidgets('opens the transfer form when the filter hides the second '
        'account', (tester) async {
      final l10n = await _pump(
        tester,
        route: AppRoutes.accounts,
        home: () => const AccountsScreen(),
        surfaceSize: const Size(900, 1200),
        accounts: _filteredDownTo(
          [_checking],
          unfilteredAccountCount: 2,
          unfilteredTransferableAccountCount: 2,
        ),
        categories: _categoriesBloc(_categoriesLoaded()),
        converter: _converterBloc(),
      );

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.contextMenuTransfer));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });

    // The other direction: a single account is still a single account, and the
    // transfer form's second picker would be empty.
    testWidgets('still refuses when only one account exists', (tester) async {
      final l10n = await _pump(
        tester,
        route: AppRoutes.accounts,
        home: () => const AccountsScreen(),
        surfaceSize: const Size(900, 1200),
        accounts: _filteredDownTo(
          [_checking],
          unfilteredAccountCount: 1,
          unfilteredTransferableAccountCount: 1,
        ),
        categories: _categoriesBloc(_categoriesLoaded()),
        converter: _converterBloc(),
      );

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.contextMenuTransfer));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsNothing);
      expect(
        find.text(l10n.addAccountBeforeTransactionDescription),
        findsOneWidget,
      );

      await _runOutSnackBar(tester);
    });
  });

  group('CategoriesScreen through a filter', () {
    // A filter narrow enough to leave the accounts grid empty. The account the
    // form needs is still there, so the tap must go through.
    testWidgets('opens the transaction form when the filter hides every '
        'account', (tester) async {
      await _pump(
        tester,
        route: AppRoutes.categories,
        home: () => const CategoriesScreen(),
        accounts: _filteredDownTo(
          const [],
          unfilteredAccountCount: 1,
          unfilteredTransferableAccountCount: 1,
        ),
        categories: _categoriesBloc(_categoriesLoaded()),
      );

      await tester.tap(find.text(_groceriesTyped.name));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });

    testWidgets('still refuses on an empty table', (tester) async {
      final l10n = await _pump(
        tester,
        route: AppRoutes.categories,
        home: () => const CategoriesScreen(),
        accounts: _filteredDownTo(
          const [],
          unfilteredAccountCount: 0,
          unfilteredTransferableAccountCount: 0,
        ),
        categories: _categoriesBloc(_categoriesLoaded()),
      );

      await tester.tap(find.text(_groceriesTyped.name));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsNothing);
      expect(
        find.text(l10n.addAccountBeforeTransactionDescription),
        findsOneWidget,
      );

      await _runOutSnackBar(tester);
    });
  });

  group('TransactionList through a filter', () {
    testWidgets('opens the transaction form when the filter hides every '
        'account', (tester) async {
      await _pump(
        tester,
        route: _listRoute,
        // The list has no Scaffold of its own, and a SnackBar needs one.
        home: () => const Scaffold(body: TransactionList()),
        accounts: _filteredDownTo(
          const [],
          unfilteredAccountCount: 1,
          unfilteredTransferableAccountCount: 1,
        ),
        transactions: _transactionsBloc(),
      );

      await tester.tap(find.text(_groceries.name));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });

    testWidgets('opens the edit form from the row menu through a filter', (
      tester,
    ) async {
      final l10n = await _pump(
        tester,
        route: _listRoute,
        home: () => const Scaffold(body: TransactionList()),
        accounts: _filteredDownTo(
          const [],
          unfilteredAccountCount: 1,
          unfilteredTransferableAccountCount: 1,
        ),
        transactions: _transactionsBloc(),
      );

      await _secondaryTap(tester, find.text(_groceries.name));
      await tester.tap(find.text(l10n.contextMenuEdit));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });

    testWidgets('still refuses on an empty table', (tester) async {
      final l10n = await _pump(
        tester,
        route: _listRoute,
        home: () => const Scaffold(body: TransactionList()),
        accounts: _filteredDownTo(
          const [],
          unfilteredAccountCount: 0,
          unfilteredTransferableAccountCount: 0,
        ),
        transactions: _transactionsBloc(),
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
  });
}
