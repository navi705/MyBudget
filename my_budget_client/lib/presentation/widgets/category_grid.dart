import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/app_spacing.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';

/// Picker-first view of the categories: one round icon per category with the
/// amount under it, instead of a full-width row each.
///
/// The list view answers "what did this category cost me", and it needs a whole
/// row per category to do it. Choosing where to put a new expense is a
/// different job: it is recognition, not reading, and on a phone the list shows
/// four or five candidates at a time when the user has thirty. The grid trades
/// the per-row detail for roughly four times the categories on screen.
class CategoryGrid extends StatefulWidget {
  /// Categories with no parent, in the order the screen decided to show them.
  final List<CategoryWithTotal> topLevelCategories;

  /// Every category the filter left, parents and children alike. Children are
  /// looked up in here.
  final List<CategoryWithTotal> allCategoriesWithTotals;

  final Set<String> selectedCategoryIds;
  final String mainCurrencyCode;
  final List<CurrencyDesignation> currencyDesignations;
  final void Function(Category) onTap;
  final void Function(Category, Offset globalPosition)? onContextMenu;
  final ScrollController? controller;

  /// Shows a spinner in the last cell while the next page loads.
  final bool isLoadingMore;

  final EdgeInsets padding;

  const CategoryGrid({
    super.key,
    required this.topLevelCategories,
    required this.allCategoriesWithTotals,
    required this.selectedCategoryIds,
    required this.mainCurrencyCode,
    required this.currencyDesignations,
    required this.onTap,
    this.onContextMenu,
    this.controller,
    this.isLoadingMore = false,
    this.padding = EdgeInsets.zero,
  });

  /// Key for the tile of [categoryId].
  static ValueKey<String> tileKey(String categoryId) =>
      ValueKey<String>('category-grid-tile-$categoryId');

  /// Key for the control that leaves a drilled-into parent.
  static const ValueKey<String> backKey = ValueKey<String>(
    'category-grid-back',
  );

  @override
  State<CategoryGrid> createState() => _CategoryGridState();
}

class _CategoryGridState extends State<CategoryGrid> {
  /// The parent the user drilled into, or null at the top level.
  ///
  /// The list view nests children in an ExpansionTile, which a grid cannot do
  /// without leaving a hole in the middle of it. Drilling in one level keeps
  /// every child reachable and keeps the tile size constant.
  String? _openParentId;

  List<CategoryWithTotal> _childrenOf(String parentId) => widget
      .allCategoriesWithTotals
      .where((c) => c.category.parentId == parentId)
      .toList();

