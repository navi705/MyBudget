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
    final changes = await repo.getChanges(lastSync);

    return Response.json(body: {
      'changes': changes,
      'server_timestamp': DateTime.now().millisecondsSinceEpoch
    });
  } catch (e) {
    return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': e.toString()});
  }
}
