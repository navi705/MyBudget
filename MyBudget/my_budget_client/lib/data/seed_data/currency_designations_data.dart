import 'package:my_budget_client/core/database/app_database.dart';

final List<CurrencyDesignationsCompanion> defaultCurrencyDesignations = [
  // For USD (currencyId: 1)
  CurrencyDesignationsCompanion.insert(value: '\$', currencyId: 1),
  CurrencyDesignationsCompanion.insert(value: 'US\$', currencyId: 1), // Added another USD designation

  // For Euro (currencyId: 2)
  CurrencyDesignationsCompanion.insert(value: '€', currencyId: 2),

  // For Russian Ruble (currencyId: 3)
  CurrencyDesignationsCompanion.insert(value: '₽', currencyId: 3),
];
