import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
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
          title: Text(context.l10n.hotKeysTitle),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: context.l10n.searchHotkeysHint,
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
              context.l10n.hkCategoryNavigation: [
                {'id': 'back', 'label': context.l10n.hkActionBack},
                {'id': 'dashboard', 'label': context.l10n.hkActionDashboard},
                {'id': 'accounts', 'label': context.l10n.hkActionAccounts},
                {
                  'id': 'transactions',
                  'label': context.l10n.hkActionTransactions,
                },
                {'id': 'categories', 'label': context.l10n.hkActionCategories},
                {'id': 'data', 'label': context.l10n.hkActionData},
                {'id': 'settings', 'label': context.l10n.hkActionSettings},
              ],
              context.l10n.hkCategoryDashboardTabs: [
                {
                  'id': 'dashboard_tab_1',
                  'label': context.l10n.hkActionDashboardTab1,
                },
                {
                  'id': 'dashboard_tab_2',
                  'label': context.l10n.hkActionDashboardTab2,
                },
                {
                  'id': 'dashboard_tab_3',
                  'label': context.l10n.hkActionDashboardTab3,
                },
              ],
              context.l10n.hkCategoryDataTabs: [
                {'id': 'data_tab_1', 'label': context.l10n.hkActionDataTab1},
                {'id': 'data_tab_2', 'label': context.l10n.hkActionDataTab2},
                {'id': 'data_tab_3', 'label': context.l10n.hkActionDataTab3},
              ],
              context.l10n.hkCategoryPeriodControl: [
                {'id': 'prev_period', 'label': context.l10n.hkActionPrevPeriod},
                {'id': 'next_period', 'label': context.l10n.hkActionNextPeriod},
                // Screen-agnostic like the two above: every list screen carries
                // the same date picker, so one binding serves all of them and
                // the focused screen is the one that answers.
                {'id': 'pick_date', 'label': context.l10n.hkActionPickDate},
              ],
              context.l10n.hkCategoryActions: [
                {'id': 'add_action', 'label': context.l10n.hkActionAddAction},
                {'id': 'sort_order', 'label': context.l10n.hkActionSortOrder},
                {
                  'id': 'filter_action',
                  'label': context.l10n.hkActionFilterAction,
                },
              ],
              context.l10n.hkCategorySelectionMode: [
                {
                  'id': 'accounts_selection_close',
                  'label': context.l10n.hkActionAccountsSelectionClose,
                },
                {
                  'id': 'accounts_selection_all',
                  'label': context.l10n.hkActionAccountsSelectionAll,
                },
                {
                  'id': 'accounts_selection_delete',
                  'label': context.l10n.hkActionAccountsSelectionDelete,
                },
                {
                  'id': 'accounts_selection_change_type',
                  'label': context.l10n.hkActionAccountsSelectionChangeType,
                },
                // Transactions offers no "select all": its selection bar has
                // never carried that button, and listing an id here would make
                // it bindable without anything to bind it to.
                {
                  'id': 'transactions_selection_close',
                  'label': context.l10n.hkActionTransactionsSelectionClose,
                },
                {
                  'id': 'transactions_selection_delete',
                  'label': context.l10n.hkActionTransactionsSelectionDelete,
                },
                {
                  'id': 'transactions_selection_change_date',
                  'label': context.l10n.hkActionTransactionsSelectionChangeDate,
                },
                {
                  'id': 'transactions_selection_change_category',
                  'label':
                      context.l10n.hkActionTransactionsSelectionChangeCategory,
                },
                {
                  'id': 'categories_selection_close',
                  'label': context.l10n.hkActionCategoriesSelectionClose,
                },
                {
                  'id': 'categories_selection_all',
                  'label': context.l10n.hkActionCategoriesSelectionAll,
                },
                {
                  'id': 'categories_selection_delete',
                  'label': context.l10n.hkActionCategoriesSelectionDelete,
                },
                {
                  'id': 'categories_selection_change_type',
                  'label': context.l10n.hkActionCategoriesSelectionChangeType,
                },
                {
                  'id': 'exchange_rates_selection_close',
                  'label': context.l10n.hkActionDataSelectionClose,
                },
                {
                  'id': 'exchange_rates_selection_all',
                  'label': context.l10n.hkActionDataSelectionAll,
                },
                {
                  'id': 'exchange_rates_selection_delete',
                  'label': context.l10n.hkActionDataSelectionDelete,
                },
                {
                  'id': 'exchange_rates_selection_change_preset',
                  'label': context.l10n.hkActionDataSelectionChangePreset,
                },
              ],
            };

            // The recorder reports a conflict by name, and the names live
            // here.
            final actionLabels = {
              for (final actions in categories.values)
                for (final action in actions) action['id']!: action['label']!,
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
                      ? context.l10n.noneLabel
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
                          ? Tooltip(
                              message: context.l10n.duplicateHotkeyTooltip,
                              child: const Icon(
                                Icons.warning,
                                color: Colors.orange,
                              ),
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
                            actionLabels: actionLabels,
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
              return Center(child: Text(context.l10n.noMatchingHotkeys));
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

  /// Action id to the name the user sees in the list.
  ///
  /// The conflict warning used to print the raw id, so it named something
  /// like `accounts_selection_change_type` - a string that appears nowhere in
  /// the interface the user is looking at.
  final Map<String, String> actionLabels;

  const HotKeyRecorderDialog({
    required this.actionId,
    required this.actionLabel,
    required this.currentKey,
    required this.allHotkeys,
    this.actionLabels = const {},
    super.key,
  });

  @override
  State<HotKeyRecorderDialog> createState() => _HotKeyRecorderDialogState();
}

class _HotKeyRecorderDialogState extends State<HotKeyRecorderDialog> {
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _pressedKeys = {};

  /// The widest combination held at once, which is what gets recorded.
  final Set<LogicalKeyboardKey> _peakKeys = {};
  String _tempKeyString = '';

  @override
  void initState() {
    super.initState();
    // Request focus immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _tempKeyString = context.l10n.pressKeysHint;
        });
        _focusNode.requestFocus();
      }
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
          _rememberPeak();
          _updateDisplay();
        });
      }
    } else if (event is KeyUpEvent) {
      // Logic: If a non-modifier key is released, we consider the combination complete.
      if (!_isModifier(event.logicalKey)) {
        // The combination recorded is the widest one held at once, not the
        // keys still down at this instant: releasing Ctrl a moment before the
        // letter used to record the bare letter and close immediately, and the
        // user found out only when it started firing while they typed.
        final finalString = HotKeyUtils.serializeKeys(_peakKeys);
        if (finalString.isNotEmpty) {
          _saveAndClose(finalString);
        }
      }

      setState(() {
        _pressedKeys.remove(event.logicalKey);
        // Hands off the keyboard entirely: the next attempt starts from
        // nothing rather than inheriting the previous one's widest set.
        if (_pressedKeys.isEmpty) _peakKeys.clear();
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

  /// Keeps the largest set seen while a non-modifier is down.
  ///
  /// A set with only modifiers in it is not a shortcut yet, so it never
  /// becomes the peak - otherwise holding Ctrl+Shift and then pressing a
  /// letter would record the modifiers alone.
  void _rememberPeak() {
    if (_pressedKeys.any((k) => !_isModifier(k)) &&
        _pressedKeys.length > _peakKeys.length) {
      _peakKeys
        ..clear()
        ..addAll(_pressedKeys);
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
      _tempKeyString = context.l10n.pressKeysHint;
    } else {
      final serialized = HotKeyUtils.serializeKeys(_pressedKeys);
      final display = HotKeyUtils.getDisplayString(serialized);

      // Check if this new sequence is used elsewhere
      final duplicateId = widget.allHotkeys.entries
          .where((e) => e.value == serialized && e.key != widget.actionId)
          .map((e) => e.key)
          .firstOrNull;

      if (duplicateId != null) {
        final duplicateLabel = widget.actionLabels[duplicateId] ?? duplicateId;
        _tempKeyString =
            '$display\n(${context.l10n.usedByLabel(duplicateLabel)})';
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
              context.l10n.recordingHotkeyTitle(widget.actionLabel),
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
            Text(
              context.l10n.pressAnyCombinationHint,
              style: const TextStyle(color: Colors.grey),
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
                  child: Text(context.l10n.cancelButton),
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
                  child: Text(context.l10n.clearSaveButton),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
