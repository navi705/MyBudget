import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/data/models/world_bank_inflation_model.dart';

/// Reading the provider's answer one point at a time.
///
/// The year came off a bare `int.parse`, so one point the provider dated in
/// any other shape threw out of the middle of the loop before a single row was
/// written. The caller catches and logs, so the visible result was an entire
/// country's inflation history missing with a line in the console about a
/// FormatException and nothing naming the point that caused it.
void main() {
  InflationDataPoint point(String date, double? value) =>
      InflationDataPoint(date: date, value: value);

  List<int> yearsOf(List<InflationDataPoint> points) =>
      InflationApiService.companionsFor(
        'SRB',
        points,
      ).map((c) => c.date.value.year).toList();

  test('a well-formed answer becomes one row per year', () {
    expect(
      yearsOf([point('2022', 3.1), point('2023', 8.4), point('2024', 4.2)]),
      [2022, 2023, 2024],
    );
  });

  test('the country and the percent are carried through', () {
    final companions = InflationApiService.companionsFor('DEU', [
      point('2023', 5.9),
    ]);

    expect(companions.single.country.value, 'DEU');
    expect(companions.single.percent.value, 5.9);
    expect(companions.single.date.value, DateTime(2023, 1, 1));
  });

  test('one undateable point does not take the other years with it', () {
    expect(
      yearsOf([point('2022', 3.1), point('2023Q1', 8.4), point('2024', 4.2)]),
      [2022, 2024],
      reason: 'a point that cannot be dated is one row lost, not all of them',
    );
  });

  test('a blank date is skipped rather than thrown on', () {
    expect(yearsOf([point('', 3.1), point('2024', 4.2)]), [2024]);
  });

  test('a year with spaces around it is still a year', () {
    expect(yearsOf([point(' 2024 ', 4.2)]), [2024]);
  });

  test('a point the provider has no figure for is skipped', () {
    expect(yearsOf([point('2024', null), point('2023', 4.2)]), [2023]);
  });

  test('a non-finite percent is refused', () {
    // Stored as a real and read straight into arithmetic, so one of these
    // turns every total it reaches into NaN.
    expect(
      yearsOf([
        point('2021', double.nan),
        point('2022', double.infinity),
        point('2023', double.negativeInfinity),
        point('2024', 4.2),
      ]),
      [2024],
    );
  });

  test('a negative percent is kept', () {
    // Deflation is a real figure, unlike the values above.
    final companions = InflationApiService.companionsFor('JPN', [
      point('2024', -0.3),
    ]);

    expect(companions.single.percent.value, -0.3);
  });

  test('an answer with nothing usable in it is empty, not an error', () {
    expect(yearsOf([point('n/a', 1.0), point('2024', null)]), isEmpty);
  });
}
