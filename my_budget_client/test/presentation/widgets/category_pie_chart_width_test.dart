import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/presentation/widgets/dashboard/category_pie_chart.dart';

import '../test_app.dart';

/// The wide layout puts the donut and the category list side by side and gives
/// the list whatever width is left. The list used to carry a 650dp cap of its
/// own on top of that, so on a maximised desktop window it stopped well short
/// of the pane it sits in and left a visible empty strip down the right.
void main() {
  final categories = [
    Category(id: 'c1', name: 'Housing', type: CategoryType.expense),
    Category(id: 'c2', name: 'Groceries', type: CategoryType.expense),
  ];

  Widget chart() => CategoryPieChart(
    categoryConvertedTotals: const {'c1': 168.0, 'c2': 70.0},
    categories: categories,
    styles: const [],
    isIncome: false,
    currencyCode: 'EUR',
  );

  Future<double> listWidth(WidgetTester tester, double paneWidth) async {
    await pumpAppWidget(
      tester,
      wrapWithBlocs(
        Center(
          child: SizedBox(width: paneWidth, child: chart()),
        ),
        settingsBloc: createSettingsBloc(),
      ),
      surfaceSize: Size(paneWidth + 200, 900),
    );
    return tester.getSize(find.byType(ListView)).width;
  }

  testWidgets('the category list fills the width left beside the donut', (
    tester,
  ) async {
    // 1168dp is what the dashboard pane hands the chart on a maximised desktop
    // window: kDashboardPaneMaxWidth less its 16dp padding on each side.
    const paneWidth = 1168.0;
    final width = await listWidth(tester, paneWidth);

    // Anything at or below the old 650dp cap means the list is being held back
    // rather than taking the rest of the row.
    expect(width, greaterThan(650.0));

    // And what it takes is exactly the rest: the donut, the 48dp gap, and the
    // list account for the whole pane with nothing left over on the right.
    final donut = tester.getSize(find.byType(AspectRatio)).width;
    expect(donut + 48.0 + width, closeTo(paneWidth, 1.0));

    // The donut itself is worth more than the 340dp it used to be stuck at,
    // whatever width the pane grew to.
    expect(donut, greaterThan(400.0));
  });

  testWidgets('the narrow layout still stacks the list under the donut', (
    tester,
  ) async {
    // Below the 800dp threshold there is no row to share, so the list gets the
    // full width and the wide-layout arithmetic above must not apply.
    const paneWidth = 400.0;
    final width = await listWidth(tester, paneWidth);

    expect(width, closeTo(paneWidth, 1.0));
  });
}
