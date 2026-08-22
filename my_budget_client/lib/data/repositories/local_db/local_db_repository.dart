import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/data/repositories/db_repository.dart';

class LocalDbRepository implements DbRepository {
  final db.AppDatabase database;

  LocalDbRepository(this.database);

  @override
  Future<void> clearAllDatabase() {
    return database.clearAllData();
  }

  @override
  Future<void> batch(Function(Batch) action) {
    return database.batch(action);
  }
}
