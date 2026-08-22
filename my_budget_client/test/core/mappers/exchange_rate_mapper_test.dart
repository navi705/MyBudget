import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/exchange_rate_mapper.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

void main() {
  drift.ExchangeRate rowFromCompanion(drift.ExchangeRatesCompanion c) =>
      drift.ExchangeRate(
        fromCurrencyCode: c.fromCurrencyCode.value,
        toCurrencyCode: c.toCurrencyCode.value,
        rate: c.rate.value,
        preset: c.preset.value,
        date: c.date.value,
        modifiedAt: 0,
      );

  test('round trip preserves every field, including a non-1 preset', () {
    final original = ExchangeRateDomain(
      fromCurrencyCode: 'USD',
      toCurrencyCode: 'EUR',
      preset: 3,
      rate: 0.9123456789, // full double precision, no rounding expected
      date: DateTime(2023, 7, 4),
    );

    final roundTripped = rowFromCompanion(original.toCompanion()).toDomain();

    expect(roundTripped.fromCurrencyCode, original.fromCurrencyCode);
    expect(roundTripped.toCurrencyCode, original.toCurrencyCode);
    expect(roundTripped.preset, original.preset);
    expect(roundTripped.rate, original.rate);
    expect(roundTripped.date, original.date);
    expect(roundTripped, original); // Equatable equality
  });

  test('list mappers round trip element-wise', () {
    final domainList = [
      ExchangeRateDomain(
        fromCurrencyCode: 'USD',
        toCurrencyCode: 'EUR',
        preset: 1,
        rate: 0.9,
        date: DateTime(2024, 1, 1),
      ),
      ExchangeRateDomain(
        fromCurrencyCode: 'GBP',
        toCurrencyCode: 'EUR',
        preset: 1,
        rate: 1.17,
        date: DateTime(2024, 2, 1),
      ),
    ];

    final rows = domainList
        .map((d) => rowFromCompanion(d.toCompanion()))
        .toList();
    final roundTripped = rows.toDomainList();

    expect(roundTripped, domainList);
  });
}
