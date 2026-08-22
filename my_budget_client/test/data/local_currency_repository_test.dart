import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/repositories/local_db/local_currency_repository.dart';
// `Currency` is both a drift row class and a domain entity, so the domain side
// has to be prefixed.
import 'package:my_budget_client/domain/entities/currency.dart' as domain;
import 'package:my_budget_client/domain/entities/currency_designation.dart'
    as domain;
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

/// Currencies, their designations and the exchange-rate table all live behind
/// this one repository. Pinned here: round-trips, the composite `sync_log`
/// record id used for rates, the designation soft-delete filter, and the
/// write paths that currently do no sync bookkeeping at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalCurrencyRepository repo;

  setUpAll(() async {
    // Opening the database seeds a few hundred thousand exchange rates, and
    // every rate write below builds its composite sync id with a
    // locale-pinned DateFormat. Load its CLDR data before either happens.
    await initializeDateFormatting();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = LocalCurrencyRepository(db);
    // Seeding inserts a few hundred thousand historical rates. They are not
    // what these tests are about and they make every assertion on the rate
    // table unreadable, so drop them once for this file.
    await db.delete(db.exchangeRates).go();
  });

  tearDownAll(() async => db.close());

  setUp(() async {
    await db.delete(db.exchangeRates).go();
    await (db.delete(
      db.currencies,
    )..where((c) => c.code.isIn(['ZZ1', 'ZZ2']))).go();
    await (db.delete(
      db.currencyDesignations,
    )..where((d) => d.id.isIn(['test-eur', 'test-usd']))).go();
    await db.delete(db.syncLog).go();
  });

  Future<List<SyncLogData>> logsFor(String table) => (db.select(
    db.syncLog,
  )..where((l) => l.changedTableName.equals(table))).get();

  Future<Currency> currencyRow(String code) =>
      (db.select(db.currencies)..where((c) => c.code.equals(code))).getSingle();

  const zz1 = domain.Currency(
    name: 'Zeta',
    code: 'ZZ1',
    languageCode: 'en',
    type: domain.TypeCurrency.crypto,
  );
  const zz2 = domain.Currency(
    name: 'Zeta Two',
    code: 'ZZ2',
    languageCode: 'en',
    type: domain.TypeCurrency.currency,
  );

  ExchangeRateDomain rate({
    String from = 'ZZ1',
    String to = 'ZZ2',
    int preset = 91,
    double value = 1.5,
    DateTime? date,
  }) => ExchangeRateDomain(
    fromCurrencyCode: from,
    toCurrencyCode: to,
    preset: preset,
    rate: value,
    date: date ?? DateTime(2024, 5, 5),
  );

  group('currencies', () {
    test('addCurrency round-trips name, code, language and type', () async {
      await repo.addCurrency(zz1);

      final read = await repo.getCurrencyByCode('ZZ1');
      expect(read!.name, 'Zeta');
      expect(read.code, 'ZZ1');
      expect(read.languageCode, 'en');
      // The type is what decides whether amounts in this currency are exact
      // minor units or a raw double, so it must survive the round-trip.
      expect(read.type, domain.TypeCurrency.crypto);
    });

    test(
      'getCurrencyByCode returns null for a code that is not stored',
      () async {
        expect(await repo.getCurrencyByCode('ZZ9'), isNull);
      },
    );

    test(
      'addCurrency stamps modifiedAt and logs an upsert under currencies',
      () async {
        final before = DateTime.now().millisecondsSinceEpoch;

        await repo.addCurrency(zz1);

        // Without a fresh modifiedAt the row sorts as never-modified and no peer
        // ever pulls it.
        expect(
          (await currencyRow('ZZ1')).modifiedAt,
          greaterThanOrEqualTo(before),
        );
        expect(
          (await logsFor('currencies')).map((l) => '${l.recordId}:${l.action}'),
          ['ZZ1:upsert'],
        );
      },
    );

    test(
      'a new currency shows up in getCurrencies and watchCurrencies',
      () async {
        await repo.addCurrency(zz1);

        expect(
          (await repo.getCurrencies()).map((c) => c.code),
          contains('ZZ1'),
        );
        expect(
          (await repo.watchCurrencies().first).map((c) => c.code),
          contains('ZZ1'),
        );
      },
    );

    // BUG (characterisation): CurrenciesDao.insertAllCurrencies
    // (lib/core/database/app_database.dart:631-639) is a bare batch insert: no
    // modifiedAt, no sync_log. Compare insertCurrency (621-629), which does
    // both and explains in a comment why it has to.
    // CORRECT behaviour: bulk-inserted currencies need the same fresh
    // modifiedAt and one 'upsert' row each. As written, currencies created by a
    // CSV import (the bulk path) have modifiedAt 0 and are never announced, so
    // they exist only on the importing device — and every account in one of
    // those currencies fails its foreign key on the peer.
    test(
      'addCurrencies leaves modifiedAt at 0 and writes no sync_log row '
      '(WRONG - both are required for the row to reach another device)',
      () async {
        await repo.addCurrencies([zz1, zz2]);

        expect((await currencyRow('ZZ1')).modifiedAt, 0);
        expect(await logsFor('currencies'), isEmpty);
      },
    );

    test('addCurrencies does store the rows themselves', () async {
      await repo.addCurrencies([zz1, zz2]);

      expect((await repo.getCurrencyByCode('ZZ1'))!.name, 'Zeta');
      expect((await repo.getCurrencyByCode('ZZ2'))!.name, 'Zeta Two');
    });

    test('updateCurrency persists the new name', () async {
      await repo.addCurrency(zz1);

      await repo.updateCurrency(zz1.copyWith(name: 'Zeta Renamed'));

      expect((await repo.getCurrencyByCode('ZZ1'))!.name, 'Zeta Renamed');
    });

    // Was a characterised bug: CurrenciesDao.updateCurrency was a bare
    // `update(currencies).replace(currency)`. The companion built by
    // CurrencyCompanionMapper (lib/core/mappers/currency_mapper.dart:18-25)
    // carries no modifiedAt, and drift's `replace` writes the column default
    // for every column the companion omits, so the stored modifiedAt was
    // overwritten with 0 - the rename then looked older than every remote copy,
    // last-write-wins threw it away and the old name came back on the next
    // sync. It now stamps `DateTime.now().millisecondsSinceEpoch` the way
    // insertCurrency does, and writes only the fields the caller set.
    test(
      'updateCurrency bumps modifiedAt so the rename wins the next sync',
      () async {
        await repo.addCurrency(zz1);
        final before = (await currencyRow('ZZ1')).modifiedAt;
        expect(before, greaterThan(0));
        await Future<void>.delayed(const Duration(milliseconds: 5));

        await repo.updateCurrency(zz1.copyWith(name: 'Zeta Renamed'));

        expect((await currencyRow('ZZ1')).modifiedAt, greaterThan(before));
      },
    );

    // BUG (characterisation): the same one-liner writes no sync_log row,
    // although CurrenciesDao has a fully written `_logChange`
    // (app_database.dart:646-656) that only insertCurrency calls.
    // CORRECT behaviour: log an 'upsert'. As written the rename never leaves
    // the device.
    test(
      'updateCurrency writes no sync_log row (WRONG - it should log an upsert)',
      () async {
        await repo.addCurrency(zz1);
        await db.delete(db.syncLog).go();

        await repo.updateCurrency(zz1.copyWith(name: 'Zeta Renamed'));

        expect(await logsFor('currencies'), isEmpty);
      },
    );

    test('deleteCurrency removes the row', () async {
      await repo.addCurrency(zz1);

      await repo.deleteCurrency(zz1);

      expect(await repo.getCurrencyByCode('ZZ1'), isNull);
    });

    // BUG (characterisation): CurrenciesDao.deleteCurrency
    // (lib/core/database/app_database.dart:643-644) is a bare
    // `delete(currencies).delete(currency)` — a hard delete with no sync_log
    // row.
    // CORRECT behaviour: log a 'delete' so peers drop it too. As written, a
    // currency the user deleted reappears on the next sync from any other
    // device, because nothing ever told that device it was removed.
    test('deleteCurrency writes no sync_log row '
        '(WRONG - the delete never reaches another device)', () async {
      await repo.addCurrency(zz1);
      await db.delete(db.syncLog).go();

      await repo.deleteCurrency(zz1);

      expect(await logsFor('currencies'), isEmpty);
    });
  });

  group('currency designations', () {
    setUp(() async {
      await repo.addCurrencyDesignation(
        const domain.CurrencyDesignation(
          id: 'test-eur',
          value: 'E1',
          currencyCode: 'EUR',
        ),
      );
      await repo.addCurrencyDesignation(
        const domain.CurrencyDesignation(
          id: 'test-usd',
          value: 'U1',
          currencyCode: 'USD',
        ),
      );
    });

    test('addCurrencyDesignation round-trips and logs an upsert', () async {
      final read = await repo.getCurrencyDesignationById('test-eur');
      expect(read!.value, 'E1');
      expect(read.currencyCode, 'EUR');
      expect(
        (await logsFor('currency_designations')).map((l) => l.recordId),
        containsAll(['test-eur', 'test-usd']),
      );
    });

    test(
      'getCurrencyDesignationsForCurrency returns only that currency',
      () async {
        final found = await repo.getCurrencyDesignationsForCurrency('USD');

        expect(found.map((d) => d.id), contains('test-usd'));
        expect(found.every((d) => d.currencyCode == 'USD'), isTrue);
      },
    );

    test('watchCurrencyDesignationsForCurrency filters the same way', () async {
      final emitted = await repo
          .watchCurrencyDesignationsForCurrency('USD')
          .first;

      expect(emitted.every((d) => d.currencyCode == 'USD'), isTrue);
      expect(emitted.map((d) => d.id), contains('test-usd'));
    });

    test('a soft-deleted designation is not returned by id', () async {
      await db.currencyDesignationsDao.deleteDesignation(
        const CurrencyDesignationsCompanion(id: Value('test-eur')),
      );

      expect(await repo.getCurrencyDesignationById('test-eur'), isNull);
    });

    test(
      'a soft-deleted designation is not returned by the list reads',
      () async {
        await db.currencyDesignationsDao.deleteDesignation(
          const CurrencyDesignationsCompanion(id: Value('test-eur')),
        );

        expect(
          (await repo.getAllCurrencyDesignations()).map((d) => d.id),
          isNot(contains('test-eur')),
        );
        expect(
          (await repo.getCurrencyDesignationsForCurrency(
            'EUR',
          )).map((d) => d.id),
          isNot(contains('test-eur')),
        );
        expect(
          (await repo.watchAllCurrencyDesignations().first).map((d) => d.id),
          isNot(contains('test-eur')),
        );
      },
    );
  });

  group('exchange rates', () {
    setUp(() async {
      // exchange_rates.from/to_currency_code are foreign keys.
      await repo.addCurrency(zz1);
      await repo.addCurrency(zz2);
      await db.delete(db.syncLog).go();
    });

    test('addExchangeRate round-trips every field', () async {
      await repo.addExchangeRate(
        rate(value: 1.2345, date: DateTime(2024, 5, 5)),
      );

      final read = (await repo.getExchangeRatesFiltered(presets: [91])).single;
      expect(read.fromCurrencyCode, 'ZZ1');
      expect(read.toCurrencyCode, 'ZZ2');
      expect(read.rate, 1.2345);
      expect(read.preset, 91);
      expect(read.date, DateTime(2024, 5, 5));
    });

    test(
      'addExchangeRate logs an upsert keyed by from_to_date_preset',
      () async {
        await repo.addExchangeRate(rate(date: DateTime(2024, 5, 5)));

        // The rate table has a composite primary key and no id column, so this
        // synthesised record id is the only handle a peer has on the row.
        expect(
          (await logsFor(
            'exchange_rates',
          )).map((l) => '${l.recordId}:${l.action}'),
          ['ZZ1_ZZ2_2024-05-05_91:upsert'],
        );
      },
    );

    test('re-adding the same from/to/date/preset replaces instead of '
        'duplicating', () async {
      await repo.addExchangeRate(rate(value: 1.5));
      await repo.addExchangeRate(rate(value: 2.5));

      final rows = await repo.getExchangeRatesFiltered(presets: [91]);
      expect(rows.length, 1);
      expect(rows.single.rate, 2.5);
    });

    test(
      'addExchangeRates inserts every rate with a fresh modifiedAt',
      () async {
        final before = DateTime.now().millisecondsSinceEpoch;

        await repo.addExchangeRates([
          rate(date: DateTime(2024, 5, 5)),
          rate(date: DateTime(2024, 5, 6)),
        ]);

        final rows = await db.select(db.exchangeRates).get();
        expect(rows.length, 2);
        expect(rows.every((r) => r.modifiedAt >= before), isTrue);
      },
    );

    test('addExchangeRates deliberately writes no sync_log rows', () async {
      // This is the bulk provider/seed path. ExchangeRatesDao
      // .insertAllExchangeRates documents why it stays out of sync_log: the
      // file-sync engine has no exchangeRates case, so every queued row would
      // be fetched and dropped, and each device pulls the same rates from the
      // same provider anyway. Pinned so the single-rate paths above (which DO
      // log) are not "fixed" by copying this one, or vice versa.
      await repo.addExchangeRates([rate(date: DateTime(2024, 5, 5))]);

      expect(await logsFor('exchange_rates'), isEmpty);
    });

    test(
      'updateExchangeRate changes the rate, bumps modifiedAt and logs',
      () async {
        await repo.addExchangeRate(rate(value: 1.5));
        final before = (await db.select(db.exchangeRates).get()).single;
        await db.delete(db.syncLog).go();
        await Future<void>.delayed(const Duration(milliseconds: 5));

        await repo.updateExchangeRate(rate(value: 9.5));

        final after = (await db.select(db.exchangeRates).get()).single;
        expect(after.rate, 9.5);
        expect(after.modifiedAt, greaterThan(before.modifiedAt));
        expect((await logsFor('exchange_rates')).map((l) => l.action), [
          'upsert',
        ]);
      },
    );

    test('replaceExchangeRate moves the row to its new key without leaving '
        'the old one behind', () async {
      final original = rate(date: DateTime(2024, 5, 5), value: 1.5);
      await repo.addExchangeRate(original);
      await db.delete(db.syncLog).go();

      await repo.replaceExchangeRate(
        original,
        original.copyWith(date: DateTime(2024, 5, 7), rate: 1.9),
      );

      final rows = await repo.getExchangeRatesFiltered(presets: [91]);
      // Editing a key field must not leave an orphan copy under the old key.
      expect(rows.length, 1);
      expect(rows.single.date, DateTime(2024, 5, 7));
      expect(rows.single.rate, 1.9);
    });

    test('replaceExchangeRate logs a delete for the old key and an upsert for '
        'the new one', () async {
      final original = rate(date: DateTime(2024, 5, 5));
      await repo.addExchangeRate(original);
      await db.delete(db.syncLog).go();

      await repo.replaceExchangeRate(
        original,
        original.copyWith(date: DateTime(2024, 5, 7)),
      );

      expect(
        (await logsFor(
          'exchange_rates',
        )).map((l) => '${l.recordId}:${l.action}'),
        containsAll([
          'ZZ1_ZZ2_2024-05-05_91:delete',
          'ZZ1_ZZ2_2024-05-07_91:upsert',
        ]),
      );
    });

    test(
      'replaceExchangeRate logs only an upsert when the key is unchanged',
      () async {
        final original = rate(date: DateTime(2024, 5, 5), value: 1.5);
        await repo.addExchangeRate(original);
        await db.delete(db.syncLog).go();

        await repo.replaceExchangeRate(original, original.copyWith(rate: 3.0));

        // A spurious delete for the same key would race the upsert on the peer.
        expect(
          (await logsFor(
            'exchange_rates',
          )).map((l) => '${l.recordId}:${l.action}'),
          ['ZZ1_ZZ2_2024-05-05_91:upsert'],
        );
      },
    );

    test(
      'getLatestExchangeRates picks the newest row on or before the date',
      () async {
        await repo.addExchangeRates([
          rate(date: DateTime(2024, 1, 1), value: 1.0),
          rate(date: DateTime(2024, 3, 1), value: 2.0),
          rate(date: DateTime(2024, 9, 1), value: 3.0),
        ]);

        final latest = await repo.getLatestExchangeRates(DateTime(2024, 6, 1));
        final mine = latest.where((r) => r.fromCurrencyCode == 'ZZ1');

        // A rate dated after the requested day must not be used to value the
        // past.
        expect(mine.map((r) => r.rate), [2.0]);
      },
    );

    test('getLatestExchangeRatesByList returns every row stored on those '
        'days, whatever time of day it carries', () async {
      await repo.addExchangeRates([
        rate(date: DateTime(2024, 1, 1), value: 1.0),
        rate(date: DateTime(2024, 3, 1), value: 2.0),
        // What an API refresh actually writes: the day asked for, stamped with
        // the wall clock of the moment it was fetched. Matching the requested
        // midnight for equality found none of these, so every pair whose rows
        // all came from a refresh was invisible and its amounts dropped out of
        // the totals.
        rate(date: DateTime(2024, 3, 1, 9, 59, 53), value: 2.5),
        rate(date: DateTime(2024, 3, 1, 23, 59, 59), value: 2.75),
        // The first instant of the next day belongs to the next day.
        rate(date: DateTime(2024, 3, 2), value: 9.0),
      ]);

      final found = await repo.getLatestExchangeRatesByList([
        DateTime(2024, 3, 1),
      ]);

      expect(found.map((r) => r.rate).toList()..sort(), [2.0, 2.5, 2.75]);
    });

    test(
      'getLatestExchangeRatesByList survives a year of scattered days',
      () async {
        // The dashboard asks for one day per day a transaction exists on, so a
        // real budget passes hundreds. OR-ing them into a left-deep chain made
        // SQLite give up on the whole statement — "parser stack overflow" — and
        // the caller saw an empty rate set, which is what put "ETH, RSD, USD,
        // USDT could not be converted" on screen while the rows sat in the table.
        final days = [
          // Every other day, so nothing collapses into a contiguous range.
          for (var i = 0; i < 400; i++)
            DateTime(2024, 1, 1).add(Duration(days: i * 2)),
        ];
        await repo.addExchangeRates([
          for (final day in days) rate(date: day, value: 1.0),
          // A day nobody asked for.
          rate(date: DateTime(2024, 1, 2), value: 99.0),
        ]);

        final found = await repo.getLatestExchangeRatesByList(days);

        expect(found, hasLength(days.length));
        expect(found.map((r) => r.rate), everyElement(1.0));
      },
    );

    test('getLatestExchangeRatesByList keeps consecutive days apart from the '
        'day after them', () async {
      // Consecutive days are merged into one range before they reach SQL; the
      // merge must not swallow the day past the end of the run.
      await repo.addExchangeRates([
        rate(date: DateTime(2024, 4, 1), value: 1.0),
        rate(date: DateTime(2024, 4, 2), value: 2.0),
        rate(date: DateTime(2024, 4, 3), value: 3.0),
        rate(date: DateTime(2024, 4, 4), value: 4.0),
      ]);

      final found = await repo.getLatestExchangeRatesByList([
        DateTime(2024, 4, 1),
        DateTime(2024, 4, 2),
        DateTime(2024, 4, 3),
      ]);

      expect(found.map((r) => r.rate).toList()..sort(), [1.0, 2.0, 3.0]);
    });

    test('getLatestExchangeRatesAll returns every stored rate', () async {
      await repo.addExchangeRates([
        rate(date: DateTime(2024, 1, 1)),
        rate(date: DateTime(2024, 3, 1)),
      ]);

      expect((await repo.getLatestExchangeRatesAll()).length, 2);
    });

    group('getExchangeRatesFiltered', () {
      setUp(() async {
        await repo.addExchangeRates([
          rate(date: DateTime(2024, 1, 1), value: 1.0),
          rate(date: DateTime(2024, 2, 1), value: 2.0),
          rate(date: DateTime(2024, 3, 1), value: 3.0, preset: 92),
          rate(from: 'ZZ2', to: 'ZZ1', date: DateTime(2024, 4, 1), value: 4.0),
        ]);
      });

      test('returns newest first by default', () async {
        final rows = await repo.getExchangeRatesFiltered();
        expect(rows.map((r) => r.rate), [4.0, 3.0, 2.0, 1.0]);
      });

      test('sortAscending flips the date ordering', () async {
        final rows = await repo.getExchangeRatesFiltered(sortAscending: true);
        expect(rows.map((r) => r.rate), [1.0, 2.0, 3.0, 4.0]);
      });

      test('honours limit and offset', () async {
        expect(
          (await repo.getExchangeRatesFiltered(limit: 2)).map((r) => r.rate),
          [4.0, 3.0],
        );
        expect(
          (await repo.getExchangeRatesFiltered(
            limit: 2,
            offset: 2,
          )).map((r) => r.rate),
          [2.0, 1.0],
        );
      });

      test('the date range is inclusive on both ends', () async {
        final rows = await repo.getExchangeRatesFiltered(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 2, 1),
          sortAscending: true,
        );

        expect(rows.map((r) => r.rate), [1.0, 2.0]);
      });

      test('fromCurrency and toCurrency are matched exactly', () async {
        final rows = await repo.getExchangeRatesFiltered(
          fromCurrency: 'ZZ2',
          toCurrency: 'ZZ1',
        );

        expect(rows.map((r) => r.rate), [4.0]);
      });

      test('presets restricts to the listed presets', () async {
        final rows = await repo.getExchangeRatesFiltered(presets: [92]);
        expect(rows.map((r) => r.rate), [3.0]);
      });

      test('an empty preset list means no preset filter', () async {
        expect((await repo.getExchangeRatesFiltered(presets: [])).length, 4);
      });

      test('getExchangeRatesCount ignores the page size', () async {
        expect((await repo.getExchangeRatesFiltered(limit: 1)).length, 1);
        expect(await repo.getExchangeRatesCount(), 4);
      });

      test(
        'getExchangeRatesCount applies the same filters as the read',
        () async {
          expect(await repo.getExchangeRatesCount(presets: [92]), 1);
          expect(await repo.getExchangeRatesCount(fromCurrency: 'ZZ2'), 1);
        },
      );

      test(
        'getAvailablePresets lists each stored preset once, ascending',
        () async {
          expect(await repo.getAvailablePresets(), [91, 92]);
        },
      );
    });

    test(
      'updateExchangeRatePresets moves the rows to the new preset',
      () async {
        final r = rate(date: DateTime(2024, 5, 5), value: 1.5);
        await repo.addExchangeRate(r);

        await repo.updateExchangeRatePresets([r], 93);

        expect(await repo.getExchangeRatesFiltered(presets: [91]), isEmpty);
        final moved = (await repo.getExchangeRatesFiltered(
          presets: [93],
        )).single;
        expect(moved.rate, 1.5);
        expect(moved.date, DateTime(2024, 5, 5));
      },
    );

    // BUG (characterisation): ExchangeRatesDao.updateExchangeRatePresets
    // (lib/core/database/app_database.dart:2488-2518) deletes each row under
    // its old composite key and re-inserts it under the new preset, but writes
    // no sync_log row for either half, although the DAO has both `_logChange`
    // and `_logChanges` and every other write path here uses them.
    // CORRECT behaviour: a 'delete' for `from_to_date_oldPreset` and an
    // 'upsert' for `from_to_date_newPreset`, the way replaceExchangeRate does
    // it at line 2437-2440. As written, re-presetting rates does nothing on any
    // other device: the peer still has them under the old preset, so the two
    // devices show different rate sets for the same preset forever.
    test(
      'updateExchangeRatePresets writes no sync_log row at all '
      '(WRONG - it should log the old key deleted and the new key upserted)',
      () async {
        final r = rate(date: DateTime(2024, 5, 5));
        await repo.addExchangeRate(r);
        await db.delete(db.syncLog).go();

        await repo.updateExchangeRatePresets([r], 93);

        expect(await logsFor('exchange_rates'), isEmpty);
      },
    );

    test('deleteExchangeRates removes exactly the rows it was given', () async {
      final keep = rate(date: DateTime(2024, 5, 5));
      final drop = rate(date: DateTime(2024, 5, 6));
      await repo.addExchangeRates([keep, drop]);

      await repo.deleteExchangeRates([drop]);

      final rows = await repo.getExchangeRatesFiltered(presets: [91]);
      expect(rows.map((r) => r.date), [DateTime(2024, 5, 5)]);
    });

    // BUG (characterisation): ExchangeRatesDao.deleteExchangeRates
    // (lib/core/database/app_database.dart:2472-2486) is a bare batch delete
    // with no sync_log rows.
    // CORRECT behaviour: one 'delete' row per rate, keyed
    // `from_to_date_preset`. As written, rates the user deleted are restored by
    // the next sync from any device that still has them, so the delete looks
    // like it silently failed.
    test('deleteExchangeRates writes no sync_log row '
        '(WRONG - deleted rates come back on the next sync)', () async {
      final r = rate(date: DateTime(2024, 5, 5));
      await repo.addExchangeRate(r);
      await db.delete(db.syncLog).go();

      await repo.deleteExchangeRates([r]);

      expect(await logsFor('exchange_rates'), isEmpty);
    });

    test('watchExchangeRateChanges fires when a rate is written', () async {
      final signal = repo.watchExchangeRateChanges().first;

      await repo.addExchangeRate(rate());

      // The converter cache is invalidated off this signal; without it a newly
      // imported rate does not take effect until the app restarts.
      await expectLater(signal, completes);
    });
  });
}
