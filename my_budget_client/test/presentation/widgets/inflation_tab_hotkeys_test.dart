// The inflation tab's date, sort and selection controls, by key.
//
// Wired the same way as the assets tab: the bodies used to live on
// `InflationTabAppBar`, one widget below the `ScreenShortcuts` in
// inflation_tab.dart, so binding a key meant hoisting each body to a
// top-level function in inflation_tab_app_bar.dart that both the button and
// the ScreenShortcuts entry can call. A key that ran a second copy of the
// logic would pass a "did something happen" check and still drift from the
// button, so each action is asserted twice - once through the key and once
// through the button, on Equatable events.
//
// The selection actions are offered by the Hot Keys screen regardless of
// whether the selection bar is on screen, so the guard can only live at the
// call site - the last group covers that.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/widgets/inflation_tab.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

import '../test_app.dart';

/// One key per action, so a test can press exactly the one it means.
const _dateKey = LogicalKeyboardKey.keyT;
const _sortKey = LogicalKeyboardKey.keyS;
const _closeKey = LogicalKeyboardKey.keyQ;
const _allKey = LogicalKeyboardKey.keyA;
const _deleteKey = LogicalKeyboardKey.keyD;

final _hotkeys = <String, String>{
  'pick_date': '${_dateKey.keyId}',
  'sort_order': '${_sortKey.keyId}',
  'inflation_selection_close': '${_closeKey.keyId}',
  'inflation_selection_all': '${_allKey.keyId}',
  'inflation_selection_delete': '${_deleteKey.keyId}',
};

final _us = InflationRateDomain(
  country: 'US',
  preset: 1,
  percent: 3.2,
  date: DateTime(2024, 3, 1),
);

final _de = InflationRateDomain(
  country: 'DE',
  preset: 1,
  percent: 2.1,
  date: DateTime(2024, 3, 1),
);

/// An [InflationBloc] that keeps what the tab dispatched.
///
/// `MockBloc.add` is a no-op that records nothing, and every assertion here is
/// about which event reached the bloc, so the recording subclass is the whole
/// instrument.
class _RecordingInflationBloc extends MockInflationBloc {
  final events = <InflationEvent>[];

  @override
  void add(InflationEvent event) => events.add(event);
}

/// Opens the tab with the selection bar on or off.
///
/// `InflationTab` builds its bloc with `sl<InflationBloc>()`, so the
/// recording bloc has to go through the service locator; a provider around
/// the tab would be ignored.
Future<_RecordingInflationBloc> _pumpInflationTab(
  WidgetTester tester, {
  bool selectionMode = false,
  Set<InflationRateDomain> selected = const {},
  Map<String, String> hotkeys = const {},
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  final bloc = _RecordingInflationBloc();
  whenListen(
    bloc,
    const Stream<InflationState>.empty(),
    initialState: InflationState(
      status: InflationStatus.success,
      rates: [_us, _de],
      totalCount: 2,
      activeDate: DateTime(2024, 3, 1),
      selectedRates: selected,
      isSelectionModeActive: selectionMode,
    ),
  );

  if (sl.isRegistered<InflationBloc>()) sl.unregister<InflationBloc>();
  sl.registerFactory<InflationBloc>(() => bloc);
  addTearDown(() => sl.unregister<InflationBloc>());

  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const InflationTab(),
      ),
      settingsBloc: createSettingsBloc(state: SettingsState(hotkeys: hotkeys)),
      currencyBloc: createCurrencyBloc(),
      stylesBloc: createStylesBloc(),
    ),
  );
  await tester.pump();
  return bloc;
}

/// The one button carrying [actionId].
///
/// Finding the button by the id it advertises rather than by its icon keeps the
/// pairing honest: the tapped widget is provably the one the badge would appear
/// on, and the finder does not have to know which of the app bar's two layout
/// branches built it.
Finder _buttonFor(String actionId) => find.byWidgetPredicate(
  (widget) => widget is MultiLevelTooltip && widget.actionId == actionId,
);

