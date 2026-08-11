import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/data/seed_data/currencies_data.dart';
import 'package:my_budget_client/data/seed_data/currency_designations_data.dart';

/// Guards the seed data against a class of bug that is invisible in the Dart
/// list and only detonates in SQLite: `currencies.name` is UNIQUE (Currencies,
/// lib/core/database/app_database.dart ~line 68) and
/// `CurrenciesDao.insertAllCurrencies` inserts with
/// `InsertMode.insertOrReplace`. Two seed rows sharing a name therefore do not
/// produce two rows - the later one REPLACEs the earlier one, silently
/// deleting a currency that `defaultCurrencyDesignations` then references,
/// and the seeding blows up with SqliteException(787) on any code path where
/// foreign keys are enforced (a real v1-origin upgrade).
///
/// Twelve name collisions existed when these tests were written (ANG/NLG both
/// 'Dutch Guilder', plus eleven old/new redenomination pairs such as BYR/BYN
/// and VEB/VEF/VES); the first three tests below all fail on that data.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('defaultCurrencies (pure data, no database)', () {
    test('no two currencies share a name', () {
      final byName = <String, List<String>>{};
      for (final c in defaultCurrencies) {
        byName.putIfAbsent(c.name.value, () => []).add(c.code.value);
      }
      final collisions = Map.fromEntries(
        byName.entries.where((e) => e.value.length > 1),
      );
      expect(
        collisions,
        isEmpty,
        reason:
            'each of these names maps to several codes; insertOrReplace keeps '
            'only the last, so the other codes never make it into the table',
      );
    });

    test('no two currencies share a code', () {
      final codes = defaultCurrencies.map((c) => c.code.value).toList();
      expect(codes.length, codes.toSet().length);
    });

    test(
      'every designation points at a currency that is actually seeded '
      '(the FK that SqliteException(787) was complaining about)',
      () {
        final seededCodes = defaultCurrencies
            .map((c) => c.code.value)
            .toSet();
        final dangling = defaultCurrencyDesignations
            .map((d) => d.currencyCode.value)
            .where((code) => !seededCodes.contains(code))
            .toSet();
        expect(dangling, isEmpty);
      },
    );
  });

  group('a freshly seeded database', () {
    late AppDatabase db;

    setUpAll(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get();
    });

    tearDownAll(() async {
      await db.close();
    });

    test('holds one row per seeded currency code', () async {
      final rows = await db.select(db.currencies).get();
      expect(rows.length, defaultCurrencies.length);
    });

    test(
      'keeps ANG and NLG as separate currencies: ANG is the Netherlands '
      'Antillean guilder, NLG the Dutch guilder proper',
      () async {
        final ang = await db.currenciesDao.getCurrencyByCode('ANG');
        final nlg = await db.currenciesDao.getCurrencyByCode('NLG');
        // ANG is the row that used to vanish, replaced by NLG's identical name.
        expect(ang, isNotNull);
        expect(nlg, isNotNull);
        expect(ang!.name, 'Netherlands Antillean Guilder');
        expect(nlg!.name, 'Dutch Guilder');
      },
    );

    test(
      'has no currency_designations row pointing at a missing currency - '
      'this is the check a v1-origin upgrade performs for real, and it is '
      'what threw SqliteException(787)',
      () async {
        // Scoped to currency_designations on purpose: a bare
        // `PRAGMA foreign_key_check` also flags thousands of seeded
        // exchange_rates rows quoting currency codes that
        // `defaultCurrencies` has never contained (BYB, CSD, ...). That is a
        // separate, older seed-data gap in exchange_rates_data.dart, not the
        // duplicate-name bug under test here.
        final violations = await db
            .customSelect('PRAGMA foreign_key_check(currency_designations)')
            .get();
        expect(violations.map((r) => r.data), isEmpty);
      },
    );
  });
}
