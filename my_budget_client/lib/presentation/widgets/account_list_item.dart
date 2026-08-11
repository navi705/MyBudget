import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart'; // Added

class AccountListItem extends StatelessWidget {
  final Account account;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(TapUpDetails)? onSecondaryTapUp;
  final Function(TapUpDetails)? onMenuPressed;
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
    this.onMenuPressed,
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
    // If bound to an asset, show even if 0 to indicate value state.
    // Relaxed hiding condition: only hide if effectively zero (< 0.0000001).
    // User wants to see small balances (e.g. 0.009).
    const epsilon = 0.000001;
    if (value.abs() < epsilon &&
        (realValue ?? 0).abs() < epsilon &&
        account.assetId == null &&
        assetStats == null) {
      return const SizedBox.shrink();
    }

    // Per-currency formatting: fiat uses ISO decimals (0 for JPY, 3 for KWD,
    // else 2); crypto shows extra precision for tiny holdings.
    final code = account.currencyCode;

    final diff = prevValue != null ? value - prevValue : 0.0;

    // Percentages
    final pct = (prevValue != null && prevValue != 0)
        ? (diff / prevValue.abs() * 100)
        : 0.0;

    // For diffs, use same logic? Or kept standard?
    // Let's use standard for diffs to avoid noise unless diff is also very small?
    // For consistency, let's keep diff standard for now unless user asks.

    return Row(
      children: [
        Flexible(
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
                      text: '${MoneyFormatter.format(value, code)} $symbol',
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
                        text: '${context.l10n.metricChange}: ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      TextSpan(
                        text:
                            '${MoneyFormatter.format(diff, code, signed: true)} (${pct > 0 ? '+' : ''}${pct.toStringAsFixed(2)}%)',
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
                      TextSpan(text: '${context.l10n.metricReal}: '),
                      TextSpan(
                        text:
                            '${MoneyFormatter.format(realValue, code)} $symbol',
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
              balanceColor = Theme.of(
                context,
              ).colorScheme.onSurfaceVariant; // Default or specific for zero
            }

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
                        context.l10n.metricBalance,
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
                          context.l10n.netBalanceMetric,
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
                          context.l10n.investedMetric,
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
                          context.l10n.realizedMetric,
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
                          context.l10n.feesMetric,
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
                          context.l10n.metricIncome,
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
                          context.l10n.metricExpense,
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
                  trailing: onMenuPressed != null
                      ? IconButton(
                          icon: const Icon(Icons.more_vert),
                          onPressed: () {
                            // Find the position of the icon button to show the menu there
                            final RenderBox renderBox =
                                context.findRenderObject() as RenderBox;
                            final offset = renderBox.localToGlobal(Offset.zero);
                            onMenuPressed!(
                              TapUpDetails(
                                globalPosition: Offset(
                                  offset.dx + renderBox.size.width - 40,
                                  offset.dy + 20,
                                ),
                                kind: PointerDeviceKind.touch,
                              ),
                            );
                          },
                        )
                      : null,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
