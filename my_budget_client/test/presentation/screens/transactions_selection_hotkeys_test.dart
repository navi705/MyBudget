// The four selection-bar actions on the transactions screen, reached by key.
//
// Transactions was the only one of the four selection screens whose bar was
// pure mouse: its buttons carried `actionId`s, so `MultiLevelTooltip` would
// have shown a shortcut badge, but no `ScreenShortcuts` map mentioned them and
// the Hot Keys settings screen did not list them, so `state.hotkeys[id]` was
// forever null and nothing could ever be bound. `screen_shortcuts.dart` only
// builds a binding for ids present in the `actions` map, so an id missing from
// it is not "unbound", it is unbindable.
//
// Two things have to hold and neither is visible from the widget tree alone:
// the key must run *the same code the button runs* rather than a copy that
// will drift, and it must do nothing at all when the selection bar is not on
// screen - the Hot Keys screen offers these ids unconditionally, so the guard
// can only live at the call site. Every test below is paired: the same
// assertion is made once through the key and once through the button, and the
// events are Equatable, so "the same" is exact rather than approximate.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
// Accounts and Categories both export a `ToggleSelectionMode`, and every one
// in this file is the transactions bloc's. The two imports are narrowed to
// what the fixtures build so the name resolves to a single declaration.
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart'
    show AccountsBloc, AccountsLoadSuccess, AccountsState;
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart'
    show CategoriesBloc, CategoriesLoadSuccess, CategoriesState;
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/transactions_screen.dart';
import 'package:my_budget_client/presentation/widgets/category_picker_dialog.dart';

import '../test_app.dart';

/// The rows the selection bar is acting on.
const _selected = {'t1', 't2'};

/// One key per action, so a test can press exactly the one it means.
const _closeKey = LogicalKeyboardKey.keyQ;
const _deleteKey = LogicalKeyboardKey.keyD;
const _dateKey = LogicalKeyboardKey.keyT;
const _categoryKey = LogicalKeyboardKey.keyC;

final _hotkeys = <String, String>{
  'transactions_selection_close': '${_closeKey.keyId}',
  'transactions_selection_delete': '${_deleteKey.keyId}',
  'transactions_selection_change_date': '${_dateKey.keyId}',
  'transactions_selection_change_category': '${_categoryKey.keyId}',
};

final _category = Category(id: 'c1', name: 'Groceries');

/// A [TransactionsBloc] that keeps what the screen dispatched.
///
/// `MockBloc.add` is a no-op that records nothing, and every assertion here is
/// about which event reached the bloc, so the recording subclass is the whole
/// instrument.
class _RecordingTransactionsBloc extends MockTransactionsBloc {
  final events = <TransactionsEvent>[];

  @override
  void add(TransactionsEvent event) => events.add(event);
}

TransactionsBloc _pinned(_RecordingTransactionsBloc bloc, TransactionsState s) {
  whenListen(bloc, const Stream<TransactionsState>.empty(), initialState: s);
  return bloc;
}

AccountsBloc _accountsBloc() {
  final bloc = MockAccountsBloc();
  whenListen(
    bloc,
    const Stream<AccountsState>.empty(),
    initialState: AccountsLoadSuccess(
      accounts: const [],
      accountTypes: const [],
      hasReachedMax: true,
      totalCount: 0,
      exchangeRates: const [],
      activeDate: DateTime(2024, 1, 1),
      unfilteredAccountCount: 1,
    ),
  );
  return bloc;
}

/// Loaded with one category, so the picker can actually be tapped through.
CategoriesBloc _categoriesBloc() {
  final bloc = MockCategoriesBloc();
  whenListen(
    bloc,
    const Stream<CategoriesState>.empty(),
    initialState: CategoriesLoadSuccess(
      categoriesWithTotals: [CategoryWithTotal(category: _category, total: 0)],
      allCategories: [_category],
      hasReachedMax: true,
      activeDate: DateTime(2024, 1, 1),
    ),
  );
  return bloc;
}

