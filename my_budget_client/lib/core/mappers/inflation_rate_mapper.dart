import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/inflation_rate.dart';

/// The database stores a worldwide rate under [drift.globalInflationCountry]
/// so its primary key can catch a repeat; above this boundary such a rate has
/// no country at all, which is what the country filter and the per-country
/// inflation multipliers key off.
extension InflationRateMapper on drift.InflationRate {
  InflationRateDomain toDomain() {
    return InflationRateDomain(
      date: date,
      percent: percent,
      country: country == drift.globalInflationCountry ? null : country,
      preset: preset,
    );
  }
}

extension InflationRateCompanionMapper on InflationRateDomain {
  drift.InflationRatesCompanion toCompanion() {
    return drift.InflationRatesCompanion(
      date: Value(date),
      percent: Value(percent),
      country: Value(country ?? drift.globalInflationCountry),
      preset: Value(preset),
    );
  }
}

extension InflationRateListMapper on List<drift.InflationRate> {
  List<InflationRateDomain> toDomainList() {
    return map((rate) => rate.toDomain()).toList();
  }
}
