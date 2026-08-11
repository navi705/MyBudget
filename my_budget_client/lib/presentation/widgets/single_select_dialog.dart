import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';

Future<T?> showSingleSelectDialog<T>({
  required BuildContext context,
  required List<T> items,
  required String title,
  T? selectedItem,
  required Widget Function(T) itemBuilder,
  required String Function(T) stringGetter,
}) {
  return DialogUtils.showAppDialog<T>(
    context: context,
    resizeToAvoidBottomInset: false,
    child: SingleSelectDialog<T>(
      items: items,
      title: title,
      selectedItem: selectedItem,
      itemBuilder: itemBuilder,
      stringGetter: stringGetter,
    ),
  );
}

class SingleSelectDialog<T> extends StatefulWidget {
  final List<T> items;
  final String title;
  final T? selectedItem;
  final Widget Function(T) itemBuilder;
  final String Function(T) stringGetter;

  const SingleSelectDialog({
    super.key,
    required this.items,
    required this.title,
    this.selectedItem,
    required this.itemBuilder,
    required this.stringGetter,
  });

  @override
  State<SingleSelectDialog<T>> createState() => _SingleSelectDialogState<T>();
}

class _SingleSelectDialogState<T> extends State<SingleSelectDialog<T>> {
  late TextEditingController _searchController;
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterItems);
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return widget.stringGetter(item).toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    title: widget.itemBuilder(item),
                    onTap: () {
                      Navigator.of(context).pop(item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(widget.selectedItem);
          },
          child: Text(context.l10n.cancelButton),
        ),
      ],
    );
  }
}
