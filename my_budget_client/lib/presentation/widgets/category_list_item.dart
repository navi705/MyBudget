import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';

class CategoryListItem extends StatelessWidget {
  final CategoryWithTotal categoryWithTotal;
  final List<CategoryWithTotal> allCategoriesWithTotals;
  final void Function(Category) onTap;
  final String mainCurrencyCode;
  final List<CurrencyDesignation> currencyDesignations;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final void Function(LongPressStartDetails)? onLongPressStart;
  final void Function(TapUpDetails)? onSecondaryTapUp;

  const CategoryListItem({
    super.key,
    required this.categoryWithTotal,
    required this.allCategoriesWithTotals,
    required this.onTap,
    required this.mainCurrencyCode,
    required this.currencyDesignations,
    this.isSelected = false,
    this.onLongPress,
    this.onLongPressStart,
    this.onSecondaryTapUp,
  });

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
          style = styleState.styles.firstWhereOrNull(
            (s) => s.id == category.styleId,
          );
        }

        final finalStyle =
            style ??
            Style(
              id: 'default',
              name: 'Default',
              iconName: 'help_outline',
              colorHex: '#808080',
              iconType: IconType.material,
            );

        final designation = currencyDesignations.firstWhereOrNull(
          (d) => d.currencyCode == mainCurrencyCode,
        );
        final currencySymbol = designation?.value ?? mainCurrencyCode;

        final formattedTotal =
            '${MoneyFormatter.format(total, mainCurrencyCode)} $currencySymbol';

        final subtitleText = category.type == CategoryType.income
            ? context.l10n.receivedTotalLabel(formattedTotal)
            : context.l10n.spentTotalLabel(formattedTotal);

        final balanceColor = category.type == CategoryType.income
            ? Colors.green
            : Colors.red;

        final listTile = GestureDetector(
          onSecondaryTapUp: onSecondaryTapUp,
          onLongPressStart: onLongPressStart,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: IconUtils.getColorFromHex(
                  finalStyle.colorHex,
                ).withAlpha((255 * 0.15).round()),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: IconUtils.getIconWidget(finalStyle),
            ),
            title: Text(
              category.name == AppConstants.systemTransferCategoryName
                  ? context.l10n.transferLabel
                  : category.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              subtitleText,
              style: TextStyle(color: balanceColor, fontSize: 14),
            ),
            onTap: () => onTap(category),
          ),
        );

        final card = Card(
          color: isSelected ? Theme.of(context).highlightColor : null,
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
          color: isSelected ? Theme.of(context).highlightColor : null,
          elevation: 2.0,
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: ExpansionTile(
            title: listTile,
            children: children
                .map(
                  (child) => Padding(
                    padding: const EdgeInsets.only(left: 16.0),
                    child: CategoryListItem(
                      key: ValueKey(child.category.id),
                      categoryWithTotal: child,
                      allCategoriesWithTotals: allCategoriesWithTotals,
                      onTap: onTap,
                      mainCurrencyCode: mainCurrencyCode,
                      currencyDesignations: currencyDesignations,
                      isSelected: false,
                      onLongPress: onLongPress,
                      onSecondaryTapUp: onSecondaryTapUp,
                    ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
