import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Manage Account Styles'),
            onTap: () {
              context.go(AppRoutes.manageAccountStyles);
            },
          ),
        ],
      ),
    );
  }
}