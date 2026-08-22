// Which categories may be a category's parent.
//
// The picker used to offer the whole list, so editing "Home" and choosing
// "Home" - or choosing "Rent", which already sits under it - filed a category
// under itself. Nothing rejected the write: `parent_id` is a plain nullable
// column, and the screens then had to cut the loop somewhere the user never
// chose in order to draw anything at all.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';
import 'package:my_budget_client/presentation/screens/categories_screen.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';

import '../test_app.dart';

Category _category(String id, String name, {String? parent}) =>
    Category(id: id, name: name, type: CategoryType.expense, parentId: parent);

final _home = _category('c1', 'Home');
final _rent = _category('c2', 'Rent', parent: 'c1');
final _deposit = _category('c3', 'Deposit', parent: 'c2');
final _food = _category('c4', 'Food');

final _all = [_home, _rent, _deposit, _food];

/// Opens the dialog on [category] and taps its parent field.
Future<void> _openParentPicker(
  WidgetTester tester, {
  Category? category,
}) async {
  setSurfaceSize(tester, const Size(900, 900));

  await tester.pumpWidget(
    wrapWithBlocs(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AddEditCategoryDialog(category: category, allCategories: _all),
        ),
      ),
      stylesBloc: createStylesBloc(),
    ),
  );
  await tester.pumpAndSettle();

  // The field is wrapped in an AbsorbPointer, so the tap belongs to the
  // GestureDetector around it. Its key is the parent currently selected.
  final field = find.byKey(Key(category?.parentId ?? 'no_parent'));
  await tester.tap(
    find.ancestor(of: field, matching: find.byType(GestureDetector)).first,
  );
  await tester.pumpAndSettle();
}

/// A name inside the open picker, and not the identically named field of the
/// edit form behind it.
Finder _option(String name) => find.descendant(
  of: find.byType(SingleSelectDialog<Category>),
  matching: find.text(name),
);

void main() {
  testWidgets('a category cannot be filed under itself', (tester) async {
    await _openParentPicker(tester, category: _home);

    expect(_option('Home'), findsNothing);
  });

  testWidgets('a category cannot be filed under its own descendants', (
    tester,
  ) async {
    // Picking a child makes a two-row loop; picking a grandchild makes a
    // three-row one. Neither is a longer walk than the picker can afford.
    await _openParentPicker(tester, category: _home);

    expect(_option('Rent'), findsNothing);
    expect(_option('Deposit'), findsNothing);
  });

  testWidgets('everything outside the subtree is still offered', (
    tester,
  ) async {
    // The guard has to remove exactly the loops, not narrow the feature: Home
    // moving under Food is an ordinary reparent.
    await _openParentPicker(tester, category: _home);

    expect(_option('Food'), findsOneWidget);
  });

  testWidgets('a category may still be filed under its own parent', (
    tester,
  ) async {
    // Rent is already under Home; Home is upwards from Rent, not downwards, so
    // it stays on offer.
    await _openParentPicker(tester, category: _rent);

    expect(_option('Home'), findsOneWidget);
    expect(_option('Rent'), findsNothing);
    expect(_option('Deposit'), findsNothing);
  });

  testWidgets('a category being created is offered every parent', (
    tester,
  ) async {
    // There is no subtree yet, and nothing to loop back to.
    await _openParentPicker(tester);

    for (final name in const ['Home', 'Rent', 'Deposit', 'Food']) {
      expect(_option(name), findsOneWidget, reason: name);
    }
  });
}
