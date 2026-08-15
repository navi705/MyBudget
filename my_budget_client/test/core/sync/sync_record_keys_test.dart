import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/sync/sync_record_keys.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The composite `sync_log.record_id` strings for `exchange_rates` and
/// `inflation_rates` are the only link between a pending change and the row it
/// describes, and they are produced by `app_database.dart` while being consumed
/// by `sync_service_io.dart`. Two things therefore have to hold:
///
/// * formatting must be byte-identical to what the DAOs write, or export and
///   import silently disagree and the change is dropped;
/// * parsing must be total. `_applyChange` runs inside a loop over a whole
///   imported packet, so one unparsable id from an older or corrupted peer must
///   yield null, never an exception that costs every other change in the file.
///
/// The DAO-side formats, reproduced here so a change to either side breaks a
/// test rather than a user's data:
///   exchange_rates:  '${from}_${to}_${yyyy-MM-dd}_${preset}'
///   inflation_rates: '${yyyy-MM-dd}_${country}_${preset}'
void main() {
  // `sync_record_keys.dart` pins its DateFormat to 'en' so a record id spells
  // the same day on every device, and a pinned locale needs its CLDR data
  // loaded. `app.dart` does this at startup; a bare `flutter test` does not, so
  // every id this suite formats or parses would throw LocaleDataException.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  // The exact expression app_database.dart uses, so "byte-identical" is
  // asserted against the real thing instead of a hand-written string.
  String daoDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  String daoExchangeRateId(String from, String to, DateTime date, int preset) =>
      '${from}_${to}_${daoDate(date)}_$preset';

  String daoInflationRateId(DateTime date, String country, int preset) =>
      '${daoDate(date)}_${country}_$preset';

  group('formatSyncRecordDate', () {
    test('matches the DAO date format exactly', () {
      for (final date in [
        DateTime(2024, 1, 5),
        DateTime(2024, 12, 31),
        DateTime(1999, 6, 1),
        // Time of day is not part of the id - only the calendar day is.
        DateTime(2024, 3, 17, 23, 59, 59),
      ]) {
        expect(formatSyncRecordDate(date), daoDate(date));
      }
    });

    test('zero-pads single digit months and days', () {
      expect(formatSyncRecordDate(DateTime(2024, 1, 2)), '2024-01-02');
    });
  });

  group('ExchangeRateKey.tryParse', () {
    test('parses an id the DAO would write', () {
      final date = DateTime(2024, 1, 15);
      final key = ExchangeRateKey.tryParse(
        daoExchangeRateId('USD', 'EUR', date, 1),
      );

      expect(key, isNotNull);
      expect(key!.fromCurrencyCode, 'USD');
      expect(key.toCurrencyCode, 'EUR');
      expect(key.date, date);
      expect(key.preset, 1);
    });

    test('round-trips back to the DAO id', () {
      final date = DateTime(2024, 7, 4, 13, 45);
      final id = daoExchangeRateId('BTC', 'usd', date, 12);

      expect(ExchangeRateKey.tryParse(id)!.format(), id);
    });

    test('keeps a lowercase or non-ASCII code verbatim', () {
      // Codes are stored as written and compared case-sensitively by SQLite,
      // so the key must not normalise them or the WHERE clause misses the row.
      final date = DateTime(2024, 2, 29);
      for (final pair in [
        ['usd', 'eur'],
        ['USD', 'eur'],
        ['₿', 'USD'],
        ['XAU', 'RUB'],
      ]) {
        final id = daoExchangeRateId(pair[0], pair[1], date, 3);
        final key = ExchangeRateKey.tryParse(id);
        expect(key, isNotNull, reason: id);
        expect(key!.fromCurrencyCode, pair[0]);
        expect(key.toCurrencyCode, pair[1]);
        expect(key.format(), id);
      }
    });

    test('day bounds span exactly the calendar day of the id', () {
      final key = ExchangeRateKey.tryParse('USD_EUR_2024-03-17_1')!;

      expect(key.dayStart, DateTime(2024, 3, 17));
      expect(key.dayAfter, DateTime(2024, 3, 18));
    });

    test('day bounds are calendar-based, not a fixed 24 hours', () {
      // Built through the DateTime constructor, so the upper bound is the start
      // of the next day even where that day is 23 or 25 hours long.
      final key = ExchangeRateKey.tryParse('USD_EUR_2024-12-31_1')!;

      expect(key.dayAfter, DateTime(2025, 1, 1));
    });

    test('malformed ids parse to null and do not throw', () {
      for (final id in <String>[
        '',
        'garbage',
        'a_b',
        'USD_EUR_notadate_1',
        // Not enough segments.
        'USD_EUR_2024-01-15',
        // Preset is not an integer.
        'USD_EUR_2024-01-15_x',
        // An extra underscore makes from/to ambiguous - reject rather than
        // guess and silently key the row wrong.
        'USD_EUR_EXTRA_2024-01-15_1',
        // Empty currency codes.
        '_EUR_2024-01-15_1',
        'USD__2024-01-15_1',
        // Date-shaped but not a real date.
        'USD_EUR_2024-13-45_1',
        // Trailing junk after the date must not be swallowed.
        'USD_EUR_2024-01-15junk_1',
        // The inflation format is not the exchange rate format.
        '2024-01-15_global_1',
      ]) {
        expect(
          () => ExchangeRateKey.tryParse(id),
          returnsNormally,
          reason: 'must not throw for: "$id"',
        );
        expect(ExchangeRateKey.tryParse(id), isNull, reason: 'for: "$id"');
      }
    });
  });

  group('InflationRateKey.tryParse', () {
    test('parses an id the DAO would write', () {
      final date = DateTime(2024, 5, 1);
      final key = InflationRateKey.tryParse(
        daoInflationRateId(date, 'Germany', 2),
      );

      expect(key, isNotNull);
      expect(key!.date, date);
      expect(key.country, 'Germany');
      expect(key.preset, 2);
    });

    test('parses the worldwide sentinel country', () {
      // The DB never stores a null country: the worldwide series lives under
      // 'global' so SQLite's primary key can actually catch a repeat.
      final key = InflationRateKey.tryParse('2024-05-01_global_1');

      expect(key, isNotNull);
      expect(key!.country, 'global');
    });

    test('round-trips back to the DAO id', () {
      final date = DateTime(2024, 5, 1);
      for (final country in ['global', 'Germany', 'Côte d\'Ivoire', 'РФ']) {
        final id = daoInflationRateId(date, country, 7);
        expect(InflationRateKey.tryParse(id)!.format(), id);
      }
    });

    test('a country containing an underscore round-trips exactly', () {
      // Unlike an exchange rate id there is nothing ambiguous here: the date is
      // pinned to the front and the preset to the back, so the middle is the
      // country whatever it contains.
      final id = daoInflationRateId(DateTime(2024, 5, 1), 'United_States', 1);
      final key = InflationRateKey.tryParse(id);

      expect(key, isNotNull);
      expect(key!.country, 'United_States');
      expect(key.format(), id);
    });

    test('day bounds span exactly the calendar day of the id', () {
      final key = InflationRateKey.tryParse('2024-03-17_global_1')!;

      expect(key.dayStart, DateTime(2024, 3, 17));
      expect(key.dayAfter, DateTime(2024, 3, 18));
    });

    test('malformed ids parse to null and do not throw', () {
      for (final id in <String>[
        '',
        'garbage',
        'a_b',
        // Preset is not an integer.
        '2024-01-15_global_x',
        // Date is not a date.
        'notadate_global_1',
        // Empty country.
        '2024-01-15__1',
        // Too few segments.
        '2024-01-15_global',
        // Date-shaped but not a real date.
        '2024-13-45_global_1',
        // The exchange rate format is not the inflation format.
        'USD_EUR_2024-01-15_1',
      ]) {
        expect(
          () => InflationRateKey.tryParse(id),
          returnsNormally,
          reason: 'must not throw for: "$id"',
        );
        expect(InflationRateKey.tryParse(id), isNull, reason: 'for: "$id"');
      }
    });
  });
}
