import 'package:my_budget_client/core/database/app_database.dart';

final List<AccountStylesCompanion> defaultAccountStyles = [
  AccountStylesCompanion.insert(
    name: 'Default Wallet',
    iconName: 'wallet',
    colorHex: '#4CAF50', // Green
  ),
  AccountStylesCompanion.insert(
    name: 'Credit Card',
    iconName: 'credit_card',
    colorHex: '#F44336', // Red
  ),
  AccountStylesCompanion.insert(
    name: 'Savings',
    iconName: 'savings',
    colorHex: '#2196F3', // Blue
  ),
];