/// Opens the screen with the selection bar on or off.
///
/// The dialogs this screen opens go onto the root navigator, so their blocs
/// have to be provided above the app rather than around the screen - a
/// provider around the routed page is invisible to a sibling route.
Future<_RecordingTransactionsBloc> _pumpTransactions(
  WidgetTester tester, {
  required bool selectionMode,
  Map<String, String> hotkeys = const {},
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  final transactionsBloc = _RecordingTransactionsBloc();
  _pinned(
    transactionsBloc,
    TransactionsState(
      status: TransactionStatus.success,
      isSelectionModeActive: selectionMode,
      selectedTransactionIds: selectionMode ? _selected : const {},
    ),
  );

  final router = GoRouter(
    initialLocation: AppRoutes.transactions,
    routes: [
      GoRoute(
        path: AppRoutes.transactions,
        builder: (_, _) => const TransactionsScreen(),
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
      settingsBloc: createSettingsBloc(state: SettingsState(hotkeys: hotkeys)),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: _accountsBloc(),
      categoriesBloc: _categoriesBloc(),
      transactionsBloc: transactionsBloc,
    ),
  );
  await tester.pump();
  return transactionsBloc;
}

/// Confirms the date picker on whatever day it opened on.
///
/// The label comes from [MaterialLocalizations] rather than a literal, so the
/// test does not quietly assert that the framework is in English.
Future<DateTime> _confirmDatePicker(WidgetTester tester) async {
  final dialog = find.byType(DatePickerDialog);
  expect(dialog, findsOneWidget);
  final materialL10n = MaterialLocalizations.of(tester.element(dialog));
  await tester.tap(find.text(materialL10n.okButtonLabel));
  await tester.pumpAndSettle();
  return DateTime.now();
}

void _expectSameDay(DateTime actual, DateTime expected) {
  expect(actual.year, expected.year);
  expect(actual.month, expected.month);
  expect(actual.day, expected.day);
}

void main() {
  group('transactions selection: close', () {
    testWidgets('the hotkey leaves selection mode', (tester) async {
      final bloc = await _pumpTransactions(
        tester,
        selectionMode: true,
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_closeKey);
      await tester.pumpAndSettle();

      expect(bloc.events, contains(const ToggleSelectionMode(false)));
    });

    testWidgets('the button leaves selection mode the same way', (
      tester,
    ) async {
      final bloc = await _pumpTransactions(tester, selectionMode: true);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(const ToggleSelectionMode(false)));
    });
  });

  group('transactions selection: delete', () {
    testWidgets('the hotkey asks before deleting anything', (tester) async {
      final l10n = await loadL10n();
      final bloc = await _pumpTransactions(
        tester,
        selectionMode: true,
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_deleteKey);
      await tester.pumpAndSettle();

      // The confirmation is the point: a key that deletes on the way down
      // would be far more dangerous than the button it stands in for.
      expect(
        find.text(l10n.deleteTransactionsConfirmationTitle),
        findsOneWidget,
      );
      expect(bloc.events.whereType<DeleteMultipleTransactions>(), isEmpty);
    });

    testWidgets('confirming after the hotkey deletes the selection', (
      tester,
    ) async {
      final l10n = await loadL10n();
      final bloc = await _pumpTransactions(
        tester,
        selectionMode: true,
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_deleteKey);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.deleteButton));
      await tester.pumpAndSettle();

      expect(
        bloc.events,
        contains(DeleteMultipleTransactions(_selected.toList())),
      );
    });

    testWidgets('the button deletes the same selection', (tester) async {
      final l10n = await loadL10n();
      final bloc = await _pumpTransactions(tester, selectionMode: true);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.deleteButton));
      await tester.pumpAndSettle();

      expect(
        bloc.events,
        contains(DeleteMultipleTransactions(_selected.toList())),
      );
    });
  });

  group('transactions selection: change date', () {
    testWidgets('the hotkey opens the picker and applies the chosen day', (
      tester,
    ) async {
      final bloc = await _pumpTransactions(
        tester,
        selectionMode: true,
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();
      final today = await _confirmDatePicker(tester);

      final events = bloc.events
          .whereType<UpdateDateForMultipleTransactions>()
          .toList();
      expect(events, hasLength(1));
      expect(events.single.ids, _selected.toList());
      _expectSameDay(events.single.newDate, today);
    });

    testWidgets('the button opens the same picker', (tester) async {
      final bloc = await _pumpTransactions(tester, selectionMode: true);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.calendar_today));
      await tester.pumpAndSettle();
      final today = await _confirmDatePicker(tester);

      final events = bloc.events
          .whereType<UpdateDateForMultipleTransactions>()
          .toList();
      expect(events, hasLength(1));
      expect(events.single.ids, _selected.toList());
      _expectSameDay(events.single.newDate, today);
    });
  });

  group('transactions selection: change category', () {
    testWidgets('the hotkey opens the picker and applies the choice', (
      tester,
    ) async {
      final bloc = await _pumpTransactions(
        tester,
        selectionMode: true,
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_categoryKey);
      await tester.pumpAndSettle();
      expect(find.byType(CategoryPickerDialog), findsOneWidget);

      await tester.tap(find.text(_category.name));
      await tester.pumpAndSettle();

      expect(
        bloc.events,
        contains(
          UpdateCategoryForMultipleTransactions(_selected.toList(), 'c1'),
        ),
      );
    });

    testWidgets('the button opens the same picker', (tester) async {
      final bloc = await _pumpTransactions(tester, selectionMode: true);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.category));
      await tester.pumpAndSettle();
      expect(find.byType(CategoryPickerDialog), findsOneWidget);

      await tester.tap(find.text(_category.name));
      await tester.pumpAndSettle();

      expect(
        bloc.events,
        contains(
          UpdateCategoryForMultipleTransactions(_selected.toList(), 'c1'),
        ),
      );
    });
  });

  group('transactions selection keys off the selection bar', () {
    // The Hot Keys screen lists these four unconditionally, so a user is free
    // to bind them to a bare letter and then spend all day on a normal
    // transactions list. Without the guard at the call site, D would delete a
    // selection that is not on screen and T would re-date it.
    testWidgets('do nothing while selection mode is off', (tester) async {
      final bloc = await _pumpTransactions(
        tester,
        selectionMode: false,
        hotkeys: _hotkeys,
      );

      for (final key in [_closeKey, _deleteKey, _dateKey, _categoryKey]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }

      // Not `isEmpty`: a screen out of selection mode shows the normal list,
      // which loads itself. Only the four selection events are forbidden.
      expect(bloc.events.whereType<ToggleSelectionMode>(), isEmpty);
      expect(bloc.events.whereType<DeleteMultipleTransactions>(), isEmpty);
      expect(
        bloc.events.whereType<UpdateDateForMultipleTransactions>(),
        isEmpty,
      );
      expect(
        bloc.events.whereType<UpdateCategoryForMultipleTransactions>(),
        isEmpty,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(DatePickerDialog), findsNothing);
    });
  });
}
