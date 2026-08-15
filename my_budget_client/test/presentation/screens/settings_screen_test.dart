// Settings is where the platform gating in this app concentrates: five of its
// rows are conditional, and two of them are the *only* entry point to a feature
// when the shell is in bottom-bar mode. A wrong gate here does not look like a
// bug — the screen renders fine, the row is simply not there.
//
// Every gate is therefore asserted on both sides. `debugAppPlatformOverride`
// drives the OS-based ones; the surface width drives the layout-based ones.
import 'package:drift/drift.dart' show Batch;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/data/repositories/db_repository.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/settings_screen.dart';

import '../test_app.dart';

// Tall on purpose: the settings list is longer than a phone viewport and a
// sliver list only builds what is near the viewport, so a short surface would
// make "row is absent" and "row is merely below the fold" look identical.
const Size _narrow = Size(400, 2400);
const Size _wide = Size(1200, 2400);

/// The hot keys row does not gate on [debugAppPlatformOverride] the way the
/// SMS and sync rows do - it gates on `Theme.of(context).platform`, because
/// `AppPlatform` reads dart:io and answers false to everything on web,
/// which would offer keyboard shortcuts to a phone browser (see
/// settings_hotkeys_row_test.dart, which pins that choice directly). Both
/// levers still have to move together here, or a test that only sets the
/// override leaves the theme's platform at whatever the harness defaults to,
/// independent of the scenario the test claims to be driving.
TargetPlatform? _themePlatformFor(AppPlatformKind? kind) => switch (kind) {
  AppPlatformKind.android => TargetPlatform.android,
  AppPlatformKind.iOS => TargetPlatform.iOS,
  AppPlatformKind.linux => TargetPlatform.linux,
  AppPlatformKind.macOS => TargetPlatform.macOS,
  AppPlatformKind.windows => TargetPlatform.windows,
  AppPlatformKind.fuchsia => TargetPlatform.fuchsia,
  // TargetPlatform has no "web" member: a real web build derives
  // defaultTargetPlatform from the browser's user agent instead, and a
  // desktop browser is what this override is meant to stand in for here.
  AppPlatformKind.web => TargetPlatform.linux,
  null => null,
};

/// Pumps SettingsScreen with the blocs it reads while building.
Future<AppLocalizations> _pumpSettings(
  WidgetTester tester, {
  required Size surfaceSize,
  Locale locale = const Locale('en'),
}) async {
  await pumpAppWidget(
    tester,
    const SettingsScreen(),
    locale: locale,
    surfaceSize: surfaceSize,
    wrapInScaffold: false,
    platform: _themePlatformFor(debugAppPlatformOverride),
    aboveApp: (app) => wrapWithBlocs(
      app,
      settingsBloc: createSettingsBloc(),
      currencyBloc: createCurrencyBloc(),
    ),
  );
  await tester.pump();
  return loadL10n(locale);
}

Finder _row(String title) => find.widgetWithText(ListTile, title);

