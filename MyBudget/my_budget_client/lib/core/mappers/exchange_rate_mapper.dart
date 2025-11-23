import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

extension ExchangeRateMapper on drift.ExchangeRate {
  ExchangeRate toDomain() {
    return ExchangeRate(
      fromCurrencyCode: fromCurrencyCode,
      toCurrencyCode: toCurrencyCode,
      rate: rate,
      date: date,
    );
  }
}

extension ExchangeRateCompanionMapper on ExchangeRate {
  drift.ExchangeRatesCompanion toCompanion() {
    return drift.ExchangeRatesCompanion(
      fromCurrencyCode: Value(fromCurrencyCode),
      toCurrencyCode: Value(toCurrencyCode),
      rate: Value(rate),
      date: Value(date),
    );
  }
}
