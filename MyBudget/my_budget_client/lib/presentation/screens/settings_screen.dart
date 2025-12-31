import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
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
        builder: (context, settingsState) {
          final persistFilters =
              settingsState.settings['persist_advanced_filters'] == 'true';
          final mainCurrencyCode =
              settingsState.settings['main_currency_code'] ?? 'EUR';

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
                  final currentMode = settingsState.themeMode;
                  final nextMode = switch (currentMode) {
                    ThemeMode.system => ThemeMode.light,
                    ThemeMode.light => ThemeMode.dark,
                    ThemeMode.dark => ThemeMode.system,
                  };
                  context.read<SettingsBloc>().add(UpdateThemeMode(nextMode));
                },
              ),
              BlocBuilder<CurrencyBloc, CurrencyState>(
                builder: (context, currencyState) {
                  if (currencyState is CurrencyLoadSuccess) {
                    return ListTile(
                      leading: const Icon(Icons.money),
                      title: const Text('Main Currency'),
                      trailing: DropdownButton<String>(
                        value: mainCurrencyCode,
                        items: currencyState.currencies
                            .map((currency) => DropdownMenuItem(
                                  value: currency.code,
                                  child: Text(currency.code),
                                ))
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            context.read<SettingsBloc>().add(UpdateSetting(
                                  'main_currency_code',
                                  newValue,
                                ));
                          }
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
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