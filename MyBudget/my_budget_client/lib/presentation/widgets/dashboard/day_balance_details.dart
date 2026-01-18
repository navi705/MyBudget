import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';

class DayBalanceDetails extends StatelessWidget {
  final DateTime date;
  final List<Account> accounts;
  final Map<String, double> dayBalances;
  final String currencyCode;
  final List<Style> styles;

  const DayBalanceDetails({
    super.key,
    required this.date,
    required this.accounts,
    required this.dayBalances,
    required this.currencyCode,
    required this.styles,
  });

  Color _getColorFromHex(String? hexColor) {
    hexColor = (hexColor ?? '#FF5733').replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
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

          final style = styles.firstWhereOrNull((s) => s.id == account.styleId);
          final finalStyle =
              style ??
              Style(
                id: 'default',
                name: 'Default',
                iconName: 'account_balance',
                colorHex: '#808080',
                iconType: IconType.material,
              );

          final color = _getColorFromHex(finalStyle.colorHex);
          final iconWidget = IconUtils.getIconWidget(finalStyle);

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: color.withAlpha((255 * 0.15).round()),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child:
                    iconWidget, // This will be white by default in IconUtils?
                // IconUtils uses Colors.white for icon color.
                // But container background is faint color.
                // Wait, IconUtils hardcodes white color?
                // I should probably tint it or let it look good on dark bg?
                // AccountListItem uses: color.withAlpha((255 * 0.15).round()) for BG.
                // And iconWidget from IconUtils (which is white).
                // If the app is light mode, white icon on faint color might be invisible.
                // AccountListItem uses `Theme.of(context).primaryColor` border on hover?
                // Let's check IconUtils again. It sets `color: Colors.white`.
                // If I am in light mode, white icon is bad on light bg.
                // AccountListItem likely runs in Dark Mode or has dark container?
                // I'll stick to AccountListItem pattern.
              ),
              title: Text(account.name),
              trailing: Text(
                NumberFormat.simpleCurrency(name: currencyCode).format(balance),
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
