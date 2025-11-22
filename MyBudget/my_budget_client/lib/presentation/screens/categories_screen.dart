import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';

import '../widgets/delete_category_dialog.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<CategoriesBloc, CategoriesState>(
      listener: (context, state) {
        if (state is CategoryDeletionConfirmationNeeded) {
          showDialog(
            context: context,
            builder: (dialogContext) => BlocProvider.value(
              value: context.read<CategoriesBloc>(),
              child: DeleteCategoryDialog(
                categoryToDelete: state.categoryToDelete,
                allCategories: state.allCategories,
              ),
            ),
          );
        }
      },
      child: Scaffold(
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

              final topLevelCategories =
                  state.categories.where((c) => c.parentId == null).toList();

              return BlocBuilder<StylesBloc, StylesState>(
                builder: (context, styleState) {
                  if (styleState is! StylesLoadSuccess) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView.builder(
                    itemCount: topLevelCategories.length,
                    itemBuilder: (context, index) {
                      final category = topLevelCategories[index];
                      return _CategoryListItem(
                        category: category,
                        allCategories: state.categories,
                        categoryTotals: state.categoryTotals,
                        styles: styleState.styles,
                      );
                    },
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

class _CategoryListItem extends StatelessWidget {
  final Category category;
  final List<Category> allCategories;
  final Map<int, double> categoryTotals;
  final List<Style> styles;

  const _CategoryListItem({
    required this.category,
    required this.allCategories,
    required this.categoryTotals,
    required this.styles,
  });

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.account_balance; // Default icon
    }
  }

  Color _getColorFromHex(String? hexColor) {
    hexColor = (hexColor ?? '#FF5733').replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
    return Colors.orange; // Default color
  }

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals[category.id] ?? 0.0;
    final style = styles.firstWhereOrNull((s) => s.id == category.styleId);
    final color = _getColorFromHex(style?.colorHex);
    final iconData = _getIconData(style?.iconName);
    final children =
        allCategories.where((c) => c.parentId == category.id).toList();

    final listTile = ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.2),
        child: Icon(iconData, color: color),
      ),
      title: Text(category.name),
      subtitle: Text('Spent: ${total.toStringAsFixed(2)}'),
      onTap: () {
        context.push(AppRoutes.addEditTransaction,
            extra: {'categoryId': category.id});
      },
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _showAddEditCategoryDialog(context, category: category);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () {
              context.read<CategoriesBloc>().add(DeleteCategory(category.id!));
            },
          ),
        ],
      ),
    );

    if (children.isEmpty) {
      return listTile;
    }

    return ExpansionTile(
      title: listTile,
      children: children
          .map((child) => Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: _CategoryListItem(
                  category: child,
                  allCategories: allCategories,
                  categoryTotals: categoryTotals,
                  styles: styles,
                ),
              ))
          .toList(),
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
  int? _selectedParentId;
  CategoryType _selectedCategoryType = CategoryType.expense;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name);
    _selectedStyleId = widget.category?.styleId;
    _selectedParentId = widget.category?.parentId;
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
                Category(
                  name: name,
                  styleId: _selectedStyleId,
                  type: _selectedCategoryType,
                  parentId: _selectedParentId,
                ),
              ),
            );
      } else {
        context.read<CategoriesBloc>().add(
              UpdateCategory(
                widget.category!.copyWith(
                  name: name,
                  styleId: _selectedStyleId,
                  type: _selectedCategoryType,
                  parentId: _selectedParentId,
                ),
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
            BlocBuilder<CategoriesBloc, CategoriesState>(
              builder: (context, state) {
                if (state is CategoriesLoadSuccess) {
                  final categories = state.categories;
                  return DropdownButtonFormField<int>(
                    value: _selectedParentId,
                    decoration:
                        const InputDecoration(labelText: 'Parent Category'),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...categories
                          .where((c) => c.id != widget.category?.id)
                          .map((c) => DropdownMenuItem<int>(
                                value: c.id,
                                child: Text(c.name),
                              ))
                          .toList(),
                    ],
                    onChanged: (v) => setState(() => _selectedParentId = v),
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