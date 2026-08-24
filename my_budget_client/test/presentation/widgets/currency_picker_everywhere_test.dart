// One list of currencies, in one order, wherever the app asks about them.
//
// The pickers put starred codes at the top and the ones already in use next,
// because a flat alphabetical run of 341 currencies puts the two or three a
// person works in behind a scroll or a search. Two screens kept asking the
// same question with the generic multi-select instead - the transactions
// filter and the assets filter - so the same currency sat at the top of one
// list and ninety rows down another, and the star put on it in one place was
// nowhere to be seen in the other.
//
// This reads the source rather than the screen: the two dialogs it guards need
// most of the app's blocs to open, and what went wrong is a choice made at the
// call site, which is what this can see.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every Dart file under `lib/presentation`, which is where currencies are
/// offered to the user.
Iterable<File> _presentationSources() sync* {
  final root = Directory('lib/presentation');
  expect(
    root.existsSync(),
    isTrue,
    reason: 'run from the package root: ${Directory.current.path}',
  );
  for (final entity in root.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) yield entity;
  }
}

void main() {
  test('no screen offers currencies through the generic multi-select', () {
    final offenders = <String>[];
    for (final file in _presentationSources()) {
      if (file.readAsStringSync().contains('MultiSelectDialog<Currency')) {
        offenders.add(file.path);
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'these ask about currencies with the generic list, which has no '
          'stars and no usage order: use CurrencySelectionDialog for several '
          'currencies, or showCurrencyPicker for one',
    );
  });

  test('the shared pickers are the only currency lists', () {
    // A cheap check that the two dialogs above still exist under the names the
    // guard above points people at.
    expect(
      File(
        'lib/presentation/widgets/currency_selection_dialog.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File('lib/presentation/widgets/currency_picker_dialog.dart').existsSync(),
      isTrue,
    );
  });
}
