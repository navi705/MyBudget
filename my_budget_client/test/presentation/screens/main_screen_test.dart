// The destination list MainScreen hands to the shell.
//
// This is where a feature goes missing: MainScreen decides which destinations
// exist, and it decides that from the width it is given. The tests below pin
// both sides of that decision and, for the one destination that is dropped on
// narrow layouts (Data / exchange rates), assert that the app still offers a
// way in — see settings_screen_test.dart for the other half of that contract.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/main_screen.dart';
import 'package:my_budget_client/presentation/widgets/adaptive_scaffold.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';

import '../test_app.dart';

const Size _phone = Size(400, 800);
const Size _desktop = Size(1200, 800);

/// Every route MainScreen can name, so `context.go` always has a target.
const List<String> _shellRoutes = [
  AppRoutes.dashboard,
  AppRoutes.accounts,
  AppRoutes.transactions,
  AppRoutes.categories,
  AppRoutes.exchangeRates,
  AppRoutes.settings,
  AppRoutes.debug,
];

GoRouter _buildRouter({String initialLocation = AppRoutes.dashboard}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          for (final route in _shellRoutes)
            GoRoute(path: route, builder: (_, _) => Text('body:$route')),
        ],
      ),
    ],
  );
}

List<NavigationItem> _destinations(WidgetTester tester) =>
    tester.widget<AdaptiveScaffold>(find.byType(AdaptiveScaffold)).destinations;

void main() {
  group('MainScreen destinations', () {
    testWidgets('wide layout offers the Data destination', (tester) async {
      await pumpRouterApp(tester, _buildRouter(), surfaceSize: _desktop);

      expect(
        _destinations(tester).map((d) => d.route),
        contains(AppRoutes.exchangeRates),
      );
    });

    testWidgets('narrow layout drops the Data destination', (tester) async {
      // Deliberate: a sub-600dp bottom bar cannot carry seven destinations, so
      // Data moves into Settings. The row that replaces it is asserted in
      // settings_screen_test.dart — without it this drop would be a hole.
      await pumpRouterApp(tester, _buildRouter(), surfaceSize: _phone);

      expect(
        _destinations(tester).map((d) => d.route),
        isNot(contains(AppRoutes.exchangeRates)),
      );
    });

    testWidgets('core destinations are present at both widths', (tester) async {
      const core = [
        AppRoutes.dashboard,
        AppRoutes.accounts,
        AppRoutes.transactions,
        AppRoutes.categories,
        AppRoutes.settings,
      ];

      await pumpRouterApp(tester, _buildRouter(), surfaceSize: _phone);
      final narrow = _destinations(tester).map((d) => d.route).toList();

      await pumpRouterApp(tester, _buildRouter(), surfaceSize: _desktop);
      final wide = _destinations(tester).map((d) => d.route).toList();

      for (final route in core) {
        expect(narrow, contains(route), reason: '$route missing on narrow');
        expect(wide, contains(route), reason: '$route missing on wide');
      }
    });

    testWidgets('narrow destinations are a subset of the wide ones', (
      tester,
    ) async {
      // Anything the bottom bar shows must also exist in the rail; the reverse
      // is allowed only for destinations Settings re-offers.
      await pumpRouterApp(tester, _buildRouter(), surfaceSize: _phone);
      final narrow = _destinations(tester).map((d) => d.route).toSet();

      await pumpRouterApp(tester, _buildRouter(), surfaceSize: _desktop);
      final wide = _destinations(tester).map((d) => d.route).toSet();

      expect(narrow.difference(wide), isEmpty);
    });

    testWidgets('every destination carries a route that resolves', (
      tester,
    ) async {
      await pumpRouterApp(tester, _buildRouter(), surfaceSize: _desktop);

      for (final destination in _destinations(tester)) {
        expect(_shellRoutes, contains(destination.route));
      }
    });
  });

  group('MainScreen labels', () {
    testWidgets('uses the short labels on narrow layouts', (tester) async {
      final l10n = await loadL10n();
      await pumpRouterApp(tester, _buildRouter(), surfaceSize: _phone);

      final labels = _destinations(tester).map((d) => d.label).toList();
      expect(labels, contains(l10n.homeLabel));
      expect(labels, contains(l10n.historyLabel));
    });

    testWidgets('uses the full labels on wide layouts', (tester) async {
      final l10n = await loadL10n();
      await pumpRouterApp(tester, _buildRouter(), surfaceSize: _desktop);

      final labels = _destinations(tester).map((d) => d.label).toList();
      expect(labels, contains(l10n.dashboardLabel));
      expect(labels, contains(l10n.transactionsAppBarTitle));
      expect(labels, contains(l10n.dataLabel));
    });

    testWidgets('labels come from the active locale, not from English', (
      tester,
    ) async {
      final arabic = await loadL10n(const Locale('ar'));
      await pumpRouterApp(
        tester,
        _buildRouter(),
        surfaceSize: _desktop,
        locale: const Locale('ar'),
      );

      expect(
        _destinations(tester).map((d) => d.label),
        contains(arabic.settingsTitle),
      );
    });
  });

  group('MainScreen right-to-left', () {
    testWidgets('builds in Arabic at both widths without overflowing', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        _buildRouter(),
        surfaceSize: _phone,
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationBar), findsOneWidget);

      await pumpRouterApp(
        tester,
        _buildRouter(),
        surfaceSize: _desktop,
        locale: const Locale('ar'),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('renders right-to-left in Urdu', (tester) async {
      await pumpRouterApp(
        tester,
        _buildRouter(),
        surfaceSize: _phone,
        locale: const Locale('ur'),
      );

      expect(
        Directionality.of(tester.element(find.byType(AdaptiveScaffold))),
        TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
