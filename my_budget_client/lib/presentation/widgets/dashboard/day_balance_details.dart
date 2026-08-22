import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart'; // Added

class DayBalanceDetails extends StatelessWidget {
  final DateTime date;
  final List<Account> accounts;
  final Map<String, double> dayBalances;
  final String currencyCode;
  final List<Style> styles; // Added
  final Map<String, CurrencyDesignation> currencyDesignations; // Added

  const DayBalanceDetails({
    super.key,
    required this.date,
    required this.accounts,
    required this.dayBalances,
    required this.currencyCode,
    required this.styles,
    required this.currencyDesignations, // Added
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
    // Built once for the whole list rather than per row: with a hundred
    // accounts and a style each, the linear search below was ten thousand
    // comparisons, and NumberFormat.simpleCurrency loads locale data every
    // time it is asked for a symbol.
    final stylesById = {
      for (final style in styles)
        if (style.id != null) style.id!: style,
    };
    final symbols = <String, String>{};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            context.l10n.dshBalancesOnDate(DateFormat.yMMMMd().format(date)),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            for (final account in accounts)
              _buildAccountItem(context, account, stylesById, symbols),
          ],
        ),
      ],
    );
  }

  Widget _buildAccountItem(
    BuildContext context,
    Account account,
    Map<String, Style> stylesById,
    Map<String, String> symbols,
  ) {
    final balance = dayBalances[account.id] ?? 0.0;

    final styleId = account.styleId;
    final style = styleId == null ? null : stylesById[styleId];
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

    // Currency formatting: lookup designation using ACCOUNT's currency, not target currency
    // This ensures each account displays with its correct currency symbol
    final designation = currencyDesignations[account.currencyDesignationId];
    final symbol =
        designation?.value ??
        (symbols[account.currencyCode] ??= NumberFormat.simpleCurrency(
          name: account.currencyCode,
        ).currencySymbol);

    // Format number without symbol first, using account's currency for proper decimal places
    final formattedBalance =
        '${MoneyFormatter.format(balance, account.currencyCode)} $symbol';

    return Card(
      margin: const EdgeInsets.only(bottom: 12), // Increased spacing
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
            color: MoneyColors.of(context).forAmount(balance),
          ),
        ),
      ),
    );
  }
}
