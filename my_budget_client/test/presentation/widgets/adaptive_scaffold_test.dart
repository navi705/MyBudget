// Behaviour of the app shell's adaptive navigation.
//
// The shell is the only thing standing between a feature and the user: if a
// destination reaches the bottom bar but not the rail (or the other way round),
// that feature is unreachable at one of the two widths even though nothing in
// the feature itself is broken. These tests therefore assert on the *set* of
// destinations at both widths, not just on which affordance is showing.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/widgets/adaptive_scaffold.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';

import '../test_app.dart';

const Size _phone = Size(400, 800);
const Size _desktop = Size(1200, 800);

/// Wide enough for the rail, narrow enough that it cannot extend.
const Size _narrowDesktop = Size(700, 800);

const List<NavigationItem> _destinations = [
  NavigationItem(
    label: 'Home',
    icon: Icons.dashboard,
    route: '/',
    tooltip: 'Home',
    hotkeyId: 'dashboard',
  ),
  NavigationItem(
    label: 'Wallets',
    icon: Icons.account_balance_wallet,
    route: '/accounts',
  ),
  NavigationItem(label: 'History', icon: Icons.swap_horiz, route: '/history'),
  NavigationItem(label: 'Config', icon: Icons.settings, route: '/settings'),
];

GoRouter _buildShellRouter({
  String initialLocation = '/',
  List<NavigationItem> destinations = _destinations,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveScaffold(destinations: destinations, child: child),
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('body:/')),
          GoRoute(
            path: '/accounts',
            builder: (_, _) => const Text('body:/accounts'),
          ),
          GoRoute(
            path: '/history',
            builder: (_, _) => const Text('body:/history'),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, _) => const Text('body:/settings'),
          ),
          GoRoute(
            path: '/exchange-rates',
            builder: (_, _) => const Text('body:/exchange-rates'),
          ),
        ],
      ),
    ],
  );
}

/// Labels currently offered by whichever navigation affordance is showing.
List<String> _visibleDestinationLabels(WidgetTester tester) {
  if (tester.any(find.byType(NavigationBar))) {
    return tester
        .widget<NavigationBar>(find.byType(NavigationBar))
        .destinations
        .cast<NavigationDestination>()
        .map((d) => d.label)
        .toList();
  }
  return tester
      .widget<NavigationRail>(find.byType(NavigationRail))
      .destinations
      .map((d) => (d.label as Text).data!)
      .toList();
}

