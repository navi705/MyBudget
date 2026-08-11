import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';

/// A way out of a picker that has nothing to offer.
///
/// The dialog is generic over [T] and cannot know how an Account or a Category
/// is created, so a caller that has somewhere to send the user supplies one of
/// these. Callers that leave it null keep the picker read-only.
class SingleSelectCreateAction {
  final String label;
  final VoidCallback onPressed;

  const SingleSelectCreateAction({
    required this.label,
    required this.onPressed,
  });
}

Future<T?> showSingleSelectDialog<T>({
  required BuildContext context,
  required List<T> items,
  required String title,
  T? selectedItem,
  required Widget Function(T) itemBuilder,
  required String Function(T) stringGetter,
  SingleSelectCreateAction? createAction,
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
      createAction: createAction,
    ),
  );
}

class SingleSelectDialog<T> extends StatefulWidget {
  final List<T> items;
  final String title;
  final T? selectedItem;
  final Widget Function(T) itemBuilder;
  final String Function(T) stringGetter;
  final SingleSelectCreateAction? createAction;

  const SingleSelectDialog({
    super.key,
    required this.items,
    required this.title,
    this.selectedItem,
    required this.itemBuilder,
    required this.stringGetter,
    this.createAction,
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
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        // Two very different dead ends used to look identical:
                        // a search that matches nothing is undone by clearing
                        // the box, an empty source list needs the user to go
                        // and create something first.
                        child: Text(
                          widget.items.isEmpty
                              ? context.l10n.selectDialogEmptyState
                              : context.l10n.selectDialogNoMatches,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Theme.of(context).hintColor),
                        ),
                      ),
                    )
                  : ListView.builder(
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
        if (widget.createAction != null)
          TextButton(
            onPressed: () {
              // The action opens a dialog of its own, and this one is already
              // on the root navigator: left open it would sit under a barrier
              // between the user and the item they came here to create.
              Navigator.of(context).pop(widget.selectedItem);
              widget.createAction!.onPressed();
            },
            child: Text(widget.createAction!.label),
          ),
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
