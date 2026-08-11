// Dates that are keys, not labels.
//
// The app points `Intl.defaultLocale` at the language the user reads in, so
// every *unqualified* `DateFormat` follows it. Among the shipped locales `bn`
// carries native digits in its CLDR data, which means an unqualified
// `DateFormat('yyyy-MM-dd')` renders `২০২৬-০৮-১২` there. Anything whose output
// becomes a sync record id, a URL, a cache key or a column in an export file
// has to stay ASCII whatever the interface language is - a Bengali device
// writing record ids in native digits matches nothing any other device wrote,
// and nothing its own parser wrote before the user switched language.
//
// These tests format under `bn` on purpose: they fail the moment one of those
// call sites loses its explicit locale.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/core/sync/sync_record_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final date = DateTime(2026, 8, 12);
  String? previousLocale;

  setUpAll(() async {
    await initializeDateFormatting();
  });

  setUp(() {
    previousLocale = Intl.defaultLocale;
    // What the app itself does once a Bengali user picks their language.
    Intl.defaultLocale = 'bn';
  });

  tearDown(() {
    Intl.defaultLocale = previousLocale;
  });

  test('the shipped locale that would break these really does break them', () {
    // The premise of every test below. If intl ever stops rendering Bengali
    // dates in native digits, these tests are no longer proving anything and
    // should be re-pointed at whatever locale does.
    expect(
      DateFormat('yyyy-MM-dd').format(date),
      isNot('2026-08-12'),
      reason: 'an unqualified DateFormat follows Intl.defaultLocale',
    );
  });

  test('a sync record id spells its date in ASCII', () {
    expect(formatSyncRecordDate(date), '2026-08-12');
  });

  test('a sync record id parses back under a native-digit locale', () {
    // The formatting and parsing sides have to agree, or a rate imported from
    // a peer keys onto no row at all.
    expect(tryParseSyncRecordDate('2026-08-12'), date);
  });

  test('an exchange-rate key round-trips through its record id', () {
    final key = ExchangeRateKey(
      fromCurrencyCode: 'EUR',
      toCurrencyCode: 'USD',
      date: date,
      preset: 0,
    );
    expect(key.format(), 'EUR_USD_2026-08-12_0');
    expect(ExchangeRateKey.tryParse(key.format())?.date, date);
  });

  group('the DAO that writes those ids', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('logs an exchange rate under an ASCII record id', () async {
      await db.exchangeRatesDao.addExchangeRate(
        ExchangeRatesCompanion.insert(
          fromCurrencyCode: 'EUR',
          toCurrencyCode: 'USD',
          rate: 1.0876,
          date: date,
          preset: 0,
          modifiedAt: const Value(1),
        ),
      );

      final logged = await (db.select(
        db.syncLog,
      )..where((l) => l.changedTableName.equals('exchange_rates'))).get();
      expect(logged.map((l) => l.recordId), contains('EUR_USD_2026-08-12_0'));
    });

    test('logs an inflation rate under an ASCII record id', () async {
      await db.inflationRatesDao.insertInflationRate(
        InflationRatesCompanion.insert(
          date: date,
          percent: 3.2,
          country: const Value('US'),
          preset: 0,
          modifiedAt: const Value(1),
        ),
      );

      final logged = await (db.select(
        db.syncLog,
      )..where((l) => l.changedTableName.equals('inflation_rates'))).get();
      expect(logged.map((l) => l.recordId), contains('2026-08-12_US_0'));
    });
  });
}