void main() {
  group('inflation: pick date', () {
    testWidgets('the hotkey opens the calendar', (tester) async {
      await _pumpInflationTab(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });

    testWidgets('the button opens the same calendar', (tester) async {
      await _pumpInflationTab(tester);

      await tester.tap(_buttonFor('pick_date'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });
  });

  group('inflation: sort order', () {
    testWidgets('the hotkey flips the sort', (tester) async {
      final bloc = await _pumpInflationTab(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_sortKey);
      await tester.pumpAndSettle();

      // The fixture starts on the state's default, `Sort.descending`, so this
      // asserts a real flip rather than a re-assertion of what was there.
      expect(bloc.events, contains(const ChangeInflationSort(Sort.ascending)));
    });

    testWidgets('the button flips it the same way', (tester) async {
      final bloc = await _pumpInflationTab(tester);

      await tester.tap(_buttonFor('sort_order'));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(const ChangeInflationSort(Sort.ascending)));
    });
  });

  group('inflation: selection actions', () {
    testWidgets('close, select-all and delete do nothing without the bar', (
      tester,
    ) async {
      final bloc = await _pumpInflationTab(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_closeKey);
      await tester.sendKeyEvent(_allKey);
      await tester.sendKeyEvent(_deleteKey);
      await tester.pumpAndSettle();

      // Not `isEmpty`: the tab loads itself on the way in, and that event is
      // not what this is about. The three selection events are the forbidden
      // ones - off the bar they would clear a selection nobody made, fill one
      // the user cannot see, or open a delete dialog over the plain list.
      expect(bloc.events.whereType<DeselectAllInflationRates>(), isEmpty);
      expect(bloc.events.whereType<SelectAllInflationRates>(), isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('the close key leaves selection mode', (tester) async {
      final bloc = await _pumpInflationTab(
        tester,
        selectionMode: true,
        selected: {_us},
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_closeKey);
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeselectAllInflationRates()));
    });

    testWidgets('the close button does the same', (tester) async {
      final bloc = await _pumpInflationTab(
        tester,
        selectionMode: true,
        selected: {_us},
      );

      await tester.tap(_buttonFor('inflation_selection_close'));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeselectAllInflationRates()));
    });

    testWidgets('the select-all key selects the rest', (tester) async {
      final bloc = await _pumpInflationTab(
        tester,
        selectionMode: true,
        selected: {_us},
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_allKey);
      await tester.pumpAndSettle();

      expect(bloc.events, contains(SelectAllInflationRates()));
    });

    testWidgets('the select-all button does the same', (tester) async {
      final bloc = await _pumpInflationTab(
        tester,
        selectionMode: true,
        selected: {_us},
      );

      await tester.tap(_buttonFor('inflation_selection_all'));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(SelectAllInflationRates()));
    });

    testWidgets('the select-all key clears a full selection', (tester) async {
      // The button reads "deselect all" at this point, and the bloc leaves
      // selection mode on `DeselectAllInflationRates` - so the key has to
      // follow the label rather than blindly re-select what is already
      // selected.
      final bloc = await _pumpInflationTab(
        tester,
        selectionMode: true,
        selected: {_us, _de},
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_allKey);
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeselectAllInflationRates()));
      expect(bloc.events.whereType<SelectAllInflationRates>(), isEmpty);
    });

    testWidgets('the delete key opens the confirmation, which deletes', (
      tester,
    ) async {
      final bloc = await _pumpInflationTab(
        tester,
        selectionMode: true,
        selected: {_us},
        hotkeys: _hotkeys,
      );
      final l10n = await loadL10n();

      await tester.sendKeyEvent(_deleteKey);
      await tester.pumpAndSettle();
      expect(find.text(l10n.inflationDeleteConfirmTitle), findsOneWidget);

      // The dialog, not the key, is what deletes: a key that deleted outright
      // would take a destructive action nobody confirmed.
      expect(bloc.events.whereType<DeleteSelectedInflationRates>(), isEmpty);

      await tester.tap(find.text(l10n.deleteButton));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeleteSelectedInflationRates()));
    });

    testWidgets('the delete button opens the same confirmation', (
      tester,
    ) async {
      final bloc = await _pumpInflationTab(
        tester,
        selectionMode: true,
        selected: {_us},
      );
      final l10n = await loadL10n();

      await tester.tap(_buttonFor('inflation_selection_delete'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.inflationDeleteConfirmTitle), findsOneWidget);

      await tester.tap(find.text(l10n.deleteButton));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeleteSelectedInflationRates()));
    });

    testWidgets('the delete key stays quiet at zero selection', (tester) async {
      // The button is hidden here, so the key has to be too - otherwise it
      // opens a confirmation for deleting nothing.
      await _pumpInflationTab(tester, selectionMode: true, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_deleteKey);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
