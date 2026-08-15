// The selection app bar's four buttons, reached by key instead of by mouse.
//
// The hot keys screen offers `categories_selection_close` / `_all` / `_delete`
// / `_change_type` like any other binding, and the conflict checker even warns
// about the key the user picks - but nothing on this screen ever listened for
// those ids, so every one of those bindings was inert forever.
//
// Registering them creates the opposite hazard: a binding is live on every
// frame the screen is mounted, including the plain date app bar and the
// loading spinner, where not one of the four buttons exists. So each id is
// pinned twice below - once for what it must do while the selection app bar is
// up, and once for the states where it must do nothing at all. Delete and
// change type carry a third case, because their buttons are themselves hidden
// while the selection is empty.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
// Both bloc libraries export ToggleSelectionMode and ClearSelection; every one
// of those names in this file is the categories bloc's.
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart'
    show AccountsLoadInProgress, AccountsState;
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';

import '../test_app.dart';

final _groceries = Category(
  id: 'c1',
  name: 'Groceries',
  type: CategoryType.expense,
);

final _rent = Category(id: 'c2', name: 'Rent', type: CategoryType.expense);

/// All four bindings, on every test.
///
/// Binding only the key under test would hide a callback that fires on the
/// wrong id; with all four live, each assertion also says the other three
/// stayed quiet.
final _hotkeys = <String, String>{
  'categories_selection_close': '${LogicalKeyboardKey.keyQ.keyId}',
  'categories_selection_all': '${LogicalKeyboardKey.keyA.keyId}',
  'categories_selection_delete': '${LogicalKeyboardKey.keyD.keyId}',
  'categories_selection_change_type': '${LogicalKeyboardKey.keyT.keyId}',
};

/// Two categories, both top level, so "everything selected" is reachable.
CategoriesLoadSuccess _loaded({
  required bool selectionMode,
  Set<String> selected = const {},
}) => CategoriesLoadSuccess(
  categoriesWithTotals: [
    CategoryWithTotal(category: _groceries, total: 0),
    CategoryWithTotal(category: _rent, total: 0),
  ],
  allCategories: [_groceries, _rent],
  hasReachedMax: true,
  activeDate: DateTime(2024, 1, 1),
  isSelectionModeActive: selectionMode,
  selectedCategoryIds: selected,
);

/// A [CategoriesBloc] that records what the screen dispatched.
///
/// `MockBloc.add` is a no-op that keeps no history, and half of these tests are
/// about *which* event a key sent - or whether one was sent at all.
class _RecordingCategoriesBloc extends MockCategoriesBloc {
  final events = <CategoriesEvent>[];

  @override
  void add(CategoriesEvent event) => events.add(event);
}

/// Pumps CategoriesScreen on [state] with all four selection keys bound.
///
/// The blocs sit above the app because both confirmation dialogs go onto the
/// root navigator, where providers wrapped around the screen are invisible -
/// the same reason `AppProviders` sits above the app in production.
Future<_RecordingCategoriesBloc> _pumpCategories(
  WidgetTester tester,
  CategoriesState state,
) async {
  final categories = _RecordingCategoriesBloc();
  whenListen(
    categories,
    const Stream<CategoriesState>.empty(),
    initialState: state,
  );

  final accounts = MockAccountsBloc();
  whenListen(
    accounts,
    const Stream<AccountsState>.empty(),
    initialState: AccountsLoadInProgress(activeDate: DateTime(2024, 1, 1)),
  );

  await pumpAppWidget(
    tester,
    const CategoriesScreen(),
    surfaceSize: const Size(900, 900),
    wrapInScaffold: false,
    aboveApp: (app) => wrapWithBlocs(
      app,
      settingsBloc: createSettingsBloc(state: SettingsState(hotkeys: _hotkeys)),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
      accountsBloc: accounts,
      categoriesBloc: categories,
    ),
  );
  await tester.pump();

  // `initState` loads the list; no test here is about that.
  categories.events.clear();
  return categories;
}

