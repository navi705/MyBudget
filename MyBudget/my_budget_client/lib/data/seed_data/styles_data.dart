import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';

final List<StylesCompanion> defaultStyles = [
  StylesCompanion.insert(
    name: 'Default Wallet',
    iconName: 'wallet',
    colorHex: '#4CAF50', // Green
  ),
  StylesCompanion.insert(
    name: 'Credit Card',
    iconName: 'credit_card',
    colorHex: '#F44336', // Red
  ),
  StylesCompanion.insert(
    name: 'Savings',
    iconName: 'savings',
    colorHex: '#2196F3', // Blue
  ),
  StylesCompanion.insert(
    name: 'Steam',
    iconName: 'lib/icons/steam.svg',
    colorHex: '#000000', // Black
    iconType: const Value(IconType.custom),
  ),
  StylesCompanion.insert(
    name: 'YouTube',
    iconName: 'lib/icons/youtube.svg',
    colorHex: '#808080', // Grey
    iconType: const Value(IconType.custom),
  ),
  StylesCompanion.insert(
    name: 'Transfer',
    iconName: 'compare_arrows',
    colorHex: '#424242', // Dark Grey
  ),
];
