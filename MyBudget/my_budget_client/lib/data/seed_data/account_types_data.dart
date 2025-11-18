import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';

final List<AccountTypesCompanion> defaultAccountTypes = [
  AccountTypesCompanion.insert(id: const Value(1), name: 'Checking'),
  AccountTypesCompanion.insert(id: const Value(2), name: 'Savings'),
  AccountTypesCompanion.insert(id: const Value(3), name: 'Credit Card'),
  AccountTypesCompanion.insert(id: const Value(4), name: 'Cash'),
  AccountTypesCompanion.insert(id: const Value(5), name: 'Investment'),
  AccountTypesCompanion.insert(id: const Value(6), name: 'Loan'),
];
