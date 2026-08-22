import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';
import 'package:my_budget_client/data/seed_data/seed_name_translations.dart';

/// The styles seeded on first launch, named in [languageCode].
///
/// Most of these names are also category names - a style is what gives a
/// category its icon and colour - so they come from the same table as the
/// categories rather than from a second list that could drift from it.
List<StylesCompanion> getDefaultStyles(String languageCode) {
  String t(String english) => seedName(languageCode, english);

  return [
    // ===== ACCOUNT STYLES =====
    StylesCompanion.insert(
      id: const Value('style_default_wallet'),
      name: t('Default Wallet'),
      iconName: 'wallet',
      colorHex: '#4CAF50', // Green
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_credit_card'),
      name: t('Credit Card'),
      iconName: 'credit_card',
      colorHex: '#F44336', // Red
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_savings'),
      name: t('Savings'),
      iconName: 'savings',
      colorHex: '#2196F3', // Blue
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_steam_account'),
      name: t('Steam Account'),
      iconName: 'lib/icons/steam.svg',
      colorHex: '#000000', // Black
      iconType: const Value(IconType.custom),
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_youtube'),
      name: t('YouTube'),
      iconName: 'lib/icons/youtube.svg',
      colorHex: '#808080', // Grey
      iconType: const Value(IconType.custom),
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_transfer'),
      name: t('Transfer'),
      iconName: 'compare_arrows',
      colorHex: '#424242', // Dark Grey
      modifiedAt: const Value(1),
    ),

    // ===== INCOME CATEGORY STYLES =====
    StylesCompanion.insert(
      id: const Value('style_salary'),
      name: t('Salary'),
      iconName: 'work',
      colorHex: '#4CAF50', // Green
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_freelance'),
      name: t('Freelance'),
      iconName: 'payments',
      colorHex: '#8BC34A', // Light Green
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_investments'),
      name: t('Investments'),
      iconName: 'trending_up',
      colorHex: '#009688', // Teal
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_gifts_received'),
      name: t('Gifts Received'),
      iconName: 'redeem',
      colorHex: '#E91E63', // Pink
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_other_income'),
      name: t('Other Income'),
      iconName: 'attach_money',
      colorHex: '#607D8B', // Blue Grey
      modifiedAt: const Value(1),
    ),

    // ===== EXPENSE CATEGORY STYLES =====
    StylesCompanion.insert(
      id: const Value('style_groceries'),
      name: t('Groceries'),
      iconName: 'shopping_cart',
      colorHex: '#FF9800', // Orange
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_transport'),
      name: t('Transport'),
      iconName: 'directions_car',
      colorHex: '#3F51B5', // Indigo
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_shopping'),
      name: t('Shopping'),
      iconName: 'shopping_bag',
      colorHex: '#9C27B0', // Purple
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_housing'),
      name: t('Housing'),
      iconName: 'home',
      colorHex: '#795548', // Brown
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_restaurant'),
      name: t('Restaurant'),
      iconName: 'restaurant',
      colorHex: '#F44336', // Red
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_traveling'),
      name: t('Traveling'),
      iconName: 'flight',
      colorHex: '#00BCD4', // Cyan
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_phone'),
      name: t('Phone'),
      iconName: 'wifi_tethering',
      colorHex: '#673AB7', // Deep Purple
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_beauty'),
      name: t('Beauty'),
      iconName: 'content_cut',
      colorHex: '#FF4081', // Pink Accent
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_steam'),
      name: t('Steam'),
      iconName: 'lib/icons/steam.svg',
      colorHex: '#1b2838', // Steam Dark Blue
      iconType: const Value(IconType.custom),
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_healthcare'),
      name: t('Healthcare'),
      iconName: 'local_hospital',
      colorHex: '#F44336', // Red
      modifiedAt: const Value(1),
    ),
    StylesCompanion.insert(
      id: const Value('style_other_expense'),
      name: t('Other Expense'),
      iconName: 'paid',
      colorHex: '#9E9E9E', // Grey
      modifiedAt: const Value(1),
    ),
  ];
}

/// The English seed set, for the stable-id migration - see
/// [defaultAccountTypes] for why that one must stay in English.
final List<StylesCompanion> defaultStyles = getDefaultStyles('en');
