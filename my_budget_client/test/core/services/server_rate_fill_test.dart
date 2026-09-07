import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/services/server_rate_service.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/domain/entities/settings.dart' as domain;

/// Where a rate the device does not have comes from, and what it costs.
///
/// The client no longer talks to a rate provider at all: the server fetches
/// the history, and the device asks the server for the days it is missing.
/// Two things about that have to hold, or the change trades one problem for a
/// worse one - the fetched rows must not be pushed back to the server that
/// published them, and a miss must not become one request per rendered row.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;
  late List<Uri> requests;

  /// What the fake server answers with, newest first.
  late List<Map<String, dynamic>> published;

  Map<String, dynamic> rate(
    String to, {
    String date = '2026-03-14',
    double value = 1.09,
  }) => {
    'fromCurrencyCode': 'EUR',
    'toCurrencyCode': to,
    'rate': value,
    'preset': 1,
    'date': '${date}T00:00:00.000Z',
  };

  ServerRateService buildServer() => ServerRateService(
    settingsRepository: settingsRepository,
    client: MockClient((request) async {
      requests.add(request.url);
      return http.Response(
        jsonEncode({'rates': published, 'has_more': false}),
        200,
      );
    }),
  );

  ExchangeRateApiService buildService({bool withServer = true}) =>
      ExchangeRateApiService(
        db.exchangeRatesDao,
        db.apiFetchStatusesDao,
        db.currenciesDao,
        serverRates: withServer ? buildServer() : null,
      );

  Future<List<ExchangeRate>> storedRates() =>
      db.exchangeRatesDao.getAllExchangesRatesAll();

  /// Queue entries naming a rate row - what a push would send upstream.
  Future<int> queuedRateRows() async {
    final rows = await db
        .customSelect(
          "SELECT COUNT(*) AS c FROM sync_push_queue "
          "WHERE changed_table_name = 'exchange_rates'",
        )
        .getSingle();
    return rows.data['c'] as int;
  }

  setUpAll(() async => initializeDateFormatting());

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.select(db.styles).get();
    await db.delete(db.exchangeRates).go();
    await db.customStatement('DELETE FROM sync_push_queue');
    settingsRepository = LocalSettingsRepository(db);
    requests = [];
    published = [];
    await settingsRepository.setSetting(
      const domain.Settings(
        key: 'server_sync_url',
        value: 'http://rates.test',
        device: 'test-device',
      ),
    );
  });

  tearDown(() async => db.close());

  group('a rate fetched on a miss', () {
    test('is stored and is not queued back to the server', () async {
      // The server published these rows; sending them back would hand it its
      // own history one day at a time, and the seeded history alone was ~367k
      // queue entries the last time that happened.
      published = [rate('USD')];

      await buildService().fillMissingRates(
        currencyCodes: ['USD'],
        date: DateTime(2026, 3, 14),
      );

      final stored = await storedRates();
      expect(stored.single.toCurrencyCode, 'USD');
      expect(stored.single.rate, 1.09);
      expect(stored.single.deviceId, kServerRateDeviceId);
      expect(await queuedRateRows(), 0);
    });

    test('keeps the day the server quoted, not the day that was asked for',
        () async {
      // A weekend has no quote of its own. Storing Friday's number under
      // Sunday's date would be invented history that nothing ever corrects.
      published = [rate('USD', date: '2026-03-13')];

      await buildService().fillMissingRates(
        currencyCodes: ['USD'],
        date: DateTime(2026, 3, 15),
      );

      expect((await storedRates()).single.date, DateTime(2026, 3, 13));
    });

    test('falls back to the newest quote when nothing is that old', () async {
      // A date older than the server's history answers empty for an upper
      // bound. Its newest quote is still better than no rate at all, and it is
      // stored under its own date so it is not mistaken for one from then.
      var call = 0;
      final service = ExchangeRateApiService(
        db.exchangeRatesDao,
        db.apiFetchStatusesDao,
        db.currenciesDao,
        serverRates: ServerRateService(
          settingsRepository: settingsRepository,
          client: MockClient((request) async {
            requests.add(request.url);
            final rates = call++ == 0 ? <Map<String, dynamic>>[] : [rate('USD')];
            return http.Response(
              jsonEncode({'rates': rates, 'has_more': false}),
              200,
            );
          }),
        ),
      );

      await service.fillMissingRates(
        currencyCodes: ['USD'],
        date: DateTime(2020),
      );

      expect(requests, hasLength(2));
      expect(requests.first.queryParameters['date_to'], '2020-01-01');
      expect(requests.last.queryParameters.containsKey('date_to'), isFalse);
      expect((await storedRates()).single.date, DateTime(2026, 3, 14));
    });

    test('a currency the device does not have is not created by a rate',
        () async {
      published = [rate('ZZZ')];

      await buildService().fillMissingRates(
        currencyCodes: ['ZZZ'],
        date: DateTime(2026, 3, 14),
      );

      expect(await storedRates(), isEmpty);
    });
  });

  group('what a miss costs', () {
    test('the same currency and month is only ever asked for once', () async {
      // The miss comes from a conversion, and conversions run once per row of
      // a list. Without this, one screen of transactions in a currency with no
      // stored rate is one request per row, repeated on every rebuild.
      published = [rate('USD')];
      final service = buildService();

      await service.fillMissingRates(
        currencyCodes: ['USD'],
        date: DateTime(2026, 3, 14),
      );
      await service.fillMissingRates(
        currencyCodes: ['USD'],
        date: DateTime(2026, 3, 20),
      );
      await service.fillMissingRates(
        currencyCodes: ['usd'],
        date: DateTime(2026, 3, 2),
      );

      expect(requests, hasLength(1));
    });

    test('another month of the same currency is a fresh question', () async {
      published = [rate('USD')];
      final service = buildService();

      await service.fillMissingRates(
        currencyCodes: ['USD'],
        date: DateTime(2026, 3, 14),
      );
      await service.fillMissingRates(
        currencyCodes: ['USD'],
        date: DateTime(2026, 4, 14),
      );

      expect(requests, hasLength(2));
    });

    test('two currencies missed together are one request', () async {
      published = [rate('USD'), rate('JPY', value: 162)];

      await buildService().fillMissingRates(
        currencyCodes: ['USD', 'JPY'],
        date: DateTime(2026, 3, 14),
      );

      expect(requests, hasLength(1));
      expect(requests.single.queryParameters['to'], 'USD,JPY');
      expect(await storedRates(), hasLength(2));
    });

    test('with no server configured nothing is asked and nothing throws',
        () async {
      await expectLater(
        buildService(withServer: false).fillMissingRates(
          currencyCodes: ['USD'],
          date: DateTime(2026, 3, 14),
        ),
        completes,
      );
      expect(requests, isEmpty);
      expect(await storedRates(), isEmpty);
    });
  });

  group('a range', () {
    test('is one request, not one per day', () async {
      // This used to be a day-at-a-time walk with a 200 ms pause between the
      // days: a stale build asking for its backfill took minutes and grew by
      // one request for every day that passed.
      published = [
        rate('USD', date: '2026-03-14'),
        rate('USD', date: '2026-03-13', value: 1.08),
        rate('USD', date: '2026-03-12', value: 1.07),
      ];

      await buildService().fetchRatesForRange(
        DateTime(2026, 3, 12),
        DateTime(2026, 3, 14),
      );

      expect(requests, hasLength(1));
      final stored = await storedRates();
      expect(stored, hasLength(3));
      expect(
        stored.map((r) => r.date).toSet(),
        {DateTime(2026, 3, 14), DateTime(2026, 3, 13), DateTime(2026, 3, 12)},
      );
      expect(await queuedRateRows(), 0);
    });

    test('marks every day it covered so it is not walked again', () async {
      published = [
        rate('USD', date: '2026-03-14'),
        rate('USD', date: '2026-03-13', value: 1.08),
      ];

      await buildService().fetchRatesForRange(
        DateTime(2026, 3, 13),
        DateTime(2026, 3, 14),
      );

      final statuses = await db.select(db.apiFetchStatuses).get();
      expect(
        statuses.where((s) => s.status == 'success').map((s) => s.id).toSet(),
        {'2026-03-14', '2026-03-13'},
      );
    });

    test('an inverted range is not a request', () async {
      await buildService().fetchRatesForRange(
        DateTime(2026, 3, 14),
        DateTime(2026, 3, 12),
      );

      expect(requests, isEmpty);
    });
  });

  test('a rate the user typed is left alone by a fetched one', () async {
    // Same primary key, so the fetch overwrites - which is right for a
    // published number and wrong for a corrected one. What must not happen is
    // the fetched row inheriting the manual row's queue entry and travelling
    // to the server as an edit.
    await db.exchangeRatesDao.insertAllExchangeRates([
      ExchangeRatesCompanion.insert(
        fromCurrencyCode: 'EUR',
        toCurrencyCode: 'USD',
        rate: 2,
        preset: 1,
        date: DateTime(2026, 3, 14),
      ),
    ]);
    final queuedBefore = await queuedRateRows();
    expect(queuedBefore, 1);

    published = [rate('USD')];
    await buildService().fillMissingRates(
      currencyCodes: ['USD'],
      date: DateTime(2026, 3, 14),
    );

    expect(await queuedRateRows(), queuedBefore);
  });
}
