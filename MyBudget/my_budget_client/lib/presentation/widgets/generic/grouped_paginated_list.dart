import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

typedef GroupHeaderBuilder<K> = Widget Function(BuildContext context, K groupKey);
typedef ItemBuilder<T> = Widget Function(BuildContext context, T item);
typedef GroupKeyGetter<T, K> = K Function(T item);

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
  });

  @override
  State<GroupedPaginatedList<T, K>> createState() =>
      _GroupedPaginatedListState<T, K>();
}

class _GroupedPaginatedListState<T, K>
    extends State<GroupedPaginatedList<T, K>> {
  late ListController _listController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _listController = ListController();
    _scrollController = ScrollController();
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
    if (widget.jumpToItemId != null && widget.jumpToAlignment != null) {
      // The jumping logic will be handled by the parent widget,
      // as it needs to calculate the index based on the final list items.
    }
  }

  Map<K, List<T>> _groupItems(List<T> items) {
    final Map<K, List<T>> grouped = {};
    for (final item in items) {
      final key = widget.groupKeyGetter(item);
      if (grouped[key] == null) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }
    return grouped;
  }

  List<Widget> _buildListItems() {
    final groupedItems = _groupItems(widget.items);
    
    // Assuming K is comparable for sorting, which is true for DateTime.
    // For other types, a custom sort function might be needed.
    final sortedKeys = groupedItems.keys.toList();
    if (K == DateTime) {
      (sortedKeys as List<DateTime>).sort((a, b) => b.compareTo(a));
    }

    final List<Widget> listItems = [];
    for (final key in sortedKeys) {
      final itemsForKey = groupedItems[key]!;
      listItems.add(widget.groupHeaderBuilder(context, key));
      for (final item in itemsForKey) {
        listItems.add(widget.itemBuilder(context, item));
      }
      listItems.add(Divider(key: ValueKey('divider_$key')));
    }
    return listItems;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const Center(child: Text('No items found.'));
    }

    final listItems = _buildListItems();

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
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return listItems[index];
              },
              childCount: listItems.length,
            ),
          ),
        ],
      ),
    );
  }
}
