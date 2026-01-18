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
        Column(children: accounts.map(_buildAccountItem).toList()),
      ],
    );
  }

  Widget _buildAccountItem(Account account) {
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

    // Currency formatting: Symbol at the end
    final numberFormat = NumberFormat.currency(name: currencyCode, symbol: '');
    final symbol = NumberFormat.simpleCurrency(
      name: currencyCode,
    ).currencySymbol;
    final formattedBalance = '${numberFormat.format(balance).trim()} $symbol';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: color.withAlpha((255 * 0.15).round()),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: iconWidget,
        ),
        title: Text(account.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Text(
          formattedBalance,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: balance >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
