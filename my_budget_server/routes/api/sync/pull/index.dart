import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/data/sync_repository.dart';
import 'package:my_budget_server/http/api_responses.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final params = context.request.uri.queryParameters;
  final lastSync = parseLastSync(params['last_sync']);

  final repo = context.read<SyncRepository>();

  try {
    final limit = parsePullLimit(params['limit']);

    final result = await repo.getChanges(lastSync, limit: limit);

    return Response.json(body: {
      'changes': result.changes,
      'server_timestamp': result.lastTimestamp,
      'has_more': result.hasMore,
    });
  } catch (e, stackTrace) {
    return internalError('GET /api/sync/pull', e, stackTrace);
  }
}
