import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';

void showCategoryFilterDialog(
  BuildContext context,
  CategoryFilters currentFilters,
) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: BlocProvider.of<CategoriesBloc>(context),
        child: CategoryFilterDialog(currentFilters: currentFilters),
      );
    },
  );
}

class CategoryFilterDialog extends StatefulWidget {
  final CategoryFilters currentFilters;

  const CategoryFilterDialog({super.key, required this.currentFilters});

  @override
  State<CategoryFilterDialog> createState() => _CategoryFilterDialogState();
}

class _CategoryFilterDialogState extends State<CategoryFilterDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountFromController;
  late TextEditingController _amountToController;
  CategoryType? _selectedType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentFilters.name);
    _amountFromController = TextEditingController(
      text: widget.currentFilters.amountFrom?.toString(),
    );
    _amountToController = TextEditingController(
      text: widget.currentFilters.amountTo?.toString(),
    );
    _selectedType = widget.currentFilters.type;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountFromController.dispose();
    _amountToController.dispose();
    super.dispose();
  }

  IconData _getIconForCategoryType(CategoryType? type) {
    switch (type) {
      case CategoryType.expense:
        return Icons.arrow_downward;
      case CategoryType.income:
        return Icons.arrow_upward;
      case CategoryType.transfer:
        return Icons.swap_horiz;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Categories'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter category name',
              ),
            ),
            TextFormField(
              controller: _amountFromController,
              decoration: const InputDecoration(labelText: 'Amount From'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            TextFormField(
              controller: _amountToController,
              decoration: const InputDecoration(labelText: 'Amount To'),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            DropdownButtonFormField<CategoryType>(
              initialValue: _selectedType,
              hint: const Text('Select Type'),
              items: [
                DropdownMenuItem<CategoryType>(
                  value: null,
                  child: Row(
                    children: [
                      Icon(_getIconForCategoryType(null)),
                      const SizedBox(width: 10),
                      const Text('All'),
                    ],
                  ),
                ),
                ...CategoryType.values.map((type) {
                  return DropdownMenuItem<CategoryType>(
                    value: type,
                    child: Row(
                      children: [
                        Icon(_getIconForCategoryType(type)),
                        const SizedBox(width: 10),
                        Text(type.name),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedType = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Clear'),
          onPressed: () {
            context.read<CategoriesBloc>().add(
              const FiltersChanged(CategoryFilters()),
            );
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        FilledButton.tonal(
          child: const Text('Apply'),
          onPressed: () {
            final newFilters = widget.currentFilters.copyWith(
              name: _nameController.text.isNotEmpty
                  ? _nameController.text
                  : null,
              amountFrom: _amountFromController.text.isNotEmpty
                  ? double.tryParse(_amountFromController.text)
                  : null,
              amountTo: _amountToController.text.isNotEmpty
                  ? double.tryParse(_amountToController.text)
                  : null,
              type: _selectedType,
            );
            context.read<CategoriesBloc>().add(FiltersChanged(newFilters));
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}
