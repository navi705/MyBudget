// The API management screen used to render a dozen strings in English no
// matter what language the user had picked, because they were written straight
// into the widget tree. These tests pump it under a locale that is *not* the
// source language, so a string that goes back to being hard-coded shows up as
// English text where a Russian one is expected.
//
// The screen resolves its bloc through GetIt rather than through a provider,
// so the mock has to be registered there; everything else it needs comes from
// `test_app.dart`.
import 'dart:convert';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/api_setting.dart';
import 'package:my_budget_client/domain/entities/custom_data_source.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_bloc.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_event.dart';
import 'package:my_budget_client/presentation/blocs/api_settings/api_settings_state.dart';
import 'package:my_budget_client/presentation/screens/api_settings_screen.dart';

import '../test_app.dart';

class MockApiSettingsBloc extends MockBloc<ApiSettingsEvent, ApiSettingsState>
    implements ApiSettingsBloc {}

const Locale _locale = Locale('ru');
final DateTime _lastFetch = DateTime(2026, 2, 3, 14, 5);

/// The screen with [state] pinned, pumped in [_locale]; returns that locale's
/// strings so the expectations never hard-code a translation.
Future<AppLocalizations> _pumpApiSettings(
  WidgetTester tester, {
  required ApiSettingsState state,
  Stream<ApiSettingsState>? stream,
}) async {
  final bloc = MockApiSettingsBloc();
  whenListen(
    bloc,
    stream ?? const Stream<ApiSettingsState>.empty(),
    initialState: state,
  );
  GetIt.I.registerFactory<ApiSettingsBloc>(() => bloc);

  await pumpAppWidget(
    tester,
    const ApiSettingsScreen(),
    locale: _locale,
    wrapInScaffold: false,
    surfaceSize: const Size(1000, 1600),
    // The screen's own EscapeBackHandler reads SettingsBloc.
    aboveApp: (app) => wrapWithBlocs(app, settingsBloc: createSettingsBloc()),
  );
  await tester.pumpAndSettle();
  return loadL10n(_locale);
}

ApiSettingsLoadSuccess _loaded({
  bool startupSyncEnabled = true,
  List<CustomDataSourceDomain> customDataSources = const [],
  Map<String, bool> testResults = const {},
  String? lastError,
}) => ApiSettingsLoadSuccess(
  apiSettings: [
    ApiSettingDomain(id: 'exchange_rates', lastFetchAt: _lastFetch),
  ],
  customDataSources: customDataSources,
  testResults: testResults,
  startupSyncEnabled: startupSyncEnabled,
  lastError: lastError,
);

const CustomDataSourceDomain _source = CustomDataSourceDomain(
  id: 'src-1',
  name: 'Home NAS',
  url: 'http://192.168.1.10:8080',
  dataType: ApiDataType.exchange,
);

