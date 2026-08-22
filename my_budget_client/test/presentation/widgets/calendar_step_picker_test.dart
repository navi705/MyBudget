// The date picker on a surface that is short rather than narrow.
//
// `CalendarStepPicker` is a bottom sheet whose chrome - header, mode selector,
// step selector and the Clear/Apply row - is a fixed ~288dp tall and cannot
// compress. Everything left over goes to the picker body through a single
// `Flexible`, and in day mode that body is a `CalendarDatePicker`, which is
// rigid the other way: it asks for ~346dp and clips to whatever it is given.
//
// On a phone in landscape (411dp tall) those two numbers do not both fit, and
// the date grid was squeezed to a sliver - the one thing the sheet exists to
// let a user do was impossible on half the orientations the app ships in.
// These tests pin the day grid as *usable* on both orientations, which is a
// claim about the arithmetic above rather than about any one widget.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/presentation/widgets/calendar_step_picker.dart';

import '../test_app.dart';

/// What [CalendarStepPicker.onApply] was handed, or null if it never fired.
class _Applied {
  DateTime? date;
  DateStep? step;
}

/// Opens the picker the way every call site does: as a modal bottom sheet.
///
/// The sheet matters. Both buttons in the picker end with
/// `Navigator.of(context).pop()`, so a picker pumped as a bare `home` widget
/// would tear down the whole app the moment Apply is tapped.
Future<_Applied> _openPicker(
  WidgetTester tester, {
  required Size surface,
  DateStep step = DateStep.day,
  PickerVisibility rangeOptionVisibility = PickerVisibility.visible,
}) async {
  final applied = _Applied();

  await pumpAppWidget(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => CalendarStepPicker(
            initialDate: DateTime(2026, 8, 10),
            initialStep: step,
            initialFilterMode: FilterMode.date,
            rangeOptionVisibility: rangeOptionVisibility,
            onApply: (date, range, appliedStep, mode) {
              applied.date = date;
              applied.step = appliedStep;
            },
          ),
        ),
        child: const Text('open'),
      ),
    ),
    surfaceSize: surface,
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return applied;
}

/// Asserts the day grid is a grid a finger could use, then picks day 15.
///
/// Clipping is quiet: a `CalendarDatePicker` handed 61dp still lays out, still
/// reports a rect for every cell and still answers a tap - the cells are just
/// 1dp tall slivers painted outside their parent. So the assertion that
/// catches it is dimensional, not behavioural: the grid must keep its own
/// ~346dp height, and the cell must be a real target inside the screen once
/// scrolled to.
Future<void> _pickTheFifteenth(WidgetTester tester, Size surface) async {
  expect(
    tester.getRect(find.byType(CalendarDatePicker)).height,
    greaterThan(340),
    reason: 'the day grid was squeezed below its own intrinsic height',
  );

  final day = find.text('15');
  expect(day, findsOneWidget, reason: 'the day grid is not rendered at all');

  // Scrolls only if the grid is taller than the room it was given. On a tall
  // surface it already fits and this is a no-op, so the same call covers both
  // orientations without asserting which one needed it.
  await tester.ensureVisible(day);
  await tester.pumpAndSettle();

  final cell = tester.getRect(day);
  expect(
    cell.height,
    greaterThan(16),
    reason: 'the day cell is a sliver, not something a finger can hit',
  );
  expect(cell.top, greaterThanOrEqualTo(0.0));
  expect(
    cell.bottom,
    lessThanOrEqualTo(surface.height),
    reason: 'day 15 sits below the bottom of the screen',
  );

  await tester.tap(day);
  await tester.pumpAndSettle();
}

void main() {
  group('CalendarStepPicker day grid', () {
    testWidgets('is usable on a phone in landscape', (tester) async {
      final l10n = await loadL10n();
      // A 411x866 phone rotated: the shortest surface the app ships on.
      final applied = await _openPicker(tester, surface: const Size(866, 411));

      // A grid clipped by its parent reports the overflow as a paint-time
      // error, which is the failure mode this test was written for.
      expect(tester.takeException(), isNull);

      // The sheet must also stay inside the screen it was opened on, or the
      // Apply button below the grid is off the bottom edge.
      expect(
        tester.getRect(find.byType(CalendarStepPicker)).height,
        lessThanOrEqualTo(411.0),
      );

      await _pickTheFifteenth(tester, const Size(866, 411));
      await tester.tap(find.text(l10n.applyButton));
      await tester.pumpAndSettle();

      expect(applied.date, DateTime(2026, 8, 15));
      expect(applied.step, DateStep.day);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is usable on a phone in portrait', (tester) async {
      final l10n = await loadL10n();
      final applied = await _openPicker(tester, surface: const Size(411, 866));

      expect(tester.takeException(), isNull);

      // Nothing should have to scroll here: the grid fits as it always did,
      // and the short-surface handling must not have cost the tall one that.
      final before = tester.getRect(find.text('15'));
      await _pickTheFifteenth(tester, const Size(411, 866));
      expect(tester.getRect(find.text('15')), before);

      await tester.tap(find.text(l10n.applyButton));
      await tester.pumpAndSettle();

      expect(applied.date, DateTime(2026, 8, 15));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'is usable on a landscape phone with the range tabs shown, which is the '
      'tallest the chrome ever gets',
      (tester) async {
        // The dashboard hides the single-date/range selector; every other call
        // site shows it, and it plus its gap is another ~56dp of chrome
        // competing with the grid for the same 411dp.
        final applied = await _openPicker(
          tester,
          surface: const Size(866, 411),
          rangeOptionVisibility: PickerVisibility.visible,
        );

        expect(find.text('15'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await _pickTheFifteenth(tester, const Size(866, 411));
        expect(applied.date, isNull, reason: 'Apply was not tapped yet');
      },
    );
  });
}
