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

    // The shape below this level used to be taken on trust: upsertBatch casts
    // each value to List and each element to Map, so a body like
    // {"transactions": 5} came back as a 500 with a stack trace in the log.
    // A malformed body is the caller's mistake, and a client that reads 5xx as
    // "the server is having a moment" retries it on a timer forever. Unknown
    // table names are deliberately NOT rejected: upsertBatch only ever walks
    // its own allow-list, so an extra key is a newer client talking to an
    // older server, which has to keep working.
    for (final entry in body.entries) {
      final rows = entry.value;
      if (rows is! List) {
        return Response.json(
            statusCode: HttpStatus.badRequest,
            body: {'error': 'Table "${entry.key}" must be a list of rows'});
      }
      if (rows.any((row) => row is! Map<String, dynamic>)) {
        return Response.json(
            statusCode: HttpStatus.badRequest,
            body: {'error': 'Every row in "${entry.key}" must be an object'});
      }
    }

    final repo = context.read<SyncRepository>();
    // Logic to process push data
    await repo.upsertBatch(body);

    // Notify the other connected clients that new data is available.
    // The pushing device is skipped so it does not echo-pull its own write.
    //
    // The client sends the X-Device-Id header, matching the id it opens the
    // WebSocket with; the query parameter is the fallback for a browser build
    // that cannot set headers on every transport. A client that sends neither
    // still pushes fine and simply hears its own write announced back.
    // Deriving the id from the rows' deviceId is deliberately NOT done: a push
    // can legitimately carry rows written by other devices.
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
