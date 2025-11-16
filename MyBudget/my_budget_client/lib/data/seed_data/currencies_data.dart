import 'package:my_budget_client/core/database/app_database.dart';

final List<CurrenciesCompanion> defaultCurrencies = [
  // Assuming IDs for designations are 1, 2, 3 for $, €, ₽ respectively
  CurrenciesCompanion.insert(name: 'US Dollar', code: 'USD', designationId: 1),
  CurrenciesCompanion.insert(name: 'Euro', code: 'EUR', designationId: 2),
  CurrenciesCompanion.insert(name: 'Russian Ruble', code: 'RUB', designationId: 3),
];
