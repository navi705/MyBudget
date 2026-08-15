// The dashboard header's three controls, by key.
//
// The date button, the currency picker and the month/year switch each already
// carried an `actionId`, so `MultiLevelTooltip` was ready to draw a shortcut
// badge - but no `ScreenShortcuts.actions` map listed `dashboard_pick_date`,
// `dashboard_currency` or `dashboard_switch_view`, and `screen_shortcuts.dart`
// only builds a binding for an id it finds there. The ids were not unbound,
// they were unbindable, and the badge could never appear. The date button now
// advertises the screen-agnostic `pick_date` that every other list screen uses;
// the other two keep ids of their own because nothing else on the app offers
// them.
//
// Two of the three bodies lived below the `ScreenShortcuts` in
// `_DashboardScreenState` - the currency sheet inside the selector's own state,
// the period picker on the screen's - so wiring them meant hoisting the bodies
// to the top level. That hoist is the risk these tests exist for: a key running
// a second copy of the code would pass a "did something happen" check and still
// drift from the button. So each action is asserted twice, once through the key
// and once through the button.
//
// The last group covers the other half: the three ids are offered by the Hot
// Keys screen whether or not the header is on screen, and the header is only
// built by the Categories and Balance tabs, so the guard can only live at the
// call site.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';
import 'package:my_budget_client/presentation/screens/dashboard_screen.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

import '../test_app.dart';

/// One key per action, so a test can press exactly the one it means.
const _dateKey = LogicalKeyboardKey.keyT;
const _currencyKey = LogicalKeyboardKey.keyC;
const _viewKey = LogicalKeyboardKey.keyV;

final _hotkeys = <String, String>{
  'pick_date': '${_dateKey.keyId}',
  'dashboard_currency': '${_currencyKey.keyId}',
  'dashboard_switch_view': '${_viewKey.keyId}',
};

