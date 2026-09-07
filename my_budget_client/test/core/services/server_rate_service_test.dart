import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/server_rate_service.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/domain/entities/settings.dart' as domain;

/// What the device accepts from its own rate server.
///
/// Rates used to be fetched per device from a public CDN, one HTTP request per
/// day of history. The server holds that history now and answers whole ranges,
/// so this is the only thing left on the client that asks anyone for a rate -
/// and everything it hands back is written straight into `exchange_rates`,
/// where a zero or a NaN is not a slightly wrong number but one that breaks
/// every balance it reaches.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;

  /// Every request the service made, in order.
  late List<Uri> requests;

  Future<void> setSetting(String key, String value) =>
      settingsRepository.setSetting(
        domain.Settings(key: key, value: value, device: 'test-device'),
      );

  /// A response body in the shape `/api/rates` answers with.
  String body(List<Map<String, dynamic>> rates, {bool hasMore = false}) =>
      jsonEncode({'rates': rates, 'has_more': hasMore});

  Map<String, dynamic> rate(
    String to, {
    String date = '2026-03-14',
    dynamic value = 1.09,
  }) => {
    'fromCurrencyCode': 'EUR',
    'toCurrencyCode': to,
    'rate': value,
    'preset': 1,
    'date': '${date}T00:00:00.000Z',
  };

  ServerRateService serviceThat(
    Future<http.Response> Function(http.Request request) answer,
  ) => ServerRateService(
    settingsRepository: settingsRepository,
    client: MockClient((request) {
      requests.add(request.url);
      return answer(request);
    }),
  );

  setUpAll(() async {
    // The service formats the days it asks for.
    await initializeDateFormatting();
  });

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.select(db.styles).get();
    settingsRepository = LocalSettingsRepository(db);
    requests = [];
    await setSetting('server_sync_url', 'http://rates.test');
  });

  tearDown(() async => db.close());

  group('a single day', () {
    test('comes back as a code to rate map', () async {
      final service = serviceThat(
        (_) async => http.Response(body([rate('USD'), rate('jpy', value: 162)]), 200),
      );

      final rates = await service.fetchDay(DateTime(2026, 3, 14));

      expect(rates, {'USD': 1.09, 'JPY': 162.0});
      expect(requests.single.path, '/api/rates');
      expect(requests.single.queryParameters['date_from'], '2026-03-14');
      expect(requests.single.queryParameters['date_to'], '2026-03-14');
    });

    test('carries the currencies the caller asked for, upper-cased', () async {
      final service = serviceThat((_) async => http.Response(body([]), 200));

      await service.fetchDay(
        DateTime(2026, 3, 14),
        toCurrencyCodes: ['usd', 'jpy'],
      );

      expect(requests.single.queryParameters['to'], 'USD,JPY');
    });
  });

  group('rows that cannot be used', () {
    test('are dropped without costing the rest of the answer', () async {
      // A rate is a multiplier. Zero divides a balance to infinity, a negative
      // flips its sign, and a NaN poisons every sum it reaches - so a bad row
      // is worse than a missing one, and the good rows in the same response
      // are still worth keeping.
      final service = serviceThat(
        (_) async => http.Response(
          body([
            rate('USD'),
            rate('AAA', value: 0),
            rate('BBB', value: -2),
            rate('CCC', value: 'not a number'),
            {'toCurrencyCode': 'DDD', 'rate': 1.0, 'date': '2026-03-14'},
            {'fromCurrencyCode': 'EUR', 'toCurrencyCode': 'EEE', 'rate': 1.0},
            rate('FFF', date: 'someday'),
          ]),
          200,
        ),
      );

      final rates = await service.fetchLatest();

      expect(rates.map((r) => r.toCurrencyCode), ['USD']);
    });

    test('a preset the server did not send defaults to the fetched one',
        () async {
      // The stored row has to collide on the primary key with the seeded and
      // imported rows for the same day, or the table grows a second copy of
      // every rate under a preset nothing reads.
      final service = serviceThat(
        (_) async => http.Response(
          body([
            {
              'fromCurrencyCode': 'EUR',
              'toCurrencyCode': 'USD',
              'rate': 1.09,
              'date': '2026-03-14',
            }
          ]),
          200,
        ),
      );

      expect((await service.fetchLatest()).single.preset, 1);
    });
  });

  group('failures answer empty rather than throwing', () {
    test('a non-200', () async {
      final service = serviceThat((_) async => http.Response('nope', 503));

      expect(await service.fetchLatest(), isEmpty);
      expect(await service.fetchDay(DateTime(2026, 3, 14)), isEmpty);
    });

    test('a body that is not the expected shape', () async {
      final service = serviceThat(
        (_) async => http.Response('["not", "a", "map"]', 200),
      );

      expect(await service.fetchLatest(), isEmpty);
    });

    test('a transport error', () async {
      final service = serviceThat((_) async => throw const SocketFailure());

      expect(await service.fetchRange(), isEmpty);
    });

    test('no server configured means no request at all', () async {
      await setSetting('server_sync_url', '');
      final service = serviceThat(
        (_) async => http.Response(body([rate('USD')]), 200),
      );

      expect(await service.isConfigured(), isFalse);
      expect(await service.fetchLatest(), isEmpty);
      expect(requests, isEmpty);
    });
  });

  group('latest', () {
    test('bounds the answer from above without a lower bound', () async {
      // "Latest" is the newest quote per pair whatever the gap - a Sunday has
      // to read as Friday's rate. A window would answer nothing for it.
      final service = serviceThat(
        (_) async => http.Response(body([rate('USD')]), 200),
      );

      await service.fetchLatest(asOf: DateTime(2026, 3, 15));

      expect(requests.single.path, '/api/rates/latest');
      expect(requests.single.queryParameters['date_to'], '2026-03-15');
      expect(requests.single.queryParameters.containsKey('date_from'), isFalse);
    });
  });

  group('a range larger than one page', () {
    test('walks back by narrowing the upper bound', () async {
      // The server answers newest first and caps the page; there is no cursor,
      // so the next page is asked for as a narrower window.
      final service = serviceThat((request) async {
        if (requests.length == 1) {
          return http.Response(
            body([
              rate('USD', date: '2026-03-03'),
              rate('USD', date: '2026-03-02'),
              rate('USD', date: '2026-03-01'),
            ], hasMore: true),
            200,
          );
        }
        return http.Response(
          body([rate('USD', date: '2026-03-01')]),
          200,
        );
      });

      final rates = await service.fetchRange(
        dateFrom: DateTime(2026, 3),
        dateTo: DateTime(2026, 3, 3),
      );

      expect(requests, hasLength(2));
      // The oldest day of a truncated page may have been cut in half, so it is
      // re-asked for rather than stored with a hole in it.
      expect(requests.last.queryParameters['date_to'], '2026-03-01');
      expect(
        rates.map((r) => r.date).toSet(),
        {DateTime(2026, 3, 3), DateTime(2026, 3, 2), DateTime(2026, 3)},
      );
    });

    test('steps past a single day that does not fit one page', () async {
      // Re-asking for the same window would return the same truncated page
      // forever; the walk has to end even when it cannot be made complete.
      final service = serviceThat((request) async {
        if (requests.length >= 3) {
          return http.Response(body([]), 200);
        }
        return http.Response(
          body([rate('USD'), rate('JPY')], hasMore: true),
          200,
        );
      });

      await service.fetchRange(
        dateFrom: DateTime(2026, 3, 13),
        dateTo: DateTime(2026, 3, 14),
      );

      expect(requests[1].queryParameters['date_to'], '2026-03-13');
    });

    test('stops once the window has walked past the day asked for', () async {
      final service = serviceThat(
        (_) async => http.Response(
          body([rate('USD', date: '2026-03-14')], hasMore: true),
          200,
        ),
      );

      await service.fetchRange(
        dateFrom: DateTime(2026, 3, 14),
        dateTo: DateTime(2026, 3, 14),
      );

      expect(requests, hasLength(1));
    });
  });

  test('the request is authenticated with the stored token', () async {
    await setSetting('server_sync_token', 'secret-token');
    var seen = '';
    final service = ServerRateService(
      settingsRepository: settingsRepository,
      client: MockClient((request) async {
        seen = request.headers['Authorization'] ?? '';
        return http.Response(body([]), 200);
      }),
    );

    await service.fetchLatest();

    expect(seen, 'Bearer secret-token');
  });
}

/// Stands in for whatever the platform throws when the server is unreachable.
class SocketFailure implements Exception {
  const SocketFailure();
}
