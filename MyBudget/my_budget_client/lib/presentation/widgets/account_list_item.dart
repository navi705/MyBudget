import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/presentation/blocs/styles/styles_bloc.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';
import 'package:my_budget_client/presentation/blocs/currency/currency_bloc.dart'; // Added
import 'package:my_budget_client/domain/entities/currency_designation.dart'; // Added

class AccountListItem extends StatelessWidget {
  final Account account;

  const AccountListItem({super.key, required this.account});

  // Helper function to map icon names to IconData
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'savings':
        return Icons.savings;
      case 'credit_card':
        return Icons.credit_card;
      default:
        return Icons.account_balance; // Default icon
    }
  }

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
    return BlocBuilder<CurrencyBloc, CurrencyState>( // Outer builder for Currency
      builder: (context, currencyState) {
        CurrencyDesignation? designation;
        if (currencyState is CurrencyLoadSuccess) {
          try {
            designation = currencyState.designations.firstWhere((d) => d.id == account.currencyDesignationId);
          } on StateError {
            designation = null; // Designation not found
          }
        }

        return BlocBuilder<StylesBloc, StylesState>(
          builder: (context, styleState) {
            Style? style;
            if (styleState is StylesLoadSuccess) {
              try {
                style = styleState.styles.firstWhere((s) => s.id == account.styleId);
              } on StateError {
                style = null; // Style not found, which is a valid case
              }
            }

            final color = _getColorFromHex(style?.colorHex);
            final iconData = _getIconData(style?.iconName);

            // Determine balance color
            Color balanceColor;
            if (account.balance > 0) {
              balanceColor = Colors.green;
            } else if (account.balance < 0) {
              balanceColor = Colors.red;
            } else {
              balanceColor = Colors.grey[600]!; // Default or specific for zero
            }

            return Card(
              elevation: 2.0,
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                leading: Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: color.withAlpha((255 * 0.15).round()),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Icon(iconData, color: color, size: 30.0),
                ),
                title: Text(
                  account.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  '${designation?.value ?? ''} ${account.balance.toStringAsFixed(2)}', // Updated to use designation.value
                  style: TextStyle(
                    color: balanceColor, // Apply determined color
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(Icons.more_vert),
                onTap: () {
                  if (account.id != null) {
                    context.push(
                      AppRoutes.editAccount.replaceFirst(':id', account.id!.toString()),
                    );
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
