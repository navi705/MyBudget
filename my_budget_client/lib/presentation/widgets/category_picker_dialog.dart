import 'package:flutter/material.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/categories/categories_bloc.dart';
import 'package:my_budget_client/core/utils/dialog_utils.dart';

void showCategoryPickerDialog(
  BuildContext context, {
  required Function(String) onCategorySelected,
}) {
  DialogUtils.showAppDialog(
    context: context,
    resizeToAvoidBottomInset: false,
    child: BlocProvider.value(
      value: BlocProvider.of<CategoriesBloc>(context),
      child: CategoryPickerDialog(onCategorySelected: onCategorySelected),
    ),
  );
}

class CategoryPickerDialog extends StatelessWidget {
  final Function(String) onCategorySelected;

  const CategoryPickerDialog({super.key, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.selectCategoryTitle),
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
                    title: Text(
                      categoryWithTotal.category.name ==
                              AppConstants.systemTransferCategoryName
                          ? context.l10n.transferLabel
                          : categoryWithTotal.category.name,
                    ),
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
