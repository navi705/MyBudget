import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/utils/chart_color_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/balance_line_chart.dart';

class BalanceReportWidget extends StatefulWidget {
  final DateTime dateRangeStart;
  final DateTime dateRangeEnd;
  final Map<DateTime, double> dailyNetWorth;
  final Map<DateTime, Map<String, double>> dayBalances;
  final Map<String, double> currencyBreakdown; // Added
  final Map<String, double> accountBreakdown; // Added
  final List<Account> accounts;
  final String currencyCode;
  final Map<String, CurrencyDesignation> currencyDesignations; // Added

  const BalanceReportWidget({
    super.key,
    required this.dateRangeStart,
    required this.dateRangeEnd,
    required this.dailyNetWorth,
    required this.dayBalances,
    required this.currencyBreakdown, // Added
    required this.accountBreakdown, // Added
    required this.accounts,
    required this.currencyCode,
    required this.currencyDesignations, // Added
  });

  @override
  State<BalanceReportWidget> createState() => _BalanceReportWidgetState();
}

class _BalanceReportWidgetState extends State<BalanceReportWidget> {
  String? _selectedAccountId; // null means "All Accounts"
  bool _isAccountSelectorHovered = false;

  @override
  Widget build(BuildContext context) {
    // 1. Filter Data
    final isAllAccounts = _selectedAccountId == null;

    // For "All", use the pre-calculated dailyNetWorth passed from parent (which is usually total).
    // For "Single", we technically need the daily history of THAT account.
    // However, the current DashboardBloc usually calculates dailyNetWorth for ALL accounts derived from transactions.
    // LIMITATION: 'dailyNetWorth' passed here is likely TOTAL.
    // To show single account trend properly, we might need logic to extract it or we just show "Current Balance" for single.
    // OPTION: For this "Visual Refresh", let's assume valid data is passed or we filter what we can.
    // Actually, DashboardState has 'dailyNetWorth' which is TOTAL.
    // If we select a single account, we can't easily reconstruct its daily history from just 'dailyNetWorth'.
    // We would need 'dailyBalances' map for each account which might not be fully available or expensive to compute here dynamically without Bloc support.

    // DECISION: For now, if "All Accounts", show Trend + Distributions.
    // If "Single Account", just show its details and maybe hide the Chart if we don't have historical data for it ready,
    // OR just show the current balance and a "Distribution not available" message or similar.
    // User asked: "один какой-то из аккаунтов смотреть так же графк по каждому из однельности"
    // (See chart for each separately).
    // To do this properly, we likely need the Bloc to provide history for the selected account.
    // BUT checking 'DashboardState', we have `dayBalances` (Map<DateTime, Map<String, double>>).
    // This allows us to construct the chart for a single account! Awesome.

    return Column(
      children: [
        // 1. Account Filter Dropdown (constrained width on desktop)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth > 600
                  ? 400.0
                  : constraints.maxWidth;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: _buildAccountSelector(),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 2. Main Balance Chart (Trend)
                _buildMainChartSection(isAllAccounts),

                const SizedBox(height: 32),

                // 3. Distribution Charts (Only if All Accounts)
                if (isAllAccounts) ...[
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildDistributions(context),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSelector() {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isAccountSelectorHovered = true),
      onExit: (_) => setState(() => _isAccountSelectorHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.zero,
        height: 44,
        decoration: BoxDecoration(
          color: _isAccountSelectorHovered
              ? colorScheme.surfaceContainerHighest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isAccountSelectorHovered
                ? colorScheme.onSurface.withValues(alpha: 0.2)
                : colorScheme.onSurface.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: _selectedAccountId,
            isExpanded: true,
            isDense: true,
            focusColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            icon: Icon(
              Icons.unfold_more_rounded,
              color: colorScheme.onSurfaceVariant,
              size: 20,
            ),
            dropdownColor: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            onChanged: (val) {
              setState(() {
                _selectedAccountId = val;
              });
            },
            selectedItemBuilder: (BuildContext context) {
              return [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "All Accounts",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ...widget.accounts.map((acc) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      acc.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }),
              ];
            },
            items: [
              DropdownMenuItem<String?>(
                value: null,
                child: Text(
                  "All Accounts",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              ...widget.accounts.map((acc) {
                return DropdownMenuItem<String?>(
                  value: acc.id,
                  child: Row(
                    children: [
                      Text(
                        acc.name,
                        style: TextStyle(color: colorScheme.onSurface),
                      ),
                      const Spacer(),
                      Text(
                        _formatCurrency(acc.balance, acc.currencyCode),
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainChartSection(bool isAllAccounts) {
    // If specific account, we need its data.
    // NOTE: The widget props currently don't include 'dayBalances' map needed for specific account history.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Text(
          isAllAccounts ? 'Total Net Worth Trend' : 'Account Balance Trend',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: 300,
          width: double.infinity,
          padding: const EdgeInsets.only(right: 16, top: 24, bottom: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.05),
            ),
          ),
          child: BalanceLineChart(
            dailyNetWorth: _getDataForChart(),
            dateRangeStart: widget.dateRangeStart,
            dateRangeEnd: widget.dateRangeEnd,
            currencySymbol: _getCurrencySymbolForChart(),
          ),
        ),
      ],
    );
  }

  String _getCurrencySymbolForChart() {
    String currencyCode;

    if (_selectedAccountId == null) {
      // All Accounts: use the selected main currency
      currencyCode = widget.currencyCode;
    } else {
      // Specific account: use that account's currency
      final account = widget.accounts.cast<Account?>().firstWhere(
        (a) => a?.id == _selectedAccountId,
        orElse: () => null,
      );
      currencyCode = account?.currencyCode ?? widget.currencyCode;
    }

    // Look up custom designation symbol
    final designation = widget.currencyDesignations.values
        .cast<CurrencyDesignation?>()
        .firstWhere((d) => d?.currencyCode == currencyCode, orElse: () => null);
    return designation?.value ?? currencyCode;
  }

  Map<DateTime, double> _getDataForChart() {
    Map<DateTime, double> sourceData;

    if (_selectedAccountId == null) {
      sourceData = widget.dailyNetWorth;
    } else {
      // Extract history for specific account
      final singleAccountData = <DateTime, double>{};
      for (final entry in widget.dayBalances.entries) {
        final date = entry.key;
        final balancesMap = entry.value;
        if (balancesMap.containsKey(_selectedAccountId)) {
          singleAccountData[date] = balancesMap[_selectedAccountId]!;
        } else {
          singleAccountData[date] = 0.0;
        }
      }
      sourceData = singleAccountData;
    }

    // Filter to only include dates within the selected period
    final filteredData = <DateTime, double>{};
    for (final entry in sourceData.entries) {
      final date = entry.key;
      if (!date.isBefore(widget.dateRangeStart) &&
          !date.isAfter(widget.dateRangeEnd)) {
        filteredData[date] = entry.value;
      }
    }
    return filteredData;
  }

  Widget _buildDistributions(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildAccountDistribution(context)),
              const SizedBox(width: 48),
              Expanded(flex: 3, child: _buildCurrencyDistribution(context)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildAccountDistribution(context),
              const SizedBox(height: 32),
              _buildCurrencyDistribution(context),
            ],
          );
        }
      },
    );
  }

  Widget _buildAccountDistribution(BuildContext context) {
    final data = _getAccountDistribution();
    return _buildPieSection(context, 'Wealth Distribution', data);
  }

  Widget _buildCurrencyDistribution(BuildContext context) {
    final data = _getCurrencyDistribution();
    return _buildPieSection(context, 'Currency Breakdown', data);
  }

  Widget _buildPieSection(
    BuildContext context,
    String title,
    List<MapEntry<String, double>> data,
  ) {
    final total = data.fold(0.0, (sum, e) => sum + e.value);

    // Show empty state if no data for this period
    if (data.isEmpty || total <= 0) {
      return Column(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 220,
            child: Center(
              child: Text(
                'No data for this period',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: data.asMap().entries.map((item) {
                final index = item.key;
                final e = item.value;
                final percentage = total > 0 ? (e.value / total) * 100 : 0.0;
                final isLarge = percentage > 5;
                final isDarkTheme =
                    Theme.of(context).brightness == Brightness.dark;
                final baseColor = ChartColorUtils.getPaletteColor(index);
                final color = ChartColorUtils.getAdaptiveColor(
                  baseColor,
                  isDarkTheme,
                );
                final textColor = ChartColorUtils.getContrastColor(color);

                return PieChartSectionData(
                  color: color,
                  value: e.value,
                  title: isLarge ? '${percentage.toStringAsFixed(2)}%' : '',
                  radius: 60,
                  titleStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: data.asMap().entries.map((item) {
            final index = item.key;
            final e = item.value;
            final percentage = total > 0 ? (e.value / total) * 100 : 0.0;
            final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
            final color = ChartColorUtils.getAdaptiveColor(
              ChartColorUtils.getPaletteColor(index),
              isDarkTheme,
            );
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key} ${percentage.toStringAsFixed(2)}% (${NumberFormat('#,##0.00', 'en_US').format(e.value).replaceAll(',', ' ')} ${widget.currencyCode})',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<MapEntry<String, double>> _getAccountDistribution() {
    final map = <String, double>{};
    for (final acc in widget.accounts) {
      // Use pre-calculated converted balance from Bloc
      final convertedBalance = widget.accountBreakdown[acc.id] ?? 0.0;
      if (convertedBalance > 0) {
        map[acc.name] = convertedBalance;
      }
    }
    return map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  List<MapEntry<String, double>> _getCurrencyDistribution() {
    // Use pre-calculated currency breakdown from Bloc (already converted)
    return widget.currencyBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
  }

  String _formatCurrency(double amount, String code) {
    return '${NumberFormat('#,##0.00', 'en_US').format(amount).replaceAll(',', ' ')} $code';
  }
}
