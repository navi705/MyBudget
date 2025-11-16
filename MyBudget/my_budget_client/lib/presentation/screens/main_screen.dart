import 'package:flutter/material.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';
import 'package:my_budget_client/presentation/screens/settings_screen.dart';
import 'package:my_budget_client/presentation/screens/transactions_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const AccountsScreen(),
    const CategoriesScreen(),
    const TransactionsScreen(),
    const SettingsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_balance_wallet),
            label: l10n.accountsAppBarTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.category),
            label: l10n.categoriesAppBarTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.compare_arrows),
            label: l10n.transactionsAppBarTitle,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settingsAppBarTitle,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
