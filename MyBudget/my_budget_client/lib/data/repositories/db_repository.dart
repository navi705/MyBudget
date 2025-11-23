import 'package:drift/drift.dart';

abstract class DbRepository {
  Future<void> clearAllDatabase();
  Future<void> batch(Function(Batch) action);
}