import 'dart:async';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:my_budget_server/ws/sync_controller.dart';

Future<Response> onRequest(RequestContext context) async {
  // Identifies the connecting device so it can be skipped when it is itself the
  // source of a push. TODO: the current client does not send this yet — it
  // connects to a bare /ws/sync — so it stays null and echo suppression is
  // inert until the client appends ?device_id=<local_device_id>.
  final deviceId = context.request.uri.queryParameters['device_id'];

  final handler = webSocketHandler(
    (channel, protocol) async {
      print('[WS_DEBUG] Handler started, protocol=$protocol');

      // Register new client
      SyncWebSocketController.addClient(channel, deviceId: deviceId);

      // Use a Completer to keep this callback alive until the stream closes.
      // This is more robust than `await for` in case dart_frog_web_socket
      // does not properly await the async callback before returning a Response.
      final completer = Completer<void>();

      print('[WS_DEBUG] Setting up stream listener...');

      channel.stream.listen(
        (message) {
          print('[WS_DEBUG] Message received: $message');
          if (message == 'ping') {
            // Respond to client heartbeat
            try {
              channel.sink.add('pong');
            } catch (e) {
              print('[WS_DEBUG] Pong send error: $e');
            }
          } else {
            print('[WS] Received message: $message');
          }
        },
        onDone: () {
          print('[WS_DEBUG] Stream done (client disconnected)');
          SyncWebSocketController.removeClient(channel);
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object e) {
          print('[WS_DEBUG] Stream error: $e');
          print('[WS] Client stream error: $e');
          SyncWebSocketController.removeClient(channel);
          if (!completer.isCompleted) completer.complete();
        },
        cancelOnError: true,
      );

      print('[WS_DEBUG] Awaiting completer (keeping handler alive)...');
      await completer.future;
      print('[WS_DEBUG] Completer done, handler exiting');
    },
  );

  return handler(context);
}
