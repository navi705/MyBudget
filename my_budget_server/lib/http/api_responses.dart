import 'dart:io';

import 'package:dart_frog/dart_frog.dart';

/// Largest page a client may ask for on `/api/sync/pull`.
///
/// The pull runs one `SELECT ... LIMIT @limit` per table and awaits them all
/// together, so the limit is multiplied by the number of tables before any of
/// it is mapped into Dart objects. An unclamped `?limit=` therefore let any
/// caller size the server's peak memory for it.
const int maxPullLimit = 5000;

/// Page size used when the client does not ask for one.
const int defaultPullLimit = 5000;

/// Reads a client-supplied `?limit=` into a usable page size.
///
/// Missing or unparseable falls back to [defaultPullLimit]. Anything else is
/// clamped into `1..maxPullLimit`. Zero and negatives are clamped rather than
/// rejected: `LIMIT 0` returns no rows and no `has_more`, which the client
/// reads as "fully synced" and stops — a silent, permanent stall is a worse
/// answer to a bad parameter than a small page is.
int parsePullLimit(String? raw) {
  if (raw == null) return defaultPullLimit;
  final parsed = int.tryParse(raw);
  if (parsed == null) return defaultPullLimit;
  if (parsed < 1) return 1;
  if (parsed > maxPullLimit) return maxPullLimit;
  return parsed;
}

/// Reads a client-supplied `?last_sync=` cursor in epoch milliseconds.
///
/// Missing, unparseable or negative all mean "from the beginning". A negative
/// cursor is not an error the client can act on — every row is newer than it,
/// so it already behaves as 0.
int parseLastSync(String? raw) {
  if (raw == null) return 0;
  final parsed = int.tryParse(raw);
  if (parsed == null || parsed < 0) return 0;
  return parsed;
}

/// A 500 that tells the caller the request failed and nothing else.
///
/// The routes used to return `e.toString()` in the body. A `postgres`
/// exception's message carries the failing SQL, the column and constraint
/// names, and on a connection failure the host and user it tried — the whole
/// schema, handed to anyone who can provoke an error. The detail belongs in
/// the server log, where the operator reads it, not in the response.
Response internalError(String route, Object error, StackTrace stackTrace) {
  print('[ERROR] $route: $error\n$stackTrace');
  return Response.json(
    statusCode: HttpStatus.internalServerError,
    body: {
      'error': 'internal_error',
      'message': 'The request could not be completed. '
          'See the server log for details.',
    },
  );
}
