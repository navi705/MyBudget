import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/data/database_client.dart';
import 'package:my_budget_server/data/sync_repository.dart';

final _dbClient = DatabaseClient();
final _syncRepo = SyncRepository(_dbClient);

// Shared Future to track schema initialization.
Future<void>? _initFuture;

Handler middleware(Handler handler) {
  return (context) async {
    // Ensure schema is created before any request is handled.
    // Use the global dbClient to run initialization if it hasn't started yet.
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