void main() {
  group('AdaptiveScaffold layout switch', () {
    testWidgets('narrow width shows a bottom bar and no rail', (tester) async {
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _phone);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('wide width shows a rail and no bottom bar', (tester) async {
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _desktop);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });
  });

  group('AdaptiveScaffold destination parity', () {
    testWidgets('offers the same destinations narrow and wide', (tester) async {
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _phone);
      final narrowLabels = _visibleDestinationLabels(tester);

      expect(narrowLabels, _destinations.map((d) => d.label).toList());

      setSurfaceSize(tester, _desktop);
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _desktop);
      final wideLabels = _visibleDestinationLabels(tester);

      expect(wideLabels, narrowLabels);
    });

    testWidgets('every destination navigates from the bottom bar', (
      tester,
    ) async {
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _phone);

      for (final destination in _destinations) {
        await tester.tap(find.text(destination.label).first);
        await tester.pumpAndSettle();
        expect(
          find.text('body:${destination.route}'),
          findsOneWidget,
          reason: '${destination.label} did not open ${destination.route}',
        );
      }
    });

    testWidgets('every destination navigates from the rail', (tester) async {
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _desktop);

      for (final destination in _destinations) {
        await tester.tap(find.text(destination.label).first);
        await tester.pumpAndSettle();
        expect(
          find.text('body:${destination.route}'),
          findsOneWidget,
          reason: '${destination.label} did not open ${destination.route}',
        );
      }
    });
  });

  group('AdaptiveScaffold selection', () {
    testWidgets('highlights the destination matching the location', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        _buildShellRouter(initialLocation: '/history'),
        surfaceSize: _phone,
      );

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        2,
      );
    });

    testWidgets('root only matches the root location', (tester) async {
      // '/'.startsWith would match every route, which would pin the highlight
      // to the first destination everywhere.
      await pumpRouterApp(
        tester,
        _buildShellRouter(initialLocation: '/accounts'),
        surfaceSize: _desktop,
      );

      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        1,
      );
    });

    testWidgets('a mobile-only route with no destination highlights Settings', (
      tester,
    ) async {
      // /exchange-rates has no bottom-bar destination; it is reached through
      // Settings there, so Settings is what must light up.
      await pumpRouterApp(
        tester,
        _buildShellRouter(initialLocation: '/exchange-rates'),
        surfaceSize: _phone,
      );

      expect(
        tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
        _destinations.indexWhere((d) => d.route == '/settings'),
      );
    });

    testWidgets('an unmatched route falls back to the first destination', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        _buildShellRouter(initialLocation: '/exchange-rates'),
        surfaceSize: _desktop,
      );

      // Wide layout has no Settings fallback rule, so index 0 is expected.
      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        0,
      );
    });
  });

  group('AdaptiveScaffold rail controls', () {
    testWidgets('collapse button toggles the rail between extended and icons', (
      tester,
    ) async {
      // 1200dp is past kExtendedRailBreakpoint, so the rail opens *extended* -
      // each label drawn beside its icon. `NavigationRail` forbids any label
      // type other than `none` while extended, so the label type is not what
      // the toggle changes at this width; `extended` is.
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _desktop);

      final railBefore = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(railBefore.extended, isTrue);
      expect(railBefore.labelType, NavigationRailLabelType.none);
      // Extended means the labels are on screen, not hidden in a tooltip.
      expect(find.text(_destinations.first.label), findsWidgets);

      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left));
      await tester.pumpAndSettle();

      final railAfter = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(railAfter.extended, isFalse);
      expect(railAfter.labelType, NavigationRailLabelType.none);
    });

    testWidgets('below the extended breakpoint the toggle drops the labels', (
      tester,
    ) async {
      // Under 900dp there is no room to draw labels beside the icons, so the
      // expanded rail stacks them (`labelType.all`) and collapsing hides them.
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _narrowDesktop,
      );

      final railBefore = tester.widget<NavigationRail>(
        find.byType(NavigationRail),
      );
      expect(railBefore.extended, isFalse);
      expect(railBefore.labelType, NavigationRailLabelType.all);

      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left));
      await tester.pumpAndSettle();

      expect(
        tester.widget<NavigationRail>(find.byType(NavigationRail)).labelType,
        NavigationRailLabelType.none,
      );
    });
  });

  group('AdaptiveScaffold right-to-left', () {
    testWidgets('builds in Arabic without overflowing', (tester) async {
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _desktop,
        locale: const Locale('ar'),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(NavigationRail), findsOneWidget);
    });

    testWidgets('collapse arrow points along the text direction', (
      tester,
    ) async {
      // The rail sits on the start edge, so in RTL "collapse" moves the panel
      // to the right; an LTR-hardcoded arrow would point off-screen.
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _desktop,
        locale: const Locale('ur'),
      );

      expect(find.byIcon(Icons.keyboard_double_arrow_right), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_double_arrow_left), findsNothing);
    });

    testWidgets('bottom bar builds right-to-left without overflowing', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _phone,
        locale: const Locale('ar'),
      );

      expect(tester.takeException(), isNull);
      expect(
        _visibleDestinationLabels(tester),
        _destinations.map((d) => d.label).toList(),
      );
    });
  });

  group('AdaptiveScaffold inside a constrained box', () {
    testWidgets('a 500dp pane in a 1200dp window still gets the bottom bar', (
      tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          ShellRoute(
            builder: (context, state, child) => Center(
              child: SizedBox(
                width: 500,
                height: 700,
                child: AdaptiveScaffold(
                  destinations: _destinations,
                  child: child,
                ),
              ),
            ),
            routes: [
              GoRoute(path: '/', builder: (_, _) => const Text('body:/')),
              GoRoute(
                path: '/settings',
                builder: (_, _) => const Text('body:/settings'),
              ),
            ],
          ),
        ],
      );

      await pumpRouterApp(tester, router, surfaceSize: _desktop);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });
  });
}
