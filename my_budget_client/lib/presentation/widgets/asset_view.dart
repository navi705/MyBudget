import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_bloc.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_event.dart';
import 'package:my_budget_client/presentation/blocs/asset/asset_state.dart';
import 'package:my_budget_client/presentation/widgets/generic/grouped_paginated_list.dart';

class AssetView extends StatelessWidget {
  final Function(AssetDataDomain?) onEdit;

  const AssetView({super.key, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AssetBloc, AssetState>(
      // The failure below can only be seen while the list is empty - which,
      // for anyone who already has assets, it never is. So a failed add, edit
      // or delete showed nothing at all: the dialog popped and the list sat
      // there unchanged.
      listenWhen: (previous, current) =>
          current.errorMessage != null &&
          current.errorMessage != previous.errorMessage &&
          current.assetData.isNotEmpty,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text('Error: ${state.errorMessage}')));
      },
      builder: (context, state) {
        if (state.status == AssetStatus.loading && state.assetData.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state.status == AssetStatus.failure && state.assetData.isEmpty) {
          return Center(child: Text('Error: ${state.errorMessage}'));
        }

        if (state.assetData.isEmpty) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onSecondaryTapUp: (details) =>
                _showEmptyAreaContextMenu(context, details.globalPosition),
            onLongPressStart: (details) =>
                _showEmptyAreaContextMenu(context, details.globalPosition),
            child: const Center(child: Text('No assets found.')),
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
                child: GroupedPaginatedList<AssetDataDomain, DateTime>(
                  items: state.assetData,
                  hasMoreDown: state.hasMore,
                  onFetchMoreDown: () {
                    context.read<AssetBloc>().add(const LoadMoreAssetData());
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
                    final isSelected = state.selectedAssets.contains(item);
                    return _AssetListItem(
                      item: item,
                      isSelected: isSelected,
                      isSelectionMode: state.isSelectionModeActive,
                      onTap: () {
                        if (state.isSelectionModeActive) {
                          context.read<AssetBloc>().add(
                            ToggleAssetSelection(item),
                          );
                        } else {
                          onEdit(item);
                        }
                      },
                      onLongPress: () {
                        context.read<AssetBloc>().add(
                          ToggleAssetSelection(item),
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
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final value = await showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
        Offset.zero & overlay.size,
      ),
      items: <PopupMenuEntry<String>>[
        const PopupMenuItem(
          value: 'add_asset',
          child: Row(
            children: [
              Icon(Icons.add),
              SizedBox(width: 8),
              Text('Add Asset Data'),
            ],
          ),
        ),
      ],
    );

    if (!context.mounted || value == null) return;

    if (value == 'add_asset') {
      onEdit(null);
    }
  }

  void _showContextMenu(
    BuildContext context,
    Offset position,
    AssetDataDomain item,
  ) {
    final bloc = context.read<AssetBloc>();
    final state = bloc.state;
    final isSelected = state.selectedAssets.contains(item);

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
            bloc.add(ToggleAssetSelection(item));
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
            bloc.add(SelectAllAssets());
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
            if (!isSelected) {
              bloc.add(ToggleAssetSelection(item));
            }
            Future.delayed(Duration.zero, () {
              if (context.mounted) _showDeleteConfirmation(context, bloc);
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

  void _showDeleteConfirmation(BuildContext context, AssetBloc bloc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Assets?'),
        content: Text(
          'Are you sure you want to delete the selected assets?', // Context menu delete usually implies simple delete or selection delete
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              bloc.add(DeleteSelectedAssets());
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _AssetListItem extends StatelessWidget {
  final AssetDataDomain item;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(TapUpDetails) onSecondaryTapUp;

  const _AssetListItem({
    required this.item,
    required this.isSelected,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
    required this.onSecondaryTapUp,
  });

  IconData _getIconForType(String? type) {
    if (type == null) return Icons.category;
    final lowerType = type.toLowerCase();
    if (lowerType.contains('stock') ||
        lowerType.contains('fund') ||
        lowerType.contains('etf')) {
      return Icons.show_chart;
    }
    if (lowerType.contains('real estate') ||
        lowerType.contains('property') ||
        lowerType.contains('house')) {
      return Icons.house;
    }
    if (lowerType.contains('crypto') || lowerType.contains('bitcoin')) {
      return Icons.currency_bitcoin;
    }
    if (lowerType.contains('cash') || lowerType.contains('savings')) {
      return Icons.attach_money;
    }
    if (lowerType.contains('vehicle') || lowerType.contains('car')) {
      return Icons.directions_car;
    }
    return Icons.category;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSteam = item.source.toLowerCase() == 'steam';

    Widget? leadingIcon;
    if (isSteam) {
      leadingIcon = SvgPicture.asset(
        'lib/icons/steam.svg',
        colorFilter: ColorFilter.mode(
          theme.colorScheme.onPrimaryContainer,
          BlendMode.srcIn,
        ),
      );
    } else {
      leadingIcon = Icon(_getIconForType(item.assetType));
    }

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
            child: leadingIcon,
          ),
          title: Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${item.assetType ?? 'Type'} • ${item.source} • ${DateFormat.yMMMMd().format(item.date)}',
          ),
          trailing: Text(
            '${MoneyFormatter.format(item.value, item.currency)} ${item.currency}',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
