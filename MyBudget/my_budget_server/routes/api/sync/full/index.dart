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
    final data = await repo.getChanges(0);

    return Response.json(body: {
      'data': data,
      'server_timestamp': DateTime.now().millisecondsSinceEpoch
    });
  } catch (e) {
    return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'error': e.toString()});
  }
}
