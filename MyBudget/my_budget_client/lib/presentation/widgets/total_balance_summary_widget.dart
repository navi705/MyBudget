import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block 1: Total Net Worth (Selected Currencies)
          if (converterState.selectedCurrencies.isNotEmpty) ...[
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: false,
                title: Text(
                  'Total Net Worth',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    alignment: WrapAlignment.start,
                    children: converterState.selectedCurrencies.map((currency) {
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
                  'Currency Breakdown',
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
    // 1. Balance
    final nominalBalance = totalBalanceFor(
      currency: currency,
      accounts: accounts,
      exchangeRates: converterState.exchangeRates,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      groupedRates: converterState.groupedRates,
    );

    final realBalance = totalBalanceFor(
      currency: currency,
      accounts: accounts,
      exchangeRates: converterState.exchangeRates,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      groupedRates: converterState.groupedRates,
      balancesOverride: accountsState.realBalances,
    );

    final prevBalance = totalBalanceFor(
      currency: currency,
      accounts: accounts,
      exchangeRates: converterState.exchangeRates,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      groupedRates: converterState.groupedRates,
      balancesOverride: accountsState.previousPeriodBalances,
    );

    final prevRealBalance = totalBalanceFor(
      currency: currency,
      accounts: accounts,
      exchangeRates: converterState.exchangeRates,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      groupedRates: converterState.groupedRates,
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
    final realExpense = _calcTotal(
      currency,
      accountsState.accountRealExpenses,
      accounts,
    );
    final prevExpense = _calcTotal(
      currency,
      accountsState.previousAccountExpenses,
      accounts,
    );
    final prevRealExpense = _calcTotal(
      currency,
      accountsState.previousAccountRealExpenses,
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
                    "Balance",
                    nominalBalance,
                    prevBalance,
                    realBalance,
                    prevRealBalance,
                    Colors.blue,
                  ),
                  const SizedBox(width: 24),
                  _buildMetricColumn(
                    context,
                    "Income",
                    nominalIncome,
                    prevIncome,
                    realIncome,
                    prevRealIncome,
                    Colors.green,
                  ),
                  const SizedBox(width: 24),
                  _buildMetricColumn(
                    context,
                    "Expense",
                    nominalExpense,
                    prevExpense,
                    realExpense,
                    prevRealExpense,
                    Colors.red,
                  ),
                ],
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
    double real,
    double prevReal,
    Color color,
  ) {
    if (nominal.abs() < 0.01 && real.abs() < 0.01 && prevNominal.abs() < 0.01) {
      if (label != "Balance") return const SizedBox.shrink();
    }

    final formatter = NumberFormat.decimalPattern();
    final nominalDiff = nominal - prevNominal;
    final realDiff = real - prevReal;

    // Percentages
    final nominalPct = prevNominal != 0
        ? (nominal - prevNominal) / prevNominal.abs() * 100
        : 0.0;
    // final realPct = prevReal != 0 ? (real - prevReal) / prevReal.abs() * 100 : 0.0;

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
                text: formatter.format(nominal).replaceAll(',', ' '),
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              if (nominalDiff.abs() >= 0.01) ...[
                TextSpan(
                  text:
                      ' ${nominalDiff > 0 ? '+' : ''}${formatter.format(nominalDiff).replaceAll(',', ' ')} (${nominalPct.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: nominalDiff > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Real
        const SizedBox(height: 2),
        SelectableText.rich(
          TextSpan(
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
              fontSize: 14,
            ),
            children: [
              const TextSpan(text: 'Real: '),
              TextSpan(text: formatter.format(real).replaceAll(',', ' ')),
              if (realDiff.abs() >= 0.01) ...[
                const TextSpan(text: ' '),
                TextSpan(
                  text:
                      '${realDiff > 0 ? '+' : ''}${formatter.format(realDiff).replaceAll(',', ' ')}',
                  style: TextStyle(
                    fontSize: 12,
                    color: realDiff > 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
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
      exchangeRates: converterState.exchangeRates,
      baseCurrencyCode: converterState.baseCurrencyCode,
      date: accountsState.activeDate,
      groupedRates: converterState.groupedRates,
      balancesOverride: balances,
    );
  }
}
