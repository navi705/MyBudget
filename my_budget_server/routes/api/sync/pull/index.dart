import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/data/sync_repository.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final params = context.request.uri.queryParameters;
  final lastSyncStr = params['last_sync'];
  final lastSync = lastSyncStr != null ? int.tryParse(lastSyncStr) ?? 0 : 0;

  final repo = context.read<SyncRepository>();

  try {
    final limitStr = params['limit'];
    final limit = limitStr != null ? int.tryParse(limitStr) ?? 5000 : 5000;

    final result = await repo.getChanges(lastSync, limit: limit);

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
