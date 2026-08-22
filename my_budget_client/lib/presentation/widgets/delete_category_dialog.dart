import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';

enum DeleteCategoryOption { reassign, delete }

class DeleteCategoryDialog extends StatefulWidget {
  final Category categoryToDelete;
  final List<Category> allCategories;

  const DeleteCategoryDialog({
    super.key,
    required this.categoryToDelete,
    required this.allCategories,
  });

  @override
  State<DeleteCategoryDialog> createState() => _DeleteCategoryDialogState();
}

class _DeleteCategoryDialogState extends State<DeleteCategoryDialog> {
  DeleteCategoryOption _selectedOption = DeleteCategoryOption.reassign;
  String? _newCategoryId;

  @override
  void initState() {
    super.initState();
    _newCategoryId = widget.allCategories
        .firstWhereOrNull((c) => c.id != widget.categoryToDelete.id)
        ?.id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final availableCategories = widget.allCategories
        .where((c) => c.id != widget.categoryToDelete.id)
        .toList();

    return AlertDialog(
      title: Text(
        l10n.deleteCategoryConfirmTitle(widget.categoryToDelete.name),
      ),
      content: RadioGroup<DeleteCategoryOption>(
        groupValue: _selectedOption,
        onChanged: (value) {
          setState(() {
            _selectedOption = value!;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.deleteCategoryMessage),
            ListTile(
              title: Text(l10n.deleteCategoryReassign),
              leading: Radio<DeleteCategoryOption>(
                value: DeleteCategoryOption.reassign,
              ),
              onTap: () {
                setState(() {
                  _selectedOption = DeleteCategoryOption.reassign;
                });
              },
            ),
            if (_selectedOption == DeleteCategoryOption.reassign)
              DropdownButtonFormField<String>(
                initialValue: _newCategoryId,
                items: availableCategories
                    .map(
                      (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _newCategoryId = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: l10n.deleteCategoryNewCategory,
                ),
              ),
            ListTile(
              title: Text(l10n.deleteCategoryDeleteAll),
              leading: Radio<DeleteCategoryOption>(
                value: DeleteCategoryOption.delete,
              ),
              onTap: () {
                setState(() {
                  _selectedOption = DeleteCategoryOption.delete;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton.tonal(
          onPressed: () {
            if (_selectedOption == DeleteCategoryOption.reassign &&
                _newCategoryId == null) {
              return;
            }

            context.read<CategoriesBloc>().add(
              DeleteCategoryConfirmed(
                categoryToDelete: widget.categoryToDelete,
                deleteTransactions:
                    _selectedOption == DeleteCategoryOption.delete,
                newCategoryId: _newCategoryId,
              ),
            );
            Navigator.of(context).pop();
          },
          child: Text(l10n.confirmButton),
        ),
      ],
    );
  }
}
