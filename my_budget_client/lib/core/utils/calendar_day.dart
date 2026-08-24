/// Day arithmetic that stays on the local midnight grid.
///
/// `DateTime.add`/`subtract` take a [Duration], and a duration of one day is
/// exactly 24 hours. A local day is 23 or 25 hours long on the two days a year
/// the clocks move, so stepping with a duration walks off midnight at the
/// first boundary it crosses and never returns to it. Anything keyed on a day
/// then stops matching: a map of transactions grouped by `DateTime(y, m, d)`
/// answers null for every lookup after the drift, and a loop bounded by
/// `isAtSameMomentAs` on a midnight runs past its end.
///
/// The [DateTime] constructor has no such problem. It is given a calendar day
/// and resolves it against the zone, normalising an out-of-range field on the
/// way: day 0 is the last day of the previous month, month 13 is January of
/// the next year. The one case it cannot honour is a zone whose clocks jump
/// forward *at* midnight, where the requested time does not exist and the
/// result is the hour the day actually begins at - still the right day.
library;

/// Local midnight on the day [date] falls in.
DateTime startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

/// The start of the day after the one [date] falls in.
DateTime nextDay(DateTime date) =>
    DateTime(date.year, date.month, date.day + 1);

/// The start of the day before the one [date] falls in.
DateTime previousDay(DateTime date) =>
    DateTime(date.year, date.month, date.day - 1);

/// The start of the day [days] after the one [date] falls in.
///
/// A negative [days] steps backwards.
DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Whichever day in [sorted] is closest to [day], or null when [sorted] is
/// empty. A day that falls exactly between two resolves to the earlier one.
///
/// [sorted] must be ascending; this binary-searches it.
///
/// One rule, in one place, because the answer is money on screen: the same
/// missing day used to resolve to the day after it on the transactions list
/// and to the day before it everywhere the rate came out of the database, so
/// one transaction showed two different converted amounts depending on which
/// screen drew it. A rate quoted before the transaction happened is the safer
/// of two equals - it was knowable at the time - so that is the tie the two
/// paths now share.
///
/// Compared as instants rather than through `Duration.inDays`, which truncates:
/// a local day is 23 hours long on the day the clocks go forward, so the day
/// before measured zero days away and tied with an exact match.
DateTime? nearestDay(List<DateTime> sorted, DateTime day) {
  var low = 0;
  var high = sorted.length;
  while (low < high) {
    final mid = (low + high) >> 1;
    if (sorted[mid].isBefore(day)) {
      low = mid + 1;
    } else {
      high = mid;
    }
  }

  final after = low < sorted.length ? sorted[low] : null;
  final before = low > 0 ? sorted[low - 1] : null;
  if (after == null) return before;
  if (before == null) return after;

  return after.difference(day).abs() < day.difference(before).abs()
      ? after
      : before;
}
