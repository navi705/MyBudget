// The date app bar's three view controls, by key.
//
// The date picker, the sort toggle and the filter button each already carried
// an `actionId`, so `MultiLevelTooltip` was ready to draw a shortcut badge -
// but no `ScreenShortcuts.actions` map on this screen listed those ids, and
// `screen_shortcuts.dart` only builds a binding for an id it finds there. The
// ids were not unbound, they were unbindable, and the badge could never appear.
//
// Two of the three bodies lived on `_AccountsDateAppBar`, several widgets below
// the `ScreenShortcuts` in `_AccountsScreenState`, so wiring them meant hoisting
// the bodies to the top level. That hoist is the risk these tests exist for: a
// key running a second copy of the code would pass a "did something happen"
// check and still drift from the button. So each action is asserted twice, once
// through the key and once through the button.
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
// Both bloc libraries export ActiveDateChanged and DatePeriodNavigated, and
// every event asserted on here belongs to the accounts bloc.
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart'
    show CategoriesBloc, CategoriesLoadSuccess, CategoriesState;
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/widgets/account_filter_dialog.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

import '../test_app.dart';

/// One key per action, so a test can press exactly the one it means.
const _dateKey = LogicalKeyboardKey.keyT;
const _sortKey = LogicalKeyboardKey.keyS;
const _filterKey = LogicalKeyboardKey.keyF;

final Map<String, String> _viewHotkeys = {
  'pick_date': '${_dateKey.keyId}',
  'sort_order': '${_sortKey.keyId}',
  'filter_action': '${_filterKey.keyId}',
};

final _checking = Account(
  id: 'a1',
  name: 'Checking',
  balance: 100,
  currencyCode: 'EUR',
  currencyDesignationId: 'd1',
  accountTypeId: 't1',
  creationDate: DateTime(2024, 1, 1),
);

const _cash = AccountType(id: 't1', name: 'Cash', languageCode: 'en');

/// The loaded screen with the date app bar on it, never the selection bar.
AccountsState _loaded() => AccountsLoadSuccess(
  accounts: [_checking],
  accountTypes: const [_cash],
  hasReachedMax: true,
  totalCount: 1,
  exchangeRates: const [],
  activeDate: DateTime(2024, 1, 1),
);

/// An [AccountsBloc] that records what the screen dispatched.
///
/// `MockBloc.add` is a no-op that keeps no history, and the sort assertions are
/// about which event reached the bloc.
class _RecordingAccountsBloc extends MockAccountsBloc {
  final events = <AccountsEvent>[];

  @override
  void add(AccountsEvent event) => events.add(event);
}

/// Every event the screen sent apart from the loads it fires while scrolling in.
List<AccountsEvent> _viewEvents(_RecordingAccountsBloc bloc) => bloc.events
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

/// Opens the accounts screen with the three view keys bound.
///
/// 900 wide is the desktop branch of the app bar, so each of the three controls
/// is built exactly once and a finder cannot pick the wrong copy.
///
/// [settle] is off for states that render a spinner: its animation never ends,
/// so `pumpAndSettle` would time out rather than fail on anything meaningful.
Future<_RecordingAccountsBloc> _pumpAccounts(
  WidgetTester tester, {
  AccountsState? state,
  Map<String, String> hotkeys = const {},
  bool settle = true,
}) async {
  setSurfaceSize(tester, const Size(900, 1200));

  final accountsBloc = _RecordingAccountsBloc();
  whenListen(
    accountsBloc,
    const Stream<AccountsState>.empty(),
    initialState: state ?? _loaded(),
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

  // Above the app: the filter dialog goes onto the root navigator and reads the
  // settings, currency and categories blocs from there.
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

/// The one control carrying [actionId].
///
/// Finding it by the id it advertises rather than by its icon keeps the pairing
/// honest: the tapped widget is provably the one the badge would appear on.
Finder _buttonFor(String actionId) => find.byWidgetPredicate(
  (widget) => widget is MultiLevelTooltip && widget.actionId == actionId,
);

void main() {
  group('accounts: pick date', () {
    testWidgets('the hotkey opens the calendar', (tester) async {
      await _pumpAccounts(tester, hotkeys: _viewHotkeys);

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });

    testWidgets('the button opens the same calendar', (tester) async {
      await _pumpAccounts(tester);

      await tester.tap(_buttonFor('pick_date'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });
  });

  group('accounts: sort order', () {
    testWidgets('the hotkey flips the sort', (tester) async {
      final bloc = await _pumpAccounts(tester, hotkeys: _viewHotkeys);

      await tester.sendKeyEvent(_sortKey);
      await tester.pumpAndSettle();

      // The state's default is descending, so this asserts a real flip rather
      // than a re-assertion of what was already there.
      expect(_viewEvents(bloc), [const SortAccounts(true)]);
    });

    testWidgets('the button flips it the same way', (tester) async {
      final bloc = await _pumpAccounts(tester);

      await tester.tap(_buttonFor('sort_order'));
      await tester.pumpAndSettle();

      expect(_viewEvents(bloc), [const SortAccounts(true)]);
    });
  });

  group('accounts: filter', () {
    testWidgets('the hotkey opens the filter dialog', (tester) async {
      await _pumpAccounts(tester, hotkeys: _viewHotkeys);

      await tester.sendKeyEvent(_filterKey);
      await tester.pumpAndSettle();

      expect(find.byType(AccountFilterDialog), findsOneWidget);
    });

    testWidgets('the button opens the same dialog', (tester) async {
      await _pumpAccounts(tester);

      await tester.tap(_buttonFor('filter_action'));
      await tester.pumpAndSettle();

      expect(find.byType(AccountFilterDialog), findsOneWidget);
    });
  });

  group('accounts: the view keys before the accounts load', () {
    // Every state other than AccountsLoadSuccess draws no date app bar at all,
    // so none of the three controls is on screen and the keys must follow.
    testWidgets('all three do nothing while the screen is still loading', (
      tester,
    ) async {
      final bloc = await _pumpAccounts(
        tester,
        state: AccountsLoadInProgress(activeDate: DateTime(2024, 1, 1)),
        hotkeys: _viewHotkeys,
        settle: false,
      );

      for (final key in [_dateKey, _sortKey, _filterKey]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }

      expect(find.byType(CalendarStepPicker), findsNothing);
      expect(find.byType(AccountFilterDialog), findsNothing);
      expect(_viewEvents(bloc), isEmpty);
    });
  });
}
