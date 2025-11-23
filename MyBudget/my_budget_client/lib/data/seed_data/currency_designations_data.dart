import 'package:my_budget_client/core/database/app_database.dart';

final List<CurrencyDesignationsCompanion> defaultCurrencyDesignations = [
  // For USD
  CurrencyDesignationsCompanion.insert(value: '\$', currencyCode: 'USD'),
  CurrencyDesignationsCompanion.insert(value: 'US\$', currencyCode: 'USD'),

  // For Euro
  CurrencyDesignationsCompanion.insert(value: '€', currencyCode: 'EUR'),

  // For Russian Ruble
  CurrencyDesignationsCompanion.insert(value: '₽', currencyCode: 'RUB'),
];
