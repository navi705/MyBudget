import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/presentation/blocs/inflation/inflation_bloc.dart';
import 'package:my_budget_client/presentation/widgets/generic/grouped_paginated_list.dart';

import 'package:my_budget_client/core/extensions/context_extensions.dart';

class InflationView extends StatelessWidget {
  final Function(InflationRateDomain?) onEdit;

  const InflationView({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<InflationBloc, InflationState>(
      builder: (context, state) {
        if (state.status == InflationStatus.loading && state.rates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == InflationStatus.failure && state.rates.isEmpty) {
          return Center(
            child: Text(l10n.inflationError(state.errorMessage ?? 'Unknown')),
          );
        }

        if (state.rates.isEmpty) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapUp: (details) =>
                _showEmptyAreaContextMenu(context, details.globalPosition),
            onLongPressStart: (details) =>
                _showEmptyAreaContextMenu(context, details.globalPosition),
            child: Center(child: Text(l10n.inflationNoRatesFound)),
          );
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onSecondaryTapUp: (details) =>
              _showEmptyAreaContextMenu(context, details.globalPosition),
          onLongPressStart: (details) =>
              _showEmptyAreaContextMenu(context, details.globalPosition),
          child: Column(
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
                    return const SizedBox.shrink();
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
          ),
        );
      },
    );
  }

  void _showEmptyAreaContextMenu(BuildContext context, Offset position) async {
    final l10n = context.l10n;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        PopupMenuItem(
          value: 'add_inflation',
          child: Row(
            children: [
              const Icon(Icons.add),
              const SizedBox(width: 8),
              Text(l10n.inflationAddRate),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'add_inflation') {
      onEdit(null);
    }
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    InflationRateDomain item,
  ) {
    final bloc = context.read<InflationBloc>();
    final state = bloc.state;
    final isSelected = state.selectedRates.contains(item);
    final l10n = context.l10n;

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
              Text(
                isSelected ? l10n.contextMenuDeselect : l10n.contextMenuSelect,
              ),
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
              Text(l10n.contextMenuSelectAll),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () {
            if (!isSelected) {
              bloc.add(ToggleInflationSelection(item));
            }

            Future.delayed(Duration.zero, () {
              if (context.mounted) {
                _showDeleteConfirmation(
                  context,
                  bloc,
                  isSelected ? state.selectedRates.length : 1,
                );
              }
            });
          },
          child: Row(
            children: [
              const Icon(Icons.delete, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                l10n.contextMenuDelete,
                style: const TextStyle(color: Colors.red),
              ),
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
    final l10n = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inflationDeleteConfirmTitle),
        content: Text(l10n.inflationDeleteConfirmMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () {
              bloc.add(DeleteSelectedInflationRates());
              Navigator.pop(context);
            },
            child: Text(
              l10n.deleteButton,
              style: const TextStyle(color: Colors.red),
            ),
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

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      color: isSelected ? theme.highlightColor : null,
      child: GestureDetector(
        onSecondaryTapUp: onSecondaryTapUp,
        child: ListTile(
          onTap: onTap,
          onLongPress: onLongPress,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
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
