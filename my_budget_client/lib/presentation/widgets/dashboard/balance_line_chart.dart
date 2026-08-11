import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/chart_color_utils.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';

class BalanceLineChart extends StatelessWidget {
  final Map<DateTime, double> dailyNetWorth;
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final String currencySymbol; // Added for tooltip
  final String currencyCode; // ISO code for per-currency tooltip decimals

  const BalanceLineChart({
    super.key,
    required this.dailyNetWorth,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    this.currencySymbol = '', // Optional, defaults to empty
    this.currencyCode = '', // Optional; when set, tooltip uses ISO decimals
  });

  @override
  Widget build(BuildContext context) {
    if (dailyNetWorth.isEmpty) {
      return Center(child: Text(context.l10n.noHistoryData));
    }

    // Optimization: Check if data is already sorted to avoid redundant O(D log D) sort
    final sortedDates = dailyNetWorth.keys.toList();
    bool isSorted = true;
    for (int i = 1; i < sortedDates.length; i++) {
      if (sortedDates[i].isBefore(sortedDates[i - 1])) {
        isSorted = false;
        break;
      }
    }
    if (!isSorted) {
      sortedDates.sort();
    }

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
                  final formattedValue = currencyCode.isNotEmpty
                      ? MoneyFormatter.format(spot.y, currencyCode)
                      : spot.y.toStringAsFixed(2);
                  final displayText = currencySymbol.isNotEmpty
                      ? '$formattedValue $currencySymbol'
                      : formattedValue;

                  // Calculate percentage change from start of period
                  final startValue = spots.isNotEmpty ? spots.first.y : 0.0;
                  final currentValue = spot.y;
                  String? percentageText;
                  Color percentageColor = Colors.green;

                  // Only calculate if start value is significant to avoid division by zero
                  if (startValue.abs() > 0.001) {
                    final diff = currentValue - startValue;
                    final percent = (diff / startValue) * 100;
                    percentageText =
                        '${diff >= 0 ? '+' : ''}${percent.toStringAsFixed(2)}%';
                    percentageColor = diff >= 0 ? Colors.green : Colors.red;
                  }

                  return LineTooltipItem(
                    displayText,
                    TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    children: percentageText != null
                        ? [
                            TextSpan(
                              text: '\n$percentageText',
                              style: TextStyle(
                                color: percentageColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ]
                        : null,
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
                  ChartColorUtils.getAdaptiveColor(
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                  ChartColorUtils.getAdaptiveColor(
                    Theme.of(context).colorScheme.secondary,
                    Theme.of(context).brightness == Brightness.dark,
                  ),
                ],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    ChartColorUtils.getAdaptiveColor(
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).brightness == Brightness.dark,
                    ).withValues(alpha: 0.3),
                    ChartColorUtils.getAdaptiveColor(
                      Theme.of(context).colorScheme.secondary,
                      Theme.of(context).brightness == Brightness.dark,
                    ).withValues(alpha: 0.0),
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
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(2)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(2)}k';
    return value.toStringAsFixed(2);
  }
}
