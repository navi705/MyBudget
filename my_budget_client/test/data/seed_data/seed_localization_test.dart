// The rows the app writes for the user before the user has written anything.
//
// Categories, styles and account types exist as rows, not as `l10n` lookups,
// because the user owns them the moment the app starts: they rename them,
// delete them and point transactions at them. The first launch is therefore
// the only chance to name them in the user's language, and it was being
// missed - the seeder asked `Intl.systemLocale`, which nothing in this app
// ever initialized, so it read '' and fell back to English for everyone. The
// translations had sat next to the seed data unused since they were written.
//
// These tests pin the three things that has to mean: the tables are complete,
// a locale actually changes the names, and none of it moves the stable IDs
// that sync and the migrations match rows on.
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/data/seed_data/account_types_data.dart';
import 'package:my_budget_client/data/seed_data/categories_data.dart';
import 'package:my_budget_client/data/seed_data/seed_name_translations.dart';
import 'package:my_budget_client/data/seed_data/styles_data.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('seedNameTranslations', () {
    test('covers every locale the app ships', () {
      final shipped = AppLocalizations.supportedLocales
          .map((l) => l.languageCode)
          .toSet();
      expect(
        shipped.difference(seedNameTranslations.keys.toSet()),
        isEmpty,
        reason: 'these locales would seed a database full of English',
      );
    });

    test('covers every name the three seeders ask for, in every locale', () {
      // The English seed lists are the definition of what gets asked for, so
      // a name added to any of them without a translation fails here rather
      // than reaching a user as the one English word among their own.
      final asked =
          <String>{
              ...getDefaultCategories('en').map((c) => c.name.value),
              ...getDefaultStyles('en').map((s) => s.name.value),
              ...getDefaultAccountTypes('en').map((t) => t.name.value),
            }
            // The transfer category is a sentinel the UI never shows - it is how a
            // transfer's two rows are recognised, not a word anyone reads.
            ..remove(AppConstants.systemTransferCategoryName);

      final missing = <String, Set<String>>{};
      for (final entry in seedNameTranslations.entries) {
        final gaps = asked.difference(entry.value.keys.toSet());
        if (gaps.isNotEmpty) missing[entry.key] = gaps;
      }
      expect(missing, isEmpty);
    });

    test('translates - the non-English tables are not English copies', () {
      // 'Steam' and 'YouTube' are brand names and stay put in every locale;
      // everything else should have moved.
      const brands = {'Steam', 'YouTube'};
      for (final code in ['ru', 'ar', 'zh', 'hi']) {
        final untranslated = seedNameTranslations[code]!.entries
            .where((e) => !brands.contains(e.key))
            .where((e) => e.value == seedNameTranslations['en']![e.key])
            .map((e) => e.key)
            .toSet();
        expect(untranslated, isEmpty, reason: '$code left these in English');
      }
    });

    test('falls back to English for a locale it has never heard of', () {
      expect(seedLanguageOf('kl'), 'en');
      expect(seedName('kl', 'Groceries'), 'Groceries');
      // And returns an unknown name unchanged rather than throwing, so a seed
      // row added without a translation still seeds.
      expect(seedName('ru', 'Nonesuch'), 'Nonesuch');
    });
  });

  group('the seed lists in another language', () {
    test('name every category, style and account type in that language', () {
      expect(
        getDefaultCategories('ru').map((c) => c.name.value),
        contains('Продукты'),
      );
      expect(
        getDefaultStyles('ru').map((s) => s.name.value),
        contains('Кредитная карта'),
      );
      expect(
        getDefaultAccountTypes('ru').map((t) => t.name.value),
        contains('Наличные'),
      );
    });

    test('keep the stable IDs the language they were seeded in cannot move', () {
      // Sync matches rows by ID across devices that may be in different
      // languages, and the stable-ID migration matches legacy rows by their
      // English names - so the IDs are the same set whatever the language, and
      // `defaultStyles` / `defaultAccountTypes` stay English for that lookup.
      expect(
        getDefaultCategories('ru').map((c) => c.id.value).toList(),
        getDefaultCategories('en').map((c) => c.id.value).toList(),
      );
      expect(
        getDefaultStyles('zh').map((s) => s.id.value).toList(),
        defaultStyles.map((s) => s.id.value).toList(),
      );
      expect(
        defaultAccountTypes.map((t) => t.name.value),
        containsAll(<String>['Checking', 'Cash']),
      );
    });

    test('leave the account type language column pointing at a seeded '
        'language row', () {
      // `AccountTypes.languageCode` is a foreign key into Languages, which
      // seeds English alone; tagging the row with the display language would
      // fail the insert with SqliteException(787).
      for (final type in getDefaultAccountTypes('ar')) {
        expect(type.languageCode.value, 'en');
      }
    });
  });

  group('a database created on a Russian device', () {
    late AppDatabase db;

    setUpAll(() async {
      binding.platformDispatcher.localeTestValue = const Locale('ru');
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
    });

    tearDownAll(() async {
      await db.close();
      binding.platformDispatcher.clearLocaleTestValue();
    });

    test('seeds Russian categories, styles and account types', () async {
      final categories = await db.select(db.categories).get();
      final styles = await db.select(db.styles).get();
      final accountTypes = await db.select(db.accountTypes).get();

      expect(categories.map((c) => c.name), contains('Продукты'));
      expect(styles.map((s) => s.name), contains('Кредитная карта'));
      expect(accountTypes.map((t) => t.name), contains('Наличные'));
    });

    test('still writes the stable IDs, so a peer in another language matches '
        'the same rows', () async {
      final ids = (await db.select(db.categories).get())
          .map((c) => c.id)
          .toSet();
      expect(ids, containsAll(<String>['cat_salary', 'cat_groceries']));
    });
  });
}
