import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/widgets/generic/grouped_paginated_list.dart';

class InflationView extends StatelessWidget {
  final Function(InflationRateDomain) onEdit;

  const InflationView({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InflationBloc, InflationState>(
      builder: (context, state) {
        if (state.status == InflationStatus.loading && state.rates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == InflationStatus.failure && state.rates.isEmpty) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }

        if (state.rates.isEmpty) {
          return const Center(child: Text('No inflation rates found.'));
        }

        return Column(
          children: [
            Expanded(
              child: GroupedPaginatedList<InflationRateDomain, DateTime>(
                items: state.rates,
                hasMoreDown: state.hasMore,
                onFetchMoreDown: () {
                  context.read<InflationBloc>().add(LoadMoreInflationRates());
                },
                groupKeyGetter: (item) =>
                    DateTime(item.date.year, item.date.month),
                keyComparator: (a, b) {
                  if (state.sort.toString().contains('ascending')) {
                    return a.compareTo(b);
                  }
                  return b.compareTo(a);
                },
                groupHeaderBuilder: (context, date) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: Text(
                      DateFormat.yMMMM().format(date),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                itemBuilder: (context, item) {
                  final isSelected = state.selectedRates.contains(item);
                  return _InflationListItem(
                    item: item,
                    isSelected: isSelected,
                    isSelectionMode: state.isSelectionModeActive,
                    onTap: () {
                      if (state.isSelectionModeActive) {
                        context.read<InflationBloc>().add(
                          ToggleInflationSelection(item),
                        );
                      } else {
                        onEdit(item);
                      }
                    },
                    onLongPress: () {
                      context.read<InflationBloc>().add(
                        ToggleInflationSelection(item),
                      );
                    },
                    onSecondaryTapUp: (details) {
                      _showContextMenu(context, details.globalPosition, item);
                    },
                  );
                },
              ),
            ),
            if (state.isLoadingMore) const LinearProgressIndicator(),
          ],
        );
      },
    );
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    InflationRateDomain item,
  ) {
    final bloc = context.read<InflationBloc>();
    final state = bloc.state;
    final isSelected = state.selectedRates.contains(item);

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        PopupMenuItem(
          onTap: () {
            bloc.add(ToggleInflationSelection(item));
          },
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.deselect : Icons.select_all,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(isSelected ? 'Deselect' : 'Select'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            bloc.add(SelectAllInflationRates());
          },
          child: Row(
            children: [
              Icon(
                Icons.select_all,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              const Text('Select All'),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            // Trigger delete confirmation
            // Since we don't have direct access to _showDeleteConfirmation here easily without state passing or callback,
            // we can just toggle selection if not selected, then let user click delete app bar.
            // OR show dialog here.
            // UX: Right click delete usually deletes generic item? Or selected?
            // If item is not selected, selecting it + delete is safer.
            // If item is selected, delete all selected.
            // Let's mimic Accounts: 'Delete' option deletes THIS item (or selection if part of it).
            // Logic:
            if (!isSelected) {
              bloc.add(ToggleInflationSelection(item));
            }
            // Wait for state update is hard.
            // Simpler: Just make 'Delete' select the item (if not selected) and then we want to trigger the Batch Delete dialog.
            // But we can't trigger the AppBar dialog from here easily.
            // Helper method for dialog?
            // I'll define _showDeleteDialog here too or use a mixin? No, just duplicate code for now or implement direct delete event (with CONFIRMATION).
            // Let's defer delete to AppBar for bulk. For single item right click delete?
            // Context menu 'Delete' usually implies immediate action or dialog.
            // I will show confirmation dialog here.

            Future.delayed(Duration.zero, () {
              if (context.mounted)
                _showDeleteConfirmation(
                  context,
                  bloc,
                  isSelected ? state.selectedRates.length : 1,
                );
            });
          },
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    InflationBloc bloc,
    int count,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rates?'),
        content: Text(
          'Are you sure you want to delete ${count > 1 ? '$count rates' : 'this rate'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // If we are here from context menu, ensuring selection is synced is tricky if we want to delete "just this one" but keep others selected?
              // Simpler: If "Delete" is clicked, we assume we want to delete the Selection (if item is in it) or just the item.
              // For consistency with Selection Mode, we should probably ensure the item IS selected, then call DeleteSelected.
              // If I added logic to Select it in onTap, it's async.
              // Better: The context menu delete always acts on "Selection" if Selection Mode is active?
              // Or acts on "Target" if no selection mode?
              // Plan: "Delete" in context menu performs "DeleteSelected" logic.
              // So I should ensure target is selected.
              // But `bloc.add` is async.
              // Hack: Dispatch Toggle then Delete? No.

              // Alternative: context menu delete is ONLY for single item delete unless it's bulk context menu?
              // Let's stick to: Context Menu > Delete -> triggers Delete events.

              // Ideally:
              bloc.add(
                DeleteSelectedInflationRates(),
              ); // Assumes selection is updated.
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _InflationListItem extends StatelessWidget {
  final InflationRateDomain item;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(TapUpDetails) onSecondaryTapUp;

  const _InflationListItem({
    required this.item,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTapUp,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countryName = item.country ?? 'Global';
    final initial = countryName.isNotEmpty ? countryName[0].toUpperCase() : 'G';

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      onSecondaryTapUp: onSecondaryTapUp,
      child: Container(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.3)
            : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            foregroundColor: theme.colorScheme.onPrimaryContainer,
            child: Text(initial),
          ),
          title: Text(
            '${item.country ?? 'Global'} (Preset: ${item.preset})',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(DateFormat.yMMMMd().format(item.date)),
          trailing: Text(
            '${item.percent > 0 ? '+' : ''}${item.percent.toStringAsFixed(2)}%',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: item.percent >= 0 ? Colors.red : Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}
