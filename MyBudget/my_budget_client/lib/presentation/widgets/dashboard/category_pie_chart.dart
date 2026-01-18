import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<String, double>
  categoryConvertedTotals; // Changed from List<GroupedTransactionTotal>
  final List<Category> categories;
  final List<Style> styles;
  final bool isIncome;
  final String currencyCode; // Added

  const CategoryPieChart({
    super.key,
    required this.categoryConvertedTotals,
    required this.categories,
    required this.styles,
    required this.isIncome,
    required this.currencyCode, // Added
  });

  @override
  Widget build(BuildContext context) {
    if (categoryConvertedTotals.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data for this period')),
      );
    }

    final filteredTotals = _getFilteredTotals();
    if (filteredTotals.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data for this range')),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Vertically center with list
            children: [
              Expanded(
                flex: 2,
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildPieChart(context, filteredTotals),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: _buildCategoryList(context, filteredTotals),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              SizedBox(
                height: 300,
                child: _buildPieChart(context, filteredTotals),
              ),
              const SizedBox(height: 24),
              _buildCategoryList(context, filteredTotals),
            ],
          );
        }
      },
    );
  }

  Widget _buildPieChart(
    BuildContext context,
    List<MapEntry<String, double>> filteredTotals,
  ) {
    return PieChart(
      PieChartData(
        startDegreeOffset: -90, // Start from 12 o'clock
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: _buildSections(context, filteredTotals),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    List<MapEntry<String, double>> filteredTotals,
  ) {
    final totalSum = filteredTotals.fold(
      0.0,
      (sum, entry) => sum + entry.value,
    );

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTotals.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = filteredTotals[index];
        final category = categories.firstWhere(
          (c) => c.id == entry.key,
          orElse: () => Category(
            id: 'unknown',
            name: 'Unknown',
            type: CategoryType.expense,
            styleId: null,
          ),
        );
        final style = _getStyle(category.styleId);
        final color =
            _parseColor(style?.colorHex) ??
            _getRandomColor(category.id.hashCode);

        final iconWidget = style != null
            ? IconUtils.getIconWidget(style)
            : const Icon(Icons.category, color: Colors.white, size: 16);

        final percentage = totalSum > 0 ? (entry.value / totalSum) : 0.0;

        return _buildCategoryItem(
          context,
          category,
          entry.value,
          percentage,
          color,
          iconWidget,
        );
      },
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    Category category,
    double amount,
    double percentage,
    Color color,
    Widget iconWidget,
  ) {
    final theme = Theme.of(context);
    // Currency formatting with symbol at end
    final numberFormat = NumberFormat.currency(name: currencyCode, symbol: '');
    final symbol = NumberFormat.simpleCurrency(
      name: currencyCode,
    ).currencySymbol;
    final formattedAmount = '${numberFormat.format(amount).trim()} $symbol';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: FittedBox(child: iconWidget),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                formattedAmount, // Updated
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: theme.colorScheme.surfaceDim,
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helpers

  List<MapEntry<String, double>> _getFilteredTotals() {
    final totalsMap = <String, double>{};
    final targetCategoryIds = categories
        .where(
          (c) => isIncome ? c.type.name == 'income' : c.type.name == 'expense',
        )
        .map((c) => c.id)
        .toSet();

    // Iterate over the converted totals map
    for (final entry in categoryConvertedTotals.entries) {
      if (targetCategoryIds.contains(entry.key)) {
        // Use .abs() to ensure positive magnitude for chart and percentages
        totalsMap[entry.key] = entry.value.abs();
      }
    }

    return totalsMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  List<PieChartSectionData> _buildSections(
    BuildContext context,
    List<MapEntry<String, double>> filteredTotals,
  ) {
    final totalSum = filteredTotals.fold(
      0.0,
      (sum, entry) => sum + entry.value,
    );

    return filteredTotals.map((entry) {
      final category = categories.firstWhere(
        (c) => c.id == entry.key,
        orElse: () => Category(
          id: 'unknown',
          name: 'Unknown',
          type: CategoryType.expense,
          styleId: null,
        ),
      );
      final style = _getStyle(category.styleId);
      final percentage = totalSum > 0 ? (entry.value / totalSum) * 100 : 0.0;
      final color =
          _parseColor(style?.colorHex) ?? _getRandomColor(category.id.hashCode);

      // Compact format for chart slice
      final compactFormat = NumberFormat.compact();
      final symbol = NumberFormat.simpleCurrency(
        name: currencyCode,
      ).currencySymbol;
      final formattedValue = '${compactFormat.format(entry.value)}$symbol';

      // SMART FORMULA: Adjust color to harmonize with background
      final isThemeDark = Theme.of(context).brightness == Brightness.dark;
      Color adjustedColor = color;

      try {
        final hsl = HSLColor.fromColor(color);
        if (isThemeDark) {
          // In dark mode: ensure colors aren't too dark (visibilty) or too pastel (contrast)
          // Boost lightness slightly if very dark, boost saturation if very dull
          adjustedColor = hsl
              .withLightness(hsl.lightness.clamp(0.4, 0.8))
              .withSaturation(hsl.saturation.clamp(0.6, 1.0))
              .toColor();
        } else {
          // In light mode: ensure colors aren't too bright (washed out against white/light card)
          // standard colors usually look okay, but maybe clamp lightness
          adjustedColor = hsl
              .withLightness(hsl.lightness.clamp(0.3, 0.7))
              .toColor();
        }
      } catch (_) {
        // Fallback if conversion fails (rare)
      }

      // Determine text color based on ADJUSTED background luminance
      final isDarkBg = adjustedColor.computeLuminance() < 0.5;
      final textColor = isDarkBg ? Colors.white : Colors.black;

      // Smart label logic
      String title = '';
      if (percentage > 15) {
        // Large slice: Show everything
        title = '${percentage.toStringAsFixed(0)}%\n$formattedValue';
      } else if (percentage > 5) {
        // Medium slice: Show only percentage
        title = '${percentage.toStringAsFixed(0)}%';
      }
      // Small slice (< 5%): Show nothing to prevent clutter

      return PieChartSectionData(
        color: adjustedColor,
        value: entry.value,
        title: title,
        radius: 80,
        titleStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      );
    }).toList();
  }

  Style? _getStyle(String? styleId) {
    if (styleId == null) return null;
    return styles.firstWhereOrNull((s) => s.id == styleId);
  }

  Color? _parseColor(String? hex) {
    if (hex == null) return null;
    try {
      String formattedHex = hex.replaceAll('#', '');
      if (formattedHex.length == 6) {
        formattedHex = 'FF$formattedHex';
      }
      return Color(int.parse('0x$formattedHex'));
    } catch (_) {
      return null;
    }
  }

  Color _getRandomColor(int seed) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
      Colors.indigo,
    ];
    return colors[seed % colors.length];
  }
}
