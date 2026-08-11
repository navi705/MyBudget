// Where the "+" button sends the user on a fresh install.
//
// Nothing seeds an account, the transaction form requires one, and the form's
// Account picker reads the same empty list — so opening the form was a dead end
// whose only exit was Back. The button and the `add_action` hotkey share one
// entry point, and the decision it makes hangs on a distinction that is easy to
// get wrong: every AccountsState reports an empty list, but only
// AccountsLoadSuccess means the accounts are really gone rather than still
// loading. All three branches are pinned below.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/transactions_screen.dart';
import 'package:my_budget_client/presentation/widgets/add_account_dialog.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

import '../test_app.dart';

/// Stands in for the add/edit transaction route, which needs the DI container.
const String _formMarker = 'transaction form';

final _account = Account(
  id: 'a1',
  name: 'Checking',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

AccountsState _loaded(List<Account> accounts) => AccountsLoadSuccess(
  accounts: accounts,
  accountTypes: const [],
  hasReachedMax: true,
  totalCount: accounts.length,
  exchangeRates: const [],
  activeDate: DateTime(2024, 1, 1),
);

/// A loaded state whose visible list and whose real table disagree.
///
/// [accounts] is what the accounts screen's type/currency/name filter left on
/// screen; [unfilteredAccountCount] is what the database actually holds. Only a
/// state built this way can catch a guard that reads the filtered list: with
/// the two kept in step, as [_loaded] keeps them, both readings agree.
AccountsState _filteredDownTo(
  List<Account> accounts, {
  required int unfilteredAccountCount,
}) => AccountsLoadSuccess(
  accounts: accounts,
  accountTypes: const [],
  hasReachedMax: true,
  totalCount: accounts.length,
  exchangeRates: const [],
  activeDate: DateTime(2024, 1, 1),
  unfilteredAccountCount: unfilteredAccountCount,
  unfilteredTransferableAccountCount: unfilteredAccountCount,
);

AccountsBloc _accountsBloc(AccountsState state) {
  final bloc = MockAccountsBloc();
  whenListen(bloc, const Stream<AccountsState>.empty(), initialState: state);
  return bloc;
}

TransactionsBloc _transactionsBloc() {
  final bloc = MockTransactionsBloc();
  whenListen(
    bloc,
    const Stream<TransactionsState>.empty(),
    initialState: TransactionsState(status: TransactionStatus.success),
  );
  return bloc;
}

Future<void> _pumpTransactions(
  WidgetTester tester, {
  required AccountsState accounts,
  Map<String, String> hotkeys = const {},
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  final router = GoRouter(
    initialLocation: AppRoutes.transactions,
    routes: [
      GoRoute(
        path: AppRoutes.transactions,
        builder: (_, _) => const TransactionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addEditTransaction,
        builder: (_, _) => const Text(_formMarker),
      ),
    ],
  );
  addTearDown(router.dispose);

  // The add-account dialog goes onto the root navigator, so its blocs have to
  // be provided above the app rather than around the screen.
  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
      settingsBloc: createSettingsBloc(state: SettingsState(hotkeys: hotkeys)),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: _accountsBloc(accounts),
      transactionsBloc: _transactionsBloc(),
    ),
  );
  await tester.pump();
}

MultiLevelTooltip _fabTooltip(WidgetTester tester) => tester.widget(
  find.ancestor(
    of: find.byType(FloatingActionButton),
    matching: find.byType(MultiLevelTooltip),
  ),
);

void main() {
  group('TransactionsScreen add button', () {
    testWidgets('opens account creation when no account exists', (
      tester,
    ) async {
      await _pumpTransactions(tester, accounts: _loaded(const []));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AddAccountDialog), findsOneWidget);
      expect(find.text(_formMarker), findsNothing);
    });

    testWidgets('opens the transaction form once an account exists', (
      tester,
    ) async {
      await _pumpTransactions(tester, accounts: _loaded([_account]));

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
      expect(find.byType(AddAccountDialog), findsNothing);
    });

    testWidgets('keeps the transaction form while accounts are loading', (
      tester,
    ) async {
      // The empty list here means "not loaded yet"; redirecting on it would
      // swap the button under the user on the first frame of every launch.
      await _pumpTransactions(
        tester,
        accounts: AccountsLoadInProgress(activeDate: DateTime(2024, 1, 1)),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });

    testWidgets('explains itself while no account exists', (tester) async {
      final l10n = await loadL10n();
      await _pumpTransactions(tester, accounts: _loaded(const []));

      expect(_fabTooltip(tester).message, l10n.accountsAddTooltip);
      expect(
        _fabTooltip(tester).description,
        l10n.addAccountBeforeTransactionDescription,
      );
    });

    testWidgets('advertises adding a transaction once an account exists', (
      tester,
    ) async {
      final l10n = await loadL10n();
      await _pumpTransactions(tester, accounts: _loaded([_account]));

      expect(_fabTooltip(tester).message, l10n.contextMenuAddTransaction);
      expect(_fabTooltip(tester).description, l10n.addTransactionDescription);
    });
  });

  group('TransactionsScreen add button through an account filter', () {
    // The accounts screen's filter is remembered in the same bloc this screen
    // reads, so a filter narrow enough to empty the accounts grid used to make
    // the "+" here offer account creation to a user who already owns accounts.
    testWidgets('opens the transaction form when the filter hides every '
        'account', (tester) async {
      await _pumpTransactions(
        tester,
        accounts: _filteredDownTo(const [], unfilteredAccountCount: 1),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
      expect(find.byType(AddAccountDialog), findsNothing);
    });

    testWidgets('advertises adding a transaction when the filter hides every '
        'account', (tester) async {
      final l10n = await loadL10n();
      await _pumpTransactions(
        tester,
        accounts: _filteredDownTo(const [], unfilteredAccountCount: 1),
      );

      expect(_fabTooltip(tester).message, l10n.contextMenuAddTransaction);
      expect(_fabTooltip(tester).description, l10n.addTransactionDescription);
    });

    // The other direction: a filter that hides nothing because there is
    // nothing to hide still has to reach account creation.
    testWidgets('still opens account creation on an empty table', (
      tester,
    ) async {
      await _pumpTransactions(
        tester,
        accounts: _filteredDownTo(const [], unfilteredAccountCount: 0),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(AddAccountDialog), findsOneWidget);
      expect(find.text(_formMarker), findsNothing);
    });
  });

  group('TransactionsScreen add hotkey', () {
    testWidgets('follows the button into account creation', (tester) async {
      await _pumpTransactions(
        tester,
        accounts: _loaded(const []),
        hotkeys: {'add_action': '${LogicalKeyboardKey.keyN.keyId}'},
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();

      expect(find.byType(AddAccountDialog), findsOneWidget);
      expect(find.text(_formMarker), findsNothing);
    });

    testWidgets('opens the transaction form once an account exists', (
      tester,
    ) async {
      await _pumpTransactions(
        tester,
        accounts: _loaded([_account]),
        hotkeys: {'add_action': '${LogicalKeyboardKey.keyN.keyId}'},
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.pumpAndSettle();

      expect(find.text(_formMarker), findsOneWidget);
    });
  });
}
