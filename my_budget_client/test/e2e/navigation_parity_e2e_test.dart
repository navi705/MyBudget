// Can a user get to every part of the app, on every surface it ships on?
//
// The shell answers "rail or bottom bar" from the box it was handed, not from
// the host OS, and the destination list is built from the same answer. That is
// deliberate - a half-width desktop window should behave like a phone - but it
// means the two shells hold DIFFERENT destination lists, and one of them is
// short an entry: on the narrow shell the Data screen is not a destination at
// all, it is reached through Settings.
//
// So "every screen is reachable" is a claim that has to be checked per surface
// rather than once. These tests boot the real app on each surface and walk to
// each screen the way a person would.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';
import 'package:my_budget_client/presentation/screens/dashboard_screen.dart';
import 'package:my_budget_client/presentation/screens/exchange_rates_screen.dart';
import 'package:my_budget_client/presentation/screens/settings_screen.dart';
import 'package:my_budget_client/presentation/screens/transactions_screen.dart';

import 'e2e_harness.dart';

void main() {
  e2eTestOnEachDevice('the app boots to the dashboard', (app) async {
    expect(find.byType(DashboardScreen), findsOneWidget);
  }, devices: E2eDevice.all);

  e2eTestOnEachDevice(
    'lays out the shell the surface calls for, not the one the host OS would',
    (app) async {
      // The Windows half-width case is the whole point: same host, same build,
      // and it must still fall back to the phone shell.
      expect(
        find.byType(NavigationRail),
        app.device.expectsRail ? findsOneWidget : findsNothing,
        reason:
            '${app.device.name} should '
            '${app.device.expectsRail ? '' : 'not '}use the rail',
      );
      expect(
        find.byType(NavigationBar),
        app.device.expectsRail ? findsNothing : findsOneWidget,
      );
    },
    devices: E2eDevice.all,
  );

  e2eTestOnEachDevice(
    'reaches Accounts, History, Categories and Settings from the shell',
    (app) async {
      final l10n = app.l10n;
      final isMobile = !app.device.expectsRail;

      Future<void> goTo(String label, Type screen) async {
        expect(
          find.text(label),
          findsWidgets,
          reason: '$label is not offered on ${app.device.name}',
        );
        await app.tester.tap(find.text(label).first);
        await settleE2e(app.tester, rounds: 4);
        expect(
          find.byType(screen),
          findsOneWidget,
          reason: 'tapping $label did not open $screen on ${app.device.name}',
        );
      }

      await goTo(l10n.accountsAppBarTitle, AccountsScreen);
      await goTo(
        isMobile ? l10n.historyLabel : l10n.transactionsAppBarTitle,
        TransactionsScreen,
      );
      await goTo(l10n.categoriesAppBarTitle, CategoriesScreen);
      await goTo(l10n.settingsTitle, SettingsScreen);
      await goTo(
        isMobile ? l10n.homeLabel : l10n.dashboardLabel,
        DashboardScreen,
      );
    },
    devices: E2eDevice.all,
  );

  e2eTestOnEachDevice(
    'reaches the Data screen - as a destination where there is room for one, '
    'and through Settings where there is not',
    (app) async {
      final l10n = app.l10n;

      if (app.device.expectsRail) {
        // Wide shell: Data is its own destination.
        await app.tester.tap(find.text(l10n.dataLabel).first);
      } else {
        // Narrow shell: it is not, and the route through Settings is the only
        // one there is. A user who cannot find it here cannot find it at all.
        await app.tester.tap(find.text(l10n.settingsTitle).first);
        await settleE2e(app.tester, rounds: 4);

        final dataTile = find.widgetWithText(ListTile, l10n.dataLabel);
        await app.tester.scrollUntilVisible(
          dataTile,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await app.tester.tap(dataTile);
      }
      await settleE2e(app.tester, rounds: 4);

      expect(
        find.byType(ExchangeRatesScreen),
        findsOneWidget,
        reason: 'the Data screen is unreachable on ${app.device.name}',
      );
    },
    devices: E2eDevice.all,
  );
}
