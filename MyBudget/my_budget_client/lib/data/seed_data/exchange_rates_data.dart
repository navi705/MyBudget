import 'package:my_budget_client/core/database/app_database.dart';

final List<ExchangeRatesCompanion> defaultExchangeRates = [
  // USD to EUR
  ExchangeRatesCompanion.insert(
    fromCurrencyId: 1,
    toCurrencyId: 2,
    rate: 0.92,
    date: DateTime.utc(2023, 10, 27),
  ),
  // USD to RUB
  ExchangeRatesCompanion.insert(
    fromCurrencyId: 1,
    toCurrencyId: 3,
    rate: 93.5,
    date: DateTime.utc(2023, 10, 27),
  ),
  // EUR to USD
  ExchangeRatesCompanion.insert(
    fromCurrencyId: 2,
    toCurrencyId: 1,
    rate: 1.08,
    date: DateTime.utc(2023, 10, 27),
  ),
  // EUR to RUB
  ExchangeRatesCompanion.insert(
    fromCurrencyId: 2,
    toCurrencyId: 3,
    rate: 101.5,
    date: DateTime.utc(2023, 10, 27),
  ),
  // RUB to USD
  ExchangeRatesCompanion.insert(
    fromCurrencyId: 3,
    toCurrencyId: 1,
    rate: 0.0107,
    date: DateTime.utc(2023, 10, 27),
  ),
  // RUB to EUR
  ExchangeRatesCompanion.insert(
    fromCurrencyId: 3,
    toCurrencyId: 2,
    rate: 0.0098,
    date: DateTime.utc(2023, 10, 27),
  ),
];
