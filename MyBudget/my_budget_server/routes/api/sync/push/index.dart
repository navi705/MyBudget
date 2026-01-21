import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/data/sync_repository.dart';

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

    return Response.json(body: {
      'success': true,
      'timestamp': DateTime.now().millisecondsSinceEpoch
    });
  } catch (e) {
    return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': e.toString()});
  }
}
