import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';

class HotKeysScreen extends StatefulWidget {
  const HotKeysScreen({super.key});

  @override
  State<HotKeysScreen> createState() => _HotKeysScreenState();
}

class _HotKeysScreenState extends State<HotKeysScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EscapeBackHandler(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hot Keys'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search hotkeys...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  filled: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final hotkeys = state.hotkeys;

            // Define available actions categorized
            final categories = {
              'Navigation': [
                {'id': 'back', 'label': 'Global: Go Back / Exit'},
                {'id': 'dashboard', 'label': 'Go to Dashboard'},
                {'id': 'accounts', 'label': 'Go to Accounts'},
                {'id': 'transactions', 'label': 'Go to Transactions'},
                {'id': 'categories', 'label': 'Go to Categories'},
                {'id': 'data', 'label': 'Go to Data / Exchange Rates'},
                {'id': 'settings', 'label': 'Go to Settings'},
              ],
              'Dashboard Tabs (Ctrl + 1/2/3)': [
                {'id': 'dashboard_tab_1', 'label': 'Calendar Tab'},
                {'id': 'dashboard_tab_2', 'label': 'Categories Tab'},
                {'id': 'dashboard_tab_3', 'label': 'Balance Tab'},
              ],
              'Data Tabs (Ctrl + 1/2/3)': [
                {'id': 'data_tab_1', 'label': 'Exchange Rates'},
                {'id': 'data_tab_2', 'label': 'Inflation'},
                {'id': 'data_tab_3', 'label': 'Assets'},
              ],
              'Period Control': [
                {'id': 'prev_period', 'label': 'Previous Period'},
                {'id': 'next_period', 'label': 'Next Period'},
              ],
              'Actions': [
                {'id': 'add_action', 'label': 'Generic Add Action'},
              ],
              'Selection Mode': [
                {'id': 'accounts_selection_close', 'label': 'Accounts: Close'},
                {
                  'id': 'accounts_selection_all',
                  'label': 'Accounts: Select All',
                },
                {
                  'id': 'accounts_selection_delete',
                  'label': 'Accounts: Delete',
                },
                {
                  'id': 'accounts_selection_change_type',
                  'label': 'Accounts: Change Type',
                },
                {
                  'id': 'categories_selection_close',
                  'label': 'Categories: Close',
                },
                {
                  'id': 'categories_selection_all',
                  'label': 'Categories: Select All',
                },
                {
                  'id': 'categories_selection_delete',
                  'label': 'Categories: Delete',
                },
                {
                  'id': 'categories_selection_change_type',
                  'label': 'Categories: Change Type',
                },
                {
                  'id': 'exchange_rates_selection_close',
                  'label': 'Data: Close',
                },
                {
                  'id': 'exchange_rates_selection_all',
                  'label': 'Data: Select All',
                },
                {
                  'id': 'exchange_rates_selection_delete',
                  'label': 'Data: Delete',
                },
                {
                  'id': 'exchange_rates_selection_change_preset',
                  'label': 'Data: Change Preset',
                },
              ],
            };

            final listItems = <Widget>[];

            categories.forEach((categoryName, actions) {
              final filteredActions = actions.where((a) {
                final label = a['label']!.toLowerCase();
                final query = _searchQuery.toLowerCase();
                return label.contains(query) ||
                    categoryName.toLowerCase().contains(query);
              }).toList();

              if (filteredActions.isNotEmpty) {
                listItems.add(
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      categoryName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                );

                for (var action in filteredActions) {
                  final id = action['id']!;
                  final label = action['label']!;
                  final currentKeyString = hotkeys[id] ?? '';
                  final displayString = currentKeyString.isEmpty
                      ? 'None'
                      : HotKeyUtils.getDisplayString(currentKeyString);

                  // Check for duplicates (informational)
                  final isDuplicate = hotkeys.entries.any(
                    (e) =>
                        e.value == currentKeyString &&
                        e.key != id &&
                        currentKeyString.isNotEmpty,
                  );

                  listItems.add(
                    ListTile(
                      title: Text(label),
                      subtitle: Text(
                        displayString,
                        style: TextStyle(
                          color: isDuplicate ? Colors.red : null,
                        ),
                      ),
                      trailing: isDuplicate
                          ? const Tooltip(
                              message: 'Duplicate Hotkey',
                              child: Icon(Icons.warning, color: Colors.orange),
                            )
                          : const Icon(Icons.keyboard),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => HotKeyRecorderDialog(
                            actionId: id,
                            actionLabel: label,
                            currentKey: currentKeyString,
                            allHotkeys: hotkeys,
                          ),
                        );
                      },
                    ),
                  );
                }
                listItems.add(const Divider());
              }
            });

            if (listItems.isEmpty) {
              return const Center(child: Text('No matching hotkeys found.'));
            }

            return ListView(children: listItems);
          },
        ),
      ),
    );
  }
}

