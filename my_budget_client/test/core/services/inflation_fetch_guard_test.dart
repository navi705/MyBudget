import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';

/// Deciding whether the provider is worth asking, and what of its answer is
/// worth writing.
///
/// The service used to return the moment the country had a single row, so the
/// first fetch a device ever did was the last one it ever did: a year
/// published afterwards never arrived, and widening the range in settings
/// changed nothing because the check never looked at the range.
void main() {
  InflationRate row(int year, double percent, {int preset = 1}) => InflationRate(
    date: DateTime(year, 1, 1),
    percent: percent,
    country: 'SRB',
    preset: preset,
    modifiedAt: 0,
  );

  InflationRatesCompanion candidate(int year, double percent, {int preset = 1}) =>
      InflationRatesCompanion(
        country: const Value('SRB'),
        percent: Value(percent),
        date: Value(DateTime(year, 1, 1)),
        preset: Value(preset),
      );

  group('lastYearOf', () {
    test('reads both ends of a range and takes the later', () {
      expect(InflationApiService.lastYearOf('2000:2025'), 2025);
    });

    test('reads a single year', () {
      expect(InflationApiService.lastYearOf('2019'), 2019);
    });

    test('takes the later end even when the range is written backwards', () {
      expect(InflationApiService.lastYearOf('2025:2000'), 2025);
    });

    test('tolerates spaces around the years', () {
      expect(InflationApiService.lastYearOf(' 2000 : 2025 '), 2025);
    });

    test('refuses a range it cannot read', () {
      expect(InflationApiService.lastYearOf(''), isNull);
      expect(InflationApiService.lastYearOf('recent'), isNull);
      expect(InflationApiService.lastYearOf('2000:'), isNull);
      expect(InflationApiService.lastYearOf('2000:2010:2020'), isNull);
    });
  });

  group('shouldFetch', () {
    test('a country with nothing stored is always fetched', () {
      expect(InflationApiService.shouldFetch(null, '2000:2025'), isTrue);
    });

    test('a stored history short of the range end is fetched', () {
      expect(InflationApiService.shouldFetch(2024, '2000:2025'), isTrue);
    });

    test('a stored history reaching the range end is left alone', () {
      expect(InflationApiService.shouldFetch(2025, '2000:2025'), isFalse);
    });

    test('a stored history past the range end is left alone', () {
      expect(InflationApiService.shouldFetch(2026, '2000:2025'), isFalse);
    });

    test('an unreadable range is fetched rather than silently skipped', () {
      expect(InflationApiService.shouldFetch(2024, 'whenever'), isTrue);
    });
  });

  group('changedOnly', () {
    test('a year that is not stored yet is written', () {
      final out = InflationApiService.changedOnly(
        [row(2024, 3.1)],
        [candidate(2024, 3.1), candidate(2025, 4.2)],
      );
      expect(out.map((c) => c.date.value.year), [2025]);
    });

    test('a year stored with the same percent is not rewritten', () {
      final out = InflationApiService.changedOnly(
        [row(2024, 3.1), row(2023, 8.0)],
        [candidate(2023, 8.0), candidate(2024, 3.1)],
      );
      expect(out, isEmpty);
    });

    test('a revised percent for a stored year is written', () {
      final out = InflationApiService.changedOnly(
        [row(2024, 3.1)],
        [candidate(2024, 3.4)],
      );
      expect(out.single.percent.value, 3.4);
    });

    test('a preset the row does not belong to does not mask it', () {
      final out = InflationApiService.changedOnly(
        [row(2024, 3.1, preset: 2)],
        [candidate(2024, 3.1)],
      );
      expect(out.map((c) => c.date.value.year), [2024]);
    });

    test('nothing stored means everything is written', () {
      final out = InflationApiService.changedOnly(
        const [],
        [candidate(2023, 8.0), candidate(2024, 3.1)],
      );
      expect(out, hasLength(2));
    });
  });
}
