import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';

final List<StylesCompanion> defaultStyles = [
  // ===== ACCOUNT STYLES =====
  StylesCompanion.insert(
    id: const Value('style_default_wallet'),
    name: 'Default Wallet',
    iconName: 'wallet',
    colorHex: '#4CAF50', // Green
  ),
  StylesCompanion.insert(
    id: const Value('style_credit_card'),
    name: 'Credit Card',
    iconName: 'credit_card',
    colorHex: '#F44336', // Red
  ),
  StylesCompanion.insert(
    id: const Value('style_savings'),
    name: 'Savings',
    iconName: 'savings',
    colorHex: '#2196F3', // Blue
  ),
  StylesCompanion.insert(
    id: const Value('style_steam_account'),
    name: 'Steam Account',
    iconName: 'lib/icons/steam.svg',
    colorHex: '#000000', // Black
    iconType: const Value(IconType.custom),
  ),
  StylesCompanion.insert(
    id: const Value('style_youtube'),
    name: 'YouTube',
    iconName: 'lib/icons/youtube.svg',
    colorHex: '#808080', // Grey
    iconType: const Value(IconType.custom),
  ),
  StylesCompanion.insert(
    id: const Value('style_transfer'),
    name: 'Transfer',
    iconName: 'compare_arrows',
    colorHex: '#424242', // Dark Grey
  ),

  // ===== INCOME CATEGORY STYLES =====
  StylesCompanion.insert(
    id: const Value('style_salary'),
    name: 'Salary',
    iconName: 'work',
    colorHex: '#4CAF50', // Green
  ),
  StylesCompanion.insert(
    id: const Value('style_freelance'),
    name: 'Freelance',
    iconName: 'payments',
    colorHex: '#8BC34A', // Light Green
  ),
  StylesCompanion.insert(
    id: const Value('style_investments'),
    name: 'Investments',
    iconName: 'trending_up',
    colorHex: '#009688', // Teal
  ),
  StylesCompanion.insert(
    id: const Value('style_gifts_received'),
    name: 'Gifts Received',
    iconName: 'redeem',
    colorHex: '#E91E63', // Pink
  ),
  StylesCompanion.insert(
    id: const Value('style_other_income'),
    name: 'Other Income',
    iconName: 'attach_money',
    colorHex: '#607D8B', // Blue Grey
  ),

  // ===== EXPENSE CATEGORY STYLES =====
  StylesCompanion.insert(
    id: const Value('style_groceries'),
    name: 'Groceries',
    iconName: 'shopping_cart',
    colorHex: '#FF9800', // Orange
  ),
  StylesCompanion.insert(
    id: const Value('style_transport'),
    name: 'Transport',
    iconName: 'directions_car',
    colorHex: '#3F51B5', // Indigo
  ),
  StylesCompanion.insert(
    id: const Value('style_shopping'),
    name: 'Shopping',
    iconName: 'shopping_bag',
    colorHex: '#9C27B0', // Purple
  ),
  StylesCompanion.insert(
    id: const Value('style_housing'),
    name: 'Housing',
    iconName: 'home',
    colorHex: '#795548', // Brown
  ),
  StylesCompanion.insert(
    id: const Value('style_restaurant'),
    name: 'Restaurant',
    iconName: 'restaurant',
    colorHex: '#F44336', // Red
  ),
  StylesCompanion.insert(
    id: const Value('style_traveling'),
    name: 'Traveling',
    iconName: 'flight',
    colorHex: '#00BCD4', // Cyan
  ),
  StylesCompanion.insert(
    id: const Value('style_phone'),
    name: 'Phone',
    iconName: 'wifi_tethering',
    colorHex: '#673AB7', // Deep Purple
  ),
  StylesCompanion.insert(
    id: const Value('style_beauty'),
    name: 'Beauty',
    iconName: 'content_cut',
    colorHex: '#FF4081', // Pink Accent
  ),
  StylesCompanion.insert(
    id: const Value('style_steam'),
    name: 'Steam',
    iconName: 'lib/icons/steam.svg',
    colorHex: '#1b2838', // Steam Dark Blue
    iconType: const Value(IconType.custom),
  ),
  StylesCompanion.insert(
    id: const Value('style_healthcare'),
    name: 'Healthcare',
    iconName: 'local_hospital',
    colorHex: '#F44336', // Red
  ),
  StylesCompanion.insert(
    id: const Value('style_other_expense'),
    name: 'Other Expense',
    iconName: 'paid',
    colorHex: '#9E9E9E', // Grey
  ),
];
