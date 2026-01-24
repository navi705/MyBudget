import 'dart:io';
import '../../core/utils/country_codes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/data_export_service.dart';
import 'package:my_budget_client/core/services/data_import_service.dart';
import 'package:my_budget_client/core/services/android_file_picker_service.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/widgets/currency_picker_dialog.dart';
import 'package:my_budget_client/presentation/widgets/country_picker_dialog.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, settingsState) {
              // final persistFilters =
              //     settingsState.settings['persist_advanced_filters'] == 'true';
              final mainCurrencyCode =
                  settingsState.settings['main_currency_code'] ?? 'EUR';
              final defaultInflationCountry =
                  settingsState.settings['default_inflation_country'] ?? 'SRB';

              final l10n = context.l10n;
              return ListView(
                children: [
                  // Appearance
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: Text(l10n.manageIconsLabel),
                    onTap: () {
                      context.push(AppRoutes.manageAccountStyles);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.brightness_6),
                    title: Text(l10n.manageThemeLabel),
                    onTap: () {
                      context.push(AppRoutes.themeSettings);
                    },
                  ),
                  const Divider(),

                  // Regional & General Preferences
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(l10n.languageLabel),
                    subtitle: Text(
                      _getLanguageName(
                        settingsState.settings['language_code'],
                        context,
                      ),
                    ),
                    onTap: () => _showLanguageDialog(
                      context,
                      settingsState.settings['language_code'],
                    ),
                  ),

                  BlocBuilder<CurrencyBloc, CurrencyState>(
                    builder: (context, currencyState) {
                      if (currencyState is CurrencyLoadSuccess) {
                        return ListTile(
                          leading: const Icon(Icons.money),
                          title: Text(l10n.mainCurrencyLabel),
                          subtitle: Text(mainCurrencyCode),
                          onTap: () async {
                            final selectedCode = await showDialog<String>(
                              context: context,
                              builder: (context) => CurrencyPickerDialog(
                                allCurrencies: currencyState.currencies,
                                selectedCurrencyCode: mainCurrencyCode,
                              ),
                            );

                            if (selectedCode != null && context.mounted) {
                              context.read<SettingsBloc>().add(
                                UpdateSetting(
                                  'main_currency_code',
                                  selectedCode,
                                ),
                              );
                            }
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.public),
                    title: Text(l10n.defaultInflationCountryLabel),
                    subtitle: Text(
                      getLocalizedCountryName(
                        defaultInflationCountry,
                        settingsState.settings['language_code'] ?? 'en',
                      ),
                    ),
                    onTap: () async {
                      final selectedCode = await showDialog<String>(
                        context: context,
                        builder: (context) => CountryPickerDialog(
                          allCountries: settingsState.allCountries,
                          selectedCountryCode: defaultInflationCountry,
                        ),
                      );

                      if (selectedCode != null && context.mounted) {
                        context.read<SettingsBloc>().add(
                          UpdateSetting(
                            'default_inflation_country',
                            selectedCode,
                          ),
                        );
                      }
                    },
                  ),
                  // ListTile(
                  //   leading: const Icon(Icons.save),
                  //   title: Text(l10n.persistAdvancedFiltersLabel),
                  //   trailing: Switch(
                  //     value: persistFilters,
                  //     onChanged: (bool value) {
                  //       context.read<SettingsBloc>().add(
                  //         UpdateSetting(
                  //           'persist_advanced_filters',
                  //           value.toString(),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                  if (!Platform.isAndroid && !Platform.isIOS)
                    ListTile(
                      leading: const Icon(Icons.keyboard),
                      title: Text(l10n.hotKeysLabel),
                      onTap: () {
                        context.push(AppRoutes.hotKeys);
                      },
                    ),
                  const Divider(),

                  // Feature-specific & External Data
                  if (Platform.isAndroid || Platform.isIOS)
                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: Text(l10n.dataLabel),
                      onTap: () {
                        context.push(AppRoutes.exchangeRates);
                      },
                    ),
                  if (Platform.isAndroid || Platform.isIOS)
                    ListTile(
                      leading: const Icon(Icons.sms),
                      title: Text(l10n.smsImportLabel),
                      subtitle: Text(l10n.smsImportSubtitle),
                      onTap: () {
                        context.push(AppRoutes.smsSettings);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.api),
                    title: Text(l10n.apiManagementLabel),
                    onTap: () {
                      context.push(AppRoutes.apiSettings);
                    },
                  ),
                  const Divider(),

                  // Synchronization
                  ListTile(
                    leading: const Icon(Icons.sync),
                    title: Text(l10n.syncSettingsLabel),
                    subtitle: Text(l10n.syncSettingsSubtitle),
                    onTap: () {
                      context.push(AppRoutes.syncSettings);
                    },
                  ),
                  const Divider(),

                  // Data Operations (Import/Export)
                  ListTile(
                    leading: const Icon(Icons.import_export),
                    title: Text(l10n.importDataLabel),
                    onTap: () {
                      context.push(AppRoutes.importScreen);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.file_download),
                    title: Text(l10n.exportDataLabel),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          actionsAlignment: MainAxisAlignment.center,
                          title: Text(
                            l10n.exportDataLabel,
                            textAlign: TextAlign.center,
                          ),
                          // content: Text(l10n.exportFormatMessage),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                _exportData(context, isCsv: false);
                              },
                              child: Text(l10n.jsonFormat),
                            ),
                            // TextButton(
                            //   onPressed: () {
                            //     Navigator.pop(context);
                            //     _exportData(context, isCsv: true);
                            //   },
                            //   child: Text(l10n.csvFormat),
                            // ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: Text(l10n.importExchangeRatesLabel),
                    onTap: () => _importExchangeRates(context),
                  ),
                  const Divider(),

                  // System / Danger Zone
                  ListTile(
                    leading: const Icon(Icons.restore_page, color: Colors.red),
                    title: Text(
                      l10n.resetDataLabel,
                      style: const TextStyle(color: Colors.red),
                    ),
                    subtitle: Text(l10n.resetDataSubtitle),
                    onTap: () => _confirmResetData(context),
                  ),
                  if (kDebugMode && (Platform.isAndroid || Platform.isIOS))
                    ListTile(
                      leading: const Icon(
                        Icons.bug_report,
                        color: Colors.orange,
                      ),
                      title: Text(l10n.debugMenuLabel),
                      subtitle: Text(l10n.debugMenuSubtitle),
                      onTap: () {
                        context.push(AppRoutes.debug);
                      },
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _exportData(BuildContext context, {required bool isCsv}) async {
    try {
      final db = GetIt.I<AppDatabase>();
      final service = DataExportService(db);
      await service.exportData(isCsv);
      if (context.mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportSuccessMessage)));
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailedMessage(e.toString()))),
        );
      }
    }
  }

  void _importExchangeRates(BuildContext context) async {
    try {
      final db = GetIt.I<AppDatabase>();
      final androidPicker = GetIt.I<AndroidFilePickerService>();
      final service = DataImportService(db, androidPicker);
      // We pass a localized title if available, otherwise default string
      final title = context.l10n.filePickerChooserTitle;
      await service.importExchangeRates(title: title);

      if (context.mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.importSuccessMessage)));
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importFailedMessage(e.toString()))),
        );
      }
    }
  }

  void _confirmResetData(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetDataConfirmationTitle),
        content: Text(l10n.resetDataConfirmationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog
              await _performReset(context);
            },
            child: Text(l10n.resetEverythingButton),
          ),
        ],
      ),
    );
  }

  Future<void> _performReset(BuildContext context) async {
    try {
      final db = GetIt.I<AppDatabase>();
      await db.clearAllData();
      await GetIt.I<SmsRepository>().clearData();

      if (context.mounted) {
        final l10n = context.l10n;
        _reloadAllBlocs(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.resetSuccessMessage)));
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.resetFailedMessage(e.toString()))),
        );
      }
    }
  }

  void _reloadAllBlocs(BuildContext context) {
    context.read<AccountsBloc>().add(LoadAccounts());
    context.read<CategoriesBloc>().add(LoadCategories());
    context.read<CurrencyBloc>().add(LoadCurrencies());
    context.read<CurrencyConverterBloc>().add(LoadCurrencyConverter());
    context.read<DashboardBloc>().add(LoadDashboard());
    context.read<SettingsBloc>().add(LoadSettings());
    context.read<StylesBloc>().add(LoadStyles());
    context.read<TransactionsBloc>().add(const InitialLoadTransactions());
    context.read<SmsBloc>().add(LoadSmsPresets());
  }

  String _getLanguageName(String? code, BuildContext context) {
    if (code == null || code.isEmpty) return context.l10n.systemDefaultLabel;
    const languageMap = {
      'en': 'English',
      'ru': 'Русский',
      'ar': 'العربية',
      'bn': 'বাংলা',
      'es': 'Español',
      'fr': 'Français',
      'hi': 'हिन्दी',
      'pt': 'Português',
      'ur': 'اردو',
      'zh': '中文',
    };
    return languageMap[code] ?? code;
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    String? currentCode,
  ) async {
    const languageMap = {
      'en': 'English',
      'ru': 'Русский',
      'ar': 'العربية',
      'bn': 'বাংলা',
      'es': 'Español',
      'fr': 'Français',
      'hi': 'हिन्दी',
      'pt': 'Português',
      'ur': 'اردو',
      'zh': '中文',
    };

    final selected = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.selectLanguageTitle),
        children: [
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(dialogContext, ''), // Empty for system
            child: Row(
              children: [
                if (currentCode == null || currentCode.isEmpty)
                  const Icon(Icons.check, size: 16),
                const SizedBox(width: 8),
                Text(context.l10n.systemDefaultLabel),
              ],
            ),
          ),
          const Divider(),
          ...languageMap.entries.map(
            (e) => SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, e.key),
              child: Row(
                children: [
                  if (currentCode == e.key) const Icon(Icons.check, size: 16),
                  const SizedBox(width: 8),
                  Text(e.value),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (selected != null && context.mounted) {
      // If empty string, we want to clear the setting (null)
      final value = selected.isEmpty ? '' : selected;
      context.read<SettingsBloc>().add(UpdateSetting('language_code', value));
    }
  }
}
