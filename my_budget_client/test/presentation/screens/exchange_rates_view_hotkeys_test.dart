// The date, sort and filter controls of the exchange rates app bar, by key.
//
// All three carried an `actionId`, so `MultiLevelTooltip` was ready to draw a
// shortcut badge on them, but the Hot Keys settings screen listed none of the
// three and no `ScreenShortcuts` map mentioned them. `screen_shortcuts.dart`
// only builds a binding for ids present in its `actions` map, so those ids
// were not unbound - they were unbindable, and the badge could never appear.
//
// Their bodies lived on `_ExchangeRatesDateAppBar`, two classes below the
// `ScreenShortcuts`, so wiring them meant hoisting the bodies to the top level
// of the file. That hoist is the risk these tests exist for: a key that runs a
// second copy of the code would pass a "did something happen" check and still
// drift from the button. So every one of the three is asserted twice, once
// through the key and once through the button, on Equatable events - "the
// same" is exact rather than approximate.
//
// The last group covers the other half of the change: the two selection
// actions that fired unguarded. The Hot Keys screen offers them whether or not
// the selection bar is on screen, so the guard can only live at the call site.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/exchange_rates/exchange_rates_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/screens/exchange_rates_screen.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

import '../test_app.dart';

/// One key per action, so a test can press exactly the one it means.
const _dateKey = LogicalKeyboardKey.keyT;
const _sortKey = LogicalKeyboardKey.keyS;
const _filterKey = LogicalKeyboardKey.keyF;
const _closeKey = LogicalKeyboardKey.keyQ;
const _allKey = LogicalKeyboardKey.keyA;

final _hotkeys = <String, String>{
  'pick_date': '${_dateKey.keyId}',
  'sort_order': '${_sortKey.keyId}',
  'filter_action': '${_filterKey.keyId}',
  'exchange_rates_selection_close': '${_closeKey.keyId}',
  'exchange_rates_selection_all': '${_allKey.keyId}',
};

/// An [ExchangeRatesBloc] that keeps what the screen dispatched.
///
/// `MockBloc.add` is a no-op that records nothing, and every assertion here is
/// about which event reached the bloc, so the recording subclass is the whole
/// instrument.
class _RecordingExchangeRatesBloc extends MockExchangeRatesBloc {
  final events = <ExchangeRatesEvent>[];

  @override
  void add(ExchangeRatesEvent event) => events.add(event);
}

/// The filter dialog asks for the preset list as soon as it opens.
///
/// It swallows a failure and renders anyway, so a bare `Fake` would still let
/// the dialog appear - but then the test would be passing for the wrong
/// reason, and would keep passing if the dialog started depending on the call.
class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<int>> getAvailablePresets() async => const [];
}

/// Opens the screen with the selection bar on or off.
///
/// The screen builds its bloc with `sl<ExchangeRatesBloc>()`, so the recording
/// bloc has to go through the service locator; a provider around the screen
/// would be ignored. `CurrencyRepository`, in contrast, is read from the
/// context - in production `AppProviders` supplies it above the app, which is
/// also where the filter dialog can see it from.
Future<_RecordingExchangeRatesBloc> _pumpExchangeRates(
  WidgetTester tester, {
  bool selectionMode = false,
  Map<String, String> hotkeys = const {},
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  final bloc = _RecordingExchangeRatesBloc();
  whenListen(
    bloc,
    const Stream<ExchangeRatesState>.empty(),
    initialState: ExchangeRatesState(
      status: ExchangeRatesStatus.success,
      activeDate: DateTime(2024, 3, 15),
      isSelectionModeActive: selectionMode,
    ),
  );

  if (sl.isRegistered<ExchangeRatesBloc>()) {
    sl.unregister<ExchangeRatesBloc>();
  }
  sl.registerFactory<ExchangeRatesBloc>(() => bloc);
  addTearDown(() => sl.unregister<ExchangeRatesBloc>());

  await tester.pumpWidget(
    RepositoryProvider<CurrencyRepository>.value(
      value: _FakeCurrencyRepository(),
      child: wrapWithBlocs(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ExchangeRatesScreen(),
        ),
        settingsBloc: createSettingsBloc(
          state: SettingsState(hotkeys: hotkeys),
        ),
        currencyBloc: createCurrencyBloc(),
        stylesBloc: createStylesBloc(),
      ),
    ),
  );
  await tester.pump();
  return bloc;
}