const _usd = Currency(
  name: 'US Dollar',
  code: 'USD',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

const _eur = Currency(
  name: 'Euro',
  code: 'EUR',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

/// A loaded dashboard sitting on [tab] with the period granularity at [step].
///
/// All three tabs build a `DashboardHeader`: Categories and Balance build one
/// directly, and the Calendar tab gets the same widget through
/// `DashboardCalendar`.
DashboardLoadSuccess _loaded({int tab = 1, DateStep step = DateStep.month}) =>
    DashboardLoadSuccess(
      activeTabIndex: tab,
      selectedDay: DateTime(2024, 3, 15),
      dateRangeStart: DateTime(2024, 3, 1),
      dateRangeEnd: DateTime(2024, 3, 31),
      dateStep: step,
      selectedCurrency: 'USD',
      availableCurrencies: const [_usd, _eur],
    );

/// A [DashboardBloc] that keeps what the screen dispatched.
///
/// `MockBloc.add` is a no-op that records nothing, and the view-switch
/// assertions are about which event reached the bloc.
class _RecordingDashboardBloc extends MockDashboardBloc {
  final events = <DashboardEvent>[];

  @override
  void add(DashboardEvent event) => events.add(event);
}

/// The dashboard's tab bar paints itself from the active theme, so the screen
/// does not build at all without one. Not part of `wrapWithBlocs`, which no
/// other widget test has needed it for.
class _MockThemeBloc extends MockBloc<ThemeEvent, ThemeState>
    implements ThemeBloc {}

ThemeBloc _themeBloc() {
  final bloc = _MockThemeBloc();
  whenListen(
    bloc,
    const Stream<ThemeState>.empty(),
    initialState: const ThemeState(),
  );
  return bloc;
}

/// Every event the screen sent apart from the load it fires on the way in.
List<DashboardEvent> _headerEvents(_RecordingDashboardBloc bloc) =>
    bloc.events.where((e) => e is! LoadDashboard).toList();

/// Opens the dashboard with the three header keys bound.
///
/// 1200 wide is the header's desktop branch, but either branch builds each of
/// the three controls exactly once, so a finder cannot pick the wrong copy.
///
/// The blocs go above the `MaterialApp`: both sheets this test opens are routes
/// under the app's own Navigator, siblings of `home` rather than descendants of
/// it, so providers wrapped around the screen would be invisible to them.
Future<_RecordingDashboardBloc> _pumpDashboard(
  WidgetTester tester, {
  DashboardState? state,
  Map<String, String> hotkeys = const {},
}) async {
  setSurfaceSize(tester, const Size(1200, 1000));

  final bloc = _RecordingDashboardBloc();
  whenListen(
    bloc,
    const Stream<DashboardState>.empty(),
    initialState: state ?? _loaded(),
  );

  await tester.pumpWidget(
    BlocProvider<ThemeBloc>.value(
      value: _themeBloc(),
      child: wrapWithBlocs(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DashboardScreen(),
        ),
        settingsBloc: createSettingsBloc(
          state: SettingsState(hotkeys: hotkeys),
        ),
        currencyBloc: createCurrencyBloc(),
        stylesBloc: createStylesBloc(),
        dashboardBloc: bloc,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return bloc;
}

/// The one control carrying [actionId].
///
/// Finding it by the id it advertises rather than by its icon keeps the pairing
/// honest: the tapped widget is provably the one the badge would appear on.
Finder _buttonFor(String actionId) => find.byWidgetPredicate(
  (widget) => widget is MultiLevelTooltip && widget.actionId == actionId,
);

/// The month/year switch's "year" segment, inside the control that advertises
/// the id - the tooltip's own centre falls between the two segments.
Finder _viewSegment(AppLocalizations l10n, String label) => find.descendant(
  of: _buttonFor('dashboard_switch_view'),
  matching: find.text(label),
);

void main() {
  group('dashboard: pick date', () {
    testWidgets('the hotkey opens the period picker', (tester) async {
      await _pumpDashboard(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });

    testWidgets('the button opens the same picker', (tester) async {
      await _pumpDashboard(tester);

      await tester.tap(_buttonFor('pick_date'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });
  });

  group('dashboard: currency', () {
    testWidgets('the hotkey opens the currency picker', (tester) async {
      await _pumpDashboard(tester, hotkeys: _hotkeys);
      final l10n = await loadL10n();

      await tester.sendKeyEvent(_currencyKey);
      await tester.pumpAndSettle();

      // The sheet's search field, which exists nowhere else on this screen.
      expect(find.text(l10n.dshSearchCurrency), findsOneWidget);
      // And the sheet really is the picker: every available currency is on it.
      expect(find.text('EUR'), findsOneWidget);
    });

    testWidgets('the button opens the same picker', (tester) async {
      await _pumpDashboard(tester);
      final l10n = await loadL10n();

      await tester.tap(_buttonFor('dashboard_currency'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.dshSearchCurrency), findsOneWidget);
      expect(find.text('EUR'), findsOneWidget);
    });

    testWidgets('picking from the sheet the key opened changes the currency', (
      tester,
    ) async {
      // The sheet is only half the action: what it does on a tap has to be the
      // button's body too, or the key would open a picker that picks nothing.
      final bloc = await _pumpDashboard(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_currencyKey);
      await tester.pumpAndSettle();
      await tester.tap(find.text('EUR'));
      await tester.pumpAndSettle();

      expect(_headerEvents(bloc), [const ChangeCurrency('EUR')]);
    });
  });

  group('dashboard: switch view', () {
    testWidgets('the hotkey moves month to year', (tester) async {
      final bloc = await _pumpDashboard(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_viewKey);
      await tester.pumpAndSettle();

      expect(_headerEvents(bloc), [const ChangeDateStep(DateStep.year)]);
    });

    testWidgets('the button moves it the same way', (tester) async {
      final bloc = await _pumpDashboard(tester);
      final l10n = await loadL10n();

      await tester.tap(_viewSegment(l10n, l10n.dshYearlyAbbreviation));
      await tester.pumpAndSettle();

      expect(_headerEvents(bloc), [const ChangeDateStep(DateStep.year)]);
    });

    testWidgets('the hotkey moves year back to month', (tester) async {
      // The switch has two segments, so the key has to be a toggle rather than
      // a one-way trip to year - the button in this state reads "M".
      final bloc = await _pumpDashboard(
        tester,
        state: _loaded(step: DateStep.year),
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_viewKey);
      await tester.pumpAndSettle();

      expect(_headerEvents(bloc), [const ChangeDateStep(DateStep.month)]);
    });

    testWidgets('the button moves it back the same way', (tester) async {
      final bloc = await _pumpDashboard(
        tester,
        state: _loaded(step: DateStep.year),
      );
      final l10n = await loadL10n();

      await tester.tap(_viewSegment(l10n, l10n.dshMonthlyAbbreviation));
      await tester.pumpAndSettle();

      expect(_headerEvents(bloc), [const ChangeDateStep(DateStep.month)]);
    });
  });

  group('dashboard: the header keys on the Balance tab', () {
    // The header is built by two tabs, not one, so the guard has to let both
    // through: a key live only on Categories would be stricter than the button.
    testWidgets('all three still work', (tester) async {
      final bloc = await _pumpDashboard(
        tester,
        state: _loaded(tab: 2),
        hotkeys: _hotkeys,
      );
      final l10n = await loadL10n();

      await tester.sendKeyEvent(_viewKey);
      await tester.pumpAndSettle();
      expect(_headerEvents(bloc), [const ChangeDateStep(DateStep.year)]);

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarStepPicker), findsOneWidget);
      await tester.tapAt(const Offset(600, 20)); // dismiss the sheet
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(_currencyKey);
      await tester.pumpAndSettle();
      expect(find.text(l10n.dshSearchCurrency), findsOneWidget);
    });
  });

  group('dashboard: the header keys on the Calendar tab', () {
    // Tab 0 draws `DashboardCalendar`, which builds the same `DashboardHeader`
    // with the same three callbacks - so the same three buttons, carrying the
    // same three ids, are on screen. The guard used to exclude this tab, which
    // left the badges advertising keys that did nothing.
    testWidgets('the three buttons are on screen', (tester) async {
      await _pumpDashboard(tester, state: _loaded(tab: 0));

      expect(_buttonFor('pick_date'), findsOneWidget);
      expect(_buttonFor('dashboard_currency'), findsOneWidget);
      expect(_buttonFor('dashboard_switch_view'), findsOneWidget);
    });

    testWidgets('all three keys work there too', (tester) async {
      final bloc = await _pumpDashboard(
        tester,
        state: _loaded(tab: 0),
        hotkeys: _hotkeys,
      );
      final l10n = await loadL10n();

      await tester.sendKeyEvent(_viewKey);
      await tester.pumpAndSettle();
      expect(_headerEvents(bloc), [const ChangeDateStep(DateStep.year)]);

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarStepPicker), findsOneWidget);
      await tester.tapAt(const Offset(600, 20)); // dismiss the sheet
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(_currencyKey);
      await tester.pumpAndSettle();
      expect(find.text(l10n.dshSearchCurrency), findsOneWidget);
    });
  });

  group('dashboard: the header keys before the dashboard loads', () {
    testWidgets('all three do nothing while the screen is still loading', (
      tester,
    ) async {
      // Every state other than DashboardLoadSuccess draws a spinner and no
      // header at all, so the keys have to follow the buttons off the screen.
      // `pump`, not `pumpAndSettle`: the spinner animates forever.
      final bloc = _RecordingDashboardBloc();
      whenListen(
        bloc,
        const Stream<DashboardState>.empty(),
        initialState: DashboardLoadInProgress(),
      );
      setSurfaceSize(tester, const Size(1200, 1000));
      await tester.pumpWidget(
        BlocProvider<ThemeBloc>.value(
          value: _themeBloc(),
          child: wrapWithBlocs(
            MaterialApp(
              locale: const Locale('en'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const DashboardScreen(),
            ),
            settingsBloc: createSettingsBloc(
              state: SettingsState(hotkeys: _hotkeys),
            ),
            currencyBloc: createCurrencyBloc(),
            stylesBloc: createStylesBloc(),
            dashboardBloc: bloc,
          ),
        ),
      );
      await tester.pump();
      final l10n = await loadL10n();

      for (final key in [_dateKey, _currencyKey, _viewKey]) {
        await tester.sendKeyEvent(key);
        await tester.pump();
      }

      expect(find.byType(CalendarStepPicker), findsNothing);
      expect(find.text(l10n.dshSearchCurrency), findsNothing);
      expect(_headerEvents(bloc), isEmpty);
    });
  });
}
