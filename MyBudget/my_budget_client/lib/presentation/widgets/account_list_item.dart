import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart'; // Added

class AccountListItem extends StatelessWidget {
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
  final AssetStats? assetStats;

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
    this.assetStats,
  });

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
    // But for Invested/Realized we might want to hide if 0?
    // Let's stick to showing if it's the main account item logic.
    if (value.abs() < 0.01 &&
        (realValue ?? 0).abs() < 0.01 &&
        account.assetId == null &&
        assetStats == null) {
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
          width: 80, // Increased width slightly for labels like "Commissions"
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13, // Adjusted
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
                    fontSize: 15,
                  ),
                  children: [
                    TextSpan(
                      text:
                          '${formatter.format(value).replaceAll(',', ' ')} $symbol',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (prevValue != null && diff.abs() >= 0.01) ...[
                      TextSpan(
                        text:
                            (Theme.of(context).platform ==
                                    TargetPlatform.android ||
                                Theme.of(context).platform ==
                                    TargetPlatform.iOS)
                            ? '\n'
                            : ' ',
                      ),
                      TextSpan(
                        text: 'Change: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      TextSpan(
                        text:
                            '${diff > 0 ? '+' : ''}${formatter.format(diff).replaceAll(',', ' ')} (${pct > 0 ? '+' : ''}${pct.toStringAsFixed(1)}%)',
                        style: TextStyle(
                          fontSize: 13,
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
                      fontSize: 13,
                    ),
                    children: [
                      const TextSpan(text: 'Real: '),
                      TextSpan(
                        text:
                            '${formatter.format(realValue).replaceAll(',', ' ')} $symbol',
                      ),
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
            (d) => d.id == account.currencyDesignationId,
          );
        }
        final symbol = designation?.value ?? '';

        return BlocBuilder<StylesBloc, StylesState>(
          builder: (context, styleState) {
            Style? style;
            if (styleState is StylesLoadSuccess) {
              style = styleState.styles.firstWhereOrNull(
                (s) => s.id == account.styleId,
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
            if (account.balance > 0) {
              balanceColor = Colors.green;
            } else if (account.balance < 0) {
              balanceColor = Colors.red;
            } else {
              balanceColor = Colors.grey[600]!; // Default or specific for zero
            }

            // Using GestureDetector inside ListTile for secondary tap if needed,
            // or rely on visual density.
            // Note: ListTile has onTap and onLongPress. For onSecondaryTapUp (Right Click),
            // we typically need a Gesture detector wrapper OR InkWell.
            // But standard ListTile doesn't support right click natively in arguments.
            // However, wrapping the ListTile in GestureDetector might block InkWell if not careful.
            // The best way for list item right click IS usually GestureDetector or Listener.
            // BUT, strictly following "Categories" visual style:
            // Categories uses: Card > ExpansionTile > ListTile (implied) OR Card > ListTile.
            // CategoryListItem uses: Card > GestureDetector(onSecondaryTapUp...) > ListTile.
            // The GestureDetector wraps the ListTile content but NOT the Card.
            // Wait, CategoryListItem creates the Card around the GestureDetector?
            // Let's re-read CategoryListItem structure from viewing context (approx line 124).
            // It builds `listTile` = `GestureDetector(...)` which wraps `ListTile`.
            // Then `card` = `Card(child: listTile)`.
            // So GestureDetector IS inside Card.
            // Correct approach: Card > GestureDetector > ListTile.
            // To get InkWell effect (ripple), ListTile has it built-in IF onTap is not null.
            // But if GestureDetector intercepts taps, ListTile onTap might not fire?
            // Actually, GestureDetector executes callback and lets event propagate if behavior is translucent?
            // No, standard GestureDetector usually competes.
            // CategoryListItem passes `onTap` to `ListTile`.
            // And puts `onSecondaryTapUp` in `GestureDetector` parent of `ListTile`.
            // Let's replicate EXACTLY that.

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              color: isSelected
                  ? Theme.of(context).highlightColor
                  : Theme.of(context).cardColor,
              child: GestureDetector(
                onSecondaryTapUp: onSecondaryTapUp,
                // Note: We do NOT pass onLongPress/onTap to GestureDetector here
                // because we want ListTile to handle primary interactions for Ripple/Cursor.
                // However, onLongPress might be tricky. CategoryListItem has explicit `onLongPressStart` passed to GestureDetector,
                // and `onTap` passed to ListTile.
                // Let's verify AccountListItem needs.
                // It needs onLongPress. ListTile supports onLongPress.
                child: ListTile(
                  onTap: onTap,
                  onLongPress: onLongPress,
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
                    account.name,
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
                        account.balance,
                        prevBalance,
                        realBalance,
                        prevRealBalance,
                        balanceColor,
                        symbol,
                      ),
                      const SizedBox(height: 4),
                      if (assetStats != null) ...[
                        _buildStatRow(
                          context,
                          "Net Bal.",
                          assetStats!.netBalance,
                          null, // Not tracking history for net balance yet
                          null, // Real Net Balance? Maybe calculate: net / inflationMultiplier
                          null,
                          Colors.blue,
                          symbol,
                        ),
                        const SizedBox(height: 4),
                        _buildStatRow(
                          context,
                          "Invested",
                          assetStats!.invested,
                          null,
                          null,
                          null,
                          Colors.orange,
                          symbol,
                        ),
                        const SizedBox(height: 4),
                        _buildStatRow(
                          context,
                          "Realized",
                          assetStats!.realized,
                          null,
                          null,
                          null,
                          Colors.purple,
                          symbol,
                        ),
                        const SizedBox(height: 4),
                        _buildStatRow(
                          context,
                          "Fees",
                          assetStats!.commissions,
                          null,
                          null,
                          null,
                          Colors.redAccent,
                          symbol,
                        ),
                      ] else ...[
                        _buildStatRow(
                          context,
                          "Income",
                          income ?? 0,
                          prevIncome,
                          realIncome,
                          prevRealIncome,
                          Colors.green,
                          symbol,
                        ),
                        const SizedBox(height: 4),
                        _buildStatRow(
                          context,
                          "Expense",
                          expense ?? 0,
                          prevExpense,
                          null, // Hide Real Expense
                          null,
                          Colors.red,
                          symbol,
                        ),
                      ],
                    ],
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
