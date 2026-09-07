import 'dart:ui';
import 'package:my_budget_client/core/utils/hex_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
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

/// The widest a column of reading content is allowed to get on a desktop.
///
/// `settings_screen.dart` picked 800 first and the renders proved it right:
/// unconstrained, a 1440px window stretches a card holding ~300px of content
/// to 1408px and parks its `⋮` menu ~1300px from the name it belongs to. Every
/// list screen now centres its content inside this one measure rather than
/// inventing a per-screen number.
///
/// It lives here, in the widgets layer, only because that is the shared file
/// this workstream owns — `lib/core/theme/app_spacing.dart` beside
/// `kMobileBreakpoint` is where it belongs.
const double kContentMaxWidth = 800.0;

/// Bottom inset a scrolling list must reserve when a FAB floats over it:
/// 56dp of button, its 16dp margin, and 16dp so the last row is not merely
/// uncovered but comfortably readable.
const double kFabScrollBottomInset = 88.0;

/// Width below which the balance row stacks its "change" figure onto a second
/// line. Measured on the value column, not the window: the amount plus the
/// change label plus the signed diff and its percentage need roughly this much
/// to sit on one line before the number itself starts wrapping.
const double _kInlineChangeMinWidth = 260.0;

/// Width cap on a stat row's label, so whatever the label does not use falls
/// through to the number beside it.
const double _kStatLabelMaxWidth = 96.0;

// ---------------------------------------------------------------------------
// Lookup indexes for the two catalogues every row reads.
//
// A row used to `firstWhereOrNull` its way through the whole designation list
// and then through the whole style list on every single build. That is two
// linear scans per visible row per emit, and one tap on the accounts date
// chevrons emits about three times — so a screenful of twelve rows paid for
// seventy-two scans of two catalogues that had not changed.
//
// The index hangs off the bloc state it was built from, via an [Expando]:
// every row in a frame sees the same state object and so shares one index, and
// there is nothing to invalidate — a new state has no index yet, and the old
// index is collected with the old state.
// ---------------------------------------------------------------------------

final Expando<Map<String, CurrencyDesignation>> _designationIndexes = Expando(
  'designationsById',
);

Map<String, CurrencyDesignation> _designationsById(CurrencyLoadSuccess state) {
  final cached = _designationIndexes[state];
  if (cached != null) return cached;

  final index = <String, CurrencyDesignation>{};
  // `putIfAbsent`, not a map literal: `firstWhereOrNull` returned the *first*
  // match and a `{for (...) d.id: d}` literal keeps the last, so a duplicated
  // id would silently start resolving to a different row.
  for (final designation in state.designations) {
    index.putIfAbsent(designation.id, () => designation);
  }
  return _designationIndexes[state] = index;
}

// Keyed on `String?` rather than `String`: `Style.id` is nullable and so is
// `Account.styleId`, and `firstWhereOrNull((s) => s.id == account.styleId)`
// matched a null id against a null styleId. Dropping the null key here would
// quietly hand those accounts the grey default style instead.
final Expando<Map<String?, Style>> _styleIndexes = Expando('stylesById');

Map<String?, Style> _stylesById(StylesLoadSuccess state) {
  final cached = _styleIndexes[state];
  if (cached != null) return cached;

  final index = <String?, Style>{};
  for (final style in state.styles) {
    index.putIfAbsent(style.id, () => style);
  }
  return _styleIndexes[state] = index;
}

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
  Color _getColorFromHex(String? hexColor) =>
      parseHexColor(hexColor ?? '#FF5733', fallback: Colors.orange);

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

    final moneyColors = MoneyColors.of(context);

    // The change figure moves onto its own line when the value column is too
    // narrow to hold it inline. It used to key off `Theme.of(context).platform`
    // instead, so a 360dp desktop window and a 360dp Android phone laid the
    // same row out differently for a reason no user could see; width is what
    // the decision is actually about.
    return LayoutBuilder(
      builder: (context, constraints) {
        final valueWidth = constraints.maxWidth - _kStatLabelMaxWidth - 8;
        final stackChange = valueWidth < _kInlineChangeMinWidth;

        return Row(
          children: [
            // A Flexible label beside an Expanded value split the ~164dp
            // subtitle evenly: the label shrink-wrapped and left its unused
            // half as dead space, while the value was capped at half regardless
            // and wrapped mid-number. Capping the label instead keeps it
            // inflexible, so whatever it does not use falls through to the
            // value.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _kStatLabelMaxWidth),
              child: Text(
                label,
                // "Баланс"/"Saldo disponible" are longer than the cap, and with
                // no line or overflow rule they simply ran past it. Two lines
                // then an ellipsis keeps the row the height the design expects
                // in every locale.
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13, // Adjusted
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Plain text, and that is the point: selectable text wins
                  // the tap and the long press against the `ListTile` behind
                  // it, and these figures cover most of the card. Tapping the
                  // numbers - where a finger naturally lands - opened nothing
                  // and selected nothing.
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 15,
                      ),
                      children: [
                        // Bidi-isolated, like every other money line in the
                        // app. Built by hand as `format(...) + ' ' + symbol`
                        // this string was a bare number sitting next to Arabic
                        // letters, and the paragraph's RTL run pulled the minus
                        // sign to the far end: an overdrawn account read
                        // `250.00-` in `ar` while the transaction list beside
                        // it read `-250.00`. `formatWithSymbol` wraps amount,
                        // separator and symbol in one LTR isolate.
                        TextSpan(
                          text: MoneyFormatter.formatWithSymbol(
                            value,
                            code,
                            symbol,
                          ),
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (prevValue != null && diff.abs() >= 0.01) ...[
                          TextSpan(text: stackChange ? '\n' : ' '),
                          TextSpan(
                            text: '${context.l10n.metricChange}: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                          // The sign is spelled out rather than left to colour
                          // alone: a red-green colourblind reader, or anyone
                          // reading a greyscale screenshot, gets the direction
                          // from the glyph. Isolated for the same reason as the
                          // amount above — the signed figure, the parentheses
                          // and the percent sign are all bidi-neutral, so an
                          // RTL paragraph reorders the group around them.
                          // Inside the isolate the run is forced LTR, which is
                          // also what makes the plain space here harmless.
                          TextSpan(
                            text: MoneyFormatter.isolate(
                              '${MoneyColors.signGlyph(isIncome: diff > 0)}'
                              '${MoneyFormatter.format(diff.abs(), code)} '
                              '(${pct > 0 ? '+' : ''}'
                              '${pct.toStringAsFixed(2)}%)',
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: moneyColors.forAmount(diff),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (realValue != null)
                    Text.rich(
                      TextSpan(
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(text: '${context.l10n.metricReal}: '),
                          // Embedded in a translated label, so it needs the
                          // isolate even more than the amount above does.
                          TextSpan(
                            text: MoneyFormatter.formatWithSymbol(
                              realValue,
                              code,
                              symbol,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      // Outer builder for Currency
      builder: (context, currencyState) {
        CurrencyDesignation? designation;
        if (currencyState is CurrencyLoadSuccess) {
          designation =
              _designationsById(currencyState)[account.currencyDesignationId];
        }
        final symbol = designation?.value ?? '';

        return BlocBuilder<StylesBloc, StylesState>(
          builder: (context, styleState) {
            Style? style;
            if (styleState is StylesLoadSuccess) {
              style = _stylesById(styleState)[account.styleId];
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

            // Money direction comes from the theme's money palette, not from
            // `Colors.green`/`Colors.red`: the user picks the seed colour, and
            // the stock swatches fail contrast on several of the dark surfaces
            // this app ships. `forAmount` also answers the zero case (neutral)
            // and the NaN case (an amount no rate could price).
            final moneyColors = MoneyColors.of(context);
            final balanceColor = moneyColors.forAmount(account.balance);

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
                          moneyColors.forAmount(assetStats!.netBalance),
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
                          // Capital moved, not gained or lost: no direction.
                          moneyColors.neutral,
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
                          moneyColors.forAmount(assetStats!.realized),
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
                          moneyColors.outflow,
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
                          moneyColors.inflow,
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
                          moneyColors.outflow,
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
