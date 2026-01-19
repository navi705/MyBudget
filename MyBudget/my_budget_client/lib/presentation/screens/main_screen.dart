import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/adaptive_scaffold.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';
import 'package:my_budget_client/presentation/widgets/screen_shortcuts.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({required this.child, super.key});

  final Widget child;

  List<NavigationItem> get _destinations {
    const baseDestinations = [
      NavigationItem(
        label: 'Dashboard',
        icon: Icons.dashboard,
        route: AppRoutes.dashboard,
        tooltip: 'Dashboard',
        hotkeyId: 'dashboard',
        tooltipDescription: 'View your financial summary',
      ),
      NavigationItem(
        label: 'Accounts',
        icon: Icons.account_balance_wallet,
        route: AppRoutes.accounts,
        tooltip: 'Accounts',
        hotkeyId: 'accounts',
        tooltipDescription: 'Manage your bank accounts and wallets',
      ),
      NavigationItem(
        label: 'Transactions',
        icon: Icons.swap_horiz,
        route: AppRoutes.transactions,
        tooltip: 'Transactions',
        hotkeyId: 'transactions',
        tooltipDescription: 'View and edit your income and expenses',
      ),
      NavigationItem(
        label: 'Categories',
        icon: Icons.category,
        route: AppRoutes.categories,
        tooltip: 'Categories',
        hotkeyId: 'categories',
        tooltipDescription: 'Organize your spending habits',
      ),
      NavigationItem(
        label: 'Data',
        icon: Icons.bar_chart,
        route: AppRoutes.exchangeRates,
        tooltip: 'Exchange Rates',
        hotkeyId: 'data',
        tooltipDescription: 'View currency exchange rates',
      ),
      NavigationItem(
        label: 'Settings',
        icon: Icons.settings,
        route: AppRoutes.settings,
        tooltip: 'Settings',
        hotkeyId: 'settings',
        tooltipDescription: 'Configure application preferences',
      ),
    ];

    if (kDebugMode) {
      return [
        ...baseDestinations,
        const NavigationItem(
          label: 'Debug',
          icon: Icons.bug_report,
          route: AppRoutes.debug,
        ),
      ];
    }
    return baseDestinations;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenShortcuts(
      actions: {
        'dashboard': () => context.go(AppRoutes.dashboard),
        'accounts': () => context.go(AppRoutes.accounts),
        'transactions': () => context.go(AppRoutes.transactions),
        'categories': () => context.go(AppRoutes.categories),
        'data': () => context.go(AppRoutes.exchangeRates),
        'settings': () => context.go(AppRoutes.settings),
      },
      child: AdaptiveScaffold(destinations: _destinations, child: child),
    );
  }
}
