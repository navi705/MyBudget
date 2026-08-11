import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/inflation_rate_mapper.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';

void main() {
  drift.InflationRate rowFromCompanion(drift.InflationRatesCompanion c) =>
      drift.InflationRate(
        date: c.date.value,
        percent: c.percent.value,
        country: c.country.value,
        preset: c.preset.value,
        modifiedAt: 0,
      );

  test('round trip preserves every field, including a country code', () {
    final original = InflationRateDomain(
      country: 'US',
      preset: 2,
      percent: 5.25,
      date: DateTime(2023, 1, 1),
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped, original); // Equatable equality
  });

  test('round trip preserves a null (global) country', () {
    final original = InflationRateDomain(
      preset: 1,
      percent: 100.0,
      date: DateTime(2022, 6, 15),
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped.country, isNull);
    expect(roundTripped.percent, 100.0); // not scaled/divided anywhere here
  });

  test('list mapper round trips element-wise', () {
    final domainList = [
      InflationRateDomain(preset: 1, percent: 3.1, date: DateTime(2021, 1, 1)),
      InflationRateDomain(
        country: 'BR',
        preset: 1,
        percent: 4.62,
        date: DateTime(2021, 2, 1),
      ),
    ];

    final rows = domainList
        .map((d) => rowFromCompanion(d.toCompanion()))
        .toList();
    final roundTripped = rows.toDomainList();

    expect(roundTripped, domainList);
  });
}
