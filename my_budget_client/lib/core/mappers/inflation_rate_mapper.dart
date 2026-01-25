import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/inflation_rate.dart';

extension InflationRateMapper on drift.InflationRate {
  InflationRateDomain toDomain() {
    return InflationRateDomain(
      date: date,
      percent: percent,
      country: country,
      preset: preset,
    );
  }
}

extension InflationRateCompanionMapper on InflationRateDomain {
  drift.InflationRatesCompanion toCompanion() {
    return drift.InflationRatesCompanion(
      date: Value(date),
      percent: Value(percent),
      country: Value(country),
      preset: Value(preset),
    );
  }
}

extension InflationRateListMapper on List<drift.InflationRate> {
  List<InflationRateDomain> toDomainList() {
    return map((rate) => rate.toDomain()).toList();
  }
}
