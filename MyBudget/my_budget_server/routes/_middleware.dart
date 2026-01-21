import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/data/database_client.dart';
import 'package:my_budget_server/data/sync_repository.dart';

final _dbClient = DatabaseClient();
final _syncRepo = SyncRepository(_dbClient);
// Start schema check on startup (fire and forget for now, or await in a wrapper if critical)
final _schemaFuture = _dbClient.ensureSchema();

Handler middleware(Handler handler) {
  return handler
      .use(requestLogger())
      .use(provider<SyncRepository>((_) => _syncRepo))
      .use(provider<DatabaseClient>((_) => _dbClient));
}
