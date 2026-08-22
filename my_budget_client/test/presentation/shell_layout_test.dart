// The shell's layout contract: what the window size is allowed to change, and
// what it is never allowed to take away.
//
// Three of these tests exist because of a rendered failure. A phone in
// landscape (780x360) is wider than the 600dp mobile breakpoint, so the shell
// chose a `NavigationRail`; the rail needs ~446dp for its toggle plus seven
// destinations, sat in no scroll view, and overflowed by 166 pixels — Data,
// Settings and Debug were simply not on the screen, and Settings is the only
// route to Hot Keys, Theme, API, SMS, Sync, Import/Export and Reset. The fix
// is in two halves and both are pinned below: the rail-or-bar decision now
// reads height as well as width, and the rail scrolls so that no size can hide
// a destination even if that decision is ever wrong again.
//
// Every test here pins a concrete surface size, because every behaviour here is
// a function of the size and of nothing else.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/core/theme/pane_layout.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/theme/theme_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/screens/dashboard_screen.dart';
import 'package:my_budget_client/presentation/screens/main_screen.dart';
import 'package:my_budget_client/presentation/screens/splash_screen.dart';
import 'package:my_budget_client/presentation/widgets/adaptive_scaffold.dart';
import 'package:my_budget_client/presentation/widgets/navigation/navigation_tab_bar.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';

import 'test_app.dart';

// The five device classes the critique rendered, named once.
const Size _phonePortrait = Size(400, 800);
const Size _phoneLandscape = Size(780, 360);
const Size _shortDesktop = Size(620, 520);
const Size _desktop = Size(1000, 800);
const Size _narrowDesktop = Size(700, 800);

/// Seven destinations, which is what the production shell hands over on a
/// desktop-sized pane (dashboard, accounts, transactions, categories, data,
/// settings and — in debug builds — debug). The count is the whole point: it
/// is the seventh that used to fall off the bottom.
const List<NavigationItem> _sevenDestinations = [
  NavigationItem(
    label: 'Home',
    icon: Icons.dashboard,
    route: AppRoutes.dashboard,
    tooltip: 'Home',
    hotkeyId: 'dashboard',
  ),
  NavigationItem(
    label: 'Wallets',
    icon: Icons.account_balance_wallet,
    route: AppRoutes.accounts,
  ),
  NavigationItem(
    label: 'History',
    icon: Icons.swap_horiz,
    route: AppRoutes.transactions,
  ),
  NavigationItem(
    label: 'Groups',
    icon: Icons.category,
    route: AppRoutes.categories,
  ),
  NavigationItem(
    label: 'Data',
    icon: Icons.bar_chart,
    route: AppRoutes.exchangeRates,
  ),
  NavigationItem(
    label: 'Config',
    icon: Icons.settings,
    route: AppRoutes.settings,
  ),
  NavigationItem(
    label: 'Debug',
    icon: Icons.bug_report,
    route: AppRoutes.debug,
  ),
];

/// The size the shell published to the screen on the last build.
///
/// Written from the routed page's own `build`, which is the only place that can
/// answer "what did the screen actually get" — the point of `PaneLayout` is
/// that it is *not* the window.
Size? _publishedPane;

GoRouter _buildShellRouter({
  String initialLocation = AppRoutes.dashboard,
  List<NavigationItem> destinations = _sevenDestinations,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AdaptiveScaffold(destinations: destinations, child: child),
        routes: [
          for (final destination in destinations)
            GoRoute(
              path: destination.route,
              builder: (_, _) => Builder(
                builder: (context) {
                  _publishedPane = context.paneSize;
                  return Text('body:${destination.route}');
                },
              ),
            ),
        ],
      ),
    ],
  );
}

/// The router MainScreen needs: every route it can name has to have a target.
GoRouter _buildMainScreenRouter() {
  return GoRouter(
    initialLocation: AppRoutes.dashboard,
    routes: [
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          for (final route in const [
            AppRoutes.dashboard,
            AppRoutes.accounts,
            AppRoutes.transactions,
            AppRoutes.categories,
            AppRoutes.exchangeRates,
            AppRoutes.settings,
            AppRoutes.debug,
          ])
            GoRoute(path: route, builder: (_, _) => Text('body:$route')),
        ],
      ),
    ],
  );
}

/// Walks every destination and proves each one opens its route.
///
/// `ensureVisible` is what makes this a real reachability check rather than a
/// "is it in the widget list" check: a destination scrolled out of the rail is
/// still in the tree, and a user still cannot press it. It is a no-op when
/// there is nothing to scroll, so the same loop covers the bottom bar.
Future<void> _tapEveryDestination(WidgetTester tester) async {
  for (final destination in _sevenDestinations) {
    final finder = find.text(destination.label).first;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
    expect(
      find.text('body:${destination.route}'),
      findsOneWidget,
      reason: '${destination.label} could not be reached',
    );
  }
}

NavigationRail _rail(WidgetTester tester) =>
    tester.widget<NavigationRail>(find.byType(NavigationRail));

