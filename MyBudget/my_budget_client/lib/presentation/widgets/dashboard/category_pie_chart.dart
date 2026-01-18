import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart'; // Added
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

class CategoryPieChart extends StatelessWidget {
  final List<GroupedTransactionTotal> categoryTotals;
  final List<Category> categories;
  final List<Style> styles;
  final bool isIncome;

  const CategoryPieChart({
    super.key,
    required this.categoryTotals,
    required this.categories,
    required this.styles,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    if (categoryTotals.isEmpty) {
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
            crossAxisAlignment: CrossAxisAlignment.start,
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
    /* Using FlChart PieChart */
    return PieChart(
      PieChartData(
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
        final percentage = totalSum > 0 ? (entry.value / totalSum) : 0.0;

        return _buildCategoryItem(
          context,
          category,
          entry.value,
          percentage,
          color,
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
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
                NumberFormat.currency(
                  symbol: '',
                ).format(amount), // Assuming base currency or raw amount
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

  // ... Helpers ... (Reuse existing logic)

  List<MapEntry<String, double>> _getFilteredTotals() {
    final totalsMap = <String, double>{};
    // Filter categories by type (income/expense)
    final targetCategoryIds = categories
        .where(
          (c) => isIncome ? c.type.name == 'income' : c.type.name == 'expense',
        )
        .map((c) => c.id)
        .toSet();

    for (final total in categoryTotals) {
      if (targetCategoryIds.contains(total.categoryId)) {
        totalsMap.update(
          total.categoryId,
          (v) => v + total.total.abs(),
          ifAbsent: () => total.total.abs(),
        );
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

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(0)}%' : '',
        radius: 80, // Slightly larger
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Style? _getStyle(String? styleId) {
    if (styleId == null) return null;
    try {
      return styles.firstWhere((s) => s.id == styleId);
    } catch (_) {
      return null;
    }
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
