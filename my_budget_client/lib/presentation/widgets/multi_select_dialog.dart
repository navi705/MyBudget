import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

class MultiSelectDialog<T, K> extends StatefulWidget {
  final List<T> items;
  final List<K> selectedIds;
  final Widget Function(T) itemBuilder;
  final K Function(T) idGetter;
  final String Function(T) stringGetter;
  final bool isSingleSelect;

  const MultiSelectDialog({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.itemBuilder,
    required this.idGetter,
    required this.stringGetter,
    this.isSingleSelect = false,
  });

  @override
  State<MultiSelectDialog<T, K>> createState() =>
      _MultiSelectDialogState<T, K>();
}

class _MultiSelectDialogState<T, K> extends State<MultiSelectDialog<T, K>> {
  late final List<K> _selectedIds;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List<K>.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = widget.items.where((item) {
      return widget
          .stringGetter(item)
          .toLowerCase()
          .contains(_searchText.toLowerCase());
    }).toList();

    return AlertDialog(
      title: Text(
        widget.isSingleSelect
            ? context.l10n.pckSelectItem
            : context.l10n.pckSelectItems,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
              decoration: InputDecoration(
                labelText: context.l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 8.0,
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  final itemId = widget.idGetter(item);
                  final isSelected = _selectedIds.contains(itemId);
                  return CheckboxListTile(
                    value: isSelected,
                    title: widget.itemBuilder(item),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          if (widget.isSingleSelect) {
                            _selectedIds.clear();
                          }
                          _selectedIds.add(itemId);
                        } else {
                          _selectedIds.remove(itemId);
                        }
                      });
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
          child: Text(context.l10n.pckClearAll),
          onPressed: () {
            setState(() {
              _selectedIds.clear();
            });
          },
        ),
        TextButton(
          child: Text(context.l10n.cancelButton),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text(context.l10n.okButton),
          onPressed: () {
            Navigator.of(context).pop(_selectedIds);
          },
        ),
      ],
    );
  }
}
