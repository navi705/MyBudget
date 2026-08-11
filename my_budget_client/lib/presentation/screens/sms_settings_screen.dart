import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
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
    if (!AppPlatform.isAndroid) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.smsImportLabel)),
        body: Center(
          child: Text(context.l10n.smsOnlyAndroid),
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(context.l10n.smsImportLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: context.l10n.smsImportSms,
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
            Text(
              context.l10n.smsPermissionRequired,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.smsPermissionRationale,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                context.read<SmsBloc>().add(RequestSmsPermission());
              },
              child: Text(context.l10n.smsGrantPermission),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetList(BuildContext context, SmsState state) {
    if (state.presets.isEmpty) {
      return Center(
        child: Text(context.l10n.smsNoPresets),
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
        title: Text(context.l10n.smsImportSms),
        content: Text(context.l10n.smsImportDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final lastWeek = DateTime.now().subtract(const Duration(days: 7));
              context.read<SmsBloc>().add(ImportSmsMessages(since: lastWeek));
            },
            child: Text(context.l10n.smsLast7Days),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<SmsBloc>().add(const ImportSmsMessages());
            },
            child: Text(context.l10n.smsAllTime),
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
            Text(context.l10n.smsFilterLabel(preset.senderFilter)),
            const SizedBox(height: 4),
            // Leading icon, delete button and Switch leave the subtitle only
            // ~130dp; both halves below are user-named account / category text
            // of any length, so each has to be loosely flexible and ellipsised
            // or the row overflows.
            Row(
              children: [
                Flexible(
                  fit: FlexFit.loose,
                  child: BlocBuilder<AccountsBloc, AccountsState>(
                    builder: (context, accState) {
                      if (accState is AccountsLoadSuccess) {
                        final account = accState.accounts.firstWhereOrNull(
                          (a) => a.id == preset.defaultAccountId,
                        );
                        if (account != null) {
                          return BlocBuilder<StylesBloc, StylesState>(
                            builder: (context, styleState) {
                              if (styleState is StylesLoadSuccess) {
                                final style = styleState.styles
                                    .firstWhereOrNull(
                                      (s) => s.id == account.styleId,
                                    );
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (style != null)
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              end: 4,
                                            ),
                                        child: BudgetIcon(
                                          style: style,
                                          radius: 8,
                                        ),
                                      ),
                                    Flexible(
                                      child: Text(
                                        account.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                );
                              }
                              return Text(
                                account.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                Flexible(
                  fit: FlexFit.loose,
                  child: BlocBuilder<CategoriesBloc, CategoriesState>(
                    builder: (context, catState) {
                      if (catState is CategoriesLoadSuccess) {
                        final category = catState.allCategories
                            .firstWhereOrNull(
                              (c) => c.id == preset.defaultCategoryId,
                            );
                        if (category != null) {
                          return BlocBuilder<StylesBloc, StylesState>(
                            builder: (context, styleState) {
                              if (styleState is StylesLoadSuccess) {
                                final style = styleState.styles
                                    .firstWhereOrNull(
                                      (s) => s.id == category.styleId,
                                    );
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (style != null)
                                      Padding(
                                        padding:
                                            const EdgeInsetsDirectional.only(
                                              end: 4,
                                            ),
                                        child: BudgetIcon(
                                          style: style,
                                          radius: 8,
                                        ),
                                      ),
                                    Flexible(
                                      child: Text(
                                        category.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ),
                                  ],
                                );
                              }
                              return Text(
                                category.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            },
                          );
                        }
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete),
                tooltip: context.l10n.deleteButton,
                onPressed: onDelete,
              ),
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
  late List<SmsCategoryKeyword> _categoryKeywords;
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
    _categoryKeywords = List.from(widget.preset?.categoryKeywords ?? []);
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
        title: Text(isEditing ? context.l10n.smsEditPreset : context.l10n.smsNewPreset),
        actions: [
          if (!isEditing)
            TextButton(
              onPressed: () => _savePreset(pop: true),
              child: Text(context.l10n.saveButton),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.l10n.presetNameLabel,
              hintText: context.l10n.smsPresetNameHint,
            ),
            enabled: !isBuiltIn,
            onChanged: (_) {
              if (isEditing) _savePreset(pop: false);
            },
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _senderController,
            decoration: InputDecoration(
              labelText: context.l10n.smsSenderFilter,
              hintText: context.l10n.smsSenderFilterHint,
              helperText: context.l10n.smsSenderFilterHelper,
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
          _buildCategoryKeywordsSection(),
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
        Text(context.l10n.smsDefaults, style: Theme.of(context).textTheme.titleMedium),
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
                                    padding: const EdgeInsetsDirectional.only(end: 12),
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
                    decoration: InputDecoration(
                      labelText: context.l10n.smsDefaultAccount,
                      border: const OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        if (style != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 12),
                            child: BudgetIcon(style: style, radius: 12),
                          ),
                        Text(selectedAccount?.name ?? context.l10n.selectAccountTitle),
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
                                    padding: const EdgeInsetsDirectional.only(end: 12),
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
                    decoration: InputDecoration(
                      labelText: context.l10n.smsDefaultCategory,
                      border: const OutlineInputBorder(),
                    ),
                    child: Row(
                      children: [
                        if (style != null)
                          Padding(
                            padding: const EdgeInsetsDirectional.only(end: 12),
                            child: BudgetIcon(style: style, radius: 12),
                          ),
                        Text(selectedCategory?.name ?? context.l10n.selectCategoryTitle),
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
    // Category has a fallback ('other') in the bloc, so only account is required.
    final bool canImport = _selectedAccountId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.smsImportMessages,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!canImport)
              Text(
                context.l10n.smsSelectDefaultsFirst,
                style: const TextStyle(color: Colors.red, fontSize: 12),
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
              label: Text(context.l10n.smsLast7Days),
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
              label: Text(context.l10n.smsAllTime),
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
              label: Text(context.l10n.smsCustomRange),
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
                  context.l10n.smsImportSuccessCount(
                    state.createdTransactionsCount,
                  ),
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
              context.l10n.smsParsingRules,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (!isBuiltIn)
              IconButton(icon: const Icon(Icons.add), onPressed: _addRule),
          ],
        ),
        const SizedBox(height: 8),
        if (_rules.isEmpty)
          Text(context.l10n.smsNoRules)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _rules.length,
            itemBuilder: (context, index) {
              final rule = _rules[index];
              return Card(
                child: BlocBuilder<CategoriesBloc, CategoriesState>(
                  builder: (context, catState) {
                    final categories = catState is CategoriesLoadSuccess
                        ? catState.allCategories
                        : <Category>[];
                    final ruleCategory = rule.categoryId != null
                        ? categories.firstWhereOrNull(
                            (c) => c.id == rule.categoryId,
                          )
                        : null;
                    return ListTile(
                      leading: Icon(
                        rule.type == TransactionType.income
                            ? Icons.arrow_downward
                            : Icons.arrow_upward,
                        color: rule.type == TransactionType.income
                            ? Colors.green
                            : Colors.red,
                      ),
                      title: Row(
                        children: [
                          Text(rule.type.name.toUpperCase()),
                          if (ruleCategory != null) ...[
                            const Text(' • ',
                                style: TextStyle(color: Colors.grey)),
                            // Only ~184dp is left after the leading icon and
                            // the delete button; the type prefix is fixed
                            // width, so the user-named category is the part
                            // that has to give way.
                            Flexible(
                              child: Text(
                                ruleCategory.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(context.l10n.smsMatchLabel(rule.matchPattern)),
                      trailing: isBuiltIn
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: context.l10n.deleteButton,
                              onPressed: () {
                                setState(() => _rules.removeAt(index));
                                if (isEditing) _savePreset(pop: false);
                              },
                            ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  void _addRule() async {
    final categoriesState = context.read<CategoriesBloc>().state;
    final categories = categoriesState is CategoriesLoadSuccess
        ? categoriesState.allCategories
        : <Category>[];

    final rule = await DialogUtils.showAppDialog<SmsParsingRule>(
      context: context,
      resizeToAvoidBottomInset: false,
      child: SmsRuleBuilderDialog(categories: categories),
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
          SnackBar(content: Text(context.l10n.smsNameSenderRequired)),
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
      // Preserve categoryKeywords — without this they are lost from the
      // in-memory cache on every save, breaking keyword-based categorisation.
      categoryKeywords: _categoryKeywords,
    );

    context.read<SmsBloc>().add(SaveSmsPreset(preset));
    if (pop) Navigator.pop(context);
  }

  Widget _buildCategoryKeywordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.smsCategoryKeywords,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              tooltip: context.l10n.smsAddKeywordRule,
              onPressed: _showAddKeywordDialog,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.smsCategoryKeywordsSubtitle,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 8),
        if (_categoryKeywords.isEmpty)
          Text(context.l10n.smsNoKeywordRules)
        else
          BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, catState) {
              final categories = catState is CategoriesLoadSuccess
                  ? catState.allCategories
                  : <Category>[];
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categoryKeywords.length,
                itemBuilder: (context, index) {
                  final kw = _categoryKeywords[index];
                  final category = categories.firstWhereOrNull(
                    (c) => c.id == kw.categoryId,
                  );
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.label_outline),
                      title: Text(
                        '"${kw.keyword}"',
                        style: const TextStyle(fontStyle: FontStyle.italic),
                      ),
                      subtitle: Text(
                        category?.name ?? kw.categoryId,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: context.l10n.deleteButton,
                        onPressed: () {
                          setState(() => _categoryKeywords.removeAt(index));
                          if (isEditing) _savePreset(pop: false);
                        },
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

  void _showAddKeywordDialog() async {
    final catState = context.read<CategoriesBloc>().state;
    final categories = catState is CategoriesLoadSuccess
        ? catState.allCategories
        : <Category>[];

    final result = await DialogUtils.showAppDialog<SmsCategoryKeyword>(
      context: context,
      resizeToAvoidBottomInset: true,
      child: _KeywordRuleDialog(categories: categories),
    );

    if (result != null) {
      setState(() => _categoryKeywords.add(result));
      if (isEditing) _savePreset(pop: false);
    }
  }
}

class _KeywordRuleDialog extends StatefulWidget {
  final List<Category> categories;

  const _KeywordRuleDialog({required this.categories});

  @override
  State<_KeywordRuleDialog> createState() => _KeywordRuleDialogState();
}

class _KeywordRuleDialogState extends State<_KeywordRuleDialog> {
  final _keywordController = TextEditingController();
  String? _selectedCategoryId;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.smsAddKeywordRule),
      // The dialog is shown with resizeToAvoidBottomInset, and the keyword
      // field autofocuses, so the keyboard is up the moment it opens and the
      // available height drops below this Column's ~150dp minimum. Scrolling
      // the content keeps both fields reachable, matching SmsRuleBuilderDialog.
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _keywordController,
              decoration: InputDecoration(
                labelText: context.l10n.smsKeyword,
                hintText: context.l10n.smsKeywordHint,
                helperText: context.l10n.smsKeywordHelper,
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategoryId,
              // Without isExpanded the item is measured against unbounded
              // width next to the arrow, so a long category name overflows
              // the field instead of being clipped to it.
              isExpanded: true,
              decoration: InputDecoration(
                labelText: context.l10n.categoryLabel,
                border: const OutlineInputBorder(),
              ),
              hint: Text(context.l10n.smsSelectCategoryHint),
              items: widget.categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _selectedCategoryId == null ||
                  _keywordController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.pop(
                    context,
                    SmsCategoryKeyword(
                      keyword: _keywordController.text.trim(),
                      categoryId: _selectedCategoryId!,
                    ),
                  );
                },
          child: Text(context.l10n.saveButton),
        ),
      ],
    );
  }
}
