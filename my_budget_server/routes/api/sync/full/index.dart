import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/data/sync_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final repo = context.read<SyncRepository>();

  try {
    // 0 implies fetch everything from the beginning of time
    final result = await repo.getChanges(0);

    return Response.json(body: {
      'changes': result.changes,
      'server_timestamp': result.lastTimestamp,
      'has_more': result.hasMore,
    });
  } catch (e) {
    return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': e.toString()});
  }
}
