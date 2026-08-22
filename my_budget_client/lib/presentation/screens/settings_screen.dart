import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import '../../core/utils/country_codes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:my_budget_client/core/theme/pane_layout.dart';
import 'package:my_budget_client/data/repositories/db_repository.dart';
import 'package:my_budget_client/core/services/data_export_service.dart';
import 'package:my_budget_client/core/services/data_import_service.dart';
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

/// The languages offered in the picker, keyed by the code stored in settings.
///
/// One map, at file scope: it used to be declared twice - once to render the
/// current language on the Settings row and once to build the dialog - so
/// adding a locale in one place silently left the other showing a raw code.
const Map<String, String> _languageNames = {
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
              final mainCurrencyCode =
                  settingsState.settings['main_currency_code'] ?? 'EUR';
              final defaultInflationCountry =
                  settingsState.settings['default_inflation_country'] ?? 'SRB';

              final l10n = context.l10n;
              // Whether the shell is currently showing its bottom
              // NavigationBar rather than the side rail. Anything the rail
              // drops at this size has to be offered from inside Settings
              // instead - see the Data row below - so this has to be the exact
              // question MainScreen asks, not a near-enough one.
              //
              // `prefersRail` is false when the pane is narrow OR short;
              // `isCompactPane` is only about width. Asking the width-only
              // question here left a band - 600dp or wider but under 500dp
              // tall, i.e. any phone in landscape - where MainScreen had
              // already dropped the Data destination for being short and
              // Settings declined to offer it for being wide. Neither half
              // published /exchange-rates, so Exchange Rates, Inflation and
              // Assets were unreachable until the user rotated the device.
              final isMobileLayout = !context.prefersRail;
              // Whether there is a keyboard to bind anything to. AppPlatform
              // reads dart:io, so every flag is false in a browser and a phone
              // browser was offered a screen for recording keyboard shortcuts
              // it has no way to press. Theme.of(context).platform falls back
              // to defaultTargetPlatform, which the web build derives from the
              // user agent, so it names the real device in both builds.
              final platform = Theme.of(context).platform;
              final hasPhysicalKeyboard =
                  platform != TargetPlatform.android &&
                  platform != TargetPlatform.iOS;
              return ListView(
                children: [
                  // --- Appearance -------------------------------------------
                  _SectionHeader(l10n.appearanceSection),
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

                  // --- Regional & general preferences ------------------------
                  _SectionHeader(l10n.settingsTitle),
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
                            final selected = await showCurrencyPicker(
                              context: context,
                              currencies: currencyState.currencies,
                              selectedCurrencyCode: mainCurrencyCode,
                            );
                            final selectedCode = selected?.code;

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
                  if (hasPhysicalKeyboard)
                    ListTile(
                      leading: const Icon(Icons.keyboard),
                      title: Text(l10n.hotKeysLabel),
                      onTap: () {
                        context.push(AppRoutes.hotKeys);
                      },
                    ),
                  const Divider(),

                  // --- Feature-specific & external data ----------------------
                  //
                  // The Data screen has no navigation destination of its own
                  // while the shell is in bottom-bar mode, so this row is its
                  // only entry point there. Gating it on Android/iOS instead
                  // made it unreachable for everyone else that lands in that
                  // mode: a phone browser (every AppPlatform flag is false on
                  // web) and a desktop window dragged below 600dp both lost
                  // /exchange-rates entirely — no rail destination, no settings
                  // row. The gate belongs on the same width MainScreen uses.
                  _SectionHeader(l10n.dataLabel),
                  if (isMobileLayout)
                    ListTile(
                      leading: const Icon(Icons.bar_chart),
                      title: Text(l10n.dataLabel),
                      onTap: () {
                        context.push(AppRoutes.exchangeRates);
                      },
                    ),
                  // SMS import only works on Android; hide on iOS to avoid a
                  // dead feature.
                  if (AppPlatform.isAndroid)
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

                  // --- Synchronisation, backup and transfer ------------------
                  // P2P sync relies on a directory picker + Directory.watch,
                  // which are unavailable in the iOS sandbox. Show only on
                  // Android and desktop.
                  _SectionHeader(l10n.syncSettingsLabel),
                  if (!kIsWeb && !AppPlatform.isIOS)
                    ListTile(
                      leading: const Icon(Icons.sync),
                      title: Text(l10n.syncSettingsLabel),
                      subtitle: Text(l10n.syncSettingsSubtitle),
                      onTap: () {
                        context.push(AppRoutes.syncSettings);
                      },
                    ),
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
                    onTap: () => _showExportDialog(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: Text(l10n.importExchangeRatesLabel),
                    onTap: () => _importExchangeRates(context),
                  ),
                  const Divider(),

                  // --- System / danger zone ----------------------------------
                  _SectionHeader(l10n.resetDataLabel, isDanger: true),
                  ListTile(
                    leading: const Icon(Icons.restore_page, color: Colors.red),
                    title: Text(
                      l10n.resetDataLabel,
                      style: const TextStyle(color: Colors.red),
                    ),
                    subtitle: Text(l10n.resetDataSubtitle),
                    onTap: () => _confirmResetData(context),
                  ),
                  // Same reasoning as the Data row: MainScreen only adds the
                  // Debug destination to the rail, so in bottom-bar mode this
                  // row is the only way in regardless of the host OS.
                  if (kDebugMode && isMobileLayout)
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

  /// The export chooser.
  ///
  /// It has one format today, and used to have that one button and nothing
  /// else: opening it by a mistap left no way out but guessing that a tap
  /// outside dismisses. Cancel is the way out, and it is the first action so
  /// the destructive-adjacent one is never under the thumb by default.
  void _showExportDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        actionsAlignment: MainAxisAlignment.center,
        title: Text(l10n.exportDataLabel, textAlign: TextAlign.center),
        // No body text: `exportFormatMessage` describes a CSV option this
        // dialog does not offer, and a dialog that names a button that is not
        // there is worse than a dialog with no body at all.
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _exportData(context, isCsv: false);
            },
            child: Text(l10n.jsonFormat),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context, {required bool isCsv}) async {
    try {
      final service = GetIt.I<DataExportService>();
      final success = await service.exportData(isCsv);
      if (!context.mounted) return;
      final l10n = context.l10n;
      // Only report success when the export actually happened, but never leave
      // the tap silent: a `false` result (cancelled save dialog / dismissed
      // share sheet) used to produce no feedback at all, which is
      // indistinguishable from a dead button.
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.exportSuccessMessage)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportFailedMessage(l10n.cancelButton))),
        );
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
      final service = GetIt.I<DataImportService>();
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

  /// How many rows the wipe is about to take, or null when the bloc that knows
  /// is not in the tree.
  ///
  /// Deleting one transaction offers an Undo; deleting everything used to offer
  /// one red button and a paragraph. Naming the counts is the cheapest way to
  /// make "all your data" concrete before the user commits to it.
  int? _countFrom(BuildContext context, int Function() read) {
    try {
      return read();
    } catch (_) {
      // ProviderNotFoundException is not exported by flutter_bloc, and the
      // dialog is worth showing even without a count, so this stays broad and
      // degrades to "unknown" rather than taking the screen down.
      return null;
    }
  }

  void _confirmResetData(BuildContext context) {
    final accountCount = _countFrom(
      context,
      () => context.read<AccountsBloc>().state.totalCount,
    );
    final transactionCount = _countFrom(
      context,
      () => context.read<TransactionsBloc>().state.totalCount,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => _ResetDataDialog(
        accountCount: accountCount,
        transactionCount: transactionCount,
        onBackup: () {
          Navigator.of(dialogContext).pop();
          _showExportDialog(context);
        },
        onConfirmed: () async {
          Navigator.of(dialogContext).pop();
          await _performReset(context);
        },
      ),
    );
  }

  Future<void> _performReset(BuildContext context) async {
    try {
      // Routed through DbRepository (already registered in DI and used the
      // same way by DebugDataSeeder) instead of calling AppDatabase.clearAllData()
      // straight from the screen.
      await GetIt.I<DbRepository>().clearAllDatabase();
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
    // SmsBloc is only provided on Android (AppProviders gates it the same way),
    // so this read has to be gated identically. Unconditionally it threw
    // ProviderNotFoundException on every other platform — after the database
    // had already been wiped — and the catch in _performReset reported the
    // reset as failed even though it had succeeded.
    if (!kIsWeb && AppPlatform.isAndroid) {
      context.read<SmsBloc>().add(LoadSmsPresets());
    }
  }

  String _getLanguageName(String? code, BuildContext context) {
    if (code == null || code.isEmpty) return context.l10n.systemDefaultLabel;
    return _languageNames[code] ?? code;
  }

  Future<void> _showLanguageDialog(
    BuildContext context,
    String? currentCode,
  ) async {
    final selected = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text(context.l10n.selectLanguageTitle),
        children: [
          _LanguageOption(
            label: context.l10n.systemDefaultLabel,
            isSelected: currentCode == null || currentCode.isEmpty,
            onPressed: () =>
                Navigator.pop(dialogContext, ''), // Empty for system
          ),
          const Divider(),
          ..._languageNames.entries.map(
            (e) => _LanguageOption(
              label: e.value,
              isSelected: currentCode == e.key,
              onPressed: () => Navigator.pop(dialogContext, e.key),
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

/// A group label for the settings list.
///
/// The list was thirteen undifferentiated rows separated by four bare
/// `Divider`s, so finding "Currency" meant reading all thirteen. The groups
/// already existed - they were just unnamed.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.isDanger = false});

  final String title;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        start: 16,
        end: 16,
        top: 16,
        bottom: 8,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isDanger ? Colors.red : theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One row of the language picker.
///
/// The check mark occupies a fixed-width slot whether or not it is drawn: the
/// selected row used to be the only one carrying an icon, which pushed its own
/// label 16dp further in than every other row and made the current language
/// read as misaligned rather than as chosen.
class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.isSelected,
    required this.onPressed,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: onPressed,
      child: Row(
        children: [
          SizedBox(
            width: 16,
            child: isSelected ? const Icon(Icons.check, size: 16) : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: isSelected
                  ? const TextStyle(fontWeight: FontWeight.bold)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// The confirmation for wiping every account and transaction.
///
/// Protection here used to be inverted against the rest of the app: deleting
/// one transaction offers an Undo, while deleting all of them sat behind a
/// single red button with no statement of what was about to go and no way back
/// afterwards. Three things change that: the counts are named, a backup is the
/// dialog's primary action, and the wipe stays disabled until the confirmation
/// word has been typed.
class _ResetDataDialog extends StatefulWidget {
  const _ResetDataDialog({
    required this.accountCount,
    required this.transactionCount,
    required this.onBackup,
    required this.onConfirmed,
  });

  final int? accountCount;
  final int? transactionCount;
  final VoidCallback onBackup;
  final VoidCallback onConfirmed;

  /// Key on the typed-confirmation field, so a test can drive it without
  /// depending on which localized label the field happens to carry.
  static const Key confirmationFieldKey = Key('reset-confirmation-field');

  /// The word the user has to type. There is no ARB key for a dedicated
  /// "type RESET to confirm" phrase yet, so the existing Confirm label doubles
  /// as the word - it is short, already translated for all ten locales, and it
  /// is what the field's own label shows.
  static String confirmationWord(BuildContext context) =>
      context.l10n.confirmButton;

  @override
  State<_ResetDataDialog> createState() => _ResetDataDialogState();
}

class _ResetDataDialogState extends State<_ResetDataDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _matches(String word) =>
      _controller.text.trim().toLowerCase() == word.trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final word = _ResetDataDialog.confirmationWord(context);
    final armed = _matches(word);

    return AlertDialog(
      title: Text(l10n.resetDataConfirmationTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.resetDataConfirmationMessage),
            const SizedBox(height: 16),
            // What is about to be lost, in numbers rather than in adjectives.
            if (widget.accountCount != null)
              _CountRow(
                label: l10n.accountsAppBarTitle,
                count: widget.accountCount!,
              ),
            if (widget.transactionCount != null)
              _CountRow(
                label: l10n.transactionsAppBarTitle,
                count: widget.transactionCount!,
              ),
            const SizedBox(height: 16),
            TextField(
              key: _ResetDataDialog.confirmationFieldKey,
              controller: _controller,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: word,
                hintText: word,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        // Secondary, and inert until the word is typed.
        TextButton(
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          onPressed: armed ? widget.onConfirmed : null,
          child: Text(l10n.resetEverythingButton),
        ),
        // Primary: the way out that costs the user nothing.
        FilledButton(
          onPressed: widget.onBackup,
          child: Text(l10n.exportDataLabel),
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(child: Text(label, style: theme.textTheme.bodyMedium)),
          const SizedBox(width: 12),
          Text(
            '$count',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
