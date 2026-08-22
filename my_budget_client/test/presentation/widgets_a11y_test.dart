// The three things every icon-only control in this app depends on.
//
// `MultiLevelTooltip` is the sole label carrier for the navigation
// destinations, the dashboard FAB and every IconButton in the filter bars. It
// used to fire on `MouseRegion.onEnter` alone, so on Android the glyphs were
// unlabelled and TalkBack announced "button" with no name; and its overlay was
// positioned by copying the anchor's offset verbatim, so anything in the right
// third of a maximised window had its card pushed off-screen.
//
// `DashboardCalendar` hardcoded a Monday-start week, which is wrong for `ar`
// (Saturday) and `en_US` (Sunday). The header row and the day grid now read the
// same `DateDisplay.firstDayOfWeek`, and the assertion below is that they agree
// with each other - checking either one alone would not catch them drifting.
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/dashboard_calendar.dart';
import 'package:my_budget_client/presentation/widgets/multi_level_tooltip.dart';

import 'test_app.dart';

// A month whose first day is neither a Monday nor the first column in any of
// the locales below: 1 June 2024 is a Saturday, so an `ar` grid starts it in
// column 0, an `en` grid in column 6 and a `ru` grid in column 5. A month that
// happened to start on a Monday would pass whatever the week-start logic did.
final DateTime _june2024 = DateTime(2024, 6, 15);

const Size _desktop = Size(1440, 900);
const Size _tallPhone = Size(400, 1600);

Widget _calendar() => DashboardCalendar(
  selectedDay: _june2024,
  dateStep: DateStep.month,
  dailyIncomes: const {},
  dailyExpenses: const {},
  dailyNetWorth: const {},
  onDaySelected: (_) {},
  onNext: () {},
  onPrevious: () {},
  onTitleTap: () {},
  currencyCode: 'EUR',
  availableCurrencies: const ['EUR'],
  onCurrencySelected: (_) {},
  onDateStepChanged: (_) {},
);

/// The column a locale's calendar should open June 2024 in, derived from the
/// same `intl` symbol data the widget reads rather than from a table typed out
/// here - a hardcoded expectation would only restate the bug.
int _expectedFirstColumn(String locale) {
  final firstDayOfWeek = DateFormat.yMd(locale).dateSymbols.FIRSTDAYOFWEEK + 1;
  return (DateTime(2024, 6, 1).weekday - firstDayOfWeek + 7) % 7;
}

/// Index of the weekday label horizontally closest to [x].
///
/// The header Row divides the width into seven equal parts while the grid
/// inserts 8dp between cells, so the two centres are a few pixels apart by
/// construction and cannot be compared for equality. "Which label is this cell
/// under" is the question that actually matters, and it is answered exactly.
int _nearestLabelColumn(WidgetTester tester, double x) {
  var best = 0;
  var bestDistance = double.infinity;
  for (var i = 0; i < 7; i++) {
    final centre = tester
        .getCenter(find.byKey(DashboardCalendar.weekdayLabelKey(i)))
        .dx;
    final distance = (centre - x).abs();
    if (distance < bestDistance) {
      bestDistance = distance;
      best = i;
    }
  }
  return best;
}

