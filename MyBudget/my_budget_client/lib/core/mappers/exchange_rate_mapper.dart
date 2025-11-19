import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

extension ExchangeRateMapper on drift.ExchangeRate {
  ExchangeRate toDomain() {
    return ExchangeRate(
      fromCurrencyId: fromCurrencyId,
      toCurrencyId: toCurrencyId,
      rate: rate,
      date: date,
    );
  }
}

extension ExchangeRateCompanionMapper on ExchangeRate {
  drift.ExchangeRatesCompanion toCompanion() {
    return drift.ExchangeRatesCompanion(
      fromCurrencyId: Value(fromCurrencyId),
      toCurrencyId: Value(toCurrencyId),
      rate: Value(rate),
      date: Value(date),
    );
  }
}
