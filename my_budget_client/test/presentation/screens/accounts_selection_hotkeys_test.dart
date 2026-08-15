// The four selection hotkeys the settings screen has always offered.
//
// `HotKeysScreen` lists `accounts_selection_close`, `_all`, `_delete` and
// `_change_type` under "Selection mode" and even warns about conflicts with
// them, but nothing on this screen ever claimed those ids: `ScreenShortcuts`
// only fires an id that appears in some `actions` map, so a key bound to any of
// the four did nothing at all.
//
// Registering them raises the opposite risk. The settings screen offers the
// bindings unconditionally and a bound key is live for as long as the accounts
// screen is, while the buttons the keys copy only exist on the selection app
// bar - two of them only once something is actually selected. So the
// interesting half of these tests is the half where a key must do nothing.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
// Both bloc libraries export ToggleSelectionMode and ClearSelection, and every
// event asserted on here belongs to the accounts bloc.
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart'
    show CategoriesBloc, CategoriesLoadSuccess, CategoriesState;
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/widgets/delete_account_dialog.dart';

import '../test_app.dart';

// ---------------------------------------------------------------------------
// The keys under test
//
// Which key is bound to which id is arbitrary; what matters is that the four
// are distinct, so a test that presses one cannot pass on another's behaviour.
// ---------------------------------------------------------------------------

const _closeKey = LogicalKeyboardKey.keyQ;
const _selectAllKey = LogicalKeyboardKey.keyA;
const _deleteKey = LogicalKeyboardKey.keyD;
const _changeTypeKey = LogicalKeyboardKey.keyT;

final Map<String, String> _selectionHotkeys = {
  'accounts_selection_close': '${_closeKey.keyId}',
  'accounts_selection_all': '${_selectAllKey.keyId}',
  'accounts_selection_delete': '${_deleteKey.keyId}',
  'accounts_selection_change_type': '${_changeTypeKey.keyId}',
};

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

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

const _cash = AccountType(id: 't1', name: 'Cash', languageCode: 'en');
const _bank = AccountType(id: 't2', name: 'Bank', languageCode: 'en');

AccountsState _loaded({
  List<Account>? accounts,
  bool selectionMode = true,
  Set<String> selected = const {},
}) {
  final list = accounts ?? [_checking, _savings];
  return AccountsLoadSuccess(
    accounts: list,
    accountTypes: const [_cash, _bank],
    hasReachedMax: true,
    totalCount: list.length,
    exchangeRates: const [],
    activeDate: DateTime(2024, 1, 1),
    isSelectionModeActive: selectionMode,
    selectedAccountIds: selected,
  );
}

// ---------------------------------------------------------------------------
// Doubles
// ---------------------------------------------------------------------------

/// An [AccountsBloc] that records what the screen dispatched.
///
/// `MockBloc.add` is a no-op that keeps no history, and every assertion here is
/// about *which* event a key produced - or whether it produced one at all.
class _RecordingAccountsBloc extends MockAccountsBloc {
  final events = <AccountsEvent>[];

  @override
  void add(AccountsEvent event) => events.add(event);
}

/// Every event the screen sent apart from the load it fires on `initState`.
List<AccountsEvent> _selectionEvents(_RecordingAccountsBloc bloc) => bloc.events
    .where((e) => e is! LoadAccounts && e is! LoadMoreAccounts)
    .toList();

