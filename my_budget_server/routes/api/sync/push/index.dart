import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/data/sync_repository.dart';
import 'package:my_budget_server/http/api_responses.dart';
import 'package:my_budget_server/ws/sync_controller.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  try {
    final body = await context.request.json();
    if (body is! Map<String, dynamic>) {
      return Response.json(
          statusCode: HttpStatus.badRequest,
          body: {'error': 'Invalid body format'});
    }

    final repo = context.read<SyncRepository>();
    // Logic to process push data
    await repo.upsertBatch(body);

    // Notify the other connected clients that new data is available.
    // The pushing device is skipped so it does not echo-pull its own write.
    //
    // TODO(sync): the client does not identify itself on push yet — the body
    // is a bare {table: [rows]} map with no top-level device id and the request
    // carries no such header. Until it sends one (an X-Device-Id header or a
    // ?device_id= query parameter, matching the id it connects the WebSocket
    // with), this stays null and every client is notified as before.
    // Deriving it from the rows' deviceId is deliberately NOT done: a push can
    // legitimately carry rows written by other devices.
    final originDeviceId = context.request.headers['X-Device-Id'] ??
        context.request.uri.queryParameters['device_id'];

    SyncWebSocketController.notifySyncAvailable(
      originDeviceId: originDeviceId,
    );

    return Response.json(body: {
      'success': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  } catch (e, stackTrace) {
    return internalError('POST /api/sync/push', e, stackTrace);
  }
}
