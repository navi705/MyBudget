// The assets tab's date, sort and selection controls, by key.
//
// Every one of them already carried an `actionId`, so `MultiLevelTooltip` was
// ready to draw a shortcut badge - but the app bar's `ScreenShortcuts` never
// listed the ids, and `screen_shortcuts.dart` only builds a binding for ids
// present in its `actions` map. The ids were not unbound, they were
// unbindable, and the badge could never appear.
//
// The bodies lived on `AssetTabAppBar`, one widget below the `ScreenShortcuts`
// in asset_tab.dart, so wiring them meant hoisting the bodies to the top level
// of asset_tab_app_bar.dart. That hoist is the risk these tests exist for: a
// key running a second copy of the code would pass a "did something happen"
// check and still drift from the button. So each action is asserted twice,
// once through the key and once through the button, on Equatable events.
//
// The last group covers the other half: the selection actions are offered by
// the Hot Keys screen whether or not the selection bar is on screen, so the
// guard can only live at the call site.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/widgets/asset_tab.dart';
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
  'asset_selection_close': '${_closeKey.keyId}',
  'asset_selection_all': '${_allKey.keyId}',
  'asset_selection_delete': '${_deleteKey.keyId}',
};

final _gold = AssetDataDomain(
  id: 'a1',
  assetId: 'XAU',
  name: 'Gold',
  date: DateTime(2024, 3, 15),
  value: 100,
  source: 'manual',
);

final _silver = AssetDataDomain(
  id: 'a2',
  assetId: 'XAG',
  name: 'Silver',
  date: DateTime(2024, 3, 15),
  value: 20,
  source: 'manual',
);

/// An [AssetBloc] that keeps what the tab dispatched.
///
/// `MockBloc.add` is a no-op that records nothing, and every assertion here is
/// about which event reached the bloc, so the recording subclass is the whole
/// instrument.
class _RecordingAssetBloc extends MockAssetBloc {
  final events = <AssetEvent>[];

  @override
  void add(AssetEvent event) => events.add(event);
}