/// The shell's own `Scaffold` — the only one in these trees, since the routed
/// pages are bare `Text`.
Scaffold _shellScaffold(WidgetTester tester) =>
    tester.widget<Scaffold>(find.byType(Scaffold));

// ---------------------------------------------------------------------------
// Dashboard scaffolding
// ---------------------------------------------------------------------------

const _usd = Currency(
  name: 'US Dollar',
  code: 'USD',
  languageCode: 'en',
  type: TypeCurrency.currency,
);

/// The dashboard's tab bar paints itself from the active theme, so the screen
/// does not build at all without one.
class _MockThemeBloc extends MockBloc<ThemeEvent, ThemeState>
    implements ThemeBloc {}

ThemeBloc _themeBloc() {
  final bloc = _MockThemeBloc();
  whenListen(
    bloc,
    const Stream<ThemeState>.empty(),
    initialState: const ThemeState(),
  );
  return bloc;
}

DashboardBloc _dashboardBloc() {
  final bloc = MockDashboardBloc();
  whenListen(
    bloc,
    const Stream<DashboardState>.empty(),
    initialState: DashboardLoadSuccess(
      selectedDay: DateTime(2024, 3, 15),
      dateRangeStart: DateTime(2024, 3, 1),
      dateRangeEnd: DateTime(2024, 3, 31),
      dateStep: DateStep.month,
      selectedCurrency: 'USD',
      availableCurrencies: const [_usd],
    ),
  );
  return bloc;
}

/// Pumps the dashboard on a surface of [size] and returns the top edge of its
/// Calendar / Categories / Balance bar.
Future<double> _dashboardTabBarTop(WidgetTester tester, Size size) async {
  setSurfaceSize(tester, size);

  await tester.pumpWidget(
    BlocProvider<ThemeBloc>.value(
      value: _themeBloc(),
      child: wrapWithBlocs(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const DashboardScreen(),
        ),
        settingsBloc: createSettingsBloc(),
        currencyBloc: createCurrencyBloc(),
        stylesBloc: createStylesBloc(),
        dashboardBloc: _dashboardBloc(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return tester.getTopLeft(find.byType(NavigationTabBar)).dy;
}

void main() {
  setUp(() => _publishedPane = null);

  group('AdaptiveScaffold rail or bar', () {
    testWidgets('a phone in landscape gets the bottom bar, not the rail', (
      tester,
    ) async {
      // 780 wide passes the 600dp width test on its own; 360 tall is the half
      // of the question that used to go unasked.
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _phoneLandscape,
      );

      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a short desktop window still gets the rail', (tester) async {
      // 620x520 clears both thresholds, so the rail is right here — it just
      // has to scroll to hold seven destinations in 520dp.
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _shortDesktop,
      );

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every destination is reachable at 780x360', (tester) async {
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _phoneLandscape,
      );

      await _tapEveryDestination(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('every destination is reachable at 620x520', (tester) async {
      // Seven destinations plus the collapse toggle need ~446dp of stacked
      // labels; the rail is 520dp tall, so this only passes because the rail
      // scrolls.
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _shortDesktop,
      );

      await _tapEveryDestination(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the rail scrolls rather than truncating', (tester) async {
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _shortDesktop,
      );

      expect(_rail(tester).scrollable, isTrue);
    });
  });

  group('AdaptiveScaffold and the soft keyboard', () {
    // `resizeToAvoidBottomInset: false` on the shell decided for every screen
    // in the app that the Android keyboard may sit on top of the field being
    // typed into. A screen that genuinely needs a pinned layout opts out for
    // itself; the shell must not opt out on its behalf.
    testWidgets('the bottom-bar branch leaves the keyboard inset alone', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _phonePortrait,
      );

      expect(_shellScaffold(tester).resizeToAvoidBottomInset, isNot(false));
    });

    testWidgets('the rail branch leaves the keyboard inset alone', (
      tester,
    ) async {
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _desktop);

      expect(_shellScaffold(tester).resizeToAvoidBottomInset, isNot(false));
    });
  });

  group('AdaptiveScaffold pane publication', () {
    testWidgets('publishes a pane narrower than the window under a rail', (
      tester,
    ) async {
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _desktop);

      expect(_publishedPane, isNotNull);
      // The rail and its divider are the difference. Screens that measured the
      // window instead of the pane disagreed with the shell across that band,
      // which is where the desktop filter bars overflowed.
      expect(_publishedPane!.width, lessThan(_desktop.width));
      expect(_publishedPane!.width, greaterThan(0));
    });

    testWidgets(
      'publishes the full width but not the full height under a bar',
      (tester) async {
        await pumpRouterApp(
          tester,
          _buildShellRouter(),
          surfaceSize: _phonePortrait,
        );

        expect(_publishedPane, isNotNull);
        expect(_publishedPane!.width, _phonePortrait.width);
        // The bottom NavigationBar comes off the height.
        expect(_publishedPane!.height, lessThan(_phonePortrait.height));
      },
    );
  });

  group('AdaptiveScaffold rail labels', () {
    testWidgets('a wide pane extends the rail so labels are readable', (
      tester,
    ) async {
      // Collapsed, the labels live in a hover-only tooltip that a touch device
      // can never summon.
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _desktop);

      expect(_rail(tester).extended, isTrue);
    });

    testWidgets('a rail below 900dp keeps its stacked labels', (tester) async {
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _narrowDesktop,
      );

      expect(_rail(tester).extended, isFalse);
      expect(_rail(tester).labelType, NavigationRailLabelType.all);
    });

    testWidgets('an extended rail never carries a stacked label type', (
      tester,
    ) async {
      // `NavigationRail` asserts outright when `extended` is combined with any
      // label type other than `none` - the two properties are one decision, and
      // the moment they disagree the whole shell throws rather than mislaying a
      // label. Both halves of the toggle are pinned here for that reason.
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _desktop);

      expect(_rail(tester).extended, isTrue);
      expect(_rail(tester).labelType, NavigationRailLabelType.none);

      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left));
      await tester.pumpAndSettle();

      // Collapsed is bare icons, so `none` again: the labels move to tooltips.
      expect(_rail(tester).extended, isFalse);
      expect(_rail(tester).labelType, NavigationRailLabelType.none);
      expect(tester.takeException(), isNull);
    });

    testWidgets('collapsing a sub-900dp rail takes the stacked labels away', (
      tester,
    ) async {
      await pumpRouterApp(
        tester,
        _buildShellRouter(),
        surfaceSize: _narrowDesktop,
      );
      expect(_rail(tester).labelType, NavigationRailLabelType.all);

      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left));
      await tester.pumpAndSettle();

      expect(_rail(tester).extended, isFalse);
      expect(_rail(tester).labelType, NavigationRailLabelType.none);
    });

    testWidgets('the user toggle outranks the pane once it is pressed', (
      tester,
    ) async {
      await pumpRouterApp(tester, _buildShellRouter(), surfaceSize: _desktop);
      expect(_rail(tester).extended, isTrue);

      await tester.tap(find.byIcon(Icons.keyboard_double_arrow_left));
      await tester.pumpAndSettle();
      expect(_rail(tester).extended, isFalse);

      // Widening the window must not undo a choice the user made by hand.
      tester.view.physicalSize = const Size(1400, 900);
      await tester.pumpAndSettle();
      expect(_rail(tester).extended, isFalse);
    });
  });

  group('MainScreen destination set', () {
    testWidgets('a landscape phone gets the mobile destinations', (
      tester,
    ) async {
      // The shell shows a bottom bar at 780x360, so MainScreen has to hand it
      // the mobile list — otherwise Data appears as a bar destination while
      // AdaptiveScaffold is still routing /exchange-rates through Settings.
      await pumpRouterApp(
        tester,
        _buildMainScreenRouter(),
        surfaceSize: _phoneLandscape,
      );

      final routes = tester
          .widget<AdaptiveScaffold>(find.byType(AdaptiveScaffold))
          .destinations
          .map((d) => d.route)
          .toList();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(routes, isNot(contains(AppRoutes.exchangeRates)));
      // Debug is a debug-build affordance and never a mobile one.
      expect(routes, isNot(contains(AppRoutes.debug)));
      expect(routes, contains(AppRoutes.settings));
    });
  });

  group('DashboardScreen tab bar placement', () {
    testWidgets('sits in the same place at 620x520 and at 780x360', (
      tester,
    ) async {
      // It used to move between the top and the bottom of the window across
      // the 600dp breakpoint: dragging a desktop window 160px narrower
      // teleported the primary tab control across the screen.
      final wide = await _dashboardTabBarTop(tester, _shortDesktop);

      await tester.pumpWidget(const SizedBox.shrink());
      final narrow = await _dashboardTabBarTop(tester, _phoneLandscape);

      expect(narrow, wide);
      // Top, specifically: the one position that cannot collide with the
      // shell's own bottom NavigationBar.
      expect(wide, 0.0);
    });
  });

  group('SplashScreen', () {
    testWidgets('follows a light platform brightness', (tester) async {
      // A hardcoded ThemeData.dark() gave every light-theme user a dark flash
      // on each cold start.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      setSurfaceSize(tester, _phonePortrait);

      await tester.pumpWidget(
        const SplashScreen(message: 'Loading...', progress: 0.5),
      );
      await tester.pump();

      final context = tester.element(find.byType(LinearProgressIndicator));
      expect(Theme.of(context).brightness, Brightness.light);
    });

    testWidgets('follows a dark platform brightness', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      setSurfaceSize(tester, _phonePortrait);

      await tester.pumpWidget(
        const SplashScreen(message: 'Loading...', progress: 0.5),
      );
      await tester.pump();

      final context = tester.element(find.byType(LinearProgressIndicator));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('fits a phone in landscape', (tester) async {
      // A fixed 200x200 logo over a 200-wide progress block is ~340dp of
      // column in a 360dp-tall window, and none of it scrolled.
      setSurfaceSize(tester, _phoneLandscape);

      await tester.pumpWidget(
        const SplashScreen(message: 'Loading...', progress: 0.5),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Loading...'), findsOneWidget);
    });
  });
}
