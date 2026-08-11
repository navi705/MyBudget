import 'package:web_socket_channel/web_socket_channel.dart';

/// Controller to manage active WebSocket connections for synchronization notifications.
class SyncWebSocketController {
  /// Track connected clients.
  static final Set<WebSocketChannel> _clients = {};

  /// Device id each client identified itself with, when it supplied one.
  /// Used to keep a device from being told about its own push.
  static final Map<WebSocketChannel, String> _deviceIds = {};

  /// Add a client to the registry.
  ///
  /// [deviceId] is the connecting device's own id when it sent one; without it
  /// the client simply cannot be excluded from its own broadcasts.
  static void addClient(WebSocketChannel channel, {String? deviceId}) {
    _clients.add(channel);
    if (deviceId != null && deviceId.isNotEmpty) {
      _deviceIds[channel] = deviceId;
    }
    print(
        '[WS] Client added (deviceId: ${deviceId ?? 'unknown'}). Total clients: ${_clients.length}');
  }

  /// Remove a client from the registry.
  static void removeClient(WebSocketChannel channel) {
    _clients.remove(channel);
    _deviceIds.remove(channel);
    print('[WS] Client removed. Total clients: ${_clients.length}');
  }

  /// Broadcast a notification to all connected clients.
  ///
  /// [excludeDeviceId], when given, skips the clients registered under that
  /// device id — the device that caused the change already has the data.
  static void broadcast(String message, {String? excludeDeviceId}) {
    // Iterate a copy: a failing sink can disconnect the client, and the
    // resulting removeClient() would mutate _clients mid-iteration.
    final targets = _clients.toList();
    print('[WS] Broadcasting: $message to ${targets.length} clients'
        '${excludeDeviceId != null ? ' (excluding device $excludeDeviceId)' : ''}');
    for (final client in targets) {
      if (excludeDeviceId != null && _deviceIds[client] == excludeDeviceId) {
        continue;
      }
      try {
        client.sink.add(message);
      } catch (e) {
        print('[WS] Error broadcasting to client: $e');
      }
    }
  }

  /// Convenience method to notify clients that new sync data is available.
  ///
  /// [originDeviceId] is the device whose push triggered this; it is skipped so
  /// it does not echo-pull the data it just sent.
  static void notifySyncAvailable({String? originDeviceId}) {
    broadcast('sync_available', excludeDeviceId: originDeviceId);
  }
}
