// Every list screen turns its sort icon the same way.
//
// The six list surfaces each draw `Icons.sort` inside a `RotatedBox` whose
// `quarterTurns` says which way the arrow points. Transactions had the
// condition inverted - ascending drew the icon upright where accounts,
// categories, exchange rates, assets and inflation drew it turned over - so
// two screens of one app showed opposite arrows for the same sort order, and
// nothing failed.
//
// A widget test would have to pump six screens with their blocs to catch that,
// and would still only cover the ones it pumped. Reading the source covers
// every `RotatedBox` that exists today and every one added later.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The one accepted spelling, modulo which field the state calls its sort.
///
/// `... ? 2 : 0` with the ascending test on the left: ascending turns the icon
/// over. The check is on the arms rather than the whole expression because the
/// blocs disagree on the field name (`sort == Sort.ascending`, `sortAscending`,
/// `filters.sort == Sort.ascending`) and that difference is not a bug.
final _ascendingTurnsIt = RegExp(r'quarterTurns:\s*(.+?)\s*\?\s*2\s*:\s*0\s*,');
final _anyQuarterTurns = RegExp(r'quarterTurns:\s*(.+?),');

/// The ascending side of the condition, to catch a flip written as
/// `descending ? 2 : 0` - same arms, opposite meaning.
bool _testsForAscending(String condition) =>
    condition.contains('ascending') || condition.contains('Ascending');

void main() {
  test('every sort RotatedBox turns the icon over when ascending', () {
    final offenders = <String>[];
    var found = 0;

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final source = entity.readAsStringSync();
      // The generated localisations are megabytes of strings with no widgets.
      if (entity.path.contains('app_localizations')) continue;

      for (final match in _anyQuarterTurns.allMatches(source)) {
        final line = match.group(0)!;
        final condition = match.group(1)!;
        // A RotatedBox with a constant angle is not a sort arrow.
        if (!_testsForAscending(condition)) continue;
        found++;
        if (!_ascendingTurnsIt.hasMatch(line)) {
          offenders.add('${entity.path}: $line');
        }
      }
    }

    // A floor, so a refactor that renames the field or drops every RotatedBox
    // cannot turn this test into one that silently checks nothing.
    expect(
      found,
      greaterThanOrEqualTo(10),
      reason:
          'found only $found sort rotations; the six list screens draw one '
          'per layout branch, so the scan has stopped seeing them',
    );
    expect(
      offenders,
      isEmpty,
      reason:
          'these rotate the sort icon the opposite way from the rest of '
          'the app: ${offenders.join('\n')}',
    );
  });
}