/// The one button carrying [actionId].
///
/// Finding the button by the id it advertises rather than by its icon keeps
/// the pairing honest: the tapped widget is provably the same one the badge
/// would appear on, and the finder does not have to know which of the app
/// bar's two layout branches built it.
Finder _buttonFor(String actionId) => find.byWidgetPredicate(
  (widget) => widget is MultiLevelTooltip && widget.actionId == actionId,
);

void main() {
  group('exchange rates: pick date', () {
    testWidgets('the hotkey opens the calendar', (tester) async {
      await _pumpExchangeRates(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });

    testWidgets('the button opens the same calendar', (tester) async {
      await _pumpExchangeRates(tester);

      await tester.tap(_buttonFor('pick_date'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });
  });

  group('exchange rates: sort order', () {
    testWidgets('the hotkey flips the sort', (tester) async {
      final bloc = await _pumpExchangeRates(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_sortKey);
      await tester.pumpAndSettle();

      // The fixture starts on the state's default, `Sort.descending`, so the
      // one flip this asserts is a real toggle rather than a re-assertion of
      // whatever the state already held.
      expect(
        bloc.events,
        contains(const ChangeExchangeRatesSort(Sort.ascending)),
      );
    });

    testWidgets('the button flips it the same way', (tester) async {
      final bloc = await _pumpExchangeRates(tester);

      await tester.tap(_buttonFor('sort_order'));
      await tester.pumpAndSettle();

      expect(
        bloc.events,
        contains(const ChangeExchangeRatesSort(Sort.ascending)),
      );
    });
  });

  group('exchange rates: filter', () {
    testWidgets('the hotkey opens the filter dialog', (tester) async {
      await _pumpExchangeRates(tester, hotkeys: _hotkeys);
      final l10n = await loadL10n();

      await tester.sendKeyEvent(_filterKey);
      await tester.pumpAndSettle();

      expect(find.text(l10n.exchFilterExchangeRates), findsOneWidget);
    });

    testWidgets('the button opens the same dialog', (tester) async {
      await _pumpExchangeRates(tester);
      final l10n = await loadL10n();

      await tester.tap(_buttonFor('filter_action'));
      await tester.pumpAndSettle();

      expect(find.text(l10n.exchFilterExchangeRates), findsOneWidget);
    });
  });

  group('exchange rates: selection actions off selection mode', () {
    testWidgets('close and select-all do nothing without the bar', (
      tester,
    ) async {
      final bloc = await _pumpExchangeRates(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_closeKey);
      await tester.sendKeyEvent(_allKey);
      await tester.pumpAndSettle();

      // Not `isEmpty`: the screen loads itself on the way in, and that event
      // is not what this is about. Only the two selection events are
      // forbidden - one would toggle a mode nobody is in, the other would fill
      // a selection with no bar to show or clear it.
      expect(bloc.events.whereType<ToggleSelectionMode>(), isEmpty);
      expect(bloc.events.whereType<SelectAllExchangeRates>(), isEmpty);
    });

    testWidgets('both fire once the bar is up', (tester) async {
      final bloc = await _pumpExchangeRates(
        tester,
        selectionMode: true,
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_closeKey);
      await tester.sendKeyEvent(_allKey);
      await tester.pumpAndSettle();

      expect(bloc.events, contains(const ToggleSelectionMode(false)));
      expect(bloc.events, contains(const SelectAllExchangeRates()));
    });
  });
}
