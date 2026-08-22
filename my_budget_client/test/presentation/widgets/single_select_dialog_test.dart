// The picker's empty branch, which did not exist.
//
// `ListView.builder` over an empty list renders nothing, so all thirteen call
// sites showed a search box above blank space and a lone Cancel button. Two
// unrelated situations looked identical there: a search that filtered
// everything out, which the user undoes by clearing the box, and a source list
// that was empty to begin with, which they can only leave by creating
// something — hence the optional create action asserted at the bottom.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/presentation/widgets/single_select_dialog.dart';

import '../test_app.dart';

/// Opens the picker from a button, the way every call site does.
Future<void> _openPicker(
  WidgetTester tester, {
  required List<String> items,
  SingleSelectCreateAction? createAction,
  Locale locale = const Locale('en'),
}) async {
  await pumpAppWidget(
    tester,
    Builder(
      builder: (context) => ElevatedButton(
        onPressed: () => showSingleSelectDialog<String>(
          context: context,
          items: items,
          title: 'Pick one',
          itemBuilder: (item) => Text(item),
          stringGetter: (item) => item,
          createAction: createAction,
        ),
        child: const Text('open'),
      ),
    ),
    locale: locale,
    surfaceSize: const Size(800, 900),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  group('SingleSelectDialog empty state', () {
    testWidgets('an empty list says there is nothing to choose from', (
      tester,
    ) async {
      final l10n = await loadL10n();
      await _openPicker(tester, items: const []);

      expect(find.text(l10n.selectDialogEmptyState), findsOneWidget);
      expect(find.text(l10n.selectDialogNoMatches), findsNothing);
    });

    testWidgets('a search matching nothing says that instead', (tester) async {
      final l10n = await loadL10n();
      await _openPicker(tester, items: const ['Cash', 'Card']);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectDialogNoMatches), findsOneWidget);
      expect(find.text(l10n.selectDialogEmptyState), findsNothing);
    });

    testWidgets('clearing the search restores the items', (tester) async {
      final l10n = await loadL10n();
      await _openPicker(tester, items: const ['Cash', 'Card']);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text(l10n.selectDialogNoMatches), findsNothing);
      expect(find.text('Cash'), findsOneWidget);
    });

    testWidgets('the message comes from the active locale', (tester) async {
      final russian = await loadL10n(const Locale('ru'));
      await _openPicker(tester, items: const [], locale: const Locale('ru'));

      expect(find.text(russian.selectDialogEmptyState), findsOneWidget);
    });
  });

  group('SingleSelectDialog create action', () {
    testWidgets('is absent unless the caller passes one', (tester) async {
      final l10n = await loadL10n();
      await _openPicker(tester, items: const []);

      expect(
        find.widgetWithText(TextButton, l10n.cancelButton),
        findsOneWidget,
      );
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('runs the callback and dismisses the picker', (tester) async {
      // Both halves matter: the callers open another root-navigator dialog, so
      // a picker left open would sit under it still listing nothing.
      var created = false;

      await _openPicker(
        tester,
        items: const [],
        createAction: SingleSelectCreateAction(
          label: 'Add account',
          onPressed: () => created = true,
        ),
      );

      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();

      expect(created, isTrue);
      expect(find.byType(SingleSelectDialog<String>), findsNothing);
    });
  });
}