void main() {
  group('categories_selection_close', () {
    testWidgets('leaves selection mode while the selection app bar is up', (
      tester,
    ) async {
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1'}),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pump();

      expect(bloc.events, [const ToggleSelectionMode(false)]);
    });

    testWidgets('does nothing on the ordinary list', (tester) async {
      final bloc = await _pumpCategories(tester, _loaded(selectionMode: false));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pump();

      expect(bloc.events, isEmpty);
    });
  });

  group('categories_selection_all', () {
    testWidgets('selects everything while part of the list is selected', (
      tester,
    ) async {
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1'}),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(bloc.events, [isA<SelectAllCategories>()]);
    });

    testWidgets('selects everything while nothing is selected', (tester) async {
      // An empty selection is not "all selected" even though the counts would
      // match on an empty list, so the key still has to reach select-all.
      final bloc = await _pumpCategories(tester, _loaded(selectionMode: true));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(bloc.events, [isA<SelectAllCategories>()]);
    });

    testWidgets('clears the selection once everything is selected', (
      tester,
    ) async {
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1', 'c2'}),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(bloc.events, [isA<ClearSelection>()]);
    });

    testWidgets('does nothing on the ordinary list', (tester) async {
      final bloc = await _pumpCategories(tester, _loaded(selectionMode: false));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      expect(bloc.events, isEmpty);
    });
  });

  group('categories_selection_delete', () {
    testWidgets('asks about the whole selection', (tester) async {
      final l10n = await loadL10n();
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1', 'c2'}),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.deleteCategoriesConfirmationTitle(2)),
        findsOneWidget,
      );
      // Nothing is destroyed before the confirmation is answered.
      expect(bloc.events, isEmpty);

      await tester.tap(find.text(l10n.deleteButton));
      await tester.pumpAndSettle();

      expect(bloc.events, [
        isA<DeleteMultipleCategories>().having(
          (e) => e.categoryIds,
          'categoryIds',
          unorderedEquals(<String>['c1', 'c2']),
        ),
      ]);
    });

    testWidgets('does nothing while the selection is empty', (tester) async {
      // The delete button is hidden at `selectedCount == 0`; the key follows.
      final bloc = await _pumpCategories(tester, _loaded(selectionMode: true));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(bloc.events, isEmpty);
    });

    testWidgets('does nothing on the ordinary list', (tester) async {
      // A selection left over from an earlier session is the dangerous case:
      // the ids are still in the state, but no selection UI is on screen.
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: false, selected: const {'c1', 'c2'}),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(bloc.events, isEmpty);
    });
  });

  group('categories_selection_change_type', () {
    testWidgets('retypes the whole selection', (tester) async {
      final l10n = await loadL10n();
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1', 'c2'}),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pumpAndSettle();

      expect(find.text(l10n.changeCategoryTypeDialogTitle), findsOneWidget);
      expect(bloc.events, isEmpty);

      await tester.tap(find.text(l10n.categoriesChangeButton));
      await tester.pumpAndSettle();

      expect(bloc.events, [
        isA<UpdateCategoryTypeForMultipleCategories>().having(
          (e) => e.categoryIds,
          'categoryIds',
          unorderedEquals(<String>['c1', 'c2']),
        ),
      ]);
    });

    testWidgets('does nothing while the selection is empty', (tester) async {
      // The change-type button shares the delete button's `selectedCount > 0`.
      final bloc = await _pumpCategories(tester, _loaded(selectionMode: true));

      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(bloc.events, isEmpty);
    });

    testWidgets('does nothing on the ordinary list', (tester) async {
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: false, selected: const {'c1', 'c2'}),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      expect(bloc.events, isEmpty);
    });
  });

  group('the four keys before the list has loaded', () {
    // Nothing is on screen but a spinner, so there is no selection to act on
    // and no app bar to have started one.
    testWidgets('stay inert', (tester) async {
      final bloc = await _pumpCategories(tester, CategoriesLoadInProgress());

      for (final key in [
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyA,
        LogicalKeyboardKey.keyD,
        LogicalKeyboardKey.keyT,
      ]) {
        await tester.sendKeyEvent(key);
        // Not `pumpAndSettle`: the loading spinner never settles.
        await tester.pump();
      }

      expect(bloc.events, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });

  group('the buttons the keys stand in for', () {
    // The point of the whole change is that a key and its button run one body,
    // so the button half is pinned to the same outcomes the key half asserts
    // above. A regression that rewires only one of the two shows up here as a
    // disagreement between two otherwise identical expectations.
    testWidgets('close leaves selection mode', (tester) async {
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1'}),
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
      await tester.pump();

      expect(bloc.events, [const ToggleSelectionMode(false)]);
    });

    testWidgets('select-all selects everything', (tester) async {
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1'}),
      );

      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.select_all_outlined),
      );
      await tester.pump();

      expect(bloc.events, [isA<SelectAllCategories>()]);
    });

    testWidgets('deselect-all clears a full selection', (tester) async {
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1', 'c2'}),
      );

      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.deselect_outlined),
      );
      await tester.pump();

      expect(bloc.events, [isA<ClearSelection>()]);
    });

    testWidgets('delete asks about the whole selection', (tester) async {
      final l10n = await loadL10n();
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1', 'c2'}),
      );

      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete));
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.deleteCategoriesConfirmationTitle(2)),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.deleteButton));
      await tester.pumpAndSettle();

      expect(bloc.events, [
        isA<DeleteMultipleCategories>().having(
          (e) => e.categoryIds,
          'categoryIds',
          unorderedEquals(<String>['c1', 'c2']),
        ),
      ]);
    });

    testWidgets('change type retypes the whole selection', (tester) async {
      final l10n = await loadL10n();
      final bloc = await _pumpCategories(
        tester,
        _loaded(selectionMode: true, selected: const {'c1', 'c2'}),
      );

      await tester.tap(
        find.widgetWithIcon(IconButton, Icons.drive_file_rename_outline),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.changeCategoryTypeDialogTitle), findsOneWidget);

      await tester.tap(find.text(l10n.categoriesChangeButton));
      await tester.pumpAndSettle();

      expect(bloc.events, [
        isA<UpdateCategoryTypeForMultipleCategories>().having(
          (e) => e.categoryIds,
          'categoryIds',
          unorderedEquals(<String>['c1', 'c2']),
        ),
      ]);
    });
  });

  group('while the delete confirmation is pending', () {
    // `CategoryDeletionConfirmationNeeded` is the state the bloc sits in after
    // a delete needs an answer - and it stays there when the user cancels,
    // because Cancel only pops the dialog and dispatches nothing. `build`
    // paints the selection app bar from `lastSuccessState` throughout, so all
    // four buttons are on screen and neither they nor their keys may be dead:
    // a guard that only accepted `CategoriesLoadSuccess` would drop every one
    // of them while they were still visible and pressable.
    CategoriesState pending() => CategoryDeletionConfirmationNeeded(
      categoryToDelete: _groceries,
      allCategories: [_groceries, _rent],
      lastSuccessState: _loaded(selectionMode: true, selected: const {'c1'}),
    );

    testWidgets('the close key still leaves selection mode', (tester) async {
      final bloc = await _pumpCategories(tester, pending());

      await tester.sendKeyEvent(LogicalKeyboardKey.keyQ);
      await tester.pump();

      expect(bloc.events, [const ToggleSelectionMode(false)]);
    });

    testWidgets('the close button still does the same', (tester) async {
      final bloc = await _pumpCategories(tester, pending());

      await tester.tap(find.widgetWithIcon(IconButton, Icons.close));
      await tester.pump();

      expect(bloc.events, [const ToggleSelectionMode(false)]);
    });
  });
}
