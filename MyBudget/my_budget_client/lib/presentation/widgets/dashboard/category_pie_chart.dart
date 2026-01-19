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
        final double maxDiameter;
        if (isWide) {
          // In Row: (Total - Gap) * (0.35)
          // Cap at 280 to keep it smaller in windowed mode
          double calculated = (constraints.maxWidth - 24) * 0.35;
          maxDiameter = calculated > 280.0 ? 280.0 : calculated;
        } else {
          // In Column: min(width, fixed height)
          // Cap at 240 for mobile/narrow
          maxDiameter = constraints.maxWidth < 240
              ? constraints.maxWidth
              : 240.0;
        }

        // Calculate responsive dimensions
        // Safe margin to prevent clipping
        final double safeDiameter = maxDiameter > 32
            ? maxDiameter - 32
            : maxDiameter;
        final double totalRadius = safeDiameter / 2;

        // Maintain roughly 1:2 ratio between center hole and section ring
        // But clamp minimums so it doesn't vanish on very small screens
        final double centerRadius = (totalRadius * 0.4).clamp(20.0, 60.0);
        final double sectionRadius = (totalRadius * 0.6).clamp(30.0, 90.0);

        // Recalculate diameter based on clamped radii to be exact
        // This ensures the chart fits perfectly in the sized box we return
        final double actualDiameter =
            (centerRadius + sectionRadius) * 2 + 40; // +40 margin

        if (isWide) {
          return Row(
            crossAxisAlignment:
                CrossAxisAlignment.center, // Vertically center with list
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Constrain the chart side
              Container(
                constraints: BoxConstraints(
                  maxWidth: actualDiameter,
                  maxHeight: actualDiameter,
                ),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: _buildPieChart(
                    context,
                    filteredTotals,
                    centerRadius,
                    sectionRadius,
                  ),
                ),
              ),
              const SizedBox(width: 48), // Increased gap
              Expanded(child: _buildCategoryList(context, filteredTotals)),
            ],
          );
        } else {
          return Column(
            children: [
              SizedBox(
                height: isWide ? maxDiameter : 300,
                child: _buildPieChart(
                  context,
                  filteredTotals,
                  centerRadius,
                  sectionRadius,
                ),
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
    double centerRadius,
    double sectionRadius,
  ) {
    return PieChart(
      PieChartData(
        startDegreeOffset: -90, // Start from 12 o'clock
        sectionsSpace: 2,
        centerSpaceRadius: centerRadius,
        sections: _buildSections(context, filteredTotals, sectionRadius),
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
    double sectionRadius,
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
      // Adjust label visibility threshold based on radius
      // Smaller radius = less space for text
      final labelThreshold = sectionRadius < 50
          ? 20
          : (sectionRadius < 80 ? 10 : 5);

      if (percentage > labelThreshold + 10) {
        // Large slice: Show everything
        title = '${percentage.toStringAsFixed(0)}%\n$formattedValue';
      } else if (percentage > labelThreshold) {
        // Medium slice: Show only percentage
        title = '${percentage.toStringAsFixed(0)}%';
      }
      // Small slice: Show nothing to prevent clutter

      return PieChartSectionData(
        color: adjustedColor,
        value: entry.value,
        title: title,
        radius: sectionRadius,
        titleStyle: TextStyle(
          fontSize: (sectionRadius / 7.5).clamp(
            9.0,
            14.0,
          ), // Responsive font size
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
      Colors.amber, // Was Colors.yellow, changed to Amber for better visibility
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
