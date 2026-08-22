import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/period_summary_widget.dart';

import '../test_app.dart';

/// Income, expense and net share one Row, each taking an exact third and
/// scaling its text down to fill that third edge to edge. On a phone the three
/// amounts butted straight against each other and the row read as one run-on
/// string: "2 991.77 EUR 123 130.62 EUR-120 138.85 EUR".
void main() {
  setUpAll(initializeDateFormatting);

  final start = DateTime(2026, 8, 1);
  final end = DateTime(2026, 8, 31);

  Widget summary() => PeriodSummaryWidget(
    dateRangeStart: start,
    dateRangeEnd: end,
    // Wide enough apart to reproduce the phone screenshot: a four-figure
    // income beside a six-figure expense and a six-figure negative net.
    dailyIncomes: {DateTime(2026, 8, 4): 2991.77},
    dailyExpenses: {DateTime(2026, 8, 4): 123130.62},
    currencyCode: 'EUR',
    currencyDesignations: const {},
  );

  Future<List<Rect>> amountRects(WidgetTester tester, Size surface) async {
    await pumpAppWidget(
      tester,
      wrapWithBlocs(summary(), settingsBloc: createSettingsBloc()),
      surfaceSize: surface,
    );

    final amounts = find.byWidgetPredicate(
      (w) => w is Text && w.data != null && w.data!.contains('EUR'),
    );
    expect(amounts, findsNWidgets(3));

    // The painted rect, not the layout one: each amount sits in a FittedBox
    // that scales it down, so a Text's own size is its unscaled size and says
    // nothing about how much of the row it actually covers.
    final rects = <Rect>[];
    for (var i = 0; i < 3; i++) {
      final box = amounts.evaluate().elementAt(i).renderObject! as RenderBox;
      rects.add(
        MatrixUtils.transformRect(
          box.getTransformTo(null),
          Offset.zero & box.size,
        ),
      );
    }
    rects.sort((a, b) => a.left.compareTo(b.left));
    return rects;
  }

  testWidgets('the three amounts keep a gap between them on a phone', (
    tester,
  ) async {
    // 411 x 914dp is the emulator this was caught on.
    final rects = await amountRects(tester, const Size(411, 914));

    expect(rects[1].left - rects[0].right, greaterThan(4.0));
    expect(rects[2].left - rects[1].right, greaterThan(4.0));
  });

  testWidgets('and on a desktop width', (tester) async {
    final rects = await amountRects(tester, const Size(1440, 900));

    expect(rects[1].left - rects[0].right, greaterThan(4.0));
    expect(rects[2].left - rects[1].right, greaterThan(4.0));
  });
}
