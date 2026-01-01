import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

extension ExchangeRateMapper on drift.ExchangeRate {
  ExchangeRateDomain toDomain() {
    return ExchangeRateDomain(
      fromCurrencyCode: fromCurrencyCode,
      toCurrencyCode: toCurrencyCode,
      preset: preset,
      rate: rate,
      date: date,
    );
  }
}

extension ExchangeRateCompanionMapper on ExchangeRateDomain {
  drift.ExchangeRatesCompanion toCompanion() {
    return drift.ExchangeRatesCompanion(
      fromCurrencyCode: Value(fromCurrencyCode),
      toCurrencyCode: Value(toCurrencyCode),
      preset: Value(preset),
      rate: Value(rate),
      date: Value(date),
    );
  }
}

extension ExchangeRateListMapper on List<drift.ExchangeRate> {
  List<ExchangeRateDomain> toDomainList() {
    return map((rate) => rate.toDomain()).toList();
  }
}

extension ExchangeRateCompanionListMapper on List<ExchangeRateDomain> {
  List<drift.ExchangeRatesCompanion> toCompanionList() {
    return map((rate) => rate.toCompanion()).toList();
  }
}
