import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

/// Picking the existing account, category or currency an imported name stands
/// for.
///
/// The identifier is asked for rather than reached for: the dialog used to pop
/// `(item as dynamic).id`, which reads whatever the runtime type happens to
/// call `id`. A currency has no such field - it is keyed by its code - so
/// mapping an imported currency onto one the app already knows threw
/// `NoSuchMethodError` on the tap and the import could not be finished. The
/// caller now says what identifies its own items, and the compiler checks it.
class ImportMappingDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final Widget Function(T) itemBuilder;
  final String Function(T) itemNameProvider;

  /// What the dialog pops for [item] - the value the mapping is stored under.
  final String? Function(T item) itemIdProvider;

  const ImportMappingDialog({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    required this.itemNameProvider,
    required this.itemIdProvider,
  });

  @override
  State<ImportMappingDialog<T>> createState() => _ImportMappingDialogState<T>();
}

class _ImportMappingDialogState<T> extends State<ImportMappingDialog<T>> {
  late TextEditingController _searchController;
  late List<T> _filteredItems;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.items.where((item) {
        return widget.itemNameProvider(item).toLowerCase().contains(query);
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
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredItems.length,
                itemBuilder: (context, index) {
                  final item = _filteredItems[index];
                  return ListTile(
                    title: widget.itemBuilder(item),
                    onTap: () {
                      Navigator.of(context).pop(widget.itemIdProvider(item));
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
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.cancelButton),
        ),
      ],
    );
  }
}
