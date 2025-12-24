import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          final persistFilters =
              state.settings['persist_advanced_filters'] == 'true';
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.palette),
                title: const Text('Manage Account Styles'),
                onTap: () {
                  context.push(AppRoutes.manageAccountStyles);
                },
              ),
              ListTile(
                leading: const Icon(Icons.brightness_6),
                title: const Text('Toggle Theme'),
                onTap: () {
                  final currentMode = state.themeMode;
                  final nextMode = switch (currentMode) {
                    ThemeMode.system => ThemeMode.light,
                    ThemeMode.light => ThemeMode.dark,
                    ThemeMode.dark => ThemeMode.system,
                  };
                  context.read<SettingsBloc>().add(UpdateThemeMode(nextMode));
                },
              ),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Persist Advanced Filters'),
                trailing: Switch(
                  value: persistFilters,
                  onChanged: (bool value) {
                    context.read<SettingsBloc>().add(UpdateSetting(
                          'persist_advanced_filters',
                          value.toString(),
                        ));
                  },
                ),
              ),
              ListTile(
                leading: const Icon(Icons.import_export),
                title: const Text('Import Data'),
                onTap: () {
                  context.push(AppRoutes.importScreen);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}