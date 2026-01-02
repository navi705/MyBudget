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

  const AccountListItem({
    super.key,
    required this.account,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTapUp,
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrencyBloc, CurrencyState>(
      // Outer builder for Currency
      builder: (context, currencyState) {
        CurrencyDesignation? designation;
        if (currencyState is CurrencyLoadSuccess) {
          designation = currencyState.designations.firstWhereOrNull(
              (d) => d.id == widget.account.currencyDesignationId);
        }

        return BlocBuilder<StylesBloc, StylesState>(
          builder: (context, styleState) {
            Style? style;
            if (styleState is StylesLoadSuccess) {
              style = styleState.styles
                  .firstWhereOrNull((s) => s.id == widget.account.styleId);
            }

            final finalStyle = style ??
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
                      horizontal: 16.0, vertical: 8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: _isHovering
                        ? BorderSide(
                            color: Theme.of(context).primaryColor, width: 3.0)
                        : BorderSide.none,
                  ),
                  color: widget.isSelected
                      ? Theme.of(context).highlightColor
                      : _isHovering
                          ? Colors.grey.withValues(alpha: 0.1)
                          : null,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
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
                        fontSize: 16,
                      ),
                    ),
                    subtitle: SelectableText(
                      '${designation?.value ?? ''} ${NumberFormat.decimalPattern().format(widget.account.balance).replaceAll(',', ' ')}',
                      style: TextStyle(
                        color: balanceColor,
                        fontSize: 14,
                      ),
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
