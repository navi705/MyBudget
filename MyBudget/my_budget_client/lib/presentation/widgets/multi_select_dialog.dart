import 'package:flutter/material.dart';

class MultiSelectDialog<T> extends StatefulWidget {
  final List<T> items;
  final List<String> selectedIds;
  final Widget Function(T) itemBuilder;
  final String Function(T) idGetter;

  const MultiSelectDialog({
    super.key,
    required this.items,
    required this.selectedIds,
    required this.itemBuilder,
    required this.idGetter,
  });

  @override
  State<MultiSelectDialog<T>> createState() => _MultiSelectDialogState<T>();
}

class _MultiSelectDialogState<T> extends State<MultiSelectDialog<T>> {
  late final List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = List<String>.from(widget.selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Items'),
      content: SingleChildScrollView(
        child: ListBody(
          children: widget.items.map((item) {
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
          }).toList(),
        ),
      ),
      actions: [
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
