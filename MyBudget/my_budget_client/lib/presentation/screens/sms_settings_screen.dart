import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';
import 'package:my_budget_client/presentation/widgets/sms_rule_builder_dialog.dart';

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

    return ListView.builder(
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
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Import SMS'),
        content: const Text(
          'Import transactions from SMS messages. Choose a time range:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              final lastWeek = DateTime.now().subtract(const Duration(days: 7));
              context.read<SmsBloc>().add(ImportSmsMessages(since: lastWeek));
            },
            child: const Text('Last 7 Days'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
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
        builder: (routeContext) => BlocProvider.value(
          value: context.read<SmsBloc>(),
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
        subtitle: Text('Filter: ${preset.senderFilter}'),
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
  late final TextEditingController _testSmsController;
  late List<SmsParsingRule> _rules;

  bool get isEditing => widget.preset != null;
  bool get isBuiltIn => widget.preset?.isBuiltIn ?? false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? '');
    _senderController = TextEditingController(
      text: widget.preset?.senderFilter ?? '',
    );
    _testSmsController = TextEditingController();
    _rules = List.from(widget.preset?.rules ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _senderController.dispose();
    _testSmsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Preset' : 'New Preset'),
        actions: [
          if (!isBuiltIn)
            IconButton(icon: const Icon(Icons.save), onPressed: _savePreset),
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
          ),
          const SizedBox(height: 24),
          _buildRulesSection(),
          const SizedBox(height: 24),
          _buildTestSection(),
        ],
      ),
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
                          },
                        ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTestSection() {
    return BlocBuilder<SmsBloc, SmsState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Parsing',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _testSmsController,
              decoration: const InputDecoration(
                labelText: 'Paste SMS text here',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _testParsing, child: const Text('Test')),
            if (state.testResult != null) ...[
              const SizedBox(height: 16),
              Card(
                color: state.testResult!.isMatch
                    ? Colors.green.withAlpha(30)
                    : Colors.red.withAlpha(30),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: state.testResult!.isMatch
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '✓ Match found!',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Type: ${state.testResult!.type?.name}'),
                            Text(
                              'Amount: ${state.testResult!.amount?.toStringAsFixed(2)}',
                            ),
                            Text(
                              'Currency: ${state.testResult!.currencyCode ?? 'N/A'}',
                            ),
                          ],
                        )
                      : Text(
                          '✗ No match',
                          style: TextStyle(
                            color: Colors.red[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _addRule() async {
    final rule = await showDialog<SmsParsingRule>(
      context: context,
      builder: (context) => const SmsRuleBuilderDialog(),
    );
    if (rule != null) {
      setState(() => _rules.add(rule));
    }
  }

  void _testParsing() {
    if (_testSmsController.text.isEmpty || _rules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter SMS text and add at least one rule'),
        ),
      );
      return;
    }

    context.read<SmsBloc>().add(
      TestSmsRule(_testSmsController.text, _rules.first),
    );
  }

  void _savePreset() {
    if (_nameController.text.isEmpty || _senderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and sender filter are required')),
      );
      return;
    }

    final preset = SmsPreset(
      id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      senderFilter: _senderController.text,
      isBuiltIn: false,
      isEnabled: widget.preset?.isEnabled ?? true,
      defaultAccountId: widget.preset?.defaultAccountId,
      defaultCategoryId: widget.preset?.defaultCategoryId,
      rules: _rules,
    );

    context.read<SmsBloc>().add(SaveSmsPreset(preset));
    Navigator.pop(context);
  }
}
