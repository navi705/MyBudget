// The exchange-rate JSON importer, the sibling of the CSV one. Same stakes: a
// rate is the multiplier every conversion in the app runs through, so a file
// read wrong is money wrong everywhere at once, quietly. These tests pin what
// each accepted shape must produce exactly, and - for every way a file can be
// mangled - that the import is refused with a message naming the entry, and
// that the rates already in the database are untouched afterwards.
//
// The worst of the old behaviours has its own test below: the date-indexed
// reader skipped every value it could not read, so a file in some other tool's
// format imported zero rows and told the user it had worked.
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/core/services/android_file_picker_service.dart';
import 'package:my_budget_client/core/services/data_import_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DataImportService importer;

  Future<List<ExchangeRate>> allRates() => db.select(db.exchangeRates).get();

  /// The rates keyed the way the table keys them, so a test can name one.
  Future<Map<String, ExchangeRate>> ratesByPair() async => {
    for (final r in await allRates())
      '${r.fromCurrencyCode}>${r.toCurrencyCode}@'
              '${r.date.toIso8601String()}':
          r,
  };

  Future<void> importJson(Object? document) =>
      importer.importExchangeRatesContent(jsonEncode(document), isCsv: false);

  /// For the documents that are not valid JSON at all.
  Future<void> importRaw(String content) =>
      importer.importExchangeRatesContent(content, isCsv: false);

  setUpAll(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    importer = DataImportService(db, AndroidFilePickerService());
  });

  tearDownAll(() async {
    await db.close();
  });

  setUp(() async {
    await db.delete(db.exchangeRates).go();
  });

  group('a list of rate objects', () {
    test('every pair, date and rate arrives verbatim', () async {
      await importJson([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 1.0876,
          'date': '2025-03-30',
        },
        {
          'fromCurrencyCode': 'BTC',
          'toCurrencyCode': 'USD',
          'rate': 82345.67,
          'date': '2025-03-31',
        },
      ]);

      final rates = await ratesByPair();
      expect(rates.length, 2);

      final eurUsd =
          rates['EUR>USD@${DateTime(2025, 3, 30).toIso8601String()}']!;
      expect(eurUsd.rate, 1.0876);
      expect(eurUsd.date, DateTime(2025, 3, 30));
      expect(eurUsd.preset, 0);

      expect(
        rates['BTC>USD@${DateTime(2025, 3, 31).toIso8601String()}']!.rate,
        82345.67,
        reason: 'a rate is stored as written, not rounded to money precision',
      );
    });

    test('this app\'s own export reads back, epoch dates and all', () async {
      // What ExchangeRate.toJson writes: the date is epoch milliseconds, the
      // preset is carried, and there are sync columns the importer has no
      // business copying from a file.
      await importJson([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 1.0876,
          'preset': 3,
          'date': DateTime(2025, 3, 30).millisecondsSinceEpoch,
          'modifiedAt': 1700000000000,
          'deviceId': 'some-other-device',
          'sourceId': null,
        },
      ]);

      final rate = (await allRates()).single;
      expect(rate.date, DateTime(2025, 3, 30));
      expect(
        rate.preset,
        3,
        reason: 'preset is part of the primary key, so a round trip keeps it',
      );
      expect(rate.rate, 1.0876);
    });

    test('a lower-case code and stray spacing are the same currency', () async {
      await importJson([
        {
          'fromCurrencyCode': ' eur ',
          'toCurrencyCode': 'usd',
          'rate': '1.0876',
          'date': '2025-03-30',
        },
      ]);

      final rate = (await allRates()).single;
      expect(rate.fromCurrencyCode, 'EUR');
      expect(rate.toCurrencyCode, 'USD');
      expect(
        rate.rate,
        1.0876,
        reason: 'plenty of exporters quote their numbers',
      );
    });

    test('two entries agreeing on the same rate are not a conflict', () async {
      await importJson([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 1.0876,
          'date': '2025-03-30',
        },
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 1.0876,
          'date': '2025-03-30T00:00:00',
        },
      ]);

      expect((await allRates()).single.rate, 1.0876);
    });
  });

  group('a date-indexed file', () {
    test('every currency under a date is quoted against EUR', () async {
      await importJson({
        '2025-03-30': {'USD': 1.0876, 'JPY': 163.42},
        '2025-03-31': {'USD': 1.0812},
      });

      final rates = await ratesByPair();
      expect(rates.length, 3);
      expect(
        rates['EUR>USD@${DateTime(2025, 3, 30).toIso8601String()}']!.rate,
        1.0876,
      );
      expect(
        rates['EUR>JPY@${DateTime(2025, 3, 30).toIso8601String()}']!.rate,
        163.42,
      );
      expect(
        rates['EUR>USD@${DateTime(2025, 3, 31).toIso8601String()}']!.rate,
        1.0812,
      );
    });

    test('a timestamped key keeps its time of day', () async {
      await importJson({
        '2025-03-30 23:45:00': {'USD': 1.0876},
      });

      expect((await allRates()).single.date, DateTime(2025, 3, 30, 23, 45));
    });
  });

  group('a malformed file is refused, and changes nothing', () {
    late List<ExchangeRate> before;

    setUp(() async {
      // A rate the user already had. Every refusal below has to leave it
      // exactly as it is - the import must not be half-applied, and must not
      // "helpfully" reset anything to 1.0.
      await db
          .into(db.exchangeRates)
          .insert(
            ExchangeRatesCompanion.insert(
              fromCurrencyCode: 'EUR',
              toCurrencyCode: 'USD',
              rate: 1.1234,
              date: DateTime(2020, 1, 1),
              preset: 0,
              modifiedAt: const Value(42),
            ),
          );
      before = await allRates();
    });

    Future<void> expectRefusedRaw(
      String content,
      Matcher messageMatcher,
    ) async {
      await expectLater(
        importRaw(content),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            messageMatcher,
          ),
        ),
      );

      final after = await allRates();
      expect(
        after.length,
        before.length,
        reason: 'a refused file must not leave a partial import behind',
      );
      final survivor = after.single;
      expect(survivor.fromCurrencyCode, 'EUR');
      expect(survivor.toCurrencyCode, 'USD');
      expect(
        survivor.rate,
        1.1234,
        reason: 'the rate the user already had must not be touched',
      );
      expect(survivor.date, DateTime(2020, 1, 1));
    }

    Future<void> expectRefused(Object? document, Matcher messageMatcher) =>
        expectRefusedRaw(jsonEncode(document), messageMatcher);

    test('text that is not JSON at all', () async {
      await expectRefusedRaw('{not json', contains('could not be parsed'));
    });

    test('a top-level value that is neither list nor map', () async {
      // This used to fall out of both branches and report success.
      await expectRefused(42, contains('list of rate objects'));
    });

    test('an empty list', () async {
      await expectRefused(const [], contains('no rates'));
    });

    test('an empty map', () async {
      await expectRefused(const <String, dynamic>{}, contains('no rates'));
    });

    test('a list entry that is not an object', () async {
      await expectRefused([
        '2025-03-30,EUR,USD,1.0876',
      ], allOf(contains('entry 1'), contains('not a rate object')));
    });

    test('an entry naming a currency this app does not know', () async {
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 1.0876,
          'date': '2025-03-30',
        },
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'ZZZ',
          'rate': 1.0,
          'date': '2025-03-30',
        },
      ], allOf(contains('entry 2'), contains('ZZZ')));
    });

    test('an entry with no currency at all', () async {
      await expectRefused([
        {'toCurrencyCode': 'USD', 'rate': 1.0876, 'date': '2025-03-30'},
      ], allOf(contains('entry 1'), contains('fromCurrencyCode')));
    });

    test('an entry whose rate is missing', () async {
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'date': '2025-03-30',
        },
      ], allOf(contains('entry 1'), contains('rate')));
    });

    test('an entry whose rate is words', () async {
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 'about one',
          'date': '2025-03-30',
        },
      ], allOf(contains('entry 1'), contains('about one')));
    });

    test('a rate of zero', () async {
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 0,
          'date': '2025-03-30',
        },
      ], allOf(contains('entry 1'), contains('positive')));
    });

    test('a negative rate', () async {
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': -1.0876,
          'date': '2025-03-30',
        },
      ], allOf(contains('entry 1'), contains('positive')));
    });

    test('a rate spelled NaN or Infinity', () async {
      // Not valid JSON numbers, so they arrive as strings - and double.tryParse
      // happily accepts both.
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 'NaN',
          'date': '2025-03-30',
        },
      ], allOf(contains('entry 1'), contains('positive')));
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 'Infinity',
          'date': '2025-03-30',
        },
      ], allOf(contains('entry 1'), contains('positive')));
    });

    test('an entry whose date is not a date', () async {
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 1.0876,
          'date': 'yesterday',
        },
      ], allOf(contains('entry 1'), contains('yesterday')));
    });

    test('an entry filed under a preset that is not a whole number', () async {
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 1.0876,
          'date': '2025-03-30',
          'preset': 'ecb',
        },
      ], allOf(contains('entry 1'), contains('ecb')));
    });

    test('two entries contradicting each other', () async {
      await expectRefused([
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 1.0876,
          'date': '2025-03-30',
        },
        {
          'fromCurrencyCode': 'EUR',
          'toCurrencyCode': 'USD',
          'rate': 1.5,
          'date': '2025-03-30',
        },
      ], allOf(contains('entry 2'), contains('entry 1'), contains('1.5')));
    });

    test('a date-indexed key that is not a date', () async {
      await expectRefused({
        'yesterday': {'USD': 1.0876},
      }, contains('yesterday'));
    });

    test('a date whose value is not a set of rates', () async {
      await expectRefused(
        {'2025-03-30': 1.0876},
        allOf(contains('2025-03-30'), contains('not a set of currency rates')),
      );
    });

    test('a date-indexed rate that is not a number', () async {
      // The one that mattered: this used to be skipped silently, so a file
      // where *every* value was unreadable imported nothing and reported
      // success, which reads as "your rates are up to date".
      await expectRefused({
        '2025-03-30': {'USD': 'n/a', 'JPY': 'n/a'},
      }, allOf(contains('2025-03-30'), contains('USD'), contains('n/a')));
    });

    test('a date-indexed currency this app does not know', () async {
      await expectRefused({
        '2025-03-30': {'ZZZ': 1.0876},
      }, allOf(contains('2025-03-30'), contains('ZZZ')));
    });

    test('a date-indexed rate of zero', () async {
      await expectRefused({
        '2025-03-30': {'USD': 0},
      }, allOf(contains('USD'), contains('positive')));
    });
  });
}
