import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/data/sync_repository.dart';
import 'package:my_budget_server/http/api_responses.dart';

/// A snapshot of the whole budget from the beginning of time.
///
/// The endpoint deliberately ignores `?last_sync=`: /full means full, and
/// honouring a cursor here would hand a partial snapshot to a caller that
/// asked to start over. That also means it cannot page itself, so when the
/// snapshot does not fit in one response it says where the rest is instead of
/// only claiming there is more. `has_more` on its own was a dead end: nothing
/// a caller could vary made the second call return anything but byte-identical
/// page one, so it either looped forever or stopped believing it had the whole
/// budget.
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
      // Only when there is genuinely more: an extra key is invisible to every
      // client that does not look for it, so the wire stays compatible in
      // both directions.
      if (result.hasMore)
        'next': '/api/sync/pull?last_sync=${result.lastTimestamp}',
    });
  } catch (e, stackTrace) {
    return internalError('GET /api/sync/full', e, stackTrace);
  }
}
