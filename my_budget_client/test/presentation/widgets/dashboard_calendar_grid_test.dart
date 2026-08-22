import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_calendar.dart';

import '../test_app.dart';

/// The month grid used to be exactly as tall as the month needed — four rows
/// for a February that starts on a Monday, six for a long month that starts on
/// a Saturday. Paging through the year therefore resized the calendar and shunted
/// everything below it up and down the screen.
void main() {
  setUpAll(initializeDateFormatting);

  const desktop = Size(1440, 900);

  Widget calendar(DateTime day, {void Function(DateTime)? onDaySelected}) =>
      DashboardCalendar(
        selectedDay: day,
        dateStep: DateStep.month,
        dailyIncomes: const {},
        dailyExpenses: const {},
        dailyNetWorth: const {},
        onDaySelected: onDaySelected ?? (_) {},
        onNext: () {},
        onPrevious: () {},
        onTitleTap: () {},
        currencyCode: 'EUR',
        availableCurrencies: const ['EUR'],
        onCurrencySelected: (_) {},
        onDateStepChanged: (_) {},
      );

  Future<Size> gridSize(WidgetTester tester, DateTime day) async {
    await pumpAppWidget(
      tester,
      wrapWithBlocs(calendar(day), settingsBloc: createSettingsBloc()),
      surfaceSize: desktop,
    );
    return tester.getSize(find.byType(GridView));
  }

  testWidgets('every month is the same height', (tester) async {
    // February 2021 is 28 days starting on a Monday — the shortest grid any
    // month can produce. August 2026 is 31 days starting on a Saturday, the
    // longest. Between those two the old grid changed by two whole rows.
    final shortest = await gridSize(tester, DateTime(2021, 2, 15));
    final longest = await gridSize(tester, DateTime(2026, 8, 15));

    expect(shortest.height, longest.height);
  });

  testWidgets('the days around the month are shown, faded, and inert', (
    tester,
  ) async {
    DateTime? selected;
    await pumpAppWidget(
      tester,
      wrapWithBlocs(
        calendar(DateTime(2026, 8, 15), onDaySelected: (d) => selected = d),
        settingsBloc: createSettingsBloc(),
      ),
      surfaceSize: desktop,
    );

    // 1 August 2026 is a Saturday, so an `en` grid (Sunday first) opens with
    // five days of July.
    final spillIn = find.byKey(
      DashboardCalendar.adjacentDayCellKey(DateTime(2026, 7, 31)),
    );
    expect(spillIn, findsOneWidget);
    expect(tester.widget<Opacity>(spillIn).opacity, lessThan(1.0));

    await tester.tap(spillIn, warnIfMissed: false);
    await tester.pump();

    // Tapping a day that is not part of the month would move the dashboard to
    // another month by accident.
    expect(selected, isNull);
  });

  testWidgets('a day of the month is still selectable', (tester) async {
    DateTime? selected;
    await pumpAppWidget(
      tester,
      wrapWithBlocs(
        calendar(DateTime(2026, 8, 15), onDaySelected: (d) => selected = d),
        settingsBloc: createSettingsBloc(),
      ),
      surfaceSize: desktop,
    );

    await tester.tap(find.byKey(DashboardCalendar.dayCellKey(20)));
    await tester.pump();

    expect(selected, DateTime(2026, 8, 20));
  });
}
