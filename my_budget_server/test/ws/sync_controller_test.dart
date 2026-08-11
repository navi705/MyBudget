import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:my_budget_server/ws/sync_controller.dart';
import 'package:test/test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class _MockChannel extends Mock implements WebSocketChannel {}

class _MockSink extends Mock implements WebSocketSink {}

/// A client that records what was sent to it.
class _FakeClient {
  _FakeClient({this.throwsOnSend = false}) {
    when(() => channel.sink).thenReturn(sink);
    when(() => sink.add(any<dynamic>())).thenAnswer((invocation) {
      if (throwsOnSend) throw StateError('sink closed');
      received.add(invocation.positionalArguments.first as String);
    });
  }

  final _MockChannel channel = _MockChannel();
  final _MockSink sink = _MockSink();
  final List<String> received = [];
  final bool throwsOnSend;
}

/// Runs [body] with `print` silenced — the controller logs on every call.
T quietly<T>(T Function() body) => runZoned(
      body,
      zoneSpecification: ZoneSpecification(print: (_, __, ___, ____) {}),
    );

void main() {
  setUpAll(() => registerFallbackValue(''));

  // The registry is static, so every test must leave it empty.
  final registered = <_FakeClient>[];

  _FakeClient connect({String? deviceId, bool throwsOnSend = false}) {
    final client = _FakeClient(throwsOnSend: throwsOnSend);
    quietly(
      () => SyncWebSocketController.addClient(
        client.channel,
        deviceId: deviceId,
      ),
    );
    registered.add(client);
    return client;
  }

  tearDown(() {
    for (final client in registered) {
      quietly(() => SyncWebSocketController.removeClient(client.channel));
    }
    registered.clear();
  });

  group('SyncWebSocketController', () {
    test('a broadcast reaches every connected client', () {
      final a = connect(deviceId: 'phone');
      final b = connect(deviceId: 'laptop');

      quietly(SyncWebSocketController.notifySyncAvailable);

      expect(a.received, ['sync_available']);
      expect(b.received, ['sync_available']);
    });

    test('the device that pushed is not told about its own push', () {
      final pusher = connect(deviceId: 'phone');
      final other = connect(deviceId: 'laptop');

      quietly(
        () => SyncWebSocketController.notifySyncAvailable(
          originDeviceId: 'phone',
        ),
      );

      expect(pusher.received, isEmpty);
      expect(other.received, ['sync_available']);
    });

    test('a client that connected without a device id still gets notified', () {
      // Without an id it cannot be matched against the origin, so the only
      // safe behaviour is to notify it — a missed notification means its data
      // silently goes stale.
      final anonymous = connect();

      quietly(
        () => SyncWebSocketController.notifySyncAvailable(
          originDeviceId: 'phone',
        ),
      );

      expect(anonymous.received, ['sync_available']);
    });

    test('two clients on the same device id are both excluded', () {
      // Reinstalling or reopening the app can leave a stale channel behind
      // under the same id; neither should echo-pull.
      final first = connect(deviceId: 'phone');
      final second = connect(deviceId: 'phone');
      final other = connect(deviceId: 'laptop');

      quietly(
        () => SyncWebSocketController.notifySyncAvailable(
          originDeviceId: 'phone',
        ),
      );

      expect(first.received, isEmpty);
      expect(second.received, isEmpty);
      expect(other.received, ['sync_available']);
    });

    test('a removed client stops receiving broadcasts', () {
      final gone = connect(deviceId: 'phone');
      final stays = connect(deviceId: 'laptop');

      quietly(() => SyncWebSocketController.removeClient(gone.channel));
      quietly(SyncWebSocketController.notifySyncAvailable);

      expect(gone.received, isEmpty);
      expect(stays.received, ['sync_available']);
    });

    test('a client whose sink throws does not stop the others', () {
      // A disconnected socket throws on add; the loop iterates a copy so the
      // resulting cleanup cannot break the iteration either.
      final broken = connect(deviceId: 'dead', throwsOnSend: true);
      final healthy = connect(deviceId: 'alive');

      quietly(SyncWebSocketController.notifySyncAvailable);

      expect(broken.received, isEmpty);
      expect(healthy.received, ['sync_available']);
    });

    test('broadcasting with no clients connected is a no-op', () {
      expect(
        () => quietly(() => SyncWebSocketController.notifySyncAvailable()),
        returnsNormally,
      );
    });
  });
}
