import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/data/seed_data/seed_name_translations.dart';

/// Default categories seeded on first app launch.
/// Each category references a style from styles_data.dart for icons.

/// Returns localized default categories.
List<CategoriesCompanion> getDefaultCategories(String languageCode) {
  // One shared table with the styles and account types: the three name sets
  // overlap, and a category that reads "Groceries" beside a style that reads
  // "Продукты" is what two tables produce.
  final t = seedNameTranslations[seedLanguageOf(languageCode)]!;

  return [
    // ----- INCOME -----
    CategoriesCompanion.insert(
      id: const Value('cat_salary'),
      name: t['Salary']!,
      type: const Value(CategoryType.income),
      styleId: const Value('style_salary'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_freelance'),
      name: t['Freelance']!,
      type: const Value(CategoryType.income),
      styleId: const Value('style_freelance'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_investments'),
      name: t['Investments']!,
      type: const Value(CategoryType.income),
      styleId: const Value('style_investments'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_gifts_received'),
      name: t['Gifts Received']!,
      type: const Value(CategoryType.income),
      styleId: const Value('style_gifts_received'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_other_income'),
      name: t['Other Income']!,
      type: const Value(CategoryType.income),
      styleId: const Value('style_other_income'),
      modifiedAt: const Value(1),
    ),

    // ----- EXPENSE -----
    CategoriesCompanion.insert(
      id: const Value('cat_groceries'),
      name: t['Groceries']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_groceries'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_transport'),
      name: t['Transport']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_transport'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_shopping'),
      name: t['Shopping']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_shopping'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_housing'),
      name: t['Housing']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_housing'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_restaurant'),
      name: t['Restaurant']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_restaurant'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_traveling'),
      name: t['Traveling']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_traveling'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_phone'),
      name: t['Phone']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_phone'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_beauty'),
      name: t['Beauty']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_beauty'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_steam'),
      name: t['Steam']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_steam'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_healthcare'),
      name: t['Healthcare']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_healthcare'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_subscriptions'),
      name: t['Subscriptions']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_subscriptions'),
      modifiedAt: const Value(1),
    ),
    CategoriesCompanion.insert(
      id: const Value('cat_other_expense'),
      name: t['Other Expense']!,
      type: const Value(CategoryType.expense),
      styleId: const Value('style_other_expense'),
      modifiedAt: const Value(1),
    ),

    // ----- TRANSFER (System) -----
    CategoriesCompanion.insert(
      id: const Value('cat_system_transfer'),
      name: AppConstants.systemTransferCategoryName,
      type: const Value(CategoryType.transfer),
      styleId: const Value('style_transfer'),
      modifiedAt: const Value(1),
    ),
  ];
}
