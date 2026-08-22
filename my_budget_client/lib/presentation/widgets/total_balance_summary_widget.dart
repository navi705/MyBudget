import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/widgets/currency_selection_dialog.dart';

class TotalBalanceSummaryWidget extends StatelessWidget {
  final AccountsLoadSuccess accountsState;
  final CurrencyConverterLoadSuccess converterState;

  const TotalBalanceSummaryWidget({
    super.key,
    required this.accountsState,
    required this.converterState,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (converterState.selectedCurrencies.isEmpty &&
        accountsState.accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final accountCurrencies = accountsState.accounts
        .map((a) => a.currencyCode)
        .toSet()
        .map((code) => _getCurrencyByCode(code))
        .whereType<Currency>()
        .toList();

    // Determine which currencies to show for Total Net Worth
    // If none selected, fallback to Base Currency
    List<Currency> currenciesToShow = converterState.selectedCurrencies;
    if (currenciesToShow.isEmpty) {
      final base = _getCurrencyByCode(converterState.baseCurrencyCode);
      if (base != null) {
        currenciesToShow = [base];
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block 1: Total Net Worth (Selected Currencies or Base)
          if (currenciesToShow.isNotEmpty) ...[
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: false, // Auto-expand if showing Total
                title: Text(
                  l10n.totalNetWorth,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  onPressed: () async {
                    final results = await showDialog<List<Currency>>(
                      context: context,
                      builder: (context) => CurrencySelectionDialog(
                        allCurrencies: converterState.allCurrencies,
                        selectedCurrencies: converterState.selectedCurrencies,
                      ),
                    );

                    if (results != null && context.mounted) {
                      final bloc = context.read<CurrencyConverterBloc>();
                      final current = converterState.selectedCurrencies;
                      for (final c in results) {
                        if (!current.any((curr) => curr.code == c.code)) {
                          bloc.add(AddSelectedCurrency(c));
                        }
                      }
                      for (final c in current) {
                        if (!results.any((curr) => curr.code == c.code)) {
                          bloc.add(RemoveSelectedCurrency(c));
                        }
                      }
                    }
                  },
                ),
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.start,
                    children: currenciesToShow.map((currency) {
                      return _buildCurrencySection(
                        context,
                        currency,
                        accountsState.accounts, // Use ALL accounts
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],

          // Block 2: Currency Breakdown (Account Currencies)
          if (accountCurrencies.isNotEmpty) ...[
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(
                  l10n.currencyBreakdown,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                initiallyExpanded: false,
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.start,
                    children: accountCurrencies.map((currency) {
                      // Filter accounts matching this currency
                      final filteredAccounts = accountsState.accounts
                          .where((a) => a.currencyCode == currency.code)
                          .toList();

                      return _buildCurrencySection(
                        context,
                        currency,
                        filteredAccounts,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Currency? _getCurrencyByCode(String code) {
    try {
      return converterState.allCurrencies.firstWhere((c) => c.code == code);
    } catch (_) {
      return null;
    }
  }

  Widget _buildCurrencySection(
    BuildContext context,
    Currency currency,
    List<Account> accounts,
  ) {
    final l10n = context.l10n;
    // 1. Balance
    final unconvertible = <String>{};
    final nominalBalance = totalBalanceFor(
      currency: currency,
      accounts: accounts,
      converter: converterState.converter,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      unconvertible: unconvertible,
    );

    final realBalance = totalBalanceFor(
      currency: currency,
      accounts: accounts,
      converter: converterState.converter,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      balancesOverride: accountsState.realBalances,
    );

    final prevBalance = totalBalanceFor(
      currency: currency,
      accounts: accounts,
      converter: converterState.converter,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      balancesOverride: accountsState.previousPeriodBalances,
    );

    final prevRealBalance = totalBalanceFor(
      currency: currency,
      accounts: accounts,
      converter: converterState.converter,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      balancesOverride: accountsState.previousPeriodRealBalances,
    );

    // 2. Income
    final nominalIncome = _calcTotal(
      currency,
      accountsState.accountIncomes,
      accounts,
    );
    final realIncome = _calcTotal(
      currency,
      accountsState.accountRealIncomes,
      accounts,
    );
    final prevIncome = _calcTotal(
      currency,
      accountsState.previousAccountIncomes,
      accounts,
    );
    final prevRealIncome = _calcTotal(
      currency,
      accountsState.previousAccountRealIncomes,
      accounts,
    );

    // 3. Expense
    final nominalExpense = _calcTotal(
      currency,
      accountsState.accountExpenses,
      accounts,
    );
    final prevExpense = _calcTotal(
      currency,
      accountsState.previousAccountExpenses,
      accounts,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ensure card fits content
          children: [
            Text(
              currency.code,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min, // Wrap width
                children: [
                  _buildMetricColumn(
                    context,
                    l10n.metricBalance,
                    nominalBalance,
                    prevBalance,
                    realBalance,
                    prevRealBalance,
                    Colors.blue,
                    currency.code,
                  ),
                  const SizedBox(width: 24),
                  _buildMetricColumn(
                    context,
                    l10n.metricIncome,
                    nominalIncome,
                    prevIncome,
                    realIncome, // Restore Real Income
                    prevRealIncome,
                    MoneyColors.of(context).inflow,
                    currency.code,
                  ),
                  const SizedBox(width: 24),
                  _buildMetricColumn(
                    context,
                    l10n.metricExpense,
                    nominalExpense,
                    prevExpense,
                    null, // Hide Real Expense
                    null,
                    MoneyColors.of(context).outflow,
                    currency.code, // Pass symbol/code
                  ),
                ],
              ),
            ),
            // A total that quietly leaves out an account is a wrong number
            // presented as a right one. Say which currencies had no rate.
            if (unconvertible.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  l10n.dashboardUnconvertibleCurrencies(
                    (unconvertible.toList()..sort()).join(', '),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MoneyColors.of(context).unconvertible,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    BuildContext context,
    String label,
    double nominal,
    double prevNominal,
    double? real,
    double? prevReal,
    Color color,
    String symbol,
  ) {
    final l10n = context.l10n;

    // Relaxed hiding: allow small non-zero values
    const epsilon = 0.000001;
    if (nominal.abs() < epsilon &&
        (real == null || real.abs() < epsilon) &&
        prevNominal.abs() < epsilon) {
      if (label != "Balance") return const SizedBox.shrink();
    }

    final nominalDiff = nominal - prevNominal;
    final realDiff = (real != null && prevReal != null) ? real - prevReal : 0.0;

    // Percentages
    final nominalPct = prevNominal != 0
        ? (nominal - prevNominal) / prevNominal.abs() * 100
        : 0.0;
    final realPct = (real != null && prevReal != null && prevReal != 0)
        ? (real - prevReal) / prevReal.abs() * 100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        // Nominal
        SelectableText.rich(
          TextSpan(
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 18,
            ),
            children: [
              TextSpan(
                text: '${MoneyFormatter.format(nominal, symbol)} $symbol',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              if (nominalDiff.abs() >= 0.01) ...[
                TextSpan(
                  text: '  ${l10n.metricChange}: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                TextSpan(
                  text:
                      '${MoneyFormatter.format(nominalDiff, symbol, signed: true)} $symbol (${nominalPct > 0 ? '+' : ''}${nominalPct.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: MoneyColors.of(context).forAmount(nominalDiff),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Real
        if (real != null) ...[
          const SizedBox(height: 2),
          SelectableText.rich(
            TextSpan(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
              ),
              children: [
                TextSpan(text: '${l10n.metricReal}: '),
                TextSpan(
                  text: '${MoneyFormatter.format(real, symbol)} $symbol',
                ),
                if (realDiff.abs() >= 0.01) ...[
                  const TextSpan(text: ' '),
                  TextSpan(
                    text:
                        '${MoneyFormatter.format(realDiff, symbol, signed: true)} $symbol (${realPct > 0 ? '+' : ''}${realPct.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: MoneyColors.of(context).forAmount(realDiff),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _calcTotal(
    Currency currency,
    Map<String, double> balances,
    List<Account> accounts,
  ) {
    return totalBalanceFor(
      currency: currency,
      accounts: accounts,
      converter: converterState.converter,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      balancesOverride: balances,
    );
  }
}