CategoriesBloc _categoriesBloc() {
  final bloc = MockCategoriesBloc();
  whenListen(
    bloc,
    const Stream<CategoriesState>.empty(),
    initialState: CategoriesLoadSuccess(
      allCategories: <Category>[],
      hasReachedMax: true,
      activeDate: DateTime(2024, 1, 1),
    ),
  );
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

// ---------------------------------------------------------------------------
// Harness
// ---------------------------------------------------------------------------

/// Opens the accounts screen on [state] with all four selection keys bound.
///
/// [settle] is off for states that render a spinner: its animation never ends,
/// so `pumpAndSettle` would time out rather than fail on anything meaningful.
Future<_RecordingAccountsBloc> _pumpAccounts(
  WidgetTester tester,
  AccountsState state, {
  bool settle = true,
}) async {
  setSurfaceSize(tester, const Size(900, 1200));

  final accountsBloc = _RecordingAccountsBloc();
  whenListen(
    accountsBloc,
    const Stream<AccountsState>.empty(),
    initialState: state,
  );

  final router = GoRouter(
    initialLocation: AppRoutes.accounts,
    routes: [
      GoRoute(
        path: AppRoutes.accounts,
        builder: (_, _) => const AccountsScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);

  // Above the app: both dialogs these keys open go onto the root navigator,
  // where providers wrapped around the screen are invisible.
  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp.router(
        routerConfig: router,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
      settingsBloc: createSettingsBloc(
        state: SettingsState(hotkeys: _selectionHotkeys),
      ),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: accountsBloc,
      categoriesBloc: _categoriesBloc(),
      currencyConverterBloc: _converterBloc(),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  return accountsBloc;
}

Future<void> _press(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool settle = true,
}) async {
  await tester.sendKeyEvent(key);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

void main() {
  group('AccountsScreen selection hotkeys while a selection is on screen', () {
    testWidgets('close leaves selection mode', (tester) async {
      final bloc = await _pumpAccounts(tester, _loaded(selected: {'a1'}));

      await _press(tester, _closeKey);

      expect(_selectionEvents(bloc), [const ToggleSelectionMode(false)]);
    });

    testWidgets('close works with nothing selected, like its button', (
      tester,
    ) async {
      // The close button is the one control that is on the app bar at zero
      // selected, so the key has to be there too.
      final bloc = await _pumpAccounts(tester, _loaded());

      await _press(tester, _closeKey);

      expect(_selectionEvents(bloc), [const ToggleSelectionMode(false)]);
    });

    testWidgets('select-all selects everything from a partial selection', (
      tester,
    ) async {
      final bloc = await _pumpAccounts(tester, _loaded(selected: {'a1'}));

      await _press(tester, _selectAllKey);

      expect(_selectionEvents(bloc), hasLength(1));
      expect(_selectionEvents(bloc).single, isA<SelectAllAccounts>());
    });

    testWidgets('select-all selects everything from an empty selection', (
      tester,
    ) async {
      final bloc = await _pumpAccounts(tester, _loaded());

      await _press(tester, _selectAllKey);

      expect(_selectionEvents(bloc).single, isA<SelectAllAccounts>());
    });

    testWidgets('select-all clears a selection that already covers the list', (
      tester,
    ) async {
      // The button is a toggle and turns into "deselect all" here; a key that
      // only ever selected would be dead on the second press.
      final bloc = await _pumpAccounts(tester, _loaded(selected: {'a1', 'a2'}));

      await _press(tester, _selectAllKey);

      expect(_selectionEvents(bloc).single, isA<ClearSelection>());
    });

    testWidgets('delete opens the confirmation for the whole selection', (
      tester,
    ) async {
      final l10n = await loadL10n();
      final bloc = await _pumpAccounts(tester, _loaded(selected: {'a1', 'a2'}));

      await _press(tester, _deleteKey);

      expect(find.text(l10n.deleteAccountsConfirmTitle(2)), findsOneWidget);

      await tester.tap(find.text(l10n.deleteAllButton));
      await tester.pumpAndSettle();

      final deletes = _selectionEvents(
        bloc,
      ).whereType<DeleteMultipleAccounts>().toList();
      expect(deletes, hasLength(1));
      expect(deletes.single.accountIds, containsAll(<String>['a1', 'a2']));
    });

    testWidgets('delete on a single account offers the reassign dialog', (
      tester,
    ) async {
      // One selected account takes the per-account dialog, exactly as the
      // button does - the two paths are the same helper.
      await _pumpAccounts(tester, _loaded(selected: {'a1'}));

      await _press(tester, _deleteKey);

      expect(find.byType(DeleteAccountDialog), findsOneWidget);
    });

    testWidgets('change type retypes the whole selection', (tester) async {
      final l10n = await loadL10n();
      final bloc = await _pumpAccounts(tester, _loaded(selected: {'a1', 'a2'}));

      await _press(tester, _changeTypeKey);

      expect(find.text(l10n.changeAccountTypeTitle), findsOneWidget);

      await tester.tap(find.text(l10n.changeButton));
      await tester.pumpAndSettle();

      final updates = _selectionEvents(
        bloc,
      ).whereType<UpdateAccountTypeForMultipleAccounts>().toList();
      expect(updates, hasLength(1));
      expect(updates.single.accountIds, containsAll(<String>['a1', 'a2']));
      // The dialog opens on the first type, so that is what Change sends.
      expect(updates.single.accountTypeId, _cash.id);
    });
  });

  // The tests above pin what each key does. These pin that it is the *same*
  // thing the button does: the key and the button are meant to be one body, and
  // a copy of the button's code would pass every assertion above while quietly
  // drifting from the app bar the settings screen says it mirrors.
  group('AccountsScreen selection hotkeys match their buttons', () {
    // Everything selected, so all four controls are on the bar (delete and
    // change-type are only rendered above zero) and both dialogs take their
    // multi-account form, which confirms with a single tap.
    AccountsState allSelected() => _loaded(selected: {'a1', 'a2'});

    /// Taps [icon] on the selection app bar and returns what that dispatched.
    Future<List<AccountsEvent>> viaButton(
      WidgetTester tester,
      IconData icon,
      String? confirmLabel,
    ) async {
      final bloc = await _pumpAccounts(tester, allSelected());
      await tester.tap(
        find.descendant(of: find.byType(AppBar), matching: find.byIcon(icon)),
      );
      await tester.pumpAndSettle();
      if (confirmLabel != null) {
        await tester.tap(find.text(confirmLabel));
        await tester.pumpAndSettle();
      }
      return _selectionEvents(bloc);
    }

    /// Presses [key] on the same screen and returns what that dispatched.
    Future<List<AccountsEvent>> viaKey(
      WidgetTester tester,
      LogicalKeyboardKey key,
      String? confirmLabel,
    ) async {
      final bloc = await _pumpAccounts(tester, allSelected());
      await _press(tester, key);
      if (confirmLabel != null) {
        await tester.tap(find.text(confirmLabel));
        await tester.pumpAndSettle();
      }
      return _selectionEvents(bloc);
    }

    testWidgets('close', (tester) async {
      final button = await viaButton(tester, Icons.close, null);
      final key = await viaKey(tester, _closeKey, null);

      expect(button, [const ToggleSelectionMode(false)]);
      expect(key, button);
    });

    testWidgets('select all', (tester) async {
      // Everything is selected, so this control is the "deselect all" half of
      // the toggle - the half a key that only ever selected would get wrong.
      final button = await viaButton(tester, Icons.deselect_outlined, null);
      final key = await viaKey(tester, _selectAllKey, null);

      expect(button.single, isA<ClearSelection>());
      expect(key.single, isA<ClearSelection>());
    });

    testWidgets('delete', (tester) async {
      final l10n = await loadL10n();

      final button = await viaButton(
        tester,
        Icons.delete,
        l10n.deleteAllButton,
      );
      final key = await viaKey(tester, _deleteKey, l10n.deleteAllButton);

      expect(button, [
        const DeleteMultipleAccounts(<String>['a1', 'a2']),
      ]);
      expect(key, button);
    });

    testWidgets('change type', (tester) async {
      final l10n = await loadL10n();

      final button = await viaButton(
        tester,
        Icons.drive_file_rename_outline,
        l10n.changeButton,
      );
      final key = await viaKey(tester, _changeTypeKey, l10n.changeButton);

      expect(button, [
        const UpdateAccountTypeForMultipleAccounts(<String>['a1', 'a2'], 't1'),
      ]);
      expect(key, button);
    });
  });

  group('AccountsScreen selection hotkeys with an empty selection', () {
    testWidgets('delete opens nothing', (tester) async {
      final bloc = await _pumpAccounts(tester, _loaded());

      await _press(tester, _deleteKey);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(DeleteAccountDialog), findsNothing);
      expect(_selectionEvents(bloc), isEmpty);
    });

    testWidgets('change type opens nothing', (tester) async {
      final l10n = await loadL10n();
      final bloc = await _pumpAccounts(tester, _loaded());

      await _press(tester, _changeTypeKey);

      expect(find.text(l10n.changeAccountTypeTitle), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(_selectionEvents(bloc), isEmpty);
    });
  });

  group('AccountsScreen selection hotkeys outside selection mode', () {
    // Selection mode off with rows still marked. `AccountsBloc` never emits
    // this - every path that turns the mode off empties the set in the same
    // emit - so it is a deliberately harsher input than production can
    // produce: it fails the guard for a second, independent reason, and a
    // guard weakened to check only the selection would still be caught here.
    // The reachable case these stand in for is select-all, which off the
    // selection bar would fill a selection with no bar to show or clear it.
    AccountsState remembered() =>
        _loaded(selectionMode: false, selected: {'a1', 'a2'});

    testWidgets('close does nothing', (tester) async {
      final bloc = await _pumpAccounts(tester, remembered());

      await _press(tester, _closeKey);

      expect(_selectionEvents(bloc), isEmpty);
    });

    testWidgets('select-all does nothing', (tester) async {
      final bloc = await _pumpAccounts(tester, remembered());

      await _press(tester, _selectAllKey);

      expect(_selectionEvents(bloc), isEmpty);
    });

    testWidgets('delete does nothing', (tester) async {
      final bloc = await _pumpAccounts(tester, remembered());

      await _press(tester, _deleteKey);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(DeleteAccountDialog), findsNothing);
      expect(_selectionEvents(bloc), isEmpty);
    });

    testWidgets('change type does nothing', (tester) async {
      final l10n = await loadL10n();
      final bloc = await _pumpAccounts(tester, remembered());

      await _press(tester, _changeTypeKey);

      expect(find.text(l10n.changeAccountTypeTitle), findsNothing);
      expect(_selectionEvents(bloc), isEmpty);
    });
  });

  group('AccountsScreen selection hotkeys before the accounts load', () {
    // Every state other than AccountsLoadSuccess reports an empty selection
    // without having looked, and none of them draws the selection app bar.
    testWidgets('all four do nothing while the screen is still loading', (
      tester,
    ) async {
      final bloc = await _pumpAccounts(
        tester,
        AccountsLoadInProgress(activeDate: DateTime(2024, 1, 1)),
        settle: false,
      );

      for (final key in [
        _closeKey,
        _selectAllKey,
        _deleteKey,
        _changeTypeKey,
      ]) {
        await _press(tester, key, settle: false);
      }

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(DeleteAccountDialog), findsNothing);
      expect(_selectionEvents(bloc), isEmpty);
    });
  });
}
