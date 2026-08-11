import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

typedef GroupHeaderBuilder<K> =
    Widget Function(BuildContext context, K groupKey);
typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef GroupKeyGetter<T, K> = K Function(T item);

class _ListItem<T, K> {
  final K? header;
  final T? item;
  final bool isHeader;

  _ListItem.header(this.header) : item = null, isHeader = true;
  _ListItem.item(this.item) : header = null, isHeader = false;
}

class GroupedPaginatedList<T, K> extends StatefulWidget {
  final List<T> items;
  final bool hasMoreUp;
  final bool hasMoreDown;
  final VoidCallback? onFetchMoreUp;
  final VoidCallback? onFetchMoreDown;
  final GroupKeyGetter<T, K> groupKeyGetter;
  final GroupHeaderBuilder<K> groupHeaderBuilder;
  final ItemBuilder<T> itemBuilder;
  final String? jumpToItemId;
  final double? jumpToAlignment;
  final int Function(K a, K b)? keyComparator;

  const GroupedPaginatedList({
    super.key,
    required this.items,
    this.hasMoreUp = false,
    this.hasMoreDown = false,
    this.onFetchMoreUp,
    this.onFetchMoreDown,
    required this.groupKeyGetter,
    required this.groupHeaderBuilder,
    required this.itemBuilder,
    this.jumpToItemId,
    this.jumpToAlignment,
    this.keyComparator,
  });

  @override
  State<GroupedPaginatedList<T, K>> createState() =>
      _GroupedPaginatedListState<T, K>();
}

class _GroupedPaginatedListState<T, K>
    extends State<GroupedPaginatedList<T, K>> {
  late ListController _listController;
  late ScrollController _scrollController;
  List<_ListItem<T, K>> _flattenedItems = [];

  @override
  void initState() {
    super.initState();
    _listController = ListController();
    _scrollController = ScrollController();
    _recalculateGroups();
  }

  @override
  void dispose() {
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant GroupedPaginatedList<T, K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // OPTIMIZATION: Deep equality check to avoid O(N) regrouping on reference changes
    // Quick check: same reference = no change
    if (identical(widget.items, oldWidget.items)) {
      if (widget.jumpToItemId != null && widget.jumpToAlignment != null) {
        // The jumping logic will be handled by the parent widget,
        // as it needs to calculate the index based on the final list items.
      }
      return;
    }
    
    // Length check: different length = definitely changed
    if (widget.items.length != oldWidget.items.length) {
      _recalculateGroups();
    } else {
      // Deep check: compare elements (only if T has proper == operator)
      bool changed = false;
      for (int i = 0; i < widget.items.length; i++) {
        if (widget.items[i] != oldWidget.items[i]) {
          changed = true;
          break;
        }
      }
      if (changed) {
        _recalculateGroups();
      }
    }
    
    if (widget.jumpToItemId != null && widget.jumpToAlignment != null) {
      // The jumping logic will be handled by the parent widget,
      // as it needs to calculate the index based on the final list items.
    }
  }

  void _recalculateGroups() {
    final Map<K, List<T>> grouped = {};
    for (final item in widget.items) {
      final key = widget.groupKeyGetter(item);
      if (grouped[key] == null) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }

    final sortedKeys = grouped.keys.toList();
    if (widget.keyComparator != null) {
      sortedKeys.sort(widget.keyComparator);
    }

    final List<_ListItem<T, K>> newFlattenedItems = [];
    for (final key in sortedKeys) {
      newFlattenedItems.add(_ListItem.header(key));
      final itemsForKey = grouped[key]!;
      for (final item in itemsForKey) {
        newFlattenedItems.add(_ListItem.item(item));
      }
      // Divider is removed to simplify index calculation for now,
      // or can be added as a separate item type if needed.
      // If we need a divider after each group, we can add it here.
      // For performance, let's skip the divider or handle it in the item.
      // Re-adding divider as a separate item type for visual consistency if requested,
      // but simpler is better for now.
      // Let's assume the previous logic: listItems.add(Divider(key: ValueKey('divider_$key')));
      // We will skip the divider for this optimized version unless critical.
    }
    _flattenedItems = newFlattenedItems;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Center(child: Text(context.l10n.noItemsFound));
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo.metrics.pixels >=
            scrollInfo.metrics.maxScrollExtent - 200) {
          if (widget.hasMoreDown && widget.onFetchMoreDown != null) {
            widget.onFetchMoreDown!();
          }
        }

        if (scrollInfo.metrics.pixels <= 200) {
          if (widget.hasMoreUp && widget.onFetchMoreUp != null) {
            widget.onFetchMoreUp!();
          }
        }
        return false;
      },
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SuperSliverList(
            listController: _listController,
            delegate: SliverChildBuilderDelegate((context, index) {
              final item = _flattenedItems[index];
              if (item.isHeader) {
                return widget.groupHeaderBuilder(context, item.header as K);
              } else {
                return widget.itemBuilder(context, item.item as T);
              }
            }, childCount: _flattenedItems.length),
          ),
        ],
      ),
    );
  }
}
