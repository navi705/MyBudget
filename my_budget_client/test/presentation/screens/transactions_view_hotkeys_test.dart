// The transactions date bar's three view controls, by key.
//
// The date picker, the sort toggle and the advanced filter each already carried
// an `actionId` - but they carried ids of their own invention
// (`filter_pick_date`, `filter_sort`, `filter_advanced`) that appeared in no
// `ScreenShortcuts.actions` map and in no Hot Keys catalog entry, while every
// other list screen bound the same three buttons under the screen-agnostic
// `pick_date` / `sort_order` / `filter_action`. `screen_shortcuts.dart` only
// builds a binding for an id it finds in its `actions` map, so those ids were
// not unbound, they were unbindable, and the badge could never appear.
//
// Two of the three bodies lived inside `FilterDate`, below the `ScreenShortcuts`
// in `TransactionsScreen`, so wiring them meant hoisting the bodies to the top
// level of filter_date.dart. That hoist is the risk these tests exist for: a key
// running a second copy of the code would pass a "did something happen" check
// and still drift from the button. So each action is asserted twice, once
// through the key and once through the button, on Equatable events.
//
// The last group covers the other half: the Hot Keys screen offers these ids
// unconditionally, but selection mode replaces the whole date bar with the
// selection app bar, so the guard can only live at the call site.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
// Accounts and Categories both export names the transactions bloc also
// exports; the two imports are narrowed to what the fixtures build so every
// event asserted on here resolves to the transactions declaration.
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart'
    show AccountsBloc, AccountsLoadSuccess, AccountsState;
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart'
    show CategoriesBloc, CategoriesLoadSuccess, CategoriesState;
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/transactions_screen.dart';
import 'package:my_budget_client/presentation/widgets/advanced_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

import '../test_app.dart';

/// One key per action, so a test can press exactly the one it means.
const _dateKey = LogicalKeyboardKey.keyT;
const _sortKey = LogicalKeyboardKey.keyS;
const _filterKey = LogicalKeyboardKey.keyF;

final _viewHotkeys = <String, String>{
  'pick_date': '${_dateKey.keyId}',
  'sort_order': '${_sortKey.keyId}',
  'filter_action': '${_filterKey.keyId}',
};

final _category = Category(id: 'c1', name: 'Groceries');

/// A [TransactionsBloc] that keeps what the screen dispatched.
///
/// `MockBloc.add` is a no-op that records nothing, and the sort assertions are
/// about which event reached the bloc.
class _RecordingTransactionsBloc extends MockTransactionsBloc {
  final events = <TransactionsEvent>[];

  @override
  void add(TransactionsEvent event) => events.add(event);
}

/// Every event the screen sent apart from the loads the list fires on the way
/// in, which are not what any of this is about.
List<TransactionsEvent> _viewEvents(_RecordingTransactionsBloc bloc) => bloc
    .events
    .where((e) => e is! InitialLoadTransactions && e is! LoadTransactions)
    .toList();

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

/// Opens the transactions screen with the date bar on it, or with the selection
/// bar that replaces it.
///
/// 900 wide is the desktop branch of the bar, so each of the three controls is
/// built exactly once and a finder cannot pick the wrong copy.
///
/// The calendar sheet and the filter dialog are routes of their own, so their
/// blocs have to be provided above the app rather than around the screen - a
/// provider around the routed page is invisible to a sibling route.
Future<_RecordingTransactionsBloc> _pumpTransactions(
  WidgetTester tester, {
  bool selectionMode = false,
  Map<String, String> hotkeys = const {},
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  final transactionsBloc = _RecordingTransactionsBloc();
  whenListen(
    transactionsBloc,
    const Stream<TransactionsState>.empty(),
    initialState: TransactionsState(
      status: TransactionStatus.success,
      isSelectionModeActive: selectionMode,
      selectedTransactionIds: selectionMode ? const {'t1'} : const {},
      activeDate: DateTime(2024, 1, 1),
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

/// The one control carrying [actionId].
///
/// Finding it by the id it advertises rather than by its icon keeps the pairing
/// honest: the tapped widget is provably the one the badge would appear on.
Finder _buttonFor(String actionId) => find.byWidgetPredicate(
  (widget) => widget is MultiLevelTooltip && widget.actionId == actionId,
);

void main() {
  group('transactions: pick date', () {
    testWidgets('the hotkey opens the calendar', (tester) async {
      await _pumpTransactions(tester, hotkeys: _viewHotkeys);

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });

    testWidgets('the button opens the same calendar', (tester) async {
      await _pumpTransactions(tester);

      await tester.tap(_buttonFor('pick_date'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });
  });

  group('transactions: sort order', () {
    testWidgets('the hotkey flips the sort', (tester) async {
      final bloc = await _pumpTransactions(tester, hotkeys: _viewHotkeys);

      await tester.sendKeyEvent(_sortKey);
      await tester.pumpAndSettle();

      // The state's default is descending, so this asserts a real flip rather
      // than a re-assertion of what was already there.
      expect(_viewEvents(bloc), [const SortChanged(Sort.ascending)]);
    });

    testWidgets('the button flips it the same way', (tester) async {
      final bloc = await _pumpTransactions(tester);

      await tester.tap(_buttonFor('sort_order'));
      await tester.pumpAndSettle();

      expect(_viewEvents(bloc), [const SortChanged(Sort.ascending)]);
    });
  });

  group('transactions: advanced filter', () {
    testWidgets('the hotkey opens the filter dialog', (tester) async {
      await _pumpTransactions(tester, hotkeys: _viewHotkeys);

      await tester.sendKeyEvent(_filterKey);
      await tester.pumpAndSettle();

      expect(find.byType(AdvancedFilterDialog), findsOneWidget);
    });

    testWidgets('the button opens the same dialog', (tester) async {
      await _pumpTransactions(tester);

      await tester.tap(_buttonFor('filter_action'));
      await tester.pumpAndSettle();

      expect(find.byType(AdvancedFilterDialog), findsOneWidget);
    });
  });

  group('transactions: the view keys under the selection bar', () {
    // Selection mode swaps the whole date bar out for the selection app bar, so
    // none of the three controls is on screen and the keys have to follow: a
    // calendar or a filter dialog over a running selection is an action the
    // mouse cannot take.
    testWidgets('all three do nothing while a selection is running', (
      tester,
    ) async {
      final bloc = await _pumpTransactions(
        tester,
        selectionMode: true,
        hotkeys: _viewHotkeys,
      );

      for (final key in [_dateKey, _sortKey, _filterKey]) {
        await tester.sendKeyEvent(key);
        await tester.pumpAndSettle();
      }

      expect(find.byType(CalendarStepPicker), findsNothing);
      expect(find.byType(AdvancedFilterDialog), findsNothing);
      expect(_viewEvents(bloc), isEmpty);
    });
  });
}
