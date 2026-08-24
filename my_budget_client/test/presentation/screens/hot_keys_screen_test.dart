// Three things the Hot Keys screen told the user that were not true.
//
// The recorder committed on the key-up of the first non-modifier key while
// modifiers were dropped from the set as they were released, so lifting Ctrl a
// moment before the letter recorded a *bare letter* - and closed at once, with
// no confirmation step, so the user found out only when it started firing while
// they typed. The conflict warning named the clashing action by its raw id, a
// string that appears nowhere in the interface. And Back was listed as bindable
// with no default at all, showing "None" while Escape demonstrably closed every
// screen.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/screens/hot_keys_screen.dart';

import '../test_app.dart';

/// Records what the recorder dispatched.
///
/// `MockBloc` stubs `add` into a no-op, and what the dialog stores is the whole
/// question here.
class _RecordingSettingsBloc extends MockSettingsBloc {
  final events = <SettingsEvent>[];

  @override
  void add(SettingsEvent event) => events.add(event);
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  _FakeSettingsRepository(this.settingsStream);

  final Stream<List<Settings>> settingsStream;

  @override
  Stream<List<Settings>> watchAllSettings() => settingsStream;
}

class _FakeInflationRepository extends Fake implements InflationRepository {
  _FakeInflationRepository(this.inflationStream);

  final Stream<List<InflationRateDomain>> inflationStream;

  @override
  Stream<List<InflationRateDomain>> watchInflationRatesFiltered({
    required int limit,
    required int offset,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? countries,
    List<int>? presets,
    bool sortAscending = false,
  }) => inflationStream;

  @override
  Future<List<String>> getAvailableCountries() async => const [];
}

class _FakeInflationApiService extends Fake implements InflationApiService {}

final _ctrlA = HotKeyUtils.serializeKeys({
  LogicalKeyboardKey.controlLeft,
  LogicalKeyboardKey.keyA,
});

void main() {
  group('the recorder', () {
    late _RecordingSettingsBloc settingsBloc;

    setUp(() => settingsBloc = _RecordingSettingsBloc());

    /// Opens the recorder the way a row on the screen opens it.
    Future<AppLocalizations> openRecorder(
      WidgetTester tester, {
      Map<String, String> hotkeys = const {},
      String actionId = 'add_action',
    }) async {
      whenListen(
        settingsBloc,
        const Stream<SettingsState>.empty(),
        initialState: SettingsState(hotkeys: hotkeys),
      );

      await pumpAppWidget(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => HotKeyRecorderDialog(
                actionId: actionId,
                actionLabel: 'Add',
                currentKey: hotkeys[actionId] ?? '',
                allHotkeys: hotkeys,
                actionLabels: const {'dashboard': 'Overview screen'},
              ),
            ),
            child: const Text('open'),
          ),
        ),
        aboveApp: (app) => wrapWithBlocs(app, settingsBloc: settingsBloc),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return loadL10n();
    }

    testWidgets('records the combination even when the modifier is released '
        'first', (tester) async {
      await openRecorder(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      // The order that used to lose Ctrl: the modifier comes up a moment
      // before the letter, which is what fingers actually do.
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle();

      final event = settingsBloc.events.single;
      expect(event, isA<UpdateHotkey>());
      expect((event as UpdateHotkey).keySetString, _ctrlA);
      expect(
        find.byType(HotKeyRecorderDialog),
        findsNothing,
        reason: 'recording ends by closing the dialog',
      );
    });

    testWidgets('records the plain key when no modifier was ever held', (
      tester,
    ) async {
      await openRecorder(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle();

      expect(
        (settingsBloc.events.single as UpdateHotkey).keySetString,
        HotKeyUtils.serializeKeys({LogicalKeyboardKey.keyA}),
      );
    });

    testWidgets('a modifier held alone is not a shortcut', (tester) async {
      await openRecorder(tester);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(settingsBloc.events, isEmpty);
      expect(find.byType(HotKeyRecorderDialog), findsOneWidget);
    });

    testWidgets('names the action a combination is already taken by', (
      tester,
    ) async {
      final l10n = await openRecorder(tester, hotkeys: {'dashboard': _ctrlA});

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.pump();

      // Held, not released: the warning is what the user reads before deciding
      // whether to let go.
      expect(
        find.textContaining(l10n.usedByLabel('Overview screen')),
        findsOneWidget,
      );
      expect(
        find.textContaining('dashboard'),
        findsNothing,
        reason: 'the raw action id is not a name the user has ever seen',
      );
    });
  });

  group('hotkey defaults', () {
    test('Back is bound to Escape, which is what it has always done', () async {
      final settingsController = StreamController<List<Settings>>.broadcast();
      final inflationController =
          StreamController<List<InflationRateDomain>>.broadcast();

      final bloc = SettingsBloc(
        settingsRepository: _FakeSettingsRepository(settingsController.stream),
        inflationRepository: _FakeInflationRepository(
          inflationController.stream,
        ),
        inflationApiService: _FakeInflationApiService(),
      );

      // Loading awaits the device name over device_info_plus's channel BEFORE
      // it subscribes to the settings stream, and that answer lands on the
      // real event loop. A fixed `pumpEventQueue` was a bet on it arriving in
      // time; on a loaded machine it lost, the broadcast controller below then
      // dropped the one event it was given for want of a listener, and the
      // bloc sat on its initial state forever. Both halves wait for the thing
      // they need instead: the subscription, then the emission.
      final loaded = bloc.stream.firstWhere((s) => s.hotkeys.isNotEmpty);

      bloc.add(LoadSettings());
      while (!settingsController.hasListener) {
        await pumpEventQueue();
      }
      // Nothing stored: the defaults are what a fresh install reads.
      settingsController.add(const []);

      final state = await loaded.timeout(const Duration(seconds: 10));

      expect(
        state.hotkeys['back'],
        HotKeyUtils.serializeKeys({LogicalKeyboardKey.escape}),
        reason:
            'EscapeBackHandler falls back to Escape, so listing Back as '
            'unbound told the user a shortcut they use does not exist',
      );

      await bloc.close();
      await settingsController.close();
      await inflationController.close();
    });
  });
}
