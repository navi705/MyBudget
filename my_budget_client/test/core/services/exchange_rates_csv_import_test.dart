// The exchange-rate CSV importer. A rate is the multiplier every conversion in
// the app runs through, so a file that is read wrong is money that is wrong
// everywhere at once, quietly. These tests pin what a valid file must produce
// exactly, and - for every way a file can be mangled - that the import is
// refused by line number and that the rates already in the database are still
// there afterwards, byte for byte.
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

  const header = 'Date,From,To,Rate';

  Future<List<ExchangeRate>> allRates() => db.select(db.exchangeRates).get();

  /// The rates keyed the way the table keys them, so a test can name one.
  Future<Map<String, ExchangeRate>> ratesByPair() async => {
    for (final r in await allRates())
      '${r.fromCurrencyCode}>${r.toCurrencyCode}@'
              '${r.date.toIso8601String()}':
          r,
  };

  Future<void> importCsv(String content) =>
      importer.importExchangeRatesContent(content, isCsv: true);

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

  group('a valid file imports exactly the rates it names', () {
    test('every pair, date and rate arrives verbatim', () async {
      await importCsv(
        '$header\r\n'
        '2025-03-30,EUR,USD,1.0876\r\n'
        '2025-03-30,EUR,JPY,163.42\r\n'
        '2025-03-31,BTC,USD,82345.67\r\n',
      );

      final rates = await ratesByPair();
      expect(rates.length, 3);

      final eurUsd =
          rates['EUR>USD@${DateTime(2025, 3, 30).toIso8601String()}']!;
      expect(eurUsd.rate, 1.0876);
      expect(eurUsd.date, DateTime(2025, 3, 30));
      expect(eurUsd.preset, 0);

      expect(
        rates['EUR>JPY@${DateTime(2025, 3, 30).toIso8601String()}']!.rate,
        163.42,
      );
      expect(
        rates['BTC>USD@${DateTime(2025, 3, 31).toIso8601String()}']!.rate,
        82345.67,
        reason: 'a rate is stored as written, not rounded to money precision',
      );
    });

    test(
      'a timestamp keeps its time of day rather than sliding to midnight',
      () async {
        await importCsv(
          '$header\r\n'
          '2025-03-30 23:45:00,EUR,USD,1.0876\r\n',
        );
        expect((await allRates()).single.date, DateTime(2025, 3, 30, 23, 45));
      },
    );

    test('a lower-case header and lower-case codes still resolve', () async {
      await importCsv(
        'date,from,to,rate\r\n'
        '2025-03-30,eur,usd,1.0876\r\n',
      );
      final rate = (await allRates()).single;
      expect(rate.fromCurrencyCode, 'EUR');
      expect(rate.toCurrencyCode, 'USD');
    });

    test('codes padded with spaces are the same codes', () async {
      await importCsv(
        '$header\r\n'
        '2025-03-30, EUR , USD ,1.0876\r\n',
      );
      final rate = (await allRates()).single;
      expect(rate.fromCurrencyCode, 'EUR');
      expect(rate.toCurrencyCode, 'USD');
    });

    test('a UTF-8 BOM on the header does not hide the Date column', () async {
      // Excel writes one, and it lands inside the first header cell.
      await importCsv(
        '\u{FEFF}$header\r\n'
        '2025-03-30,EUR,USD,1.0876\r\n',
      );
      expect((await allRates()).single.rate, 1.0876);
    });

    test('LF-only input parses the same as CRLF', () async {
      await importCsv(
        '$header\n'
        '2025-03-30,EUR,USD,1.0876\n',
      );
      final rate = (await allRates()).single;
      expect(rate.rate, 1.0876);
      expect(
        rate.toCurrencyCode,
        'USD',
        reason: 'a parser pinned to LF welds the \\r onto the last column',
      );
    });

    test(
      'a blank separator line is skipped, not read as a short row',
      () async {
        await importCsv(
          '$header\r\n'
          '2025-03-30,EUR,USD,1.0876\r\n'
          '\r\n'
          '2025-03-31,EUR,USD,1.0812\r\n',
        );
        expect((await allRates()).length, 2);
      },
    );

    test('an extra unknown column is ignored', () async {
      await importCsv(
        '$header,Source,Note\r\n'
        '2025-03-30,EUR,USD,1.0876,ECB,checked\r\n',
      );
      expect((await allRates()).single.rate, 1.0876);
    });

    test(
      'a line repeated with the same rate is the same single rate',
      () async {
        await importCsv(
          '$header\r\n'
          '2025-03-30,EUR,USD,1.0876\r\n'
          '2025-03-30,EUR,USD,1.0876\r\n',
        );
        expect((await allRates()).single.rate, 1.0876);
      },
    );

    test(
      're-importing the same file replaces rather than duplicates',
      () async {
        const content =
            '$header\r\n'
            '2025-03-30,EUR,USD,1.0876\r\n';
        await importCsv(content);
        await importCsv(content);
        expect((await allRates()).length, 1);
      },
    );

    test(
      'a later import overwrites the rate for a pair on the same date',
      () async {
        await importCsv('$header\r\n2025-03-30,EUR,USD,1.0876\r\n');
        await importCsv('$header\r\n2025-03-30,EUR,USD,1.0900\r\n');
        expect((await allRates()).single.rate, 1.09);
      },
    );
  });

  group('a malformed file is refused by line, and changes nothing', () {
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

    Future<void> expectRefused(String content, Matcher messageMatcher) async {
      await expectLater(
        importCsv(content),
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

    test('an empty file', () async {
      await expectRefused('', contains('empty'));
    });

    test('a file of blank lines', () async {
      await expectRefused('\r\n\r\n', contains('empty'));
    });

    test('a header that is missing a required column', () async {
      await expectRefused(
        'Date,From,To\r\n'
        '2025-03-30,EUR,USD\r\n',
        contains('Missing Date, From, To, or Rate'),
      );
    });

    test("a file in another tool's format, with no header at all", () async {
      // The old reader took line 1 as a header, found none of its columns and
      // said so - but had it found them, every following line would have been
      // coerced into a today-dated rate of 1.0.
      await expectRefused(
        '2025-03-30,EUR,USD,1.0876\r\n'
        '2025-03-31,EUR,USD,1.0812\r\n',
        contains('Missing Date, From, To, or Rate'),
      );
    });

    test('a header with no data rows under it', () async {
      await expectRefused('$header\r\n', contains('no rates'));
    });

    test('a row with fewer columns than the header', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,USD,1.0876\r\n'
        '2025-03-31,EUR\r\n',
        allOf(contains('line 3'), contains('columns')),
      );
    });

    test('text where the date belongs', () async {
      await expectRefused(
        '$header\r\n'
        'yesterday,EUR,USD,1.0876\r\n',
        allOf(contains('line 2'), contains('date'), contains('yesterday')),
      );
    });

    test('a date in a format DateTime cannot read', () async {
      await expectRefused(
        '$header\r\n'
        '30/03/2025,EUR,USD,1.0876\r\n',
        allOf(contains('line 2'), contains('date'), contains('30/03/2025')),
      );
    });

    test('text where the rate belongs', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,USD,about one\r\n',
        allOf(contains('line 2'), contains('rate'), contains('about one')),
      );
    });

    test('a comma-decimal rate, which parses as nothing at all', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,USD,"1,0876"\r\n',
        allOf(contains('line 2'), contains('rate'), contains('1,0876')),
      );
    });

    test('a rate of zero, which converts every amount to nothing', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,USD,0\r\n',
        allOf(contains('line 2'), contains('positive'), contains('"0"')),
      );
    });

    test('a negative rate', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,USD,-1.0876\r\n',
        allOf(contains('line 2'), contains('positive'), contains('-1.0876')),
      );
    });

    test('NaN and Infinity, which double.tryParse accepts', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,USD,NaN\r\n',
        allOf(contains('line 2'), contains('positive'), contains('NaN')),
      );
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,USD,Infinity\r\n',
        allOf(contains('line 2'), contains('positive'), contains('Infinity')),
      );
    });

    test('an empty currency cell', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30,,USD,1.0876\r\n',
        allOf(contains('line 2'), contains('From')),
      );
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,,1.0876\r\n',
        allOf(contains('line 2'), contains('To')),
      );
    });

    test('a currency the app does not have', () async {
      // Straight to SQLite this was "FOREIGN KEY constraint failed", which
      // names neither the line nor the code.
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,USD,1.0876\r\n'
        '2025-03-31,ZZZ,USD,1.0812\r\n',
        allOf(contains('line 3'), contains('ZZZ')),
      );
    });

    test(
      'two lines that disagree about the same pair on the same date',
      () async {
        // insertOrReplace keyed on (from, to, date, preset) let the last one win
        // in silence, so the file imported as fewer rates than it has lines.
        await expectRefused(
          '$header\r\n'
          '2025-03-30,EUR,USD,1.0876\r\n'
          '2025-03-30,EUR,USD,1.5\r\n',
          allOf(
            contains('line 3'),
            contains('line 2'),
            contains('1.5'),
            contains('1.0876'),
          ),
        );
      },
    );

    test('the good rows around a bad one are not imported either', () async {
      await expectRefused(
        '$header\r\n'
        '2025-03-30,EUR,USD,1.0876\r\n'
        '2025-03-31,EUR,USD,oops\r\n'
        '2025-04-01,EUR,USD,1.0801\r\n',
        contains('line 3'),
      );
      // expectRefused already proved only the pre-existing row is there; this
      // names what specifically must not have been written.
      final dates = (await allRates()).map((r) => r.date).toSet();
      expect(dates.contains(DateTime(2025, 3, 30)), isFalse);
      expect(dates.contains(DateTime(2025, 4, 1)), isFalse);
    });

    test(
      'a mangled file does not become a pile of today-dated rates of 1.0',
      () async {
        // The whole point: the old reader turned this file into three rates of
        // 1.0 dated now, and reported success. Every amount in a foreign
        // currency then converted at par.
        await expectRefused(
          '$header\r\n'
          'n/a,EUR,USD,n/a\r\n'
          'n/a,EUR,JPY,n/a\r\n'
          'n/a,BTC,USD,n/a\r\n',
          contains('line 2'),
        );
        for (final rate in await allRates()) {
          expect(rate.rate, isNot(1.0));
          expect(rate.date.year, 2020);
        }
      },
    );
  });
}
