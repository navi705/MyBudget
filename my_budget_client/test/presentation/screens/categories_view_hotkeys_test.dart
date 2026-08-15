// The date, sort and filter controls of the categories app bar, by key.
//
// All three carried an `actionId`, so `MultiLevelTooltip` was ready to draw a
// shortcut badge on them, but the ids were per-screen and no `ScreenShortcuts`
// map mentioned them. `screen_shortcuts.dart` builds a binding only for ids
// present in its `actions` map, so those ids were not unbound - they were
// unbindable, and the badge could never appear.
//
// The calendar and the sort toggle lived on `_CategoriesDateAppBar`, a class
// the screen's `ScreenShortcuts` cannot reach, so wiring them meant hoisting
// the bodies to the top level of the file. That hoist is the risk these tests
// exist for: a key running a second copy of the code would pass a "did
// something happen" check and still drift from the button. So every one of the
// three is asserted twice, once through the key and once through the button.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart'
    show AccountsLoadInProgress, AccountsState;
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

import '../test_app.dart';

final _groceries = Category(
  id: 'c1',
  name: 'Groceries',
  type: CategoryType.expense,
);

final _rent = Category(id: 'c2', name: 'Rent', type: CategoryType.expense);

/// One key per action, so a test can press exactly the one it means.
const _dateKey = LogicalKeyboardKey.keyT;
const _sortKey = LogicalKeyboardKey.keyS;
const _filterKey = LogicalKeyboardKey.keyF;

/// All three bindings, on every test.
///
/// Binding only the key under test would hide a callback that fires on the
/// wrong id; with all three live, each assertion also says the other two stayed
/// quiet.
final _hotkeys = <String, String>{
  'pick_date': '${_dateKey.keyId}',
  'sort_order': '${_sortKey.keyId}',
  'filter_action': '${_filterKey.keyId}',
};

/// The loaded list the date app bar is painted from.
///
/// `filters` is left at its default, which sorts ascending, so the one flip the
/// sort tests assert is a real toggle rather than a re-assertion of whatever
/// the state already held.
CategoriesLoadSuccess _loaded() => CategoriesLoadSuccess(
  categoriesWithTotals: [
    CategoryWithTotal(category: _groceries, total: 0),
    CategoryWithTotal(category: _rent, total: 0),
  ],
  allCategories: [_groceries, _rent],
  hasReachedMax: true,
  activeDate: DateTime(2024, 1, 1),
);

/// A [CategoriesBloc] that records what the screen dispatched.
///
/// `MockBloc.add` is a no-op that keeps no history, and the sort assertions are
/// about *which* event reached the bloc - or whether one was sent at all.
class _RecordingCategoriesBloc extends MockCategoriesBloc {
  final events = <CategoriesEvent>[];

  @override
  void add(CategoriesEvent event) => events.add(event);
}

/// Pumps CategoriesScreen on [state] with the three view keys bound.
///
/// The blocs sit above the app because the filter dialog and the calendar sheet
/// go onto the navigator, where providers wrapped around the screen are
/// invisible - the same reason `AppProviders` sits above the app in production.
/// The 900pt surface puts the app bar on its desktop branch, so each of the
/// three ids is carried by exactly one button rather than by both layouts.
Future<_RecordingCategoriesBloc> _pumpCategories(
  WidgetTester tester,
  CategoriesState state, {
  Map<String, String> hotkeys = const {},
}) async {
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
      settingsBloc: createSettingsBloc(state: SettingsState(hotkeys: hotkeys)),
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

/// The one button carrying [actionId].
///
/// Finding the button by the id it advertises rather than by its icon keeps the
/// pairing honest: the tapped widget is provably the same one the badge would
/// appear on, and the finder does not have to know which of the app bar's two
/// layout branches built it.
Finder _buttonFor(String actionId) => find.byWidgetPredicate(
  (widget) => widget is MultiLevelTooltip && widget.actionId == actionId,
);

void main() {
  group('categories: pick date', () {
    testWidgets('the hotkey opens the calendar', (tester) async {
      await _pumpCategories(tester, _loaded(), hotkeys: _hotkeys);

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });

    testWidgets('the button opens the same calendar', (tester) async {
      await _pumpCategories(tester, _loaded());

      await tester.tap(_buttonFor('pick_date'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });
  });

  group('categories: sort order', () {
    testWidgets('the hotkey flips the sort', (tester) async {
      final bloc = await _pumpCategories(tester, _loaded(), hotkeys: _hotkeys);

      await tester.sendKeyEvent(_sortKey);
      await tester.pumpAndSettle();

      expect(bloc.events, [const SortChanged(Sort.descending)]);
    });

    testWidgets('the button flips it the same way', (tester) async {
      final bloc = await _pumpCategories(tester, _loaded());

      await tester.tap(_buttonFor('sort_order'));
      await tester.pumpAndSettle();

      expect(bloc.events, [const SortChanged(Sort.descending)]);
    });
  });

  group('categories: filter', () {
    testWidgets('the hotkey opens the filter dialog', (tester) async {
      final l10n = await loadL10n();
      await _pumpCategories(tester, _loaded(), hotkeys: _hotkeys);

      await tester.sendKeyEvent(_filterKey);
      await tester.pumpAndSettle();

      expect(find.text(l10n.fltFilterCategoriesTitle), findsOneWidget);
    });

    testWidgets('the button opens the same dialog', (tester) async {
      final l10n = await loadL10n();
      await _pumpCategories(tester, _loaded());

      await tester.tap(_buttonFor('filter_action'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.fltFilterCategoriesTitle), findsOneWidget);
    });
  });

  group('while the delete confirmation is pending', () {
    // `CategoryDeletionConfirmationNeeded` is the state the bloc sits in after a
    // delete needs an answer - and it stays there when the user cancels, because
    // Cancel only pops the dialog and dispatches nothing. `build` paints the
    // date app bar from `lastSuccessState` throughout, so all three buttons are
    // on screen and neither they nor their keys may be dead: a guard that only
    // accepted `CategoriesLoadSuccess` would drop every one of them while they
    // were still visible and pressable.
    CategoriesState pending() => CategoryDeletionConfirmationNeeded(
      categoryToDelete: _groceries,
      allCategories: [_groceries, _rent],
      lastSuccessState: _loaded(),
    );

    testWidgets('the sort key still flips the sort', (tester) async {
      final bloc = await _pumpCategories(tester, pending(), hotkeys: _hotkeys);

      await tester.sendKeyEvent(_sortKey);
      await tester.pumpAndSettle();

      expect(bloc.events, [const SortChanged(Sort.descending)]);
    });

    testWidgets('the sort button still does the same', (tester) async {
      final bloc = await _pumpCategories(tester, pending());

      await tester.tap(_buttonFor('sort_order'));
      await tester.pumpAndSettle();

      expect(bloc.events, [const SortChanged(Sort.descending)]);
    });
  });

  group('the three keys before the list has loaded', () {
    // Nothing is on screen but a spinner: there is no date to open a calendar
    // on, no sort to flip and no filters to seed a dialog with, and no button
    // offers any of the three either.
    testWidgets('stay inert', (tester) async {
      final bloc = await _pumpCategories(
        tester,
        CategoriesLoadInProgress(),
        hotkeys: _hotkeys,
      );

      for (final key in [_dateKey, _sortKey, _filterKey]) {
        await tester.sendKeyEvent(key);
        // Not `pumpAndSettle`: the loading spinner never settles.
        await tester.pump();
      }

      expect(bloc.events, isEmpty);
      expect(find.byType(CalendarStepPicker), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
