// The Hot Keys row was gated on `!AppPlatform.isAndroid && !AppPlatform.isIOS`.
// AppPlatform reads dart:io, and dart:io is not there in a browser, so every
// flag answers false on web - including a phone browser, which was offered a
// screen for recording keyboard shortcuts it has no way to press. The gate now
// reads the theme's platform, which falls back to defaultTargetPlatform, and
// the web build derives that from the user agent.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/presentation/screens/settings_screen.dart';

import '../test_app.dart';

void main() {
  /// Renders Settings on [platform] and answers whether the row is offered.
  ///
  /// The surface is tall on purpose: the row sits far enough down the ListView
  /// that a phone-sized viewport would leave it unbuilt, and "not built yet"
  /// looks exactly like "not offered".
  Future<bool> offersHotKeys(WidgetTester tester, TargetPlatform platform) async {
    await pumpAppWidget(
      tester,
      const SettingsScreen(),
      platform: platform,
      surfaceSize: const Size(800, 2400),
      wrapInScaffold: false,
      aboveApp: (app) => wrapWithBlocs(
        app,
        settingsBloc: createSettingsBloc(),
        currencyBloc: createCurrencyBloc(),
      ),
    );
    await tester.pumpAndSettle();

    final l10n = await loadL10n();
    return find.text(l10n.hotKeysLabel).evaluate().isNotEmpty;
  }

  testWidgets('a touch device is not offered keyboard shortcuts', (
    tester,
  ) async {
    expect(await offersHotKeys(tester, TargetPlatform.android), isFalse);
  });

  testWidgets('an iPhone is not offered keyboard shortcuts either', (
    tester,
  ) async {
    expect(await offersHotKeys(tester, TargetPlatform.iOS), isFalse);
  });

  testWidgets('a desktop is', (tester) async {
    expect(await offersHotKeys(tester, TargetPlatform.windows), isTrue);
  });

  testWidgets('and so is a Mac', (tester) async {
    expect(await offersHotKeys(tester, TargetPlatform.macOS), isTrue);
  });
}
