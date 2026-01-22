import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Category, Currency, Style;
import 'package:my_budget_client/core/services/data_import_service.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/import/import_bloc.dart';
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
    FilePickerResult? result;
    List<String>? pickedPaths;

    if (Platform.isAndroid) {
      pickedPaths = await sl<AndroidFilePickerService>().pickFile(
        mimeType: '*/*',
        title: context.l10n.filePickerChooserTitle,
        allowMultiple: true,
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: true,
      );
      if (result != null) {
        pickedPaths = result.paths.whereType<String>().toList();
      }
    }

    if (pickedPaths != null && pickedPaths.isNotEmpty) {
      final csvFiles = pickedPaths.map((path) => File(path)).toList();

      // Basic validation: Check if file names look like OneMoney exports
      // Typically: "OneMoney-2023-10-27.csv"
      bool allValid = true;
      for (final file in csvFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        // Simple check: ends with .csv
        if (!fileName.toLowerCase().endsWith('.csv')) {
          allValid = false;
          break;
        }
      }

      if (!allValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.selectAccountError,
              ), // Using selectAccountError as a fallback or I should add a specific one
            ),
          );
        }
        return;
      }

      if (!mounted) return;
      context.read<ImportBloc>().add(StartImportProcess(csvFiles));
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
      final db = sl<AppDatabase>();
      final androidPicker = sl<AndroidFilePickerService>();
      final service = DataImportService(db, androidPicker);
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final existingAccounts =
                                  await sl<AccountRepository>().getAccounts();
                              if (!context.mounted) return;
                              final selectedId = await showDialog<String>(
                                context: context,
                                builder: (_) => _MappingDialog<Account>(
                                  title: context.l10n.importMapAccountTitle(
                                    accountName,
                                  ),
                                  items: existingAccounts,
                                  itemNameProvider: (account) => account.name,
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

                                    Color color = Colors.grey;
                                    try {
                                      String hex = style.colorHex.replaceAll(
                                        '#',
                                        '',
                                      );
                                      if (hex.length == 6) hex = 'FF$hex';
                                      color = Color(int.parse('0x$hex'));
                                    } catch (_) {}

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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final existingCategories =
                                  await sl<CategoryRepository>()
                                      .getCategories();
                              if (!context.mounted) return;
                              final selectedId = await showDialog<String>(
                                context: context,
                                builder: (_) => _MappingDialog<Category>(
                                  title: context.l10n.importMapCategoryTitle(
                                    categoryName,
                                  ),
                                  items: existingCategories,
                                  itemNameProvider: (category) => category.name,
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

                                    Color color = Colors.grey;
                                    try {
                                      String hex = style.colorHex.replaceAll(
                                        '#',
                                        '',
                                      );
                                      if (hex.length == 6) hex = 'FF$hex';
                                      color = Color(int.parse('0x$hex'));
                                    } catch (_) {}

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
                          const SizedBox(width: 8),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () async {
                              final existingCurrencies =
                                  await sl<CurrencyRepository>()
                                      .getCurrencies();
                              if (!context.mounted) return;
                              final selectedId = await showDialog<String>(
                                context: context,
                                builder: (_) => _MappingDialog<Currency>(
                                  title: context.l10n.importMapCurrencyTitle(
                                    currencyName,
                                  ),
                                  items: existingCurrencies,
                                  itemNameProvider: (currency) => currency.name,
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
                          const SizedBox(width: 8),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {
                                context.read<ImportBloc>().add(
                                  ResolveDuplicate(record, 'skip'),
                                );
                              },
                              child: Text(context.l10n.importSkip),
                            ),
                            const SizedBox(width: 8),
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
                            context.l10n.importDecisionLabel(
                              resolution.toUpperCase(),
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

class _MappingDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final String Function(T) itemNameProvider;

  const _MappingDialog({
    required this.title,
    required this.items,
    required this.itemBuilder,
    required this.itemNameProvider,
  });

  @override
  State<_MappingDialog<T>> createState() => _MappingDialogState<T>();
}

class _MappingDialogState<T> extends State<_MappingDialog<T>> {
  late TextEditingController _searchController;
  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return widget.itemNameProvider(item).toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    title: widget.itemBuilder(item),
                    onTap: () {
                      Navigator.of(context).pop((item as dynamic).id);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancelButton),
        ),
      ],
    );
  }
}
