import 'package:web_socket_channel/web_socket_channel.dart';

/// Controller to manage active WebSocket connections for synchronization notifications.
class SyncWebSocketController {
  /// Track connected clients.
  static final Set<WebSocketChannel> _clients = {};

  /// Add a client to the registry.
  static void addClient(WebSocketChannel channel) {
    _clients.add(channel);
    print('[WS] Client added. Total clients: ${_clients.length}');
  }

  /// Remove a client from the registry.
  static void removeClient(WebSocketChannel channel) {
    _clients.remove(channel);
    print('[WS] Client removed. Total clients: ${_clients.length}');
  }

  /// Broadcast a notification to all connected clients.
  static void broadcast(String message) {
    print('[WS] Broadcasting: $message to ${_clients.length} clients');
    for (final client in _clients) {
      try {
        client.sink.add(message);
      } catch (e) {
        print('[WS] Error broadcasting to client: $e');
      }
    }
  }

  /// Convenience method to notify clients that new sync data is available.
  static void notifySyncAvailable() {
    broadcast('sync_available');
  }
}