void main() {
  tearDown(() => debugAppPlatformOverride = null);

  group('SettingsScreen Data row', () {
    // The Data screen (/exchange-rates) has a rail destination only on wide
    // layouts. On narrow ones this row is the whole entry point, so it must
    // follow the same width MainScreen used to drop the destination — not the
    // host OS. Gating it on Android/iOS lost the feature on web (where every
    // AppPlatform flag is false) and in any desktop window under 600dp.
    testWidgets('is offered on a narrow layout on a desktop OS', (
      tester,
    ) async {
      debugAppPlatformOverride = AppPlatformKind.windows;

      final l10n = await _pumpSettings(tester, surfaceSize: _narrow);

      expect(_row(l10n.dataLabel), findsOneWidget);
    });

    testWidgets('is offered on a narrow layout on web', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.web;

      final l10n = await _pumpSettings(tester, surfaceSize: _narrow);

      expect(_row(l10n.dataLabel), findsOneWidget);
    });

    testWidgets('is offered on a narrow layout on Android', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.android;

      final l10n = await _pumpSettings(tester, surfaceSize: _narrow);

      expect(_row(l10n.dataLabel), findsOneWidget);
    });

    testWidgets('is hidden on a wide layout, where the rail carries it', (
      tester,
    ) async {
      debugAppPlatformOverride = AppPlatformKind.android;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.dataLabel), findsNothing);
    });

    testWidgets('opens the exchange rates route', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.windows;
      final l10n = await loadL10n();

      final router = GoRouter(
        initialLocation: AppRoutes.settings,
        routes: [
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, _) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.exchangeRates,
            builder: (_, _) => const Text('body:exchange-rates'),
          ),
        ],
      );

      await pumpRouterApp(
        tester,
        router,
        surfaceSize: _narrow,
        currencyBloc: createCurrencyBloc(),
      );
      await tester.tap(_row(l10n.dataLabel));
      await tester.pumpAndSettle();

      expect(find.text('body:exchange-rates'), findsOneWidget);
    });
  });

  group('SettingsScreen debug row', () {
    // Same shape as the Data row: MainScreen only puts Debug in the rail.
    testWidgets('is offered on a narrow layout', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.windows;

      final l10n = await _pumpSettings(tester, surfaceSize: _narrow);

      expect(_row(l10n.debugMenuLabel), findsOneWidget);
    });

    testWidgets('is hidden on a wide layout', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.windows;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.debugMenuLabel), findsNothing);
    });
  });

  group('SettingsScreen SMS row', () {
    // Correct as written: the reader plugin is Android-only, and SmsSettings
    // itself shows a "not supported" notice everywhere else.
    testWidgets('is offered on Android', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.android;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.smsImportLabel), findsOneWidget);
    });

    testWidgets('is hidden on iOS', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.iOS;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.smsImportLabel), findsNothing);
    });

    testWidgets('is hidden on desktop', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.linux;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.smsImportLabel), findsNothing);
    });
  });

  group('SettingsScreen hot keys row', () {
    // Correct as written: hot keys need a physical keyboard, and the screen
    // behind it edits desktop shortcuts.
    testWidgets('is offered on desktop', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.macOS;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.hotKeysLabel), findsOneWidget);
    });

    testWidgets('is offered on web', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.web;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.hotKeysLabel), findsOneWidget);
    });

    testWidgets('is hidden on Android', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.android;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.hotKeysLabel), findsNothing);
    });

    testWidgets('is hidden on iOS', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.iOS;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.hotKeysLabel), findsNothing);
    });
  });

  group('SettingsScreen sync row', () {
    // Correct as written: P2P sync needs a directory picker and Directory
    // watching, which the iOS sandbox does not give.
    testWidgets('is offered on Android', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.android;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.syncSettingsLabel), findsOneWidget);
    });

    testWidgets('is offered on desktop', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.windows;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.syncSettingsLabel), findsOneWidget);
    });

    testWidgets('is hidden on iOS', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.iOS;

      final l10n = await _pumpSettings(tester, surfaceSize: _wide);

      expect(_row(l10n.syncSettingsLabel), findsNothing);
    });
  });

  group('SettingsScreen unconditional rows', () {
    testWidgets('are present on every platform and at both widths', (
      tester,
    ) async {
      final l10n = await loadL10n();
      const platforms = [
        AppPlatformKind.android,
        AppPlatformKind.iOS,
        AppPlatformKind.windows,
        AppPlatformKind.web,
      ];

      for (final platform in platforms) {
        for (final size in [_narrow, _wide]) {
          debugAppPlatformOverride = platform;
          await _pumpSettings(tester, surfaceSize: size);

          for (final title in [
            l10n.manageIconsLabel,
            l10n.manageThemeLabel,
            l10n.languageLabel,
            l10n.mainCurrencyLabel,
            l10n.defaultInflationCountryLabel,
            l10n.apiManagementLabel,
            l10n.importDataLabel,
            l10n.exportDataLabel,
            l10n.importExchangeRatesLabel,
            l10n.resetDataLabel,
          ]) {
            expect(
              _row(title),
              findsOneWidget,
              reason: '"$title" missing on $platform at $size',
            );
          }
        }
      }
    });
  });

  group('SettingsScreen reset data', () {
    late _FakeDbRepository db;
    late _FakeSmsRepository sms;

    setUp(() {
      db = _FakeDbRepository();
      sms = _FakeSmsRepository();
      GetIt.I.registerSingleton<DbRepository>(db);
      GetIt.I.registerSingleton<SmsRepository>(sms);
    });

    tearDown(GetIt.I.reset);

    testWidgets('succeeds where no SmsBloc is provided', (tester) async {
      // SmsBloc is only provided on Android (AppProviders gates it), so on
      // every other platform the tree below has exactly this shape — no
      // SmsBloc. Reloading it unconditionally after the wipe threw a
      // ProviderNotFoundException inside the try block, which surfaced as
      // "reset failed" even though the database had already been cleared.
      debugAppPlatformOverride = AppPlatformKind.windows;
      final l10n = await loadL10n();

      await pumpAppWidget(
        tester,
        const SettingsScreen(),
        surfaceSize: _narrow,
        wrapInScaffold: false,
        // Note the absence of an SmsBloc: this is the provider set the app
        // builds everywhere except Android.
        aboveApp: (app) => wrapWithBlocs(
          app,
          settingsBloc: createSettingsBloc(),
          currencyBloc: createCurrencyBloc(),
          stylesBloc: createStylesBloc(),
          accountsBloc: MockAccountsBloc(),
          categoriesBloc: MockCategoriesBloc(),
          transactionsBloc: MockTransactionsBloc(),
          dashboardBloc: MockDashboardBloc(),
          currencyConverterBloc: MockCurrencyConverterBloc(),
        ),
      );
      await tester.pump();

      await tester.tap(_row(l10n.resetDataLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.resetEverythingButton));
      await tester.pumpAndSettle();

      expect(db.cleared, isTrue);
      expect(sms.cleared, isTrue);
      expect(find.text(l10n.resetSuccessMessage), findsOneWidget);
    });

    testWidgets('can be cancelled without touching the database', (
      tester,
    ) async {
      debugAppPlatformOverride = AppPlatformKind.windows;
      final l10n = await _pumpSettings(tester, surfaceSize: _narrow);

      await tester.tap(_row(l10n.resetDataLabel));
      await tester.pumpAndSettle();
      expect(find.text(l10n.resetDataConfirmationTitle), findsOneWidget);

      await tester.tap(find.text(l10n.cancelButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.resetDataConfirmationTitle), findsNothing);
      expect(db.cleared, isFalse);
    });
  });

  group('SettingsScreen right-to-left', () {
    testWidgets('builds in Arabic without overflowing', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.android;

      final l10n = await _pumpSettings(
        tester,
        surfaceSize: _narrow,
        locale: const Locale('ar'),
      );

      expect(tester.takeException(), isNull);
      expect(_row(l10n.dataLabel), findsOneWidget);
    });

    testWidgets('builds in Urdu without overflowing', (tester) async {
      debugAppPlatformOverride = AppPlatformKind.windows;

      final l10n = await _pumpSettings(
        tester,
        surfaceSize: _wide,
        locale: const Locale('ur'),
      );

      expect(tester.takeException(), isNull);
      expect(_row(l10n.hotKeysLabel), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.byType(SettingsScreen))),
        TextDirection.rtl,
      );
    });
  });
}

