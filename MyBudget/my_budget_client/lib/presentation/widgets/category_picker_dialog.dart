import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';

void showCategoryPickerDialog(BuildContext context,
    {required Function(String) onCategorySelected}) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      return BlocProvider.value(
        value: BlocProvider.of<CategoriesBloc>(context),
        child: CategoryPickerDialog(onCategorySelected: onCategorySelected),
      );
    },
  );
}

class CategoryPickerDialog extends StatelessWidget {
  final Function(String) onCategorySelected;

  const CategoryPickerDialog({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Category'),
      content: SizedBox(
        width: double.maxFinite,
        child: BlocBuilder<CategoriesBloc, CategoriesState>(
          builder: (context, state) {
            if (state is CategoriesLoadSuccess) {
              return ListView.builder(
                shrinkWrap: true,
                itemCount: state.categoriesWithTotals.length,
                itemBuilder: (context, index) {
                  final categoryWithTotal = state.categoriesWithTotals[index];
                  return ListTile(
                    title: Text(categoryWithTotal.category.name),
                    onTap: () {
                      onCategorySelected(categoryWithTotal.category.id!);
                      Navigator.of(context).pop();
                    },
                  );
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}