/// Opens the tab with the selection bar on or off.
///
/// `AssetTab` builds its bloc with `sl<AssetBloc>()`, so the recording bloc has
/// to go through the service locator; a provider around the tab would be
/// ignored.
Future<_RecordingAssetBloc> _pumpAssetTab(
  WidgetTester tester, {
  bool selectionMode = false,
  Set<AssetDataDomain> selected = const {},
  Map<String, String> hotkeys = const {},
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  final bloc = _RecordingAssetBloc();
  whenListen(
    bloc,
    const Stream<AssetState>.empty(),
    initialState: AssetState(
      status: AssetStatus.success,
      assetData: [_gold, _silver],
      totalCount: 2,
      activeDate: DateTime(2024, 3, 15),
      selectedAssets: selected,
      isSelectionModeActive: selectionMode,
    ),
  );

  if (sl.isRegistered<AssetBloc>()) sl.unregister<AssetBloc>();
  sl.registerFactory<AssetBloc>(() => bloc);
  addTearDown(() => sl.unregister<AssetBloc>());

  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AssetTab(),
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
  group('assets: pick date', () {
    testWidgets('the hotkey opens the calendar', (tester) async {
      await _pumpAssetTab(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_dateKey);
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });

    testWidgets('the button opens the same calendar', (tester) async {
      await _pumpAssetTab(tester);

      await tester.tap(_buttonFor('pick_date'));
      await tester.pumpAndSettle();

      expect(find.byType(CalendarStepPicker), findsOneWidget);
    });
  });

  group('assets: sort order', () {
    testWidgets('the hotkey flips the sort', (tester) async {
      final bloc = await _pumpAssetTab(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_sortKey);
      await tester.pumpAndSettle();

      // The fixture starts on the state's default, `Sort.descending`, so this
      // asserts a real flip rather than a re-assertion of what was there.
      expect(bloc.events, contains(const ChangeAssetSort(Sort.ascending)));
    });

    testWidgets('the button flips it the same way', (tester) async {
      final bloc = await _pumpAssetTab(tester);

      await tester.tap(_buttonFor('sort_order'));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(const ChangeAssetSort(Sort.ascending)));
    });
  });

  group('assets: selection actions', () {
    testWidgets('close, select-all and delete do nothing without the bar', (
      tester,
    ) async {
      final bloc = await _pumpAssetTab(tester, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_closeKey);
      await tester.sendKeyEvent(_allKey);
      await tester.sendKeyEvent(_deleteKey);
      await tester.pumpAndSettle();

      // Not `isEmpty`: the tab loads itself on the way in, and that event is
      // not what this is about. The three selection events are the forbidden
      // ones - off the bar they would clear a selection nobody made, fill one
      // the user cannot see, or open a delete dialog over the plain list.
      expect(bloc.events.whereType<DeselectAllAssets>(), isEmpty);
      expect(bloc.events.whereType<SelectAllAssets>(), isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('the close key leaves selection mode', (tester) async {
      final bloc = await _pumpAssetTab(
        tester,
        selectionMode: true,
        selected: {_gold},
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_closeKey);
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeselectAllAssets()));
    });

    testWidgets('the close button does the same', (tester) async {
      final bloc = await _pumpAssetTab(
        tester,
        selectionMode: true,
        selected: {_gold},
      );

      await tester.tap(_buttonFor('asset_selection_close'));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeselectAllAssets()));
    });

    testWidgets('the select-all key selects the rest', (tester) async {
      final bloc = await _pumpAssetTab(
        tester,
        selectionMode: true,
        selected: {_gold},
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_allKey);
      await tester.pumpAndSettle();

      expect(bloc.events, contains(SelectAllAssets()));
    });

    testWidgets('the select-all button does the same', (tester) async {
      final bloc = await _pumpAssetTab(
        tester,
        selectionMode: true,
        selected: {_gold},
      );

      await tester.tap(_buttonFor('asset_selection_all'));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(SelectAllAssets()));
    });

    testWidgets('the select-all key clears a full selection', (tester) async {
      // The button reads "deselect all" at this point, and the bloc leaves
      // selection mode on `DeselectAllAssets` - so the key has to follow the
      // label rather than blindly re-select what is already selected.
      final bloc = await _pumpAssetTab(
        tester,
        selectionMode: true,
        selected: {_gold, _silver},
        hotkeys: _hotkeys,
      );

      await tester.sendKeyEvent(_allKey);
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeselectAllAssets()));
      expect(bloc.events.whereType<SelectAllAssets>(), isEmpty);
    });

    testWidgets('the delete key opens the confirmation, which deletes', (
      tester,
    ) async {
      final bloc = await _pumpAssetTab(
        tester,
        selectionMode: true,
        selected: {_gold},
        hotkeys: _hotkeys,
      );
      final l10n = await loadL10n();

      await tester.sendKeyEvent(_deleteKey);
      await tester.pumpAndSettle();
      expect(find.text(l10n.assetDeleteConfirmTitle), findsOneWidget);

      // The dialog, not the key, is what deletes: a key that deleted outright
      // would take a destructive action nobody confirmed.
      expect(bloc.events.whereType<DeleteSelectedAssets>(), isEmpty);

      await tester.tap(find.text(l10n.deleteButton));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeleteSelectedAssets()));
    });

    testWidgets('the delete button opens the same confirmation', (
      tester,
    ) async {
      final bloc = await _pumpAssetTab(
        tester,
        selectionMode: true,
        selected: {_gold},
      );
      final l10n = await loadL10n();

      await tester.tap(_buttonFor('asset_selection_delete'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.assetDeleteConfirmTitle), findsOneWidget);

      await tester.tap(find.text(l10n.deleteButton));
      await tester.pumpAndSettle();

      expect(bloc.events, contains(DeleteSelectedAssets()));
    });

    testWidgets('the delete key stays quiet at zero selection', (tester) async {
      // The button is hidden here, so the key has to be too - otherwise it
      // opens a confirmation for deleting nothing.
      await _pumpAssetTab(tester, selectionMode: true, hotkeys: _hotkeys);

      await tester.sendKeyEvent(_deleteKey);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
