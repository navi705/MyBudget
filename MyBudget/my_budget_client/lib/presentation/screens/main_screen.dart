import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // This is where you could use a BlocBuilder<SettingsBloc, ...>
    // to decide which navigation type to show (e.g., bottom bar, rail, drawer).
    // For now, we'll default to BottomNavigationBar.

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        // This makes the selected item pop with color, while others are grey.
        type: BottomNavigationBarType.fixed,
        // Determine the current index by checking the current route location.
        currentIndex: _calculateSelectedIndex(context),
        onTap: (int index) => _onItemTapped(index, context),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.swap_horiz),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == AppRoutes.accounts) {
      return 0;
    }
    if (location == AppRoutes.transactions) {
      return 1;
    }
    if (location == AppRoutes.categories) {
      return 2;
    }
    if (location == AppRoutes.settings) {
      return 3;
    }
    return 0; // Default to the first item
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go(AppRoutes.accounts);
        break;
      case 1:
        context.go(AppRoutes.transactions);
        break;
      case 2:
        context.go(AppRoutes.categories);
        break;
      case 3:
        context.go(AppRoutes.settings);
        break;
    }
  }
}