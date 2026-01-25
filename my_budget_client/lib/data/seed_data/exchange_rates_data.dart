import 'package:my_budget_client/core/database/app_database.dart';

final List<ExchangeRatesCompanion> defaultExchangeRates = [
  // USD to EUR
  ExchangeRatesCompanion.insert(
    fromCurrencyCode: 'USD',
    toCurrencyCode: 'EUR',
    rate: 0.92,
    date: DateTime.utc(2023, 10, 27),
    preset: 1
  ),
  // USD to RUB
  ExchangeRatesCompanion.insert(
    fromCurrencyCode: 'USD',
    toCurrencyCode: 'RUB',
    rate: 93.5,
    date: DateTime.utc(2023, 10, 27),
    preset: 1
  ),
  // EUR to USD
  ExchangeRatesCompanion.insert(
    fromCurrencyCode: 'EUR',
    toCurrencyCode: 'USD',
    rate: 1.08,
    date: DateTime.utc(2023, 10, 27),
    preset: 1
  ),
  // EUR to RUB
  ExchangeRatesCompanion.insert(
    fromCurrencyCode: 'EUR',
    toCurrencyCode: 'RUB',
    rate: 101.5,
    date: DateTime.utc(2023, 10, 27),
    preset: 1
  ),
  // RUB to USD
  ExchangeRatesCompanion.insert(
    fromCurrencyCode: 'RUB',
    toCurrencyCode: 'USD',
    rate: 0.0107,
    date: DateTime.utc(2023, 10, 27),
    preset: 1
  ),
  // RUB to EUR
  ExchangeRatesCompanion.insert(
    fromCurrencyCode: 'RUB',
    toCurrencyCode: 'EUR',
    rate: 0.0098,
    date: DateTime.utc(2023, 10, 27),
    preset: 1
  ),
];
