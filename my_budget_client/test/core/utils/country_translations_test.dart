// The country name tables, checked as tables rather than country by country.
//
// `getLocalizedCountryName` looks a 3-letter code up in the map for the user's
// language and returns the raw code when it misses. A miss is therefore
// silent: the Urdu reader saw "PHL" where every other country was spelled out,
// and the cause was a leading space in the key - `' PHL'` - which no amount of
// reading the Urdu names would reveal.
//
// A per-language key-set comparison catches that whole class at once: a typo'd
// key, a country translated in one language and forgotten in another, a copy
// that dropped a line.
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/country_codes.dart';
import 'package:my_budget_client/core/utils/country_translations.dart';

void main() {
  group('countryTranslations', () {
    test('has no key with stray whitespace', () {
      final bad = <String, List<String>>{};
      for (final entry in countryTranslations.entries) {
        final keys = entry.value.keys.where((k) => k != k.trim()).toList();
        if (keys.isNotEmpty) bad[entry.key] = keys;
      }
      expect(
        bad,
        isEmpty,
        reason: 'these keys can never be hit, so the code is shown instead',
      );
    });

    test('keys every country the same way in every language', () {
      final english = countryTranslations['en']!.keys.toSet();
      for (final entry in countryTranslations.entries) {
        expect(
          entry.value.keys.toSet(),
          english,
          reason: '${entry.key} does not cover the same countries as en',
        );
      }
    });

    test('spells out the two countries the stray keys hid', () {
      // Philippines and Timor-Leste, the two that carried ' PHL' and ' TLS'.
      expect(getLocalizedCountryName('PHL', 'ur'), isNot('PHL'));
      expect(getLocalizedCountryName('TLS', 'ur'), isNot('TLS'));
    });

    test('falls back to English for a language it does not carry, and to the '
        'code itself for a country no language carries', () {
      expect(
        getLocalizedCountryName('PHL', 'kl'),
        countryTranslations['en']!['PHL'],
      );
      expect(getLocalizedCountryName('ZZZ', 'ru'), 'ZZZ');
    });
  });
}
