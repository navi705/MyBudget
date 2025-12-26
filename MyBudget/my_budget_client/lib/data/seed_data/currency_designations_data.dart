import 'package:my_budget_client/core/database/app_database.dart';

final List<CurrencyDesignationsCompanion> defaultCurrencyDesignations = [
  // For USD
  CurrencyDesignationsCompanion.insert(value: '\$', currencyCode: 'USD'),
  CurrencyDesignationsCompanion.insert(value: 'US\$', currencyCode: 'USD'),

  // For Euro
  CurrencyDesignationsCompanion.insert(value: '€', currencyCode: 'EUR'),

  // For Russian Ruble
  CurrencyDesignationsCompanion.insert(value: '₽', currencyCode: 'RUB'),

  // For British Pound
  CurrencyDesignationsCompanion.insert(value: '£', currencyCode: 'GBP'),

  // For Japanese Yen
  CurrencyDesignationsCompanion.insert(value: '¥', currencyCode: 'JPY'),

  // For Australian Dollar
  CurrencyDesignationsCompanion.insert(value: 'A\$', currencyCode: 'AUD'),

  // For Canadian Dollar
  CurrencyDesignationsCompanion.insert(value: 'C\$', currencyCode: 'CAD'),

  // For Swiss Franc
  CurrencyDesignationsCompanion.insert(value: 'CHF', currencyCode: 'CHF'),

  // For Chinese Yuan
  CurrencyDesignationsCompanion.insert(value: '¥', currencyCode: 'CNY'),

  // For Indian Rupee
  CurrencyDesignationsCompanion.insert(value: '₹', currencyCode: 'INR'),

  // For Serbian Dinar
  CurrencyDesignationsCompanion.insert(value: 'din.', currencyCode: 'RSD'),
];
