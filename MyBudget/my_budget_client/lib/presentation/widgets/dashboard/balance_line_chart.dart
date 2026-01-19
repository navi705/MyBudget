import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BalanceLineChart extends StatelessWidget {
  final Map<DateTime, double> dailyNetWorth;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final String currencySymbol; // Added for tooltip

  const BalanceLineChart({
    super.key,
    required this.dailyNetWorth,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    this.currencySymbol = '', // Optional, defaults to empty
  });

  @override
  Widget build(BuildContext context) {
    if (dailyNetWorth.isEmpty) {
      return const Center(child: Text('No history data available'));
    }

    final sortedDates = dailyNetWorth.keys.toList()..sort();
    final spots = <FlSpot>[];

    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final value = dailyNetWorth[date]!;
      spots.add(FlSpot(i.toDouble(), value));

      if (value < minY) minY = value;
      if (value > maxY) maxY = value;
    }

    // Add some padding to Y axis
    final rangeY = maxY - minY;
    minY -= rangeY * 0.1;
    maxY += rangeY * 0.1;

    return Padding(
      padding: const EdgeInsets.only(right: 18, left: 12, top: 24, bottom: 12),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: rangeY > 0 ? rangeY / 5 : 1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: (sortedDates.length / 5).clamp(1, 100).toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedDates.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MM/dd').format(sortedDates[index]),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: rangeY > 0
                    ? rangeY / 3
                    : 1, // Reduced from 4 to 3 intervals
                getTitlesWidget: (value, meta) {
                  // Skip edge labels that might overlap
                  if (value == meta.min || value == meta.max) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    _formatCurrency(value),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 10),
                  );
                },
                reservedSize: 55,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
            ),
          ),
          minX: 0,
          maxX: (sortedDates.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final formattedValue = spot.y.toStringAsFixed(2);
                  final displayText = currencySymbol.isNotEmpty
                      ? '$formattedValue $currencySymbol'
                      : formattedValue;
                  return LineTooltipItem(
                    displayText,
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                    Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return value.toStringAsFixed(0);
  }
}
