import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/utils/calendar_day.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/period_summary_widget.dart';

import '../test_app.dart';

/// The period totals walked their range with nominal 24-hour arithmetic: a day
/// count of `end.difference(start).inDays + 1` and a step of
/// `start.add(Duration(days: i))`. Wherever the local clocks move, one of the
/// days in a range spanning the change is not 24 hours long, and both parts
/// went wrong together - the shorter day was reached under two different `i`
/// and counted into the totals twice, while the count that bounded the loop
/// came up a day short and dropped the last day of the range.
///
/// A user in such a zone saw one day's income added to the month twice and the
/// last day of the month missing from it, twice a year, with nothing on the
/// screen to say so.
///
/// Where the local zone has no clock change these still assert the ordinary
/// case: every day of the range counted exactly once.
void main() {
  setUpAll(initializeDateFormatting);

  /// The days of [year] that are not 24 hours long, in local time.
  List<DateTime> clockChangeDays(int year) {
    final days = <DateTime>[];
    var day = DateTime(year, 1, 1);
    while (day.year == year) {
      final after = nextDay(day);
      if (after.difference(day) != const Duration(hours: 24)) days.add(day);
      day = after;
    }
    return days;
  }

  /// A week centred on [day], and the amounts to spread over it.
  ///
  /// The two amounts are on the day the clocks move and on the last day of the
  /// range - the two the old walk got wrong, one counted twice and one never
  /// reached.
  Widget summaryAround(DateTime day) {
    final start = addDays(day, -3);
    final end = addDays(day, 3);
    return PeriodSummaryWidget(
      dateRangeStart: start,
      dateRangeEnd: end,
      dailyIncomes: {day: 100.0, end: 50.0},
      dailyExpenses: const {},
      currencyCode: 'EUR',
      currencyDesignations: const {},
    );
  }

  Future<List<String>> amountTexts(WidgetTester tester, Widget widget) async {
    await pumpAppWidget(
      tester,
      wrapWithBlocs(widget, settingsBloc: createSettingsBloc()),
      surfaceSize: const Size(1440, 900),
    );

    return find
        .byWidgetPredicate(
          (w) => w is Text && w.data != null && w.data!.contains('EUR'),
        )
        .evaluate()
        .map((e) => (e.widget as Text).data!)
        .toList();
  }

  testWidgets('every day of a range counts once, and none is missed', (
    tester,
  ) async {
    final texts = await amountTexts(tester, summaryAround(DateTime(2025, 6, 15)));

    expect(texts.any((t) => t.contains('150')), isTrue, reason: '100 + 50');
    expect(texts.any((t) => t.contains('200')), isFalse);
  });

  for (final day in clockChangeDays(2025)) {
    final label = '${day.year}-${day.month}-${day.day}';

    testWidgets('a range spanning the clock change on $label totals once', (
      tester,
    ) async {
      final texts = await amountTexts(tester, summaryAround(day));

      expect(
        texts.any((t) => t.contains('150')),
        isTrue,
        reason:
            'the day the clocks move is one day of income, and the last day '
            'of the range is still in it: got $texts',
      );
      expect(
        texts.any((t) => t.contains('200')),
        isFalse,
        reason: 'a 25-hour day must not be walked onto twice',
      );
      expect(
        texts.any((t) => t.contains('100.') || t.contains('100,')),
        isFalse,
        reason: 'a 23-hour day must not drop the day after it',
      );
    });
  }
}
