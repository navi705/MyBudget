import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/domain/entities/settings.dart' as domain;

/// A sink that swallows everything. The service pings it and closes it on
/// teardown; neither is what these tests measure.
class _FakeSink implements WebSocketSink {
  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A socket that stays open and records nothing. Every test here is about
/// whether a dial happens at all, so what the socket does afterwards is
/// irrelevant — but it must not close on its own, or a test could mistake a
/// reconnect for a first dial.
class _FakeChannel implements WebSocketChannel {
  final StreamController<dynamic> _controller = StreamController<dynamic>();

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  final WebSocketSink sink = _FakeSink();

  @override
  Future<void> get ready => Future<void>.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// What server sync does when it is switched on but has no server to talk to.
///
/// A blank `server_sync_url` is the ordinary state of a device where the user
/// flipped the switch before typing the address. It used not to fail loudly: an
/// empty base URL builds *relative* URIs, so `Uri.parse('/api/sync/pull?...')`
/// threw `No host specified in URI` and the socket threw `only ws: and wss:
/// schemes are supported`. Both read as a transient outage, so the reconnect
/// ladder and the 30-second retry hammered them for the whole session — 33
/// dials in one desktop run.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;
  ServerSyncService? service;

  /// One entry per dial, so a socket opened against nothing is visible.
  late List<Uri> dials;

  /// Every HTTP request the service made, pull or push.
  late List<String> requests;

  Future<void> setSetting(String key, String value) =>
      settingsRepository.setSetting(
        domain.Settings(key: key, value: value, device: 'test-device'),
      );

  ServerSyncService build() => ServerSyncService(
    database: db,
    settingsRepository: settingsRepository,
    // Small enough that a ladder which does start is caught inside the test's
    // own wait rather than after it.
    reconnectBaseDelay: const Duration(milliseconds: 20),
    channelFactory: (url) {
      dials.add(url);
      return _FakeChannel();
    },
    httpClient: MockClient((request) async {
      requests.add('${request.method} ${request.url}');
      if (request.method == 'POST') {
        return http.Response('{"status":"ok"}', 200);
      }
      return http.Response(
        jsonEncode({
          'changes': <String, dynamic>{},
          'server_timestamp': 1,
          'has_more': false,
        }),
        200,
      );
    }),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.select(db.styles).get();
    settingsRepository = LocalSettingsRepository(db);
    dials = [];
    requests = [];
    await setSetting('server_sync_enabled', 'true');
  });

  tearDown(() async {
    service?.dispose();
    await db.close();
  });

  group('normalizeSyncBaseUrl', () {
    test('rejects what cannot be the start of a request URL', () {
      // Each of these used to be concatenated straight into
      // '$baseUrl/api/sync/pull' and produce a relative URI instead of an
      // error.
      expect(normalizeSyncBaseUrl(''), isNull);
      expect(normalizeSyncBaseUrl('   '), isNull);
      expect(normalizeSyncBaseUrl('\n'), isNull);
      expect(normalizeSyncBaseUrl('/api'), isNull);
      // No scheme: the single most likely thing a user types.
      expect(normalizeSyncBaseUrl('my-server.example'), isNull);
      expect(normalizeSyncBaseUrl('ftp://my-server.example'), isNull);
      expect(normalizeSyncBaseUrl('http://'), isNull);
    });

    test('keeps a usable address, minus the noise around it', () {
      expect(
        normalizeSyncBaseUrl('http://127.0.0.1:9999'),
        'http://127.0.0.1:9999',
      );
      expect(
        normalizeSyncBaseUrl('  https://example.com  '),
        'https://example.com',
      );
      // A trailing slash would make every path a double slash, which nginx and
      // most proxies route differently from the single-slash form.
      expect(
        normalizeSyncBaseUrl('https://example.com/'),
        'https://example.com',
      );
      expect(
        normalizeSyncBaseUrl('https://example.com/mybudget-sync/'),
        'https://example.com/mybudget-sync',
      );
    });
  });

  group('with no server URL configured', () {
    setUp(() => setSetting('server_sync_url', ''));

    test('no socket is dialled, now or on any ladder rung', () async {
      service = build();
      await service!.initWebSocket();

      // Long enough for several rungs of a 20 ms ladder, had one started.
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(dials, isEmpty);
      expect(service!.reconnectAttempts, 0);
    });

    test('sync() sends nothing', () async {
      service = build();
      await service!.sync();

      expect(requests, isEmpty);
    });

    test('a local write does not queue a push to nowhere', () async {
      service = build();
      await service!.initAutoSync();

      await settingsRepository.setSetting(
        const domain.Settings(
          key: 'a_write_that_would_normally_trigger_a_push',
          value: '1',
          device: 'test-device',
        ),
      );
      // Past the 500 ms debounce the DB listener waits out before it syncs.
      await Future<void>.delayed(const Duration(milliseconds: 900));

      expect(requests, isEmpty);
      expect(dials, isEmpty);
    });

    test('testConnection reports "not configured", not "failed"', () async {
      service = build();

      // Nothing is broken and nothing should be retried; the user has simply
      // not filled the field in. Reporting `failed` sent them checking a server
      // they had never named.
      expect(
        await service!.testConnection(),
        SyncConnectionStatus.notConfigured,
      );
      expect(
        await service!.testConnection(url: '   '),
        SyncConnectionStatus.notConfigured,
      );
      expect(
        await service!.testConnection(url: 'my-server.example'),
        SyncConnectionStatus.notConfigured,
      );
      expect(requests, isEmpty);
    });
  });

  group('with a server URL configured', () {
    test('the socket is dialled and the sync paths run', () async {
      // The other half of the rule: the guard must decline only when there is
      // genuinely nothing to talk to.
      await setSetting('server_sync_url', 'http://127.0.0.1:9999');
      service = build();

      await service!.initWebSocket();
      await service!.sync();

      expect(dials, hasLength(1));
      expect(
        dials.single.toString(),
        startsWith('ws://127.0.0.1:9999/ws/sync'),
      );
      expect(requests, isNotEmpty);
    });

    test(
      'a trailing slash does not become a double slash in the path',
      () async {
        await setSetting('server_sync_url', 'http://127.0.0.1:9999/');
        service = build();

        await service!.sync();

        expect(requests, isNotEmpty);
        for (final request in requests) {
          expect(request, isNot(contains('9999//')));
        }
      },
    );
  });
}
