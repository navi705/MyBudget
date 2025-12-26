import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';

class CategoryListItem extends StatelessWidget {
  final CategoryWithTotal categoryWithTotal;
  final List<CategoryWithTotal> allCategoriesWithTotals;
  final VoidCallback onTap;

  const CategoryListItem({
    super.key,
    required this.categoryWithTotal,
    required this.allCategoriesWithTotals,
    required this.onTap,
  });

  Color _getColorFromHex(String? hexColor) {
    hexColor = (hexColor ?? '#FF5733').replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final category = categoryWithTotal.category;
    final total = categoryWithTotal.total;
    final children = allCategoriesWithTotals
        .where((c) => c.category.parentId == category.id)
        .toList();

    return BlocBuilder<StylesBloc, StylesState>(
      builder: (context, styleState) {
        Style? style;
        if (styleState is StylesLoadSuccess) {
          style = styleState.styles
              .firstWhereOrNull((s) => s.id == category.styleId);
        }

        final finalStyle = style ??
            Style(
              id: 'default',
              name: 'Default',
              iconName: 'help_outline',
              colorHex: '#808080',
              iconType: IconType.material,
            );

        final color = _getColorFromHex(finalStyle.colorHex);
        final iconWidget = IconUtils.getIconWidget(finalStyle);

        final subtitleText = category.type == CategoryType.income
            ? 'Received: ${total.toStringAsFixed(2)}'
            : 'Spent: ${total.toStringAsFixed(2)}';
        
        final balanceColor = category.type == CategoryType.income
            ? Colors.green
            : Colors.red;

        final listTile = ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          leading: Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: color.withAlpha((255 * 0.15).round()),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: iconWidget,
          ),
          title: Text(
            category.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            subtitleText,
            style: TextStyle(
              color: balanceColor,
              fontSize: 14,
            ),
          ),
          onTap: onTap,
        );

        final card = Card(
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: listTile,
        );

        if (children.isEmpty) {
          return card;
        }

        return Card(
           elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ExpansionTile(
            title: listTile,
            children: children
                .map((child) => Padding(
                      padding: const EdgeInsets.only(left: 16.0),
                      child: CategoryListItem(
                        categoryWithTotal: child,
                        allCategoriesWithTotals: allCategoriesWithTotals,
                        onTap: onTap,
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}
