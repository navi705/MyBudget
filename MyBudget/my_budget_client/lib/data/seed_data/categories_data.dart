import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';

/// Default categories seeded on first app launch.
/// Each category references a style from styles_data.dart for icons.
final List<CategoriesCompanion> defaultCategories = [
  // ----- INCOME -----
  CategoriesCompanion.insert(
    name: 'Salary',
    type: const Value(CategoryType.income),
  ),
  CategoriesCompanion.insert(
    name: 'Freelance',
    type: const Value(CategoryType.income),
  ),
  CategoriesCompanion.insert(
    name: 'Investments',
    type: const Value(CategoryType.income),
  ),
  CategoriesCompanion.insert(
    name: 'Gifts Received',
    type: const Value(CategoryType.income),
  ),
  CategoriesCompanion.insert(
    name: 'Other Income',
    type: const Value(CategoryType.income),
  ),

  // ----- EXPENSE -----
  CategoriesCompanion.insert(
    name: 'Groceries',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Transport',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Shopping',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Housing',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Restaurant',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Traveling',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Phone',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Beauty',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Steam',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Healthcare',
    type: const Value(CategoryType.expense),
  ),
  CategoriesCompanion.insert(
    name: 'Other Expense',
    type: const Value(CategoryType.expense),
  ),

  // ----- TRANSFER (System) -----
  CategoriesCompanion.insert(
    name: AppConstants.systemTransferCategoryName,
    type: const Value(CategoryType.transfer),
  ),
];
