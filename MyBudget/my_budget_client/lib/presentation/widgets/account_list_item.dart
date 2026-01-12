import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart'; // Added
import 'package:my_budget_client/domain/entities/currency_designation.dart'; // Added
import 'package:intl/intl.dart';

class AccountListItem extends StatefulWidget {
  final Account account;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(TapUpDetails)? onSecondaryTapUp;
  final double? realBalance;
  final double? inflationLoss;
  final double? income;
  final double? expense;
  final double? realIncome;
  final double? realExpense;
  final double? prevBalance;
  final double? prevIncome;
  final double? prevExpense;
  final double? prevRealBalance;
  final double? prevRealIncome;
  final double? prevRealExpense;

  const AccountListItem({
    super.key,
    required this.account,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapUp,
    this.realBalance,
    this.inflationLoss,
    this.income,
    this.expense,
    this.realIncome,
    this.realExpense,
    this.prevBalance,
    this.prevIncome,
    this.prevExpense,
    this.prevRealBalance,
    this.prevRealIncome,
    this.prevRealExpense,
  });

  @override
  State<AccountListItem> createState() => _AccountListItemState();
}

class _AccountListItemState extends State<AccountListItem> {
  bool _isHovering = false;

  // Helper function to parse hex color strings
  Color _getColorFromHex(String? hexColor) {
    hexColor = (hexColor ?? '#FF5733').replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF$hexColor";
    }
    if (hexColor.length == 8) {
      return Color(int.parse("0x$hexColor"));
    }
    return Colors.orange; // Default color
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    double value,
    double? prevValue,
    double? realValue,
    double? prevRealValue,
    Color color,
    String symbol,
  ) {
    // If bound to an asset, show even if 0 to indicate value state
    if (value.abs() < 0.01 &&
        (realValue ?? 0).abs() < 0.01 &&
        widget.account.assetId == null) {
      return const SizedBox.shrink();
    }

    final formatter = NumberFormat.decimalPattern();
    final diff = prevValue != null ? value - prevValue : 0.0;

    // Percentages
    final pct = (prevValue != null && prevValue != 0)
        ? (diff / prevValue.abs() * 100)
        : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 70, // Increased width slightly for larger label
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14, // Increased 12 -> 14
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText.rich(
                TextSpan(
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 16, // Increased 13 -> 16
                  ),
                  children: [
                    TextSpan(
                      text:
                          '$symbol ${formatter.format(value).replaceAll(',', ' ')}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (prevValue != null && diff.abs() >= 0.01) ...[
                      const TextSpan(text: ' '),
                      TextSpan(
                        text:
                            '${diff > 0 ? '+' : ''}${formatter.format(diff).replaceAll(',', ' ')} (${pct.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 14, // Increased 10 -> 14
                          color: diff > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (realValue != null)
                SelectableText.rich(
                  TextSpan(
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 14, // Increased 11 -> 14
                    ),
                    children: [
                      const TextSpan(text: 'Real: '),
                      TextSpan(
                        text:
                            '$symbol ${formatter.format(realValue).replaceAll(',', ' ')}',
                      ),
                      // Comparison logic for real if needed
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      // Outer builder for Currency
      builder: (context, currencyState) {
        CurrencyDesignation? designation;
        if (currencyState is CurrencyLoadSuccess) {
          designation = currencyState.designations.firstWhereOrNull(
            (d) => d.id == widget.account.currencyDesignationId,
          );
        }
        final symbol = designation?.value ?? '';

        return BlocBuilder<StylesBloc, StylesState>(
          builder: (context, styleState) {
            Style? style;
            if (styleState is StylesLoadSuccess) {
              style = styleState.styles.firstWhereOrNull(
                (s) => s.id == widget.account.styleId,
              );
            }

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

            // Determine balance color
            Color balanceColor;
            if (widget.account.balance > 0) {
              balanceColor = Colors.green;
            } else if (widget.account.balance < 0) {
              balanceColor = Colors.red;
            } else {
              balanceColor = Colors.grey[600]!; // Default or specific for zero
            }

            return MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: GestureDetector(
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
                onSecondaryTapUp: widget.onSecondaryTapUp,
                child: Card(
                  elevation: 2.0,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: _isHovering
                        ? BorderSide(
                            color: Theme.of(context).primaryColor,
                            width: 3.0,
                          )
                        : BorderSide.none,
                  ),
                  color: widget.isSelected
                      ? Theme.of(context).highlightColor
                      : _isHovering
                      ? Colors.grey.withValues(alpha: 0.1)
                      : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10.0,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: color.withAlpha((255 * 0.15).round()),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: iconWidget,
                    ),
                    title: Text(
                      widget.account.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        _buildStatRow(
                          context,
                          "Balance",
                          widget.account.balance,
                          widget.prevBalance,
                          widget.realBalance,
                          widget.prevRealBalance,
                          balanceColor,
                          symbol,
                        ),
                        const SizedBox(height: 4),
                        _buildStatRow(
                          context,
                          "Income",
                          widget.income ?? 0,
                          widget.prevIncome,
                          widget.realIncome,
                          widget.prevRealIncome,
                          Colors.green,
                          symbol,
                        ),
                        const SizedBox(height: 4),
                        _buildStatRow(
                          context,
                          "Expense",
                          widget.expense ?? 0,
                          widget.prevExpense,
                          widget.realExpense,
                          widget.prevRealExpense,
                          Colors.red,
                          symbol,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