class _FakeDbRepository implements DbRepository {
  bool cleared = false;

  @override
  Future<void> clearAllDatabase() async => cleared = true;

  @override
  Future<void> batch(Function(Batch) action) async {}
}

/// Only [clearData] matters here; the rest of the interface is device SMS
/// access, which a widget test never reaches.
class _FakeSmsRepository implements SmsRepository {
  bool cleared = false;

  @override
  Future<void> clearData() async => cleared = true;

  @override
  Future<List<SmsPreset>> getAllPresets() async => const [];

  @override
  Future<List<SmsPreset>> getEnabledPresets() async => const [];

  @override
  Future<void> savePreset(SmsPreset preset) async {}

  @override
  Future<void> deletePreset(String presetId) async {}

  @override
  Future<void> togglePreset(String presetId, bool isEnabled) async {}

  @override
  Future<DateTime?> getLastSyncTimestamp() async => null;

  @override
  Future<void> setLastSyncTimestamp(DateTime timestamp) async {}

  @override
  Future<List<SmsMessage>> getSmsMessages({
    DateTime? since,
    List<String>? senderFilters,
  }) async => const [];

  @override
  Stream<SmsMessage> listenForSms() => const Stream<SmsMessage>.empty();

  @override
  Future<bool> hasSmsPermission() async => false;

  @override
  Future<bool> requestSmsPermission() async => false;
}
