// Dates used to come out in English whatever language the app was set to:
// nothing ever loaded intl's locale data, and nothing ever pointed
// `Intl.defaultLocale` at the locale being rendered, so every `DateFormat`
// either fell back to en_US or threw.
//
// The assertion that matters here is that the *same instant* reads differently
// in two locales. Both halves of the fix are needed for that: the symbols have
// to be loaded (`initializeAppDateFormatting`) and the running locale has to be
// published to intl (`IntlLocaleSync`).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';

import 'test_app.dart';

final DateTime _probeDate = DateTime(2026, 8, 12);

/// Renders [_probeDate] with an *unqualified* `DateFormat` - the shape almost
/// every screen in this app uses, and the one that silently formats in
/// `Intl.defaultLocale`.
///
/// Deliberately built without `const` at every use below. A `const` child is
/// canonicalised, so Flutter would skip updating the subtree when only the
/// locale changed and the probe would show a stale date even though
/// `Intl.defaultLocale` had moved on. That is not a case the app can hit - it
/// rebuilds under a locale-derived `ValueKey`, and any widget showing a date
/// also reads `context.l10n` - but it would make this test lie about which
/// half of the fix it is exercising.
class _DateProbe extends StatelessWidget {
  const _DateProbe();

  @override
  Widget build(BuildContext context) => IntlLocaleSync(
    child: Builder(
      builder: (context) => Text(DateFormat.yMMMM().format(_probeDate)),
    ),
  );
}

void main() {
  // `Intl.defaultLocale` is process-global; leaving it set would decide the
  // outcome of whatever test ran next.
  final defaultLocaleBefore = Intl.defaultLocale;
  tearDown(() => Intl.defaultLocale = defaultLocaleBefore);

  group('initializeAppDateFormatting', () {
    // Must stay the first test in this file. `GlobalMaterialLocalizations.load`
    // installs intl's date symbols as a side effect, so any earlier
    // `pumpAppWidget` would leave the table populated and this test would pass
    // with the initialization removed.
    test('loads date symbols for every locale the app ships', () async {
      await initializeAppDateFormatting();

      final rendered = <String, String>{
        for (final locale in AppLocalizations.supportedLocales)
          locale.toString(): DateFormat.yMMMM(
            locale.toString(),
          ).format(_probeDate),
      };

      expect(
        rendered.length,
        AppLocalizations.supportedLocales.length,
        reason: 'every supported locale must be formattable',
      );
      // Not a tautology: before the fix this threw LocaleDataException for
      // everything but English.
      expect(rendered['ru'], isNot(rendered['en']));
      expect(rendered['zh'], isNot(rendered['en']));
      expect(rendered.values.toSet().length, greaterThan(1));
    });
  });

  group('IntlLocaleSync', () {
    testWidgets('an unqualified DateFormat follows the locale being rendered', (
      tester,
    ) async {
      await initializeAppDateFormatting();

      await pumpAppWidget(tester, _DateProbe(), locale: const Locale('en'));
      expect(find.text(DateFormat.yMMMM('en').format(_probeDate)), findsOneWidget);

      await pumpAppWidget(tester, _DateProbe(), locale: const Locale('ru'));
      expect(find.text(DateFormat.yMMMM('ru').format(_probeDate)), findsOneWidget);
      // The whole point: the two renderings differ.
      expect(find.text(DateFormat.yMMMM('en').format(_probeDate)), findsNothing);
      expect(Intl.defaultLocale, 'ru');
    });

    testWidgets('a locale change is picked up without restarting the app', (
      tester,
    ) async {
      await initializeAppDateFormatting();

      // The app's locale is a setting that changes at runtime, so this cannot
      // be settled once in main(): the switch below is the case a one-shot
      // assignment gets wrong.
      final locale = ValueNotifier<Locale>(const Locale('en'));
      addTearDown(locale.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder<Locale>(
          valueListenable: locale,
          builder: (context, value, _) => MaterialApp(
            locale: value,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: _DateProbe(),
          ),
        ),
      );
      expect(find.text(DateFormat.yMMMM('en').format(_probeDate)), findsOneWidget);
      expect(Intl.defaultLocale, 'en');

      locale.value = const Locale('fr');
      await tester.pumpAndSettle();

      expect(find.text(DateFormat.yMMMM('fr').format(_probeDate)), findsOneWidget);
      expect(find.text(DateFormat.yMMMM('en').format(_probeDate)), findsNothing);
      expect(Intl.defaultLocale, 'fr');
    });
  });
}
