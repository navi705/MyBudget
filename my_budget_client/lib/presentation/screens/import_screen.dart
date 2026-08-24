import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/import_file_data.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_budget_client/core/utils/hex_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/services/data_import_service.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/import/import_bloc.dart';
import 'package:my_budget_client/presentation/widgets/import_mapping_dialog.dart';
import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:collection/collection.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/services/android_file_picker_service.dart';

class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ImportBloc(
        accountRepository: sl<AccountRepository>(),
        categoryRepository: sl<CategoryRepository>(),
        transactionRepository: sl<TransactionRepository>(),
        currencyRepository: sl<CurrencyRepository>(),
      ),
      child: const _ImportView(),
    );
  }
}

class _ImportView extends StatefulWidget {
  const _ImportView();

  @override
  State<_ImportView> createState() => _ImportViewState();
}

class _ImportViewState extends State<_ImportView> {
  Future<void> _startOneMoneyImport() async {
    List<ImportFileData>? importFiles;

    if (AppPlatform.isAndroid) {
      final pickedPaths = await sl<AndroidFilePickerService>().pickFile(
        mimeType: '*/*',
        title: context.l10n.filePickerChooserTitle,
        allowMultiple: true,
      );
      if (pickedPaths != null) {
        importFiles = pickedPaths
            .map(
              (path) => ImportFileData(
                name: path.split(AppPlatform.pathSeparator).last,
                path: path,
              ),
            )
            .toList();
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: true,
        withData: true, // Needed for web
      );
      if (result != null) {
        importFiles = result.files.map((file) {
          return ImportFileData(
            name: file.name,
            path: file.path,
            bytes: file.bytes,
          );
        }).toList();
      }
    }

    if (importFiles != null && importFiles.isNotEmpty) {
      // Basic validation: Check if file names look like OneMoney exports
      bool allValid = true;
      for (final file in importFiles) {
        if (!file.name.toLowerCase().endsWith('.csv')) {
          allValid = false;
          break;
        }
      }

      if (!allValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.selectAccountError)),
          );
        }
        return;
      }

      if (!mounted) return;
      context.read<ImportBloc>().add(StartImportProcess(importFiles));
    }
  }

  @override
  Widget build(BuildContext context) {
    return EscapeBackHandler(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.importDataTitle),
          actions: [
            BlocBuilder<ImportBloc, ImportState>(
              builder: (context, state) {
                if (state.step != ImportStep.idle) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: context.l10n.importStartOverTooltip,
                    onPressed: () {
                      context.read<ImportBloc>().add(ResetImport());
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocBuilder<ImportBloc, ImportState>(
          builder: (context, state) {
            switch (state.step) {
              case ImportStep.idle:
                return _buildFileSelectionStep();
              case ImportStep.parsing:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(context.l10n.importParsingStep),
                    ],
                  ),
                );
              case ImportStep.mappingAccounts:
                return _buildAccountMappingStep(state);
              case ImportStep.mappingCategories:
                return _buildCategoryMappingStep(state);
              case ImportStep.mappingCurrencies:
                return _buildCurrencyMappingStep(state);
              case ImportStep.resolvingDuplicates:
                return _buildDuplicateResolutionStep(state);
              case ImportStep.fetchingRates:
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(context.l10n.importFetchingRatesStep),
                    ],
                  ),
                );
              case ImportStep.readyToImport:
                return _buildReadyToImportStep(state);
              case ImportStep.importing:
                return _buildImportingStep(state);
              case ImportStep.complete:
                return _buildCompletionStep(state);
              case ImportStep.failure:
                return Center(
                  child: Text(
                    context.l10n.importErrorLabel(state.errorMessage ?? ''),
                  ),
                );
            }
          },
        ),
      ),
    );
  }

  Widget _buildFileSelectionStep() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Existing OneMoney Import
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_money),
                label: Text(context.l10n.importOneMoneyLabel),
                onPressed: _startOneMoneyImport,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(height: 16),
              // MyBudget CSV Import
              // OutlinedButton.icon(
              //   icon: const Icon(Icons.table_chart),
              //   label: Text(context.l10n.importMyBudgetLabel),
              //   onPressed: () => _handleGeneralImport(true),
              //   style: OutlinedButton.styleFrom(
              //     padding: const EdgeInsets.symmetric(vertical: 16),
              //     textStyle: Theme.of(context).textTheme.titleMedium,
              //   ),
              // ),
              const SizedBox(height: 16),
              // JSON Backup Import
              FilledButton.tonalIcon(
                icon: const Icon(Icons.restore),
                label: Text(context.l10n.restoreBackupLabel),
                onPressed: () => _handleGeneralImport(false), // JSON
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: Theme.of(context).textTheme.titleMedium,
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onErrorContainer,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    context.l10n.importSelectionHelp,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleGeneralImport(bool isCsv) async {
    final l10n = context.l10n;
    // Logic for general import
    // Note: This bypasses the ImportBloc which is specific to OneMoney mapping.
    // For simplicity, we run it directly here.
    if (!isCsv) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.warningOverwriteTitle),
          content: Text(l10n.warningOverwriteMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: Text(l10n.restoreOverwriteButton),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    try {
      final service = sl<DataImportService>();
      final title = l10n.filePickerChooserTitle;
      final success = await service.importData(isCsv, title: title);

      if (mounted && success) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.importSuccess)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.importFailed(e.toString()))),
        );
      }
    }
  }

  Widget _buildAccountMappingStep(ImportState state) {
    final unmapped = state.unmappedAccounts.toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_circle_outline),
                label: Text(context.l10n.importCreateAllNew),
                onPressed: () {
                  for (final name in unmapped) {
                    context.read<ImportBloc>().add(MapAccount(name, 'new'));
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: unmapped.length,
            itemBuilder: (context, index) {
              final accountName = unmapped[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.importNewAccountFound(accountName),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      // Wrap, not Row: the two labels together are wider than a
                      // 360dp phone card in the longer locales, and a Row would
                      // just overflow instead of moving the second button down.
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final existingAccounts =
                                  await sl<AccountRepository>().getAccounts();
                              if (!context.mounted) return;
                              final selectedId = await showDialog<String>(
                                context: context,
                                builder: (_) => ImportMappingDialog<Account>(
                                  title: context.l10n.importMapAccountTitle(
                                    accountName,
                                  ),
                                  items: existingAccounts,
                                  itemNameProvider: (account) => account.name,
                                  itemIdProvider: (account) => account.id,
                                  itemBuilder: (account) {
                                    final stylesState = context
                                        .read<StylesBloc>()
                                        .state;
                                    List<Style> styles = [];
                                    if (stylesState is StylesLoadSuccess) {
                                      styles = stylesState.styles;
                                    }
                                    final style =
                                        styles.firstWhereOrNull(
                                          (s) => s.id == account.styleId,
                                        ) ??
                                        Style(
                                          id: 'default',
                                          name: context.l10n.newAccountLabel,
                                          iconName: 'account_balance',
                                          colorHex: '#808080',
                                          iconType: IconType.material,
                                        );

                                    final color = parseHexColor(
                                      style.colorHex,
                                      fallback: Colors.grey,
                                    );

                                    return Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                          child: IconUtils.getIconWidget(style),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(account.name),
                                      ],
                                    );
                                  },
                                ),
                              );
                              if (!context.mounted) return;
                              if (selectedId != null) {
                                context.read<ImportBloc>().add(
                                  MapAccount(accountName, selectedId),
                                );
                              }
                            },
                            child: Text(context.l10n.importMapToExisting),
                          ),
                          FilledButton.tonal(
                            onPressed: () {
                              context.read<ImportBloc>().add(
                                MapAccount(accountName, 'new'),
                              );
                            },
                            child: Text(context.l10n.importCreateNew),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryMappingStep(ImportState state) {
    final unmapped = state.unmappedCategories.keys.toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_circle_outline),
                label: Text(context.l10n.importCreateAllNew),
                onPressed: () {
                  for (final name in unmapped) {
                    context.read<ImportBloc>().add(MapCategory(name, 'new'));
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: unmapped.length,
            itemBuilder: (context, index) {
              final categoryName = unmapped[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.importNewCategoryFound(categoryName),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      // Wrap, not Row: the two labels together are wider than a
                      // 360dp phone card in the longer locales, and a Row would
                      // just overflow instead of moving the second button down.
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final existingCategories =
                                  await sl<CategoryRepository>()
                                      .getCategories();
                              if (!context.mounted) return;
                              final selectedId = await showDialog<String>(
                                context: context,
                                builder: (_) => ImportMappingDialog<Category>(
                                  title: context.l10n.importMapCategoryTitle(
                                    categoryName,
                                  ),
                                  items: existingCategories,
                                  itemNameProvider: (category) => category.name,
                                  itemIdProvider: (category) => category.id,
                                  itemBuilder: (category) {
                                    final stylesState = context
                                        .read<StylesBloc>()
                                        .state;
                                    List<Style> styles = [];
                                    if (stylesState is StylesLoadSuccess) {
                                      styles = stylesState.styles;
                                    }
                                    final style =
                                        styles.firstWhereOrNull(
                                          (s) => s.id == category.styleId,
                                        ) ??
                                        Style(
                                          id: 'default',
                                          name: context.l10n.searchHint,
                                          iconName: 'category',
                                          colorHex: '#808080',
                                          iconType: IconType.material,
                                        );

                                    final color = parseHexColor(
                                      style.colorHex,
                                      fallback: Colors.grey,
                                    );

                                    return Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8.0),
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                          child: IconUtils.getIconWidget(style),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(category.name),
                                      ],
                                    );
                                  },
                                ),
                              );
                              if (!context.mounted) return;
                              if (selectedId != null) {
                                context.read<ImportBloc>().add(
                                  MapCategory(categoryName, selectedId),
                                );
                              }
                            },
                            child: Text(context.l10n.importMapToExisting),
                          ),
                          FilledButton.tonal(
                            onPressed: () {
                              context.read<ImportBloc>().add(
                                MapCategory(categoryName, 'new'),
                              );
                            },
                            child: Text(context.l10n.importCreateNew),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencyMappingStep(ImportState state) {
    final unmapped = state.unmappedCurrencies.toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add_circle_outline),
                label: Text(context.l10n.importCreateAllNew),
                onPressed: () {
                  for (final name in unmapped) {
                    context.read<ImportBloc>().add(MapCurrency(name, 'new'));
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: unmapped.length,
            itemBuilder: (context, index) {
              final currencyName = unmapped[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.importNewCurrencyFound(currencyName),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      // Wrap, not Row: the two labels together are wider than a
                      // 360dp phone card in the longer locales, and a Row would
                      // just overflow instead of moving the second button down.
                      Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final existingCurrencies =
                                  await sl<CurrencyRepository>()
                                      .getCurrencies();
                              if (!context.mounted) return;
                              final selectedId = await showDialog<String>(
                                context: context,
                                builder: (_) => ImportMappingDialog<Currency>(
                                  title: context.l10n.importMapCurrencyTitle(
                                    currencyName,
                                  ),
                                  items: existingCurrencies,
                                  itemNameProvider: (currency) => currency.name,
                                  itemIdProvider: (currency) => currency.code,
                                  itemBuilder: (currency) =>
                                      Text(currency.name),
                                ),
                              );
                              if (selectedId != null && context.mounted) {
                                context.read<ImportBloc>().add(
                                  MapCurrency(currencyName, selectedId),
                                );
                              }
                            },
                            child: Text(context.l10n.importMapToExisting),
                          ),
                          FilledButton.tonal(
                            onPressed: () {
                              context.read<ImportBloc>().add(
                                MapCurrency(currencyName, 'new'),
                              );
                            },
                            child: Text(context.l10n.importCreateNew),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicateResolutionStep(ImportState state) {
    final duplicates = state.potentialDuplicates;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.skip_next),
                label: Text(context.l10n.importSkipAll),
                onPressed: () {
                  for (final record in duplicates) {
                    context.read<ImportBloc>().add(
                      ResolveDuplicate(record, 'skip'),
                    );
                  }
                },
              ),
              const SizedBox(width: 8),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.download),
                label: Text(context.l10n.importImportAll),
                onPressed: () {
                  for (final record in duplicates) {
                    context.read<ImportBloc>().add(
                      ResolveDuplicate(record, 'import'),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: duplicates.length,
            itemBuilder: (context, index) {
              final record = duplicates[index];
              final resolution = state.duplicateResolutions[record];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: resolution != null ? Colors.grey.shade300 : null,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.importPotentialDuplicate,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.importDateLabel(
                          record.date.toLocal().toString().split(' ')[0],
                        ),
                      ),
                      Text(context.l10n.importFromLabel(record.from)),
                      Text(context.l10n.importToLabel(record.to)),
                      Text(
                        context.l10n.importAmountLabel(
                          record.amount,
                          record.currency,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (resolution == null)
                        // Wrap, not Row: the two labels together are wider than a
                        // 360dp phone card in the longer locales, and a Row would
                        // just overflow instead of moving the second button down.
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                context.read<ImportBloc>().add(
                                  ResolveDuplicate(record, 'skip'),
                                );
                              },
                              child: Text(context.l10n.importSkip),
                            ),
                            FilledButton.tonal(
                              onPressed: () {
                                context.read<ImportBloc>().add(
                                  ResolveDuplicate(record, 'import'),
                                );
                              },
                              child: Text(context.l10n.importImportAnyway),
                            ),
                          ],
                        )
                      else
                        Center(
                          child: Text(
                            // The decision read back in the language the
                            // buttons offering it were written in: it used to
                            // come back as the raw 'SKIP' or 'IMPORT' the
                            // event carries, whatever the app was set to.
                            context.l10n.importDecisionLabel(
                              resolution == 'skip'
                                  ? context.l10n.importSkip
                                  : context.l10n.importImportAnyway,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReadyToImportStep(ImportState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.importReadyTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.importReadyMessage(state.parsedRecords.length),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.tonal(
              onPressed: () {
                context.read<ImportBloc>().add(FinalizeImport());
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
              child: Text(context.l10n.importFinalizeButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportingStep(ImportState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              context.l10n.importingTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(value: state.progress),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionStep(ImportState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task_alt, color: Colors.blue, size: 80),
            const SizedBox(height: 24),
            Text(
              context.l10n.importCompleteTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            Text(
              context.l10n.importAccountsCreatedLabel(
                state.createdAccountsCount,
              ),
            ),
            Text(
              context.l10n.importCategoriesCreatedLabel(
                state.createdCategoriesCount,
              ),
            ),
            Text(
              context.l10n.importTransactionsImportedLabel(
                state.importedTransactionsCount,
              ),
            ),
            Text(
              context.l10n.importDuplicatesSkippedLabel(
                state.skippedDuplicatesCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