void main() {
  setUpAll(initializeDateFormatting);

  group('MultiLevelTooltip labelling', () {
    testWidgets('exposes a semantics label without any hover', (tester) async {
      // Disposed at the end of the body rather than through `addTearDown`:
      // the binding checks for leaked semantics handles when the test function
      // returns, which is before any tear-down registered inside it runs, so a
      // deferred dispose fails the test it was meant to clean up after.
      final semantics = tester.ensureSemantics();

      final l10n = await loadL10n();
      await pumpAppWidget(
        tester,
        wrapWithBlocs(
          MultiLevelTooltip(
            message: l10n.previousPeriodTooltip,
            actionId: 'prev_period',
            description: l10n.previousPeriodDescription,
            child: IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {},
            ),
          ),
          settingsBloc: createSettingsBloc(),
        ),
        surfaceSize: _tallPhone,
      );

      // No pointer has ever entered the widget: this is what a phone user and
      // a screen reader get.
      expect(
        find.bySemanticsLabel(l10n.previousPeriodTooltip),
        findsOneWidget,
        reason: 'the icon button is announced as a bare "button" without this',
      );

      semantics.dispose();
    });

    testWidgets('opens its own card on a long press on the touch platforms', (
      tester,
    ) async {
      // A finger has no hover, so the long press is the whole affordance on
      // Android. It used to be a Material `Tooltip`, which showed the title
      // only; the card shows the description too.
      final l10n = await loadL10n();
      await pumpAppWidget(
        tester,
        wrapWithBlocs(
          MultiLevelTooltip(
            message: l10n.previousPeriodTooltip,
            actionId: 'prev_period',
            description: l10n.previousPeriodDescription,
            child: IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () {},
            ),
          ),
          settingsBloc: createSettingsBloc(),
        ),
        surfaceSize: _tallPhone,
        platform: TargetPlatform.android,
      );

      expect(find.text(l10n.previousPeriodTooltip), findsNothing);

      await tester.longPress(find.byType(IconButton));
      await tester.pump();

      expect(find.text(l10n.previousPeriodTooltip), findsOneWidget);
      expect(
        find.text(l10n.previousPeriodDescription),
        findsOneWidget,
        reason: 'a long press opens the card at level 2, description included',
      );

      // And it takes itself away: there is no pointer-exit on a touch screen,
      // so a card that only closed on exit would stay on top of the UI.
      await tester.pump(const Duration(seconds: 5));
      expect(find.text(l10n.previousPeriodTooltip), findsNothing);
    });

    testWidgets('says its message once when hovered on a touch platform', (
      tester,
    ) async {
      // The default target platform in a widget test is Android, and plenty of
      // real Android devices have a mouse. A Material `Tooltip` on the touch
      // path opened on hover as well - `triggerMode` only governs tap and long
      // press - so the control rendered and announced its title twice, once
      // from the Tooltip and once from this widget's card.
      final l10n = await loadL10n();
      await pumpAppWidget(
        tester,
        wrapWithBlocs(
          MultiLevelTooltip(
            message: l10n.selectDateTooltip,
            actionId: 'pick_date',
            description: l10n.selectDateDescription,
            child: IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () {},
            ),
          ),
          settingsBloc: createSettingsBloc(),
        ),
        surfaceSize: _tallPhone,
        platform: TargetPlatform.android,
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
      await tester.pump();
      // Level 1 after a second, level 2 three seconds later.
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();

      expect(find.text(l10n.selectDateTooltip), findsOneWidget);
      expect(find.text(l10n.selectDateDescription), findsOneWidget);

      await mouse.moveTo(Offset.zero);
      await tester.pump();
    });

    testWidgets('keeps the hover card on screen against the right edge', (
      tester,
    ) async {
      final l10n = await loadL10n();
      await pumpAppWidget(
        tester,
        wrapWithBlocs(
          Align(
            // Hard against the trailing edge, where the rail toggle and the
            // filter bar overflow live. The old overlay was a
            // `Positioned(width: 250)` pinned to the anchor's own x, so its
            // card ran ~200px past the window here.
            alignment: Alignment.topRight,
            child: MultiLevelTooltip(
              message: l10n.selectDateTooltip,
              actionId: 'pick_date',
              description: l10n.selectDateDescription,
              child: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () {},
              ),
            ),
          ),
          settingsBloc: createSettingsBloc(),
        ),
        surfaceSize: _desktop,
      );

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(IconButton)));
      await tester.pump();
      // The card opens after a 1000ms dwell.
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();

      final card = find.byType(IntrinsicWidth);
      expect(card, findsOneWidget, reason: 'the hover card never opened');

      final rect = tester.getRect(card);
      expect(rect.right, lessThanOrEqualTo(_desktop.width));
      expect(rect.left, greaterThanOrEqualTo(0.0));
      expect(rect.bottom, lessThanOrEqualTo(_desktop.height));
      expect(rect.top, greaterThanOrEqualTo(0.0));

      // Leaving the anchor cancels the level-2 timer the card is still
      // holding; a test that ends with one pending fails on the timer, not on
      // the assertion it was written for.
      await mouse.moveTo(Offset.zero);
      await tester.pump();
    });

    testWidgets('flips the hover card above an anchor at the bottom edge', (
      tester,
    ) async {
      final l10n = await loadL10n();
      await pumpAppWidget(
        tester,
        wrapWithBlocs(
          Align(
            alignment: Alignment.bottomLeft,
            child: MultiLevelTooltip(
              message: l10n.selectDateTooltip,
              actionId: 'pick_date',
              description: l10n.selectDateDescription,
              child: IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () {},
              ),
            ),
          ),
          settingsBloc: createSettingsBloc(),
        ),
        surfaceSize: _desktop,
      );

      final anchor = tester.getRect(find.byType(IconButton));

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(anchor.center);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump();

      final rect = tester.getRect(find.byType(IntrinsicWidth));
      expect(rect.bottom, lessThanOrEqualTo(_desktop.height));
      expect(
        rect.top,
        lessThan(anchor.top),
        reason: 'a card below a bottom-edge anchor is clipped, not shown',
      );

      await mouse.moveTo(Offset.zero);
      await tester.pump();
    });
  });

  group('DashboardCalendar week start', () {
    // en resolves to the US week (Sunday) and ar to the Gulf week (Saturday),
    // so the two runs put day 1 of June 2024 in different columns. Both are
    // asserted the same way: the cell has to sit under its own label.
    for (final locale in const [Locale('en'), Locale('ar'), Locale('ru')]) {
      testWidgets('labels and day cells agree in ${locale.languageCode}', (
        tester,
      ) async {
        await pumpAppWidget(
          tester,
          wrapWithBlocs(_calendar(), settingsBloc: createSettingsBloc()),
          locale: locale,
          surfaceSize: _tallPhone,
        );
        await tester.pump();

        final expectedColumn = _expectedFirstColumn(locale.languageCode);
        final firstCell = find.byKey(DashboardCalendar.dayCellKey(1));
        expect(firstCell, findsOneWidget);

        expect(
          _nearestLabelColumn(tester, tester.getCenter(firstCell).dx),
          expectedColumn,
          reason:
              'day 1 of June 2024 should sit in column $expectedColumn in '
              '${locale.languageCode}',
        );

        // And the day after it is one column further along, which pins the
        // direction of the grid under RTL as well as the offset.
        final secondCell = find.byKey(DashboardCalendar.dayCellKey(2));
        expect(
          _nearestLabelColumn(tester, tester.getCenter(secondCell).dx),
          (expectedColumn + 1) % 7,
        );
      });
    }

    testWidgets('the Saturday-start and Sunday-start weeks differ', (
      tester,
    ) async {
      // Guards the test above from silently passing on a shared wrong answer:
      // if every locale produced the same first column, the assertions would
      // still hold and the bug would be back.
      expect(_expectedFirstColumn('ar'), isNot(_expectedFirstColumn('en')));
      expect(_expectedFirstColumn('ru'), isNot(_expectedFirstColumn('en')));
    });
  });
}