  @override
  void didUpdateWidget(CategoryGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The open parent can be deleted, filtered out or moved under someone else
    // while its children are on screen. Falling back to the top level beats
    // showing an empty grid with no way out.
    final openParentId = _openParentId;
    if (openParentId != null &&
        !widget.allCategoriesWithTotals.any(
          (c) => c.category.id == openParentId,
        )) {
      _openParentId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final openParent = _openParentId == null
        ? null
        : widget.allCategoriesWithTotals.firstWhereOrNull(
            (c) => c.category.id == _openParentId,
          );

    // Inside a parent the grid shows the parent itself first: the money can be
    // booked against it directly, and the list view allows exactly that.
    final entries = openParent == null
        ? widget.topLevelCategories
        : [openParent, ..._childrenOf(openParent.category.id!)];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Roughly 110dp per tile, which fits the icon, a two-line name and the
        // amount without clipping at the largest text scale the app ships with.
        final columns = (constraints.maxWidth / 110).floor().clamp(3, 8);

        return CustomScrollView(
          controller: widget.controller,
          slivers: [
            if (openParent != null)
              SliverToBoxAdapter(
                child: _DrillHeader(
                  parent: openParent.category,
                  onBack: () => setState(() => _openParentId = null),
                ),
              ),
            SliverPadding(
              padding: widget.padding,
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.78,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final entry = entries[index];
                  final category = entry.category;
                  final children = _childrenOf(category.id!);
                  // Inside a parent, the parent's own tile must not offer to
                  // drill into itself again.
                  final canDrillIn = openParent == null && children.isNotEmpty;

                  return CategoryGridTile(
                    key: CategoryGrid.tileKey(category.id!),
                    categoryWithTotal: entry,
                    childCount: canDrillIn ? children.length : 0,
                    isSelected: widget.selectedCategoryIds.contains(
                      category.id,
                    ),
                    mainCurrencyCode: widget.mainCurrencyCode,
                    currencyDesignations: widget.currencyDesignations,
                    onTap: () {
                      if (canDrillIn && widget.selectedCategoryIds.isEmpty) {
                        setState(() => _openParentId = category.id);
                      } else {
                        widget.onTap(category);
                      }
                    },
                    onContextMenu: widget.onContextMenu == null
                        ? null
                        : (position) =>
                              widget.onContextMenu!(category, position),
                  );
                }, childCount: entries.length),
              ),
            ),
            if (widget.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DrillHeader extends StatelessWidget {
  final Category parent;
  final VoidCallback onBack;

  const _DrillHeader({required this.parent, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            key: CategoryGrid.backKey,
            // Back points at the start edge, which is the right-hand one in
            // ar / ur, so the glyph has to flip with the text direction.
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.arrow_forward
                  : Icons.arrow_back,
            ),
            tooltip: context.l10n.categoriesGridBackTooltip,
            onPressed: onBack,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              parent.name,
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// One category in [CategoryGrid]: coloured disc, name, amount.
class CategoryGridTile extends StatelessWidget {
  final CategoryWithTotal categoryWithTotal;

  /// Number of sub-categories reachable by tapping this tile; 0 hides the
  /// badge and makes the tap select the category itself.
  final int childCount;

  final bool isSelected;
  final String mainCurrencyCode;
  final List<CurrencyDesignation> currencyDesignations;
  final VoidCallback onTap;
  final void Function(Offset globalPosition)? onContextMenu;

  const CategoryGridTile({
    super.key,
    required this.categoryWithTotal,
    required this.childCount,
    required this.isSelected,
    required this.mainCurrencyCode,
    required this.currencyDesignations,
    required this.onTap,
    this.onContextMenu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = categoryWithTotal.category;

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
        final color = IconUtils.getColorFromHex(finalStyle.colorHex);

        final designation = currencyDesignations.firstWhereOrNull(
          (d) => d.currencyCode == mainCurrencyCode,
        );
        final currencySymbol = designation?.value ?? mainCurrencyCode;
        final amount =
            '${MoneyFormatter.format(categoryWithTotal.total, mainCurrencyCode)} '
            '$currencySymbol';

        final name = category.name == AppConstants.systemTransferCategoryName
            ? context.l10n.transferLabel
            : category.name;

        return GestureDetector(
          onSecondaryTapUp: onContextMenu == null
              ? null
              : (details) => onContextMenu!(details.globalPosition),
          onLongPressStart: onContextMenu == null
              ? null
              : (details) => onContextMenu!(details.globalPosition),
          child: Semantics(
            selected: isSelected,
            button: true,
            // The disc, the name and the amount are three separate Text/Icon
            // nodes that only mean anything together.
            label: '$name, $amount',
            excludeSemantics: true,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? theme.highlightColor : null,
                  borderRadius: BorderRadius.circular(AppSpacing.sm),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: IconUtils.getIconWidget(finalStyle, size: 24),
                        ),
                        if (childCount > 0)
                          PositionedDirectional(
                            end: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: color, width: 1),
                              ),
                              child: Text(
                                '$childCount',
                                style: theme.textTheme.labelSmall,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      amount,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: MoneyColors.of(context).forDirection(
                          isIncome: category.type == CategoryType.income,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
