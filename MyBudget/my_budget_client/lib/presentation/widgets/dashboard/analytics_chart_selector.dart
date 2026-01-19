import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/account.dart';
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

  // NOTE: Category/Style params might not be needed if removing category view,
  // but kept for compatibility until cleanup or for Distribution colors.

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
  });

  @override
  State<BalanceReportWidget> createState() => _BalanceReportWidgetState();
}

class _BalanceReportWidgetState extends State<BalanceReportWidget> {
  String? _selectedAccountId; // null means "All Accounts"

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedAccountId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          hint: const Text("All Accounts (Total Net Worth)"),
          onChanged: (val) {
            setState(() {
              _selectedAccountId = val;
            });
          },
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text(
                "All Accounts",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...widget.accounts.map((acc) {
              return DropdownMenuItem<String?>(
                value: acc.id,
                child: Row(
                  children: [
                    Text(acc.name),
                    const SizedBox(width: 8),
                    Text(
                      _formatCurrency(acc.balance, acc.currencyCode),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMainChartSection(bool isAllAccounts) {
    // If specific account, we need its data.
    // NOTE: The widget props currently don't include 'dayBalances' map needed for specific account history.
    // I need to add that to the widget parameters in the next step (updating dashboard_screen.dart).
    // For now I will assume 'dailyNetWorth' is correct for 'All', and I'll add a placeholder or update props.
    // Wait, I can't access data I don't have.
    // I will modify the widget constructor to accept 'dayBalances' in this same edit to be safe,
    // or relying on a Todo.
    // Let's rely on adding `dayBalances` property.

    // But since I am editing the file now, I should add the property definitions.
    // See updated class definition below.

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isAllAccounts ? 'Total Net Worth Trend' : 'Account Balance Trend',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
          width: double.infinity,
          padding: const EdgeInsets.only(right: 16, top: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: BalanceLineChart(
            dailyNetWorth: _getDataForChart(),
            dateRangeStart: widget.dateRangeStart,
            dateRangeEnd: widget.dateRangeEnd,
            // Pass color if single account?
          ),
        ),
      ],
    );
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
        if (constraints.maxWidth > 700) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAccountDistribution(context)),
              const SizedBox(width: 24),
              Expanded(child: _buildCurrencyDistribution(context)),
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
              sections: data.map((e) {
                final percentage = total > 0 ? (e.value / total) * 100 : 0.0;
                final isLarge = percentage > 5;
                return PieChartSectionData(
                  color: _getRandomColor(e.key.hashCode),
                  value: e.value,
                  title: isLarge ? '${percentage.toStringAsFixed(1)}%' : '',
                  radius: 60,
                  titleStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
          children: data.map((e) {
            final percentage = total > 0 ? (e.value / total) * 100 : 0.0;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getRandomColor(e.key.hashCode),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${e.key} ${percentage.toStringAsFixed(0)}%',
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

  Color _getRandomColor(int seed) {
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.amber,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.cyan,
      Colors.indigo,
    ];
    return colors[seed % colors.length];
  }

  String _formatCurrency(double amount, String code) {
    return NumberFormat.simpleCurrency(
      name: code,
      decimalDigits: 2,
    ).format(amount);
  }
}
