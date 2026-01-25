import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final l10n = context.l10n;
    final destinations = [
      NavigationItem(
        label: (Platform.isAndroid || Platform.isIOS)
            ? l10n.homeLabel
            : l10n.dashboardLabel,
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
        label: (Platform.isAndroid || Platform.isIOS)
            ? l10n.historyLabel
            : l10n.transactionsAppBarTitle,
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
      if (!Platform.isAndroid && !Platform.isIOS)
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

    if (kDebugMode && !Platform.isAndroid && !Platform.isIOS) {
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