class HotKeyRecorderDialog extends StatefulWidget {
  final String actionId;
  final String actionLabel;
  final String currentKey;
  final Map<String, String> allHotkeys;

  const HotKeyRecorderDialog({
    required this.actionId,
    required this.actionLabel,
    required this.currentKey,
    required this.allHotkeys,
    super.key,
  });

  @override
  State<HotKeyRecorderDialog> createState() => _HotKeyRecorderDialogState();
}

class _HotKeyRecorderDialogState extends State<HotKeyRecorderDialog> {
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};
  String _tempKeyString = 'Press keys...';

  @override
  void initState() {
    super.initState();
    // Request focus immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (!_pressedKeys.contains(event.logicalKey)) {
        setState(() {
          _pressedKeys.add(event.logicalKey);
          _updateDisplay();
        });
      }
    } else if (event is KeyUpEvent) {
      // Logic: If a non-modifier key is released, we consider the combination complete.
      if (!_isModifier(event.logicalKey)) {
        // Construct final string
        final finalString = HotKeyUtils.serializeKeys(_pressedKeys);
        if (finalString.isNotEmpty) {
          _saveAndClose(finalString);
        }
      }

      setState(() {
        _pressedKeys.remove(event.logicalKey);
        _updateDisplay();
      });
    } else if (event is KeyRepeatEvent) {
      // Treat repeat as down if not present
      if (!_pressedKeys.contains(event.logicalKey)) {
        _pressedKeys.add(event.logicalKey);
        _updateDisplay();
      }
    }
  }

  bool _isModifier(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight ||
        key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight;
  }

  void _updateDisplay() {
    if (_pressedKeys.isEmpty) {
      _tempKeyString = 'Press keys...';
    } else {
      final serialized = HotKeyUtils.serializeKeys(_pressedKeys);
      final display = HotKeyUtils.getDisplayString(serialized);

      // Check if this new sequence is used elsewhere
      final duplicateId = widget.allHotkeys.entries
          .where((e) => e.value == serialized && e.key != widget.actionId)
          .map((e) => e.key)
          .firstOrNull;

      if (duplicateId != null) {
        _tempKeyString = '$display\n(Used by $duplicateId)';
      } else {
        _tempKeyString = display;
      }
    }
  }

  void _saveAndClose(String keyString) {
    context.read<SettingsBloc>().add(UpdateHotkey(widget.actionId, keyString));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Recording Hotkey for "${widget.actionLabel}"',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _tempKeyString,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Press any key combination.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Focus(
              focusNode: _focusNode,
              onKeyEvent: (node, event) {
                // Determine if we should handle this event
                // If it's pure Escape (without modifiers), we might want to let it close dialog?
                // But user might want to bind Escape.
                // We'll rely on "Cancel" button for cancelling, and let user bind Escape.
                _handleKeyEvent(event);
                return KeyEventResult.handled;
              },
              child: const SizedBox(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Manual save if needed (e.g. if they just pressed modifiers and clicked save? unlikely)
                    if (_pressedKeys.isNotEmpty) {
                      final finalString = HotKeyUtils.serializeKeys(
                        _pressedKeys,
                      );
                      _saveAndClose(finalString);
                    } else {
                      // Clear hotkey?
                      _saveAndClose('');
                    }
                  },
                  child: const Text('Clear / Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
