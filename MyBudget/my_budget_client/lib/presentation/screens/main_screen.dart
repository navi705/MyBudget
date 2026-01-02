import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/adaptive_scaffold.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({required this.child, super.key});

  final Widget child;

  List<NavigationItem> get _destinations {
    const baseDestinations = [
      NavigationItem(
        label: 'Dashboard',
        icon: Icons.dashboard,
        route: AppRoutes.dashboard,
      ),
      NavigationItem(
        label: 'Accounts',
        icon: Icons.account_balance_wallet,
        route: AppRoutes.accounts,
      ),
      NavigationItem(
        label: 'Transactions',
        icon: Icons.swap_horiz,
        route: AppRoutes.transactions,
      ),
      NavigationItem(
        label: 'Categories',
        icon: Icons.category,
        route: AppRoutes.categories,
      ),
      NavigationItem(
        label: 'Data',
        icon: Icons.bar_chart,
        route: AppRoutes.exchangeRates,
      ),
      NavigationItem(
        label: 'Settings',
        icon: Icons.settings,
        route: AppRoutes.settings,
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
    return AdaptiveScaffold(destinations: _destinations, child: child);
  }
}
