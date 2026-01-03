import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/entities/account.dart';

class DayBalanceDetails extends StatelessWidget {
  final DateTime date;
  final List<Account> accounts;
  final Map<String, double> dayBalances;

  const DayBalanceDetails({
    super.key,
    required this.date,
    required this.accounts,
    required this.dayBalances,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat.currency(symbol: '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Balances on ${DateFormat.yMMMMd().format(date)}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        ...accounts.map((account) {
          final balance = dayBalances[account.id] ?? 0.0;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(account.name),
              trailing: Text(
                '${numberFormat.format(balance)} ${account.currencyCode}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: balance >= 0 ? Colors.green : Colors.red,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
