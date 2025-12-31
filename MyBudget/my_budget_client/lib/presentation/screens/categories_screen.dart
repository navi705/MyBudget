import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/presentation/widgets/category_list_item.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/widgets/delete_category_dialog.dart';
import 'package:my_budget_client/presentation/widgets/generic/generic_filter_app_bar.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart'
    show DateStep, FilterMode;
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';
import 'package:my_budget_client/presentation/widgets/category_filter_dialog.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<CategoriesBloc>().add(LoadCategories());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<CategoriesBloc>().add(LoadMoreCategories());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

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
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: BlocBuilder<CategoriesBloc, CategoriesState>(
            builder: (context, state) {
              if (state is CategoriesLoadSuccess) {
                return _CategoriesDateAppBar(state: state);
              }
              return AppBar(title: const Text('Categories'));
            },
          ),
        ),
        body: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            if (state is CategoriesLoadInProgress) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CategoriesLoadSuccess) {
              if (state.categoriesWithTotals.isEmpty) {
                return const Center(child: Text('No categories created yet.'));
              }

              final filteredCategories = state.filters.type == null
                  ? state.categoriesWithTotals
                  : state.categoriesWithTotals
                      .where((c) =>
                          c.category.type == state.filters.type)
                      .toList();

              final topLevelCategories = filteredCategories
                  .where((c) => c.category.parentId == null)
                  .toList();

              return ListView.builder(
                controller: _scrollController,
                itemCount: state.hasReachedMax
                    ? topLevelCategories.length
                    : topLevelCategories.length + 1,
                itemBuilder: (context, index) {
                  if (index >= topLevelCategories.length) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final categoryWithTotal = topLevelCategories[index];
                  return CategoryListItem(
                    categoryWithTotal: categoryWithTotal,
                    allCategoriesWithTotals: filteredCategories,
                    onTap: () => _showAddEditCategoryDialog(context,
                        category: categoryWithTotal.category),
                    mainCurrencyCode: state.mainCurrencyCode,
                    currencyDesignations: state.currencyDesignations,
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

class _CategoriesDateAppBar extends StatelessWidget {
  final CategoriesLoadSuccess state;

  const _CategoriesDateAppBar({required this.state});

  void _showCustomCalendar(BuildContext context, CategoriesLoadSuccess state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows the modal to be taller
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return BlocProvider.value(
          value: context.read<CategoriesBloc>(),
          child: CalendarStepPicker(
            initialDate: state.activeDate,
            initialRange: null,
            initialStep: state.dateStep,
            initialFilterMode: FilterMode.date,
            rangeOptionVisibility: PickerVisibility.hidden,
            onApply: (date, range, step, mode) {
              final bloc = context.read<CategoriesBloc>();
              if (state.dateStep != step) {
                bloc.add(DateStepChanged(step));
              }
              bloc.add(ActiveDateChanged(date));
            },
          ),
        );
      },
    );
  }

  String _formatDate(BuildContext context, CategoriesLoadSuccess state) {
    if (state.filterMode == FilterMode.range) {
      if (state.activeDateRange == null) return 'Select Range';
      final start =
          MaterialLocalizations.of(context).formatShortDate(state.activeDateRange!.start);
      final end =
          MaterialLocalizations.of(context).formatShortDate(state.activeDateRange!.end);
      return '$start - $end';
    }
    
    switch (state.dateStep) {
      case DateStep.day:
        return MaterialLocalizations.of(
          context,
        ).formatShortDate(state.activeDate);
      case DateStep.month:
        return MaterialLocalizations.of(
          context,
        ).formatMonthYear(state.activeDate);
      case DateStep.year:
        return state.activeDate.year.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CategoriesBloc>();
    final centerWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(
            Icons.tune,
            color: Colors.white,
          ),
          tooltip: 'Filter',
          onPressed: () => showCategoryFilterDialog(context, state.filters),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: () => bloc.add(const DatePeriodNavigated(-1)),
        ),
        InkWell(
          onTap: () => _showCustomCalendar(context, state),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            alignment: Alignment.center,
            child: Text(
              _formatDate(context, state),
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: () => bloc.add(const DatePeriodNavigated(1)),
        ),
        const SizedBox(width: 24),
        RotatedBox(
          quarterTurns: state.filters.sort == Sort.ascending ? 0 : 2,
          child: IconButton(
            icon: const Icon(
              Icons.sort,
              color: Colors.white,
            ),
            tooltip: 'Sort by Name',
            onPressed: () {
              final newSort = state.filters.sort == Sort.ascending
                  ? Sort.descending
                  : Sort.ascending;
              context.read<CategoriesBloc>().add(SortChanged(newSort));
            },
          ),
        ),
      ],
    );

    return GenericFilterAppBar(
      centerWidget: centerWidget,
      totalCountText: 'Total: ${state.categoriesWithTotals.length}',
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
  String? _selectedStyleId;
  String? _selectedParentId;
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
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedStyleId,
                    decoration: const InputDecoration(labelText: 'Style'),
                    items: state.styles.map((style) {
                      return DropdownMenuItem<String>(
                        value: style.id,
                        child: Row(
                          children: [
                            IconUtils.getIconWidget(style),
                            const SizedBox(width: 8),
                            Text(style.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedStyleId = v),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            BlocBuilder<CategoriesBloc, CategoriesState>(
              builder: (context, state) {
                if (state is CategoriesLoadSuccess) {
                  final categories = state.categoriesWithTotals
                      .map((e) => e.category);
                  return DropdownButtonFormField<String>(
                    initialValue: _selectedParentId,
                    decoration:
                        const InputDecoration(labelText: 'Parent Category'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...categories
                          .where((c) => c.id != widget.category?.id)
                          .map((c) => DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(c.name),
                              )),
                    ],
                    onChanged: (v) => setState(() => _selectedParentId = v),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            DropdownButtonFormField<CategoryType>(
              initialValue: _selectedCategoryType,
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
