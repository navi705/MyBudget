import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/core/theme/pane_layout.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/adaptive_scaffold.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // How many destinations fit, and how terse their labels must be, is a
    // question about the space on hand — not about the host OS. The web build
    // reports `false` for every AppPlatform flag (see platform_web.dart), so
    // the old OS gate handed a phone browser all six-plus destinations packed
    // into a sub-600dp NavigationBar. Measuring here also keeps this in step
    // with AdaptiveScaffold, which measures the same box.
    return LayoutBuilder(
      builder: (context, constraints) {
        // Publish the box before reading it, so this list and the shell's own
        // rail-or-bar decision are answered by one authority. Height is part of
        // the question: a phone in landscape is wide enough for a rail and far
        // too short to hold one, and the destination list has to agree with
        // whichever affordance AdaptiveScaffold ends up drawing - it is the
        // mobile list that routes Data through Settings.
        return PaneLayout(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          child: Builder(builder: (context) => _buildShell(context)),
        );
      },
    );
  }

  Widget _buildShell(BuildContext context) {
    final l10n = context.l10n;
    final isMobile = !context.prefersRail;

    final destinations = [
      NavigationItem(
        label: isMobile ? l10n.homeLabel : l10n.dashboardLabel,
        icon: Icons.dashboard,
        route: AppRoutes.dashboard,
        tooltip: l10n.dashboardLabel,
        hotkeyId: 'dashboard',
        tooltipDescription: l10n.dashboardBalanceDescription,
      ),
      NavigationItem(
        label: l10n.accountsAppBarTitle,
        icon: Icons.account_balance_wallet,
        route: AppRoutes.accounts,
        tooltip: l10n.accountsAppBarTitle,
        hotkeyId: 'accounts',
        tooltipDescription: l10n.addAccountDescription, // Maybe generic desc?
      ),
      NavigationItem(
        label: isMobile ? l10n.historyLabel : l10n.transactionsAppBarTitle,
        icon: Icons.swap_horiz,
        route: AppRoutes.transactions,
        tooltip: l10n.transactionsAppBarTitle,
        hotkeyId: 'transactions',
        tooltipDescription: l10n.transactionsScreenBody, // Placeholder logic
      ),
      NavigationItem(
        label: l10n.categoriesAppBarTitle,
        icon: Icons.category,
        route: AppRoutes.categories,
        tooltip: l10n.categoriesAppBarTitle,
        hotkeyId: 'categories',
        tooltipDescription: l10n.categoriesScreenBody,
      ),
      // On mobile the Data screen is reached through Settings instead;
      // AdaptiveScaffold highlights Settings for /exchange-rates there.
      if (!isMobile)
        NavigationItem(
          label: l10n.dataLabel,
          icon: Icons.bar_chart,
          route: AppRoutes.exchangeRates,
          tooltip: l10n.dataLabel,
          hotkeyId: 'data',
          tooltipDescription: l10n.dataLabel,
        ),
      NavigationItem(
        label: l10n.settingsTitle,
        icon: Icons.settings,
        route: AppRoutes.settings,
        tooltip: l10n.settingsTitle,
        hotkeyId: 'settings',
        tooltipDescription: l10n.settingsTitle,
      ),
    ];

    if (kDebugMode && !isMobile) {
      destinations.add(
        const NavigationItem(
          label: 'Debug',
          icon: Icons.bug_report,
          route: AppRoutes.debug,
        ),
      );
    }

    return ScreenShortcuts(
      actions: {
        'dashboard': () => context.go(AppRoutes.dashboard),
        'accounts': () => context.go(AppRoutes.accounts),
        'transactions': () => context.go(AppRoutes.transactions),
        'categories': () => context.go(AppRoutes.categories),
        'data': () => context.go(AppRoutes.exchangeRates),
        'settings': () => context.go(AppRoutes.settings),
      },
      child: AdaptiveScaffold(destinations: destinations, child: child),
    );
  }
}
