import 'package:flutter/material.dart';
import 'package:my_budget_client/presentation/screens/accounts_screen.dart';

class AppRouter {
  static const String accountsRoute = '/';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case accountsRoute:
        return MaterialPageRoute(builder: (_) => const AccountsScreen());
      default:
        return MaterialPageRoute(builder: (_) => const Text('Error: Unknown route'));
    }
  }
}