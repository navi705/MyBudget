import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/analytics_chart_selector.dart';

import '../test_app.dart';

/// The wealth donut drew a slice per account. Past a dozen the extra slices are
/// sub-degree slivers - no label fits in them and the 2dp gap between sections
/// is wider than the arc - so the ring is capped and the tail folded into one
/// section, while the legend underneath still names every account.
void main() {
  const accountCount = 30;

  final accounts = [
    for (var i = 0; i < accountCount; i++)
      Account(
        id: 'a$i',
        name: 'Account ${i + 1}',
        balance: (accountCount - i).toDouble(),
        currencyCode: 'EUR',
        currencyDesignationId: 'd1',
        accountTypeId: 't1',
        creationDate: DateTime(2026, 1, 1),
      ),
  ];

  // Descending, so account 1 is the largest share and account 30 the smallest.
  final breakdown = {
    for (var i = 0; i < accountCount; i++) 'a$i': (accountCount - i).toDouble(),
  };

  Future<void> pumpReport(WidgetTester tester) async {
    await pumpAppWidget(
      tester,
      wrapWithBlocs(
        SizedBox(
          height: 2200,
          child: BalanceReportWidget(
            dateRangeStart: DateTime(2026, 1, 1),
            dateRangeEnd: DateTime(2026, 1, 31),
            dailyNetWorth: {DateTime(2026, 1, 1): 465.0},
            dayBalances: const {},
            currencyBreakdown: const {'EUR': 465.0},
            accountBreakdown: breakdown,
            accounts: accounts,
            currencyCode: 'EUR',
            currencyDesignations: const {},
          ),
        ),
        settingsBloc: createSettingsBloc(),
      ),
      surfaceSize: const Size(700, 2200),
    );
  }

  testWidgets('the wealth donut stops at a dozen slices plus the remainder', (
    tester,
  ) async {
    await pumpReport(tester);

    final chart = tester.widgetList<PieChart>(find.byType(PieChart)).first;
    final sections = chart.data.sections;

    expect(sections, hasLength(13));

    // The twelve largest keep their own arc, in order.
    expect(sections.take(12).map((s) => s.value), [
      for (var i = 0; i < 12; i++) (accountCount - i).toDouble(),
    ]);

    // The eighteen left over are one arc between them, and the ring still adds
    // up to the whole: a cap that dropped them would understate every share.
    expect(sections.last.value, 18 * 19 / 2);
    expect(
      sections.fold<double>(0, (sum, s) => sum + s.value),
      accountCount * (accountCount + 1) / 2,
    );
  });

  testWidgets('the legend still names the accounts the ring folded away', (
    tester,
  ) async {
    await pumpReport(tester);

    for (final name in ['Account 1', 'Account 13', 'Account 30']) {
      expect(
        find.textContaining('$name '),
        findsWidgets,
        reason: '$name is missing from the legend',
      );
    }
  });

  testWidgets('hovering the account filter leaves the charts alone', (
    tester,
  ) async {
    await pumpReport(tester);

    Color? fill() =>
        (tester
                    .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                    .decoration
                as BoxDecoration)
            .color;
    PieChart donut() => tester.widget<PieChart>(find.byType(PieChart).first);

    final chartBefore = donut();
    final fillBefore = fill();

    final pointer = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(pointer.hover(Offset.zero));
    await tester.sendEventToBinding(
      pointer.hover(tester.getCenter(find.byType(DropdownButton<String?>))),
    );
    await tester.pump();

    // The hover did land, so the identity check below is about who rebuilt and
    // not about nothing having happened.
    expect(fill(), isNot(fillBefore));

    // Repainting the filter's own background used to rebuild the report state,
    // and with it the trend chart and both donuts, on every frame of the 200ms
    // hover animation.
    expect(identical(donut(), chartBefore), isTrue);
  });
}
