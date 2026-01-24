import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:my_budget_server/ws/sync_controller.dart';

Future<Response> onRequest(RequestContext context) async {
  final handler = webSocketHandler(
    (channel, protocol) {
      // Register new client
      SyncWebSocketController.addClient(channel);

      channel.stream.listen(
        (message) {
          // Could handle specific client messages here if needed
          print('[WS] Received message: $message');
        },
        onDone: () {
          // Cleanup on disconnect
          SyncWebSocketController.removeClient(channel);
        },
      );
    },
  );

  return handler(context);
}
