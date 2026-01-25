import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';

final List<AccountTypesCompanion> defaultAccountTypes = [
  AccountTypesCompanion.insert(
    id: const Value('account_type_checking'),
    name: 'Checking',
    languageCode: 'en',
    modifiedAt: const Value(1),
  ),
  AccountTypesCompanion.insert(
    id: const Value('account_type_savings'),
    name: 'Savings',
    languageCode: 'en',
    modifiedAt: const Value(1),
  ),
  AccountTypesCompanion.insert(
    id: const Value('account_type_credit_card'),
    name: 'Credit Card',
    languageCode: 'en',
    modifiedAt: const Value(1),
  ),
  AccountTypesCompanion.insert(
    id: const Value('account_type_cash'),
    name: 'Cash',
    languageCode: 'en',
    modifiedAt: const Value(1),
  ),
  AccountTypesCompanion.insert(
    id: const Value('account_type_investment'),
    name: 'Investment',
    languageCode: 'en',
    modifiedAt: const Value(1),
  ),
  AccountTypesCompanion.insert(
    id: const Value('account_type_loan'),
    name: 'Loan',
    languageCode: 'en',
    modifiedAt: const Value(1),
  ),
];
