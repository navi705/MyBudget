import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/widgets/budget_icon.dart';
import 'package:my_budget_client/presentation/widgets/sms_rule_builder_dialog.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';

class SmsSettingsScreen extends StatelessWidget {
  const SmsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Only available on Android
    if (!Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(title: const Text('SMS Import')),
        body: const Center(
          child: Text('SMS import is only available on Android'),
        ),
      );
    }

    return BlocProvider(
      create: (context) => sl<SmsBloc>()..add(LoadSmsPresets()),
      child: const _SmsSettingsContent(),
    );
  }
}

class _SmsSettingsContent extends StatelessWidget {
  const _SmsSettingsContent();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Import'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Import SMS',
            onPressed: () => _showImportDialog(context),
          ),
        ],
      ),
      body: BlocBuilder<SmsBloc, SmsState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!state.hasPermission) {
            return _buildPermissionRequest(context);
          }

          return _buildPresetList(context, state);
        },
      ),
      floatingActionButton: BlocBuilder<SmsBloc, SmsState>(
        builder: (context, state) {
          if (!state.hasPermission) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () => _showPresetEditor(context, null),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  Widget _buildPermissionRequest(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sms, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'SMS Permission Required',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'To import transactions from SMS, we need permission to read your messages.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                context.read<SmsBloc>().add(RequestSmsPermission());
              },
              child: const Text('Grant Permission'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetList(BuildContext context, SmsState state) {
    if (state.presets.isEmpty) {
      return const Center(
        child: Text('No presets configured. Tap + to add one.'),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<AccountsBloc>()..add(LoadAccounts()),
        ),
        BlocProvider(
          create: (context) => sl<CategoriesBloc>()..add(LoadCategories()),
        ),
        BlocProvider(create: (context) => sl<StylesBloc>()..add(LoadStyles())),
      ],
      child: ListView.builder(
        itemCount: state.presets.length,
        itemBuilder: (context, index) {
          final preset = state.presets[index];
          return _PresetCard(
            preset: preset,
            onToggle: (enabled) {
              context.read<SmsBloc>().add(ToggleSmsPreset(preset.id, enabled));
            },
            onEdit: () => _showPresetEditor(context, preset),
            onDelete: preset.isBuiltIn
                ? null
                : () {
                    context.read<SmsBloc>().add(DeleteSmsPreset(preset.id));
                  },
          );
        },
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    DialogUtils.showAppDialog(
      context: context,
      resizeToAvoidBottomInset: false,
      child: AlertDialog(
        title: const Text('Import SMS'),
        content: const Text(
          'Import transactions from SMS messages. Choose a time range:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final lastWeek = DateTime.now().subtract(const Duration(days: 7));
              context.read<SmsBloc>().add(ImportSmsMessages(since: lastWeek));
            },
            child: const Text('Last 7 Days'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SmsBloc>().add(const ImportSmsMessages());
            },
            child: const Text('All Time'),
          ),
        ],
      ),
    );
  }

  void _showPresetEditor(BuildContext context, SmsPreset? preset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (routeContext) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<SmsBloc>()),
            BlocProvider(
              create: (context) => sl<AccountsBloc>()..add(LoadAccounts()),
            ),
            BlocProvider(
              create: (context) => sl<CategoriesBloc>()..add(LoadCategories()),
            ),
            BlocProvider(
              create: (context) => sl<StylesBloc>()..add(LoadStyles()),
            ),
          ],
          child: SmsPresetEditorScreen(preset: preset),
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final SmsPreset preset;
  final ValueChanged<bool> onToggle;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _PresetCard({
    required this.preset,
    required this.onToggle,
    required this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(
          preset.isBuiltIn ? Icons.verified : Icons.person,
          color: preset.isEnabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey,
        ),
        title: Text(preset.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter: ${preset.senderFilter}'),
            const SizedBox(height: 4),
            Row(
              children: [
                BlocBuilder<AccountsBloc, AccountsState>(
                  builder: (context, accState) {
                    if (accState is AccountsLoadSuccess) {
                      final account = accState.accounts.firstWhereOrNull(
                        (a) => a.id == preset.defaultAccountId,
                      );
                      if (account != null) {
                        return BlocBuilder<StylesBloc, StylesState>(
                          builder: (context, styleState) {
                            if (styleState is StylesLoadSuccess) {
                              final style = styleState.styles.firstWhereOrNull(
                                (s) => s.id == account.styleId,
                              );
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (style != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: BudgetIcon(
                                        style: style,
                                        radius: 8,
                                      ),
                                    ),
                                  Text(
                                    account.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              );
                            }
                            return Text(account.name);
                          },
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
                BlocBuilder<CategoriesBloc, CategoriesState>(
                  builder: (context, catState) {
                    if (catState is CategoriesLoadSuccess) {
                      final category = catState.allCategories.firstWhereOrNull(
                        (c) => c.id == preset.defaultCategoryId,
                      );
                      if (category != null) {
                        return BlocBuilder<StylesBloc, StylesState>(
                          builder: (context, styleState) {
                            if (styleState is StylesLoadSuccess) {
                              final style = styleState.styles.firstWhereOrNull(
                                (s) => s.id == category.styleId,
                              );
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (style != null)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 4),
                                      child: BudgetIcon(
                                        style: style,
                                        radius: 8,
                                      ),
                                    ),
                                  Text(
                                    category.name,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              );
                            }
                            return Text(category.name);
                          },
                        );
                      }
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
            Switch(value: preset.isEnabled, onChanged: onToggle),
          ],
        ),
        onTap: onEdit,
      ),
    );
  }
}

class SmsPresetEditorScreen extends StatefulWidget {
  final SmsPreset? preset;

  const SmsPresetEditorScreen({super.key, this.preset});

  @override
  State<SmsPresetEditorScreen> createState() => _SmsPresetEditorScreenState();
}

class _SmsPresetEditorScreenState extends State<SmsPresetEditorScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _senderController;
  late List<SmsParsingRule> _rules;
  String? _selectedAccountId;
  String? _selectedCategoryId;

  bool get isEditing => widget.preset != null;
  bool get isBuiltIn => widget.preset?.isBuiltIn ?? false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _senderController = TextEditingController(
      text: widget.preset?.senderFilter ?? '',
    );
    _rules = List.from(widget.preset?.rules ?? []);
    _selectedAccountId = widget.preset?.defaultAccountId;
    _selectedCategoryId = widget.preset?.defaultCategoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _senderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Preset' : 'New Preset'),
        actions: [
          if (!isEditing)
            TextButton(
              onPressed: () => _savePreset(pop: true),
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Preset Name',
              hintText: 'e.g., My Bank',
            ),
            enabled: !isBuiltIn,
            onChanged: (_) {
              if (isEditing) _savePreset(pop: false);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _senderController,
            decoration: const InputDecoration(
              labelText: 'Sender Filter',
              hintText: 'e.g., ALTA or +381...',
              helperText: 'Filter SMS by sender name or phone number',
            ),
            enabled: !isBuiltIn,
            onChanged: (_) {
              if (isEditing) _savePreset(pop: false);
            },
          ),
          const SizedBox(height: 24),
          _buildDefaultsSection(),
          const SizedBox(height: 24),
          _buildRulesSection(),
          const SizedBox(height: 24),
          if (isEditing) ...[_buildImportSection(), const SizedBox(height: 24)],
        ],
      ),
    );
  }

  Widget _buildDefaultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Defaults', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        BlocBuilder<AccountsBloc, AccountsState>(
          builder: (context, state) {
            final accounts = state is AccountsLoadSuccess
                ? state.accounts
                : <Account>[];
            final selectedAccount = accounts.firstWhereOrNull(
              (a) => a.id == _selectedAccountId,
            );

            return BlocBuilder<StylesBloc, StylesState>(
              builder: (context, styleState) {
                Style? style;
                if (styleState is StylesLoadSuccess &&
                    selectedAccount != null) {
                  style = styleState.styles.firstWhereOrNull(
                    (s) => s.id == selectedAccount.styleId,
                  );
                }

                return InkWell(
                  onTap: () async {
                    final account = await showSingleSelectDialog<Account>(
                      context: context,
                      items: accounts,
                      title: context.l10n.selectAccountTitle,
                      selectedItem: selectedAccount,
                      itemBuilder: (account) => Row(
                        children: [
                          BlocBuilder<StylesBloc, StylesState>(
                            builder: (context, state) {
                              if (state is StylesLoadSuccess) {
                                final s = state.styles.firstWhereOrNull(
                                  (s) => s.id == account.styleId,
                                );
                                if (s != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: BudgetIcon(style: s, radius: 12),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          Text(account.name),
                        ],
                      ),
                      stringGetter: (account) => account.name,
                    );

                    if (account != null) {
                      setState(() => _selectedAccountId = account.id);
                      if (isEditing) _savePreset(pop: false);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Default Account',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        if (style != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: BudgetIcon(style: style, radius: 12),
                          ),
                        Text(selectedAccount?.name ?? 'Select Account'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            final categories = state is CategoriesLoadSuccess
                ? state.allCategories
                : <Category>[];
            final selectedCategory = categories.firstWhereOrNull(
              (c) => c.id == _selectedCategoryId,
            );

            return BlocBuilder<StylesBloc, StylesState>(
              builder: (context, styleState) {
                Style? style;
                if (styleState is StylesLoadSuccess &&
                    selectedCategory != null) {
                  style = styleState.styles.firstWhereOrNull(
                    (s) => s.id == selectedCategory.styleId,
                  );
                }

                return InkWell(
                  onTap: () async {
                    final category = await showSingleSelectDialog<Category>(
                      context: context,
                      items: categories,
                      title: context.l10n.selectCategoryTitle,
                      selectedItem: selectedCategory,
                      itemBuilder: (category) => Row(
                        children: [
                          BlocBuilder<StylesBloc, StylesState>(
                            builder: (context, state) {
                              if (state is StylesLoadSuccess) {
                                final s = state.styles.firstWhereOrNull(
                                  (s) => s.id == category.styleId,
                                );
                                if (s != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: BudgetIcon(style: s, radius: 12),
                                  );
                                }
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                          Text(category.name),
                        ],
                      ),
                      stringGetter: (category) => category.name,
                    );

                    if (category != null) {
                      setState(() => _selectedCategoryId = category.id);
                      if (isEditing) _savePreset(pop: false);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Default Category',
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        if (style != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: BudgetIcon(style: style, radius: 12),
                          ),
                        Text(selectedCategory?.name ?? 'Select Category'),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildImportSection() {
    final bool canImport =
        _selectedAccountId != null && _selectedCategoryId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Import Messages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!canImport)
              const Text(
                'Select defaults first',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: !canImport
                  ? null
                  : () {
                      final since = DateTime.now().subtract(
                        const Duration(days: 7),
                      );
                      context.read<SmsBloc>().add(
                        ImportSmsWithPreset(
                          presetId: widget.preset!.id,
                          since: since,
                        ),
                      );
                    },
              icon: const Icon(Icons.calendar_view_week),
              label: const Text('Last 7 Days'),
            ),
            FilledButton.tonalIcon(
              onPressed: !canImport
                  ? null
                  : () {
                      context.read<SmsBloc>().add(
                        ImportSmsWithPreset(presetId: widget.preset!.id),
                      );
                    },
              icon: const Icon(Icons.all_inclusive),
              label: const Text('All Time'),
            ),
            FilledButton.icon(
              onPressed: !canImport
                  ? null
                  : () async {
                      final range = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (range != null && mounted) {
                        context.read<SmsBloc>().add(
                          ImportSmsWithPreset(
                            presetId: widget.preset!.id,
                            since: range.start,
                            until: range.end,
                          ),
                        );
                      }
                    },
              icon: const Icon(Icons.date_range),
              label: const Text('Custom Range'),
            ),
          ],
        ),
        BlocBuilder<SmsBloc, SmsState>(
          builder: (context, state) {
            if (state.isImporting) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              );
            }
            if (state.createdTransactionsCount > 0) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  'Success: ${state.createdTransactionsCount} transactions imported',
                  style: const TextStyle(color: Colors.green),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildRulesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Parsing Rules',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!isBuiltIn)
              IconButton(icon: const Icon(Icons.add), onPressed: _addRule),
          ],
        ),
        const SizedBox(height: 8),
        if (_rules.isEmpty)
          const Text('No rules defined. Tap + to add one.')
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rules.length,
            itemBuilder: (context, index) {
              final rule = _rules[index];
              return Card(
                child: ListTile(
                  leading: Icon(
                    rule.type == TransactionType.income
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: rule.type == TransactionType.income
                        ? Colors.green
                        : Colors.red,
                  ),
                  title: Text(rule.type.name.toUpperCase()),
                  subtitle: Text('Match: ${rule.matchPattern}'),
                  trailing: isBuiltIn
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() => _rules.removeAt(index));
                            if (isEditing) _savePreset(pop: false);
                          },
                        ),
                ),
              );
            },
          ),
      ],
    );
  }

  void _addRule() async {
    final rule = await DialogUtils.showAppDialog<SmsParsingRule>(
      context: context,
      resizeToAvoidBottomInset: false,
      child: const SmsRuleBuilderDialog(),
    );
    if (rule != null) {
      setState(() => _rules.add(rule));
      if (isEditing) _savePreset(pop: false);
    }
  }

  void _savePreset({bool pop = true}) {
    if (_nameController.text.isEmpty || _senderController.text.isEmpty) {
      if (pop) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and sender filter are required')),
        );
      }
      return;
    }

    final preset = SmsPreset(
      id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      senderFilter: _senderController.text,
      isBuiltIn: isBuiltIn,
      isEnabled: widget.preset?.isEnabled ?? true,
      defaultAccountId: _selectedAccountId,
      defaultCategoryId: _selectedCategoryId,
      rules: _rules,
    );

    context.read<SmsBloc>().add(SaveSmsPreset(preset));
    if (pop) Navigator.pop(context);
  }
}
