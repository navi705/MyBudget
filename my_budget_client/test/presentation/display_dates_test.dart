// Dates the user reads, as opposed to the ones the sync layer writes.
//
// The counterpart to test/core/machine_date_locale_test.dart: that file pins
// the dates that must stay ASCII whatever the language, this one pins the
// dates that must follow it. Both failures look the same from the outside -
// someone typed a pattern into a `DateFormat` - and both were present: the
// dashboard chart's axis read `08/22` for every user on earth, and the date
// buttons on the API, exchange rate, asset and inflation screens were fixed to
// `yyyy-MM-dd`, `dd.MM.yyyy`, `dd MMM yyyy` and `MMMM yyyy` respectively.
//
// A locale is not a preference about punctuation. `ar` and `bn` write dates in
// their own digits, `ru` puts the day first, `zh` the year - a hardcoded
// pattern is simply the wrong date for most of the people the app ships to.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/date_display.dart';

/// Renders [build] under [locale] and returns what it printed.
Future<String> _render(
  WidgetTester tester,
  Locale locale,
  String Function(BuildContext context) build,
) async {
  late String output;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: [locale],
      home: Builder(
        builder: (context) {
          output = build(context);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return output;
}

void main() {
  setUpAll(DateDisplay.ensureInitialized);

  final date = DateTime(2026, 8, 22);

  group('DateDisplay', () {
    testWidgets('renders the day-and-month axis label in the reader\'s '
        'locale', (tester) async {
      final en = await _render(
        tester,
        const Locale('en'),
        (c) => DateDisplay.dayMonth(c, date),
      );
      final ru = await _render(
        tester,
        const Locale('ru'),
        (c) => DateDisplay.dayMonth(c, date),
      );
      final bn = await _render(
        tester,
        const Locale('bn'),
        (c) => DateDisplay.dayMonth(c, date),
      );

      expect(en, '8/22');
      // Day first, and separated the way Russian writes it.
      expect(ru, '22.08');
      // Bengali carries its own digits; ASCII here means the label never
      // reached intl's locale data.
      expect(bn, isNot(matches(RegExp(r'^[0-9/.]+$'))));
    });

    testWidgets('spells the month out in the reader\'s language for the '
        'medium format', (tester) async {
      final en = await _render(
        tester,
        const Locale('en'),
        (c) => DateDisplay.medium(c, date),
      );
      final ru = await _render(
        tester,
        const Locale('ru'),
        (c) => DateDisplay.medium(c, date),
      );

      expect(en, contains('Aug'));
      expect(ru, contains('авг'));
    });
  });

  test('no widget formats a date with a pattern of its own', () {
    // The rule this enforces: anything under lib/presentation/ that a user
    // reads goes through DateDisplay, which takes the locale from the widget
    // tree. `DateFormat` there is either a hardcoded pattern or an unqualified
    // one that silently follows Intl.defaultLocale - both were bugs here.
    final offenders = <String>[];
    final dir = Directory('lib/presentation');
    for (final file in dir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        // `DateFormat.yMd(locale)` and friends are the named constructors and
        // take their locale explicitly; only the pattern constructor is the
        // problem.
        if (RegExp(r'\bDateFormat\(').hasMatch(lines[i])) {
          offenders.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: 'use DateDisplay (lib/core/utils/date_display.dart) instead',
    );
  });
}
