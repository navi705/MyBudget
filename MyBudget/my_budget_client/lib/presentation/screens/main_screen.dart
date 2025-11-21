import 'package:flutter/material.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/adaptive_scaffold.dart';
import 'package:my_budget_client/presentation/widgets/navigation_item.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({
    required this.child,
    super.key,
  });

  final Widget child;

  static const List<NavigationItem> _destinations = [
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
      label: 'Settings',
      icon: Icons.settings,
      route: AppRoutes.settings,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      destinations: _destinations,
      child: child,
    );
  }
}