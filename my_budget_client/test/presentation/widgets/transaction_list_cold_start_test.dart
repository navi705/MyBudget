// Every door out of the transaction list into the transaction form.
//
// The form requires an Account and its Account picker reads the same list the
// app has none of on a fresh install, so pushing it with no account open is a
// dead end: it can be opened but never saved. The list has three such pushes —
// tapping a row, the row's "edit" menu item, and the empty-area "add" menu item
// — and all three now go through one guard, so all three are pinned here.
import 'package:bloc_test/bloc_test.dart';
// `show`: foundation also exports a `Category`, which would collide with the
// domain entity of that name.
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/transaction_category.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';
import 'package:my_budget_client/presentation/widgets/transaction_list.dart';

import '../test_app.dart';

/// Stands in for the add/edit transaction route, which needs the DI container.
const String _formMarker = 'transaction form';

const String _listRoute = '/list';

final _account = Account(
  id: 'a1',
  name: 'Checking',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

final _groceries = Category(id: 'c1', name: 'Groceries');

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

Future<AppLocalizations> _pumpList(
  WidgetTester tester, {
  required AccountsState accounts,
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  final router = GoRouter(
    initialLocation: _listRoute,
    routes: [
      GoRoute(
        path: _listRoute,
        // The list has no Scaffold of its own, and a SnackBar needs one.
        builder: (_, _) => const Scaffold(body: TransactionList()),
      ),
      GoRoute(
        path: AppRoutes.addEditTransaction,
        builder: (_, _) => const Text(_formMarker),
      ),
    ],
  );
  addTearDown(router.dispose);

  // Above the app, because the add-account dialog goes onto the root navigator
  // and cannot see providers wrapped around the list.
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
      transactionsBloc: _transactionsBloc(),
    ),
  );
  await tester.pumpAndSettle();

  return loadL10n();
}

/// Right-clicks [finder].
///
/// The row's context menu is desktop-only — the handler reads
/// `defaultTargetPlatform`, which is Android under the test binding — so the
/// platform is overridden across the gesture and put back immediately: the test
/// binding fails any test that *ends* with a foundation debug variable set,
/// which a tear-down is too late to prevent.
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
  group('TransactionList row tap', () {
    testWidgets('refuses the transaction form while no account exists', (
      tester,
    ) async {
      final l10n = await _pumpList(tester, accounts: _accountsLoaded(const []));

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
      final l10n = await _pumpList(tester, accounts: _accountsLoaded(const []));

      await tester.tap(find.text(_groceries.name));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.accountsAddTooltip));
      await tester.pumpAndSettle();

      expect(find.byType(AddAccountDialog), findsOneWidget);
    });

    testWidgets('opens the transaction form once an account exists', (
      tester,
    ) async {
      await _pumpList(tester, accounts: _accountsLoaded([_account]));

      await tester.tap(find.text(_groceries.name));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });

    testWidgets('keeps the transaction form while accounts are loading', (
      tester,
    ) async {
      // Every AccountsState reports an empty list until the load lands, so
      // refusing on "empty" alone would refuse the first taps of every launch.
      final l10n = await _pumpList(
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

  group('TransactionList row menu', () {
    testWidgets('refuses editing while no account exists', (tester) async {
      final l10n = await _pumpList(tester, accounts: _accountsLoaded(const []));

      await _secondaryTap(tester, find.text(_groceries.name));
      await tester.tap(find.text(l10n.contextMenuEdit));
      await tester.pumpAndSettle();

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
      final l10n = await _pumpList(
        tester,
        accounts: _accountsLoaded([_account]),
      );

      await _secondaryTap(tester, find.text(_groceries.name));
      await tester.tap(find.text(l10n.contextMenuEdit));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });
  });

  group('TransactionList empty-area menu', () {
    testWidgets('refuses adding while no account exists', (tester) async {
      final l10n = await _pumpList(tester, accounts: _accountsLoaded(const []));

      await tester.longPressAt(const Offset(450, 850));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.addTransactionDescription));
      await tester.pumpAndSettle();

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
      final l10n = await _pumpList(
        tester,
        accounts: _accountsLoaded([_account]),
      );

      await tester.longPressAt(const Offset(450, 850));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.addTransactionDescription));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });
  });
}
