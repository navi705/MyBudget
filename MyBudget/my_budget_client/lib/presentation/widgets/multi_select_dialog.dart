import 'package:flutter/material.dart';

class MultiSelectDialog<T> extends StatefulWidget {
  final List<T> items;
  final List<String> selectedIds;
  final Widget Function(T) itemBuilder;
  final String Function(T) idGetter;
  final String Function(T) stringGetter;

  const MultiSelectDialog({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.itemBuilder,
    required this.idGetter,
    required this.stringGetter,
  });

  @override
  State<MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<MultiSelectDialog<T>> {
  late final List<String> _selectedIds;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.selectedIds);
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
      title: const Text('Select Items'),
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
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
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
          child: const Text('Clear All'),
          onPressed: () {
            setState(() {
              _selectedIds.clear();
            });
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('OK'),
          onPressed: () {
            Navigator.of(context).pop(_selectedIds);
          },
        ),
      ],
    );
  }
}
