import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
      ),
      body: BlocBuilder<CategoriesBloc, CategoriesState>(
        builder: (context, state) {
          if (state is CategoriesLoadInProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CategoriesLoadSuccess) {
            if (state.categories.isEmpty) {
              return const Center(child: Text('No categories created yet.'));
            }
            return ListView.builder(
              itemCount: state.categories.length,
              itemBuilder: (context, index) {
                final category = state.categories[index];
                final total = state.categoryTotals[category.id] ?? 0.0;
                return ListTile(
                  title: Text(category.name),
                  subtitle: Text('Spent: ${total.toStringAsFixed(2)}'),
                  onTap: () {
                    context.push(AppRoutes.addEditTransaction, extra: category);
                  },
                  onLongPress: () {
                    _showAddEditCategoryDialog(context, category: category);
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      context.read<CategoriesBloc>().add(DeleteCategory(category.id!));
                    },
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Failed to load categories.'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddEditCategoryDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEditCategoryDialog(BuildContext context, {Category? category}) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(
              value: BlocProvider.of<CategoriesBloc>(context),
            ),
            BlocProvider.value(
              value: BlocProvider.of<StylesBloc>(context),
            ),
          ],
          child: AddEditCategoryDialog(category: category),
        );
      },
    );
  }
}

class AddEditCategoryDialog extends StatefulWidget {
  final Category? category;

  const AddEditCategoryDialog({super.key, this.category});

  @override
  State<AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  int? _selectedStyleId;
  CategoryType _selectedCategoryType = CategoryType.expense;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedStyleId = widget.category?.styleId;
    _selectedCategoryType = widget.category?.type ?? CategoryType.expense;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      if (widget.category == null) {
        context.read<CategoriesBloc>().add(
              AddCategory(
                Category(name: name, styleId: _selectedStyleId, type: _selectedCategoryType),
              ),
            );
      } else {
        context.read<CategoriesBloc>().add(
              UpdateCategory(
                widget.category!.copyWith(name: name, styleId: _selectedStyleId, type: _selectedCategoryType),
              ),
            );
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add Category' : 'Edit Category'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Category Name'),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Please enter a name' : null,
            ),
            BlocBuilder<StylesBloc, StylesState>(
              builder: (context, state) {
                if (state is StylesLoadSuccess) {
                  return DropdownButtonFormField<int>(
                    initialValue: _selectedStyleId,
                    decoration: const InputDecoration(labelText: 'Style'),
                    items: state.styles
                        .map((s) => DropdownMenuItem<int>(
                              value: s.id,
                              child: Text(s.name),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedStyleId = v),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            DropdownButtonFormField<CategoryType>(
              value: _selectedCategoryType,
              decoration: const InputDecoration(labelText: 'Category Type'),
              items: CategoryType.values
                  .map((type) => DropdownMenuItem<CategoryType>(
                        value: type,
                        child: Text(type.toString().split('.').last),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategoryType = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}