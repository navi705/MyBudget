import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/calendar_day.dart';

void main() {
  group('nearestDay', () {
    test('an empty list has no nearest day', () {
      expect(nearestDay(const [], DateTime(2024, 3, 10)), isNull);
    });

    test('an exact match is its own nearest day', () {
      final days = [DateTime(2024, 3, 1), DateTime(2024, 3, 10)];
      expect(nearestDay(days, DateTime(2024, 3, 10)), DateTime(2024, 3, 10));
    });

    test('a day before every stored one takes the first', () {
      final days = [DateTime(2024, 3, 5), DateTime(2024, 3, 10)];
      expect(nearestDay(days, DateTime(2024, 1, 1)), DateTime(2024, 3, 5));
    });

    test('a day after every stored one takes the last', () {
      final days = [DateTime(2024, 3, 5), DateTime(2024, 3, 10)];
      expect(nearestDay(days, DateTime(2024, 12, 31)), DateTime(2024, 3, 10));
    });

    test('the nearer neighbour wins when the gap differs', () {
      final days = [DateTime(2024, 3, 1), DateTime(2024, 3, 20)];
      expect(nearestDay(days, DateTime(2024, 3, 4)), DateTime(2024, 3, 1));
      expect(nearestDay(days, DateTime(2024, 3, 18)), DateTime(2024, 3, 20));
    });

    // The rule the DAO and the transactions bloc disagreed on: the bloc took
    // the later day, so a transaction on the midpoint converted at one rate on
    // the list and another everywhere the DAO answered.
    test('a day exactly between two resolves to the earlier one', () {
      final days = [DateTime(2024, 3, 8), DateTime(2024, 3, 12)];
      expect(nearestDay(days, DateTime(2024, 3, 10)), DateTime(2024, 3, 8));
    });

    test('the earlier day wins a tie whichever end of the list it is at', () {
      final days = [
        DateTime(2024, 1, 1),
        DateTime(2024, 3, 8),
        DateTime(2024, 3, 12),
        DateTime(2024, 12, 31),
      ];
      expect(nearestDay(days, DateTime(2024, 3, 10)), DateTime(2024, 3, 8));
    });

    test('a single stored day is the answer for any day', () {
      final days = [DateTime(2024, 3, 10)];
      expect(nearestDay(days, DateTime(2020, 1, 1)), DateTime(2024, 3, 10));
      expect(nearestDay(days, DateTime(2030, 1, 1)), DateTime(2024, 3, 10));
    });

    // Measured as instants, not in whole `inDays`. Truncating made a 23-hour
    // gap read as zero days, which tied with - and under the old bloc rule
    // beat - the day being asked about.
    test('a day is nearer to itself than to a short neighbouring day', () {
      // 2024-03-31 is a 23-hour day in a Europe-style zone; the arithmetic
      // below is written so the test holds in any zone, DST or not.
      final target = DateTime(2024, 3, 31);
      final days = [DateTime(2024, 3, 30), target];
      expect(nearestDay(days, target), target);
    });

    test('the shorter real gap wins even when both round to the same day', () {
      final days = [
        DateTime(2024, 3, 10, 1),
        DateTime(2024, 3, 11, 20),
      ];
      // 20 hours before the second, 39 hours after the first: both are "0" or
      // "1" whole days away depending on which end you truncate from.
      expect(
        nearestDay(days, DateTime(2024, 3, 11)),
        DateTime(2024, 3, 11, 20),
      );
    });

    test('duplicate stored days do not change the answer', () {
      final days = [
        DateTime(2024, 3, 8),
        DateTime(2024, 3, 8),
        DateTime(2024, 3, 12),
      ];
      expect(nearestDay(days, DateTime(2024, 3, 10)), DateTime(2024, 3, 8));
    });
  });
}
