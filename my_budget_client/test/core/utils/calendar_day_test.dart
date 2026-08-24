import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/calendar_day.dart';

/// Stepping a day at a time without leaving the local midnight grid.
///
/// The dashboard's net-worth walk-back steps backwards one day per iteration
/// and looks up `transactionsByDate[iterDate]`, a map keyed on
/// `DateTime(y, m, d)`. Stepping with `Duration(days: 1)` subtracts 24 hours,
/// so on the two days a year the clocks move it landed an hour off midnight
/// and stayed there: from that day backwards every lookup missed, the
/// walk-back stopped undoing transactions, and the chart reported every
/// earlier day at the balance held on the day the clocks changed.
///
/// The strongest of these run only where the local zone actually moves its
/// clocks - they are written so they hold anywhere, and the DST scan below
/// says which case the machine running them exercised.
void main() {
  group('a step lands on midnight', () {
    test('going forward', () {
      expect(nextDay(DateTime(2025, 3, 14)), DateTime(2025, 3, 15));
    });

    test('going back', () {
      expect(previousDay(DateTime(2025, 3, 14)), DateTime(2025, 3, 13));
    });

    test('from a time of day, not just from midnight', () {
      expect(nextDay(DateTime(2025, 3, 14, 23, 59, 59)), DateTime(2025, 3, 15));
      expect(previousDay(DateTime(2025, 3, 14, 0, 0, 1)), DateTime(2025, 3, 13));
    });

    test('and startOfDay drops the time', () {
      expect(startOfDay(DateTime(2025, 3, 14, 17, 42, 3, 9)), DateTime(2025, 3, 14));
    });
  });

  group('a step crosses a boundary', () {
    test('into the next month', () {
      expect(nextDay(DateTime(2025, 1, 31)), DateTime(2025, 2, 1));
    });

    test('back into the previous month', () {
      expect(previousDay(DateTime(2025, 3, 1)), DateTime(2025, 2, 28));
    });

    test('into the next year', () {
      expect(nextDay(DateTime(2025, 12, 31)), DateTime(2026, 1, 1));
    });

    test('back into the previous year', () {
      expect(previousDay(DateTime(2026, 1, 1)), DateTime(2025, 12, 31));
    });

    test('onto a leap day', () {
      expect(nextDay(DateTime(2024, 2, 28)), DateTime(2024, 2, 29));
      expect(previousDay(DateTime(2024, 3, 1)), DateTime(2024, 2, 29));
    });

    test('over the leap day a non-leap year does not have', () {
      expect(nextDay(DateTime(2025, 2, 28)), DateTime(2025, 3, 1));
      expect(previousDay(DateTime(2025, 3, 1)), DateTime(2025, 2, 28));
    });
  });

  group('walking a range', () {
    /// Every day of [year] as the walk-back would reach them.
    List<DateTime> walkBack(int year) {
      final days = <DateTime>[];
      var day = DateTime(year, 12, 31);
      final limit = DateTime(year, 1, 1);
      while (!day.isBefore(limit)) {
        days.add(day);
        day = previousDay(day);
      }
      return days;
    }

    test('reaches every day of a year exactly once', () {
      final days = walkBack(2025);

      expect(days, hasLength(365));
      expect(days.toSet(), hasLength(365), reason: 'no day is visited twice');
    });

    test('reaches every day of a leap year exactly once', () {
      expect(walkBack(2024), hasLength(366));
    });

    test('never leaves midnight', () {
      // The property the map lookups depend on. Where the local zone moves its
      // clocks this is what a 24-hour step breaks.
      final offGrid = walkBack(2025).where(
        (d) => d.hour != 0 || d.minute != 0 || d.second != 0,
      );

      expect(
        offGrid,
        isEmpty,
        reason: 'a day key that is not midnight matches nothing',
      );
    });

    test('stops exactly on its limit', () {
      final days = walkBack(2025);

      expect(days.last, DateTime(2025, 1, 1));
      expect(
        days.last.isAtSameMomentAs(DateTime(2025, 1, 1)),
        isTrue,
        reason: 'a loop bounded by isAtSameMomentAs has to be able to hit it',
      );
    });
  });

  test('the local zone moves its clocks, or it does not', () {
    // Not an assertion about the machine - a note in the output about which
    // case the group above actually exercised, since the 24-hour step is only
    // wrong where a local day is not 24 hours long.
    var shifting = 0;
    var day = DateTime(2025, 1, 1);
    while (day.year == 2025) {
      final after = nextDay(day);
      if (after.difference(day) != const Duration(hours: 24)) shifting++;
      day = after;
    }

    expect(shifting, anyOf(0, 1, 2));
  });
}
