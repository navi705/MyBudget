import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/category.dart';
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
    final filteredTotals = _getFilteredTotals();

    if (filteredTotals.isEmpty) {
      return const Center(child: Text('No data for this range'));
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1.3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: _buildSections(context, filteredTotals),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(context, filteredTotals),
      ],
    );
  }

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
      final category = categories.firstWhere((c) => c.id == entry.key);
      final style = _getStyle(category.styleId);
      final percentage = (entry.value / totalSum) * 100;

      return PieChartSectionData(
        color:
            _parseColor(style?.colorHex) ??
            _getRandomColor(category.id.hashCode),
        value: entry.value,
        title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(
    BuildContext context,
    List<MapEntry<String, double>> filteredTotals,
  ) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: filteredTotals.map((entry) {
        final category = categories.firstWhere((c) => c.id == entry.key);
        final style = _getStyle(category.styleId);
        final color =
            _parseColor(style?.colorHex) ??
            _getRandomColor(category.id.hashCode);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            Text(category.name, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      }).toList(),
    );
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
