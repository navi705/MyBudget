import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/auth/bearer_auth.dart';
import 'package:my_budget_server/data/database_client.dart';
import 'package:my_budget_server/data/sync_repository.dart';

final _dbClient = DatabaseClient();
final _syncRepo = SyncRepository(_dbClient);
final _auth = BearerAuth.fromEnvironment();

// Shared Future to track schema initialization.
Future<void>? _initFuture;

// Logged once per process rather than per request, so a misconfigured server
// is obvious at startup without drowning the log.
bool _warnedMissingToken = false;

/// Paths that carry budget data and therefore require the shared token.
/// `/` stays open as a liveness probe: it returns a fixed string and reads
/// nothing from the database.
bool _requiresAuth(Uri uri) {
  final path = uri.path;
  return path.startsWith('/api') || path.startsWith('/ws');
}

Handler middleware(Handler handler) {
  return (context) async {
    final request = context.request;

    if (_requiresAuth(request.uri)) {
      // The `token` query parameter is accepted for the WebSocket route only.
      // A browser's WebSocket API cannot set an Authorization header, so the
      // web build has no alternative; on the HTTP routes a token in the URL
      // would be copied into every access log and proxy log.
      final isWebSocket = request.uri.path.startsWith('/ws');
      final result = _auth.check(
        authorizationHeader: request.headers['authorization'],
        queryToken:
            isWebSocket ? request.uri.queryParameters['token'] : null,
      );

      switch (result) {
        case AuthResult.notConfigured:
          if (!_warnedMissingToken) {
            _warnedMissingToken = true;
            print('[AUTH] ${BearerAuth.setupHint}');
          }
          // 503, not 401: the client's credentials are not the problem and
          // retrying with a different token will not help. The operator has
          // to act.
          return Response.json(
            statusCode: 503,
            body: {
              'error': 'server_not_configured',
              'message': BearerAuth.setupHint,
            },
          );
        case AuthResult.denied:
          return Response.json(
            statusCode: 401,
            headers: {'www-authenticate': 'Bearer realm="my_budget_sync"'},
            body: {
              'error': 'unauthorized',
              'message': 'Missing or invalid sync token.',
            },
          );
        case AuthResult.ok:
          break;
      }
    }

    // Ensure schema is created before any request is handled.
    // Use the global dbClient to run initialization if it hasn't started yet.
    // Deliberately after the auth check: an unauthenticated caller must not be
    // able to make the server open database connections or run DDL.
    _initFuture ??= _dbClient.ensureSchema();

    try {
      await _initFuture;
    } catch (e) {
      _initFuture = null; // Allow retry on next request
      return Response.json(
        statusCode: 500,
        body: {'error': 'Database initialization failed: $e'},
      );
    }

    final innerHandler = handler
        .use(requestLogger())
        .use(provider<SyncRepository>((_) => _syncRepo))
        .use(provider<DatabaseClient>((_) => _dbClient));

    return innerHandler(context);
  };
}