void main() {
  tearDown(GetIt.I.reset);

  group('ApiSettingsScreen strings follow the locale', () {
    testWidgets('the section titles and the last-fetch line are translated', (
      tester,
    ) async {
      final l10n = await _pumpApiSettings(tester, state: _loaded());

      expect(find.text(l10n.apiCategoriesSection), findsOneWidget);
      expect(find.text(l10n.manualUtilitiesSection), findsOneWidget);
      // The timestamp is a placeholder, not a concatenation: the label and the
      // colon belong to the translation - and the date inside it follows the
      // locale too. It used to be a hardcoded `yyyy-MM-dd HH:mm`, which is the
      // one date format no reader of this screen writes by hand.
      final stamp =
          '${DateFormat.yMd('ru').format(_lastFetch)} '
          '${DateFormat.Hm('ru').format(_lastFetch)}';
      expect(stamp, '03.02.2026 14:05');
      expect(find.text(l10n.apiLastFetchLabel(stamp)), findsOneWidget);
      expect(
        find.textContaining('2026-02-03'),
        findsNothing,
        reason: 'the ISO form is the machine one, not this one',
      );
      expect(find.text('API Categories'), findsNothing);
      expect(find.text('Manual Utilities'), findsNothing);
    });

    testWidgets('an expanded API card translates its custom-source block', (
      tester,
    ) async {
      final l10n = await _pumpApiSettings(tester, state: _loaded());

      await tester.tap(find.text(l10n.apiTitleExchangeRates));
      await tester.pumpAndSettle();

      expect(find.text(l10n.individualCustomSourcesTitle), findsOneWidget);
      expect(find.text(l10n.noCustomSourcesAdded), findsOneWidget);
      expect(find.text('Individual Custom Sources'), findsNothing);
      expect(find.text('No custom sources added.'), findsNothing);
    });

    testWidgets('the switches explain themselves in the active locale when '
        'global sync is off', (tester) async {
      final l10n = await _pumpApiSettings(
        tester,
        state: _loaded(startupSyncEnabled: false),
      );

      await tester.tap(find.text(l10n.apiTitleExchangeRates));
      await tester.pumpAndSettle();

      expect(find.text(l10n.disabledByGlobalSync), findsWidgets);
      expect(find.text('Disabled by Global Sync'), findsNothing);
    });

    testWidgets('a tested custom source reports its result translated', (
      tester,
    ) async {
      final l10n = await _pumpApiSettings(
        tester,
        state: _loaded(
          customDataSources: const [_source],
          testResults: const {'http://192.168.1.10:8080': true},
        ),
      );

      await tester.tap(find.text(l10n.apiTitleExchangeRates));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_source.name));
      await tester.pumpAndSettle();

      expect(find.text(l10n.connectionOk), findsOneWidget);
      expect(find.text(l10n.testConnectionButton), findsOneWidget);
      expect(find.text('Connection OK'), findsNothing);
      expect(find.text('Test Connection'), findsNothing);
    });

    testWidgets('the manual Steam utility translates its game picker', (
      tester,
    ) async {
      final l10n = await _pumpApiSettings(tester, state: _loaded());

      await tester.tap(find.text(l10n.manualSteamInventoryTitle));
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectGameHint), findsOneWidget);
      expect(find.text(l10n.fetchValueButton), findsOneWidget);
      expect(find.text('Select Game'), findsNothing);
      expect(find.text('Fetch Value'), findsNothing);
    });

    testWidgets('the add-source dialog translates its example name', (
      tester,
    ) async {
      final l10n = await _pumpApiSettings(tester, state: _loaded());

      await tester.tap(find.text(l10n.apiTitleExchangeRates));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.addCustomSourceTitle));
      await tester.pumpAndSettle();

      expect(find.text(l10n.customSourceNameHint), findsOneWidget);
      expect(find.text('My Home Server'), findsNothing);
    });

    testWidgets('a failed operation reports the error through a placeholder', (
      tester,
    ) async {
      const message = 'connection refused';
      final l10n = await _pumpApiSettings(
        tester,
        state: _loaded(),
        stream: Stream<ApiSettingsState>.value(_loaded(lastError: message)),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.apiErrorLabel(message)), findsOneWidget);
      expect(find.text('Error: $message'), findsNothing);
    });
  });

  group('the keys this screen uses ship in every locale', () {
    // Every key the screen now reads. A key that exists only in app_en.arb
    // still compiles - `flutter gen-l10n` falls back to English - so the check
    // has to be against the .arb files themselves as well as the delegates.
    final readers = <String, String Function(AppLocalizations)>{
      'apiErrorLabel': (l) => l.apiErrorLabel('x'),
      'apiLastFetchLabel': (l) => l.apiLastFetchLabel('x'),
      'apiCategoriesSection': (l) => l.apiCategoriesSection,
      'manualUtilitiesSection': (l) => l.manualUtilitiesSection,
      'individualCustomSourcesTitle': (l) => l.individualCustomSourcesTitle,
      'noCustomSourcesAdded': (l) => l.noCustomSourcesAdded,
      'disabledByGlobalSync': (l) => l.disabledByGlobalSync,
      'steamIdHint': (l) => l.steamIdHint,
      'selectGameHint': (l) => l.selectGameHint,
      'fetchValueButton': (l) => l.fetchValueButton,
      'connectionOk': (l) => l.connectionOk,
      'connectionFailed': (l) => l.connectionFailed,
      'testConnectionButton': (l) => l.testConnectionButton,
      'customSourceNameHint': (l) => l.customSourceNameHint,
    };

    test('no .arb file is missing one of them', () {
      for (final locale in AppLocalizations.supportedLocales) {
        final file = File('lib/l10n/app_${locale.languageCode}.arb');
        expect(
          file.existsSync(),
          isTrue,
          reason: '${file.path} is missing for a supported locale',
        );
        final arb = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        for (final key in readers.keys) {
          expect(
            arb[key],
            isA<String>().having((s) => s.trim(), 'text', isNotEmpty),
            reason: '$key is missing from ${file.path}',
          );
        }
      }
    });

    test('every locale resolves them to a non-empty string', () async {
      for (final locale in AppLocalizations.supportedLocales) {
        final l10n = await AppLocalizations.delegate.load(locale);
        for (final entry in readers.entries) {
          expect(
            entry.value(l10n).trim(),
            isNotEmpty,
            reason: '${entry.key} is empty in $locale',
          );
        }
      }
    });
  });
}
