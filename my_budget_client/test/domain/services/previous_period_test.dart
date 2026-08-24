import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';

/// The window the accounts screen compares the current period against.
///
/// The day case was `start.subtract(const Duration(days: 1))` for both ends,
/// so "previous day" was the single instant of midnight. Period stats are
/// filtered inclusively between start and end, which left yesterday holding
/// only a transaction stamped exactly 00:00:00 - in practice, nothing.
void main() {
  DatePeriod dayOf(DateTime d) =>
      DatePeriod(DateTime(d.year, d.month, d.day),
          DateTime(d.year, d.month, d.day, 23, 59, 59));

  group('previousFor day', () {
    test('covers the whole of the day before, not just its midnight', () {
      final previous = dayOf(DateTime(2024, 5, 10)).previousFor(DateStep.day);

      expect(previous.start, DateTime(2024, 5, 9));
      expect(previous.end, DateTime(2024, 5, 9, 23, 59, 59));
    });

    test('steps back over a month boundary', () {
      final previous = dayOf(DateTime(2024, 3, 1)).previousFor(DateStep.day);

      expect(previous.start, DateTime(2024, 2, 29));
      expect(previous.end, DateTime(2024, 2, 29, 23, 59, 59));
    });

    test('steps back over a year boundary', () {
      final previous = dayOf(DateTime(2024, 1, 1)).previousFor(DateStep.day);

      expect(previous.start, DateTime(2023, 12, 31));
      expect(previous.end, DateTime(2023, 12, 31, 23, 59, 59));
    });

    // The day before is a calendar day, not 24 hours. On the day after a
    // spring-forward, subtracting a duration landed at 23:00 on the day before
    // yesterday, so both ends named the wrong day.
    test('lands on the calendar day before, whatever the clocks did', () {
      for (final day in [
        DateTime(2024, 3, 31),
        DateTime(2024, 4, 1),
        DateTime(2024, 10, 27),
        DateTime(2024, 10, 28),
        DateTime(2024, 11, 4),
      ]) {
        final previous = dayOf(day).previousFor(DateStep.day);
        final expected = DateTime(day.year, day.month, day.day - 1);

        expect(previous.start, expected, reason: 'start for $day');
        expect(previous.end.year, expected.year, reason: 'end year for $day');
        expect(previous.end.month, expected.month, reason: 'end month for $day');
        expect(previous.end.day, expected.day, reason: 'end day for $day');
      }
    });
  });

  group('previousFor month', () {
    test('covers the whole of the month before', () {
      final march = DatePeriod(DateTime(2024, 3, 1), DateTime(2024, 3, 31, 23, 59, 59));
      final previous = march.previousFor(DateStep.month);

      expect(previous.start, DateTime(2024, 2, 1));
      expect(previous.end, DateTime(2024, 2, 29, 23, 59, 59));
    });

    test('steps back over a year boundary', () {
      final january = DatePeriod(DateTime(2024, 1, 1), DateTime(2024, 1, 31, 23, 59, 59));
      final previous = january.previousFor(DateStep.month);

      expect(previous.start, DateTime(2023, 12, 1));
      expect(previous.end, DateTime(2023, 12, 31, 23, 59, 59));
    });
  });

  group('previousFor year', () {
    test('covers the whole of the year before', () {
      final year = DatePeriod(DateTime(2024, 1, 1), DateTime(2024, 12, 31, 23, 59, 59));
      final previous = year.previousFor(DateStep.year);

      expect(previous.start, DateTime(2023, 1, 1));
      expect(previous.end, DateTime(2023, 12, 31, 23, 59, 59));
    });
  });

  test('every step hands back a window that is not a single instant', () {
    final period = dayOf(DateTime(2024, 5, 10));

    for (final step in DateStep.values) {
      final previous = period.previousFor(step);
      expect(previous.end.isAfter(previous.start), isTrue, reason: '$step');
    }
  });
}
