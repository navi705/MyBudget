import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/presentation/widgets/scaffold_with_escape_back.dart';

class HotKeysScreen extends StatelessWidget {
  const HotKeysScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return EscapeBackHandler(
      child: Scaffold(
        appBar: AppBar(title: const Text('Hot Keys')),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            final hotkeys = state.hotkeys;

            // Define available actions here
            final actions = [
              {'id': 'back', 'label': 'Global: Go Back / Exit'},
              {'id': 'dashboard', 'label': 'Navigation: Go to Dashboard'},
              {'id': 'accounts', 'label': 'Navigation: Go to Accounts'},
              {'id': 'transactions', 'label': 'Navigation: Go to Transactions'},
              {'id': 'categories', 'label': 'Navigation: Go to Categories'},
              {
                'id': 'data',
                'label': 'Navigation: Go to Data / Exchange Rates',
              },
              {'id': 'settings', 'label': 'Navigation: Go to Settings'},

              {'id': 'dashboard_tab_1', 'label': 'Dashboard: Calendar Tab'},
              {'id': 'dashboard_tab_2', 'label': 'Dashboard: Categories Tab'},
              {'id': 'dashboard_tab_3', 'label': 'Dashboard: Balance Tab'},

              {
                'id': 'add_transaction',
                'label': 'Transactions: Add Transaction',
              },
              {'id': 'prev_period', 'label': 'Period: Previous Period'},
              {'id': 'next_period', 'label': 'Period: Next Period'},

              {'id': 'add_account', 'label': 'Accounts: Add Account'},
              {'id': 'filter_accounts', 'label': 'Accounts: Toggle Filter'},
              {'id': 'accounts_pick_date', 'label': 'Accounts: Select Date'},
              {'id': 'accounts_sort', 'label': 'Accounts: Toggle Sort'},
              {
                'id': 'accounts_curr_select',
                'label': 'Accounts: Select Currencies',
              },
              {
                'id': 'accounts_selection_close',
                'label': 'Accounts: Close Selection',
              },
              {'id': 'accounts_selection_all', 'label': 'Accounts: Select All'},
              {
                'id': 'accounts_selection_delete',
                'label': 'Accounts: Delete Selected',
              },
              {
                'id': 'accounts_selection_change_type',
                'label': 'Accounts: Change Selected Type',
              },

              {'id': 'add_category', 'label': 'Categories: Add Category'},
              {'id': 'filter_categories', 'label': 'Categories: Toggle Filter'},
              {
                'id': 'categories_pick_date',
                'label': 'Categories: Select Date',
              },
              {'id': 'categories_sort', 'label': 'Categories: Toggle Sort'},
              {
                'id': 'categories_selection_close',
                'label': 'Categories: Close Selection',
              },
              {
                'id': 'categories_selection_all',
                'label': 'Categories: Select All',
              },
              {
                'id': 'categories_selection_delete',
                'label': 'Categories: Delete Selected',
              },
              {
                'id': 'categories_selection_change_type',
                'label': 'Categories: Change Selected Type',
              },

              {'id': 'add_exchange_rate', 'label': 'Data: Add Exchange Rate'},
              {'id': 'filter_exchange_rates', 'label': 'Data: Toggle Filter'},
              {'id': 'exchange_rates_pick_date', 'label': 'Data: Select Date'},
              {'id': 'exchange_rates_sort', 'label': 'Data: Toggle Sort'},
              {
                'id': 'exchange_rates_selection_close',
                'label': 'Data: Close Selection',
              },
              {
                'id': 'exchange_rates_selection_all',
                'label': 'Data: Select All',
              },
              {
                'id': 'exchange_rates_selection_delete',
                'label': 'Data: Delete Selected',
              },
              {
                'id': 'exchange_rates_selection_change_preset',
                'label': 'Data: Change Selected Preset',
              },

              {'id': 'add_inflation_rate', 'label': 'Inflation: Add Rate'},
              {'id': 'inflation_pick_date', 'label': 'Inflation: Select Date'},
              {'id': 'inflation_sort', 'label': 'Inflation: Toggle Sort'},
              {
                'id': 'inflation_selection_all',
                'label': 'Inflation: Select All',
              },
              {
                'id': 'inflation_selection_delete',
                'label': 'Inflation: Delete Selected',
              },

              {'id': 'add_asset', 'label': 'Assets: Add Asset'},
              {'id': 'asset_pick_date', 'label': 'Assets: Select Date'},
              {'id': 'asset_sort', 'label': 'Assets: Toggle Sort'},
              {'id': 'asset_selection_all', 'label': 'Assets: Select All'},
              {
                'id': 'asset_selection_delete',
                'label': 'Assets: Delete Selected',
              },

              {'id': 'api_fetch_rates', 'label': 'API: Fetch Exchange Rates'},
              {'id': 'api_fetch_steam', 'label': 'API: Fetch Steam Inventory'},
              {
                'id': 'api_fetch_inflation',
                'label': 'API: Fetch Inflation Data',
              },

              {'id': 'settings_icons', 'label': 'Settings: Manage Icons'},
              {'id': 'settings_theme', 'label': 'Settings: Manage Theme'},
              {'id': 'settings_currency', 'label': 'Settings: Main Currency'},
              {
                'id': 'settings_country',
                'label': 'Settings: Inflation Country',
              },
              {'id': 'settings_hotkeys', 'label': 'Settings: Hot Keys'},
              {
                'id': 'settings_persist_filters',
                'label': 'Settings: Persist Filters',
              },
              {'id': 'settings_import', 'label': 'Settings: Import Data'},
              {
                'id': 'settings_import_rates',
                'label': 'Settings: Import Rates',
              },
              {'id': 'settings_export', 'label': 'Settings: Export Data'},
              {'id': 'settings_api', 'label': 'Settings: API Management'},
              {'id': 'settings_reset', 'label': 'Settings: Reset Data'},
            ];

            return ListView.separated(
              itemCount: actions.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final action = actions[index];
                final id = action['id']!;
                final label = action['label']!;
                final currentKeyString = hotkeys[id] ?? '';
                final displayString = currentKeyString.isEmpty
                    ? 'None'
                    : HotKeyUtils.getDisplayString(currentKeyString);

                return ListTile(
                  title: Text(label),
                  subtitle: Text(displayString),
                  trailing: const Icon(Icons.keyboard),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => HotKeyRecorderDialog(
                        actionId: id,
                        actionLabel: label,
                        currentKey: currentKeyString,
                      ),
                    );
                  },
                );
              },
            );
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

  const HotKeyRecorderDialog({
    required this.actionId,
    required this.actionLabel,
    required this.currentKey,
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
      // _tempKeyString = 'Press keys...';
      // Keep showing press keys prompt or show nothing?
      // When keys are released, we might still be in dialog if it was just modifiers released without trigger.
      _tempKeyString = 'Press keys...';
    } else {
      final serialized = HotKeyUtils.serializeKeys(_pressedKeys);
      _tempKeyString = HotKeyUtils.getDisplayString(serialized);
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
