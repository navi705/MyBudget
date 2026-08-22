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

/// A [WebSocketSink] that swallows everything. The service only ever writes
/// `'ping'` to it and closes it, and neither is what these tests measure.
class _FakeSink implements WebSocketSink {
  /// Whether the service has closed this socket. The one thing that proves the
  /// service shut itself down rather than merely declining to use what it had
  /// left open.
  bool closed = false;

  @override
  void add(dynamic data) {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// A socket whose lifetime the test decides.
///
/// `holdOpen: false` completes the handshake and then drops a few milliseconds
/// later — a server that accepts the connection and immediately loses it, which
/// is what a flapping network or a restarting server looks like from here, and
/// exactly the case the backoff ladder exists for.
class _FakeChannel implements WebSocketChannel {
  _FakeChannel({required bool holdOpen}) {
    if (!holdOpen) {
      // After `ready`, deliberately: the listener is registered before the
      // service awaits the handshake, so closing sooner would exercise a
      // different ordering than the one production sees.
      Timer(const Duration(milliseconds: 5), _controller.close);
    }
  }

  final StreamController<dynamic> _controller = StreamController<dynamic>();
  final _FakeSink _sink = _FakeSink();

  bool get closed => _sink.closed;

  @override
  Stream<dynamic> get stream => _controller.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  Future<void> get ready => Future<void>.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The socket half of server sync: how hard it retries a server that keeps
/// dropping it, and what becomes of the whole machine when the user switches
/// the feature off.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;
  ServerSyncService? service;

  /// One entry per dial, so a reconnect that never happened is visible.
  late List<Uri> dials;

  /// The sockets handed out, in dial order.
  late List<_FakeChannel> channels;

  /// Every HTTP request the service made, pull or push.
  late List<String> requests;

  Future<void> setEnabled(bool enabled) => settingsRepository.setSetting(
    domain.Settings(
      key: 'server_sync_enabled',
      value: enabled ? 'true' : 'false',
      device: 'test-device',
    ),
  );

  /// Builds the service with a time base small enough to watch several rungs of
  /// the ladder inside one test, and a factory that decides per dial whether
  /// the socket holds.
  ServerSyncService build({
    required bool Function(int dialNumber) holdOpen,
    Duration base = const Duration(milliseconds: 20),
    Duration stability = const Duration(milliseconds: 500),
  }) {
    return ServerSyncService(
      database: db,
      settingsRepository: settingsRepository,
      reconnectBaseDelay: base,
      connectionStabilityWindow: stability,
      channelFactory: (url) {
        dials.add(url);
        final channel = _FakeChannel(holdOpen: holdOpen(dials.length));
        channels.add(channel);
        return channel;
      },
      httpClient: MockClient((request) async {
        requests.add('${request.method} ${request.url.path}');
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
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.select(db.styles).get();
    settingsRepository = LocalSettingsRepository(db);
    dials = [];
    channels = [];
    requests = [];
    await setEnabled(true);
    await settingsRepository.setSetting(
      const domain.Settings(
        key: 'server_sync_url',
        value: 'http://127.0.0.1:9999',
        device: 'test-device',
      ),
    );
  });

  tearDown(() async {
    service?.dispose();
    await db.close();
  });

  group('reconnect backoff', () {
    test(
      'a server that keeps dropping us is retried further apart each time',
      () async {
        // The ladder used to be reset the instant `ready` completed, and a
        // handshake completing is not a connection working: a socket that lived
        // 5 ms satisfied it just as well as one that lived an hour. So every
        // failure was attempt number one, the delay never left its first rung,
        // and an unreachable server was dialled several times a second for as
        // long as the app stayed open.
        service = build(holdOpen: (_) => false);
        await service!.initWebSocket();

        await Future<void>.delayed(const Duration(milliseconds: 400));

        expect(
          service!.reconnectAttempts,
          greaterThan(2),
          reason: 'the counter must climb, not be reset by each handshake',
        );
        expect(dials.length, greaterThan(2));
      },
    );

    test('a connection that actually holds resets the ladder', () async {
      // The other half of the same rule: backing off forever would be just as
      // wrong. A connection that survives the stability window has proved
      // itself, and the next outage starts again from the bottom rung.
      service = build(
        holdOpen: (dial) => dial >= 3,
        stability: const Duration(milliseconds: 150),
      );
      await service!.initWebSocket();

      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(dials, hasLength(3), reason: 'two drops, then one that holds');
      expect(
        service!.reconnectAttempts,
        0,
        reason: 'the third socket held past the window',
      );
    });
  });

  group('switching server sync off', () {
    test(
      'a reconnect scheduled beforehand tears down instead of dialling',
      () async {
        // Nothing in the app calls stop() — the settings screen writes the
        // setting and that is all — so a reconnect already on the clock used to
        // bring the socket straight back up against a server the user had just
        // disconnected from, and to keep doing it. The dial itself now re-reads
        // the setting.
        service = build(
          holdOpen: (_) => false,
          base: const Duration(milliseconds: 200),
        );
        await service!.initWebSocket();
        await Future<void>.delayed(const Duration(milliseconds: 50));
        expect(
          dials,
          hasLength(1),
          reason: 'the first socket connected, then died',
        );

        await setEnabled(false);
        await Future<void>.delayed(const Duration(milliseconds: 500));

        expect(
          dials,
          hasLength(1),
          reason: 'the scheduled reconnect found the setting false and stopped',
        );
      },
    );

    test('the open socket is torn down, not just left unused', () async {
      // Nothing in lib/ calls stop() or dispose(), and the settings screen is
      // out of bounds — so the service has to notice for itself. Switching the
      // feature off used to leave a live, token-authenticated socket to the
      // server the user had just disconnected from, held open for the rest of
      // the process's life, with the periodic timer and the table-update
      // listener behind it.
      service = build(holdOpen: (_) => true);
      await service!.initAutoSync();
      await service!.initWebSocket();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(channels, hasLength(1));
      expect(channels.single.closed, isFalse);

      await setEnabled(false);
      // The next sync of any kind is the one that notices.
      await service!.sync();

      expect(
        channels.single.closed,
        isTrue,
        reason: 'the service shut its own machinery down',
      );

      final dialsAfter = dials.length;
      final requestsAfter = requests.length;

      await db.stylesDao.insertStyle(
        StylesCompanion.insert(
          name: 'Written after disconnecting',
          iconName: 'star',
          colorHex: '#123456',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 800));

      expect(
        requests.length,
        requestsAfter,
        reason: 'no traffic to a server the user disconnected from',
      );
      expect(dials.length, dialsAfter, reason: 'and no socket either');
    });
  });
}
