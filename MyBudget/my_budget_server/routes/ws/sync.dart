import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';

Future<Response> onRequest(RequestContext context) async {
  final handler = webSocketHandler(
    (channel, protocol) {
      // A new client has connected.
      print('New websocket connection');

      channel.stream.listen(
        (message) {
          // echo
          channel.sink.add('Received: $message');
        },
        onDone: () => print('Client disconnected'),
      );
    },
  );

  return handler(context);
}
