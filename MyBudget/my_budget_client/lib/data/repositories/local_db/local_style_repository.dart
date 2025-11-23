import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/style_mapper.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';

class LocalStyleRepository implements StyleRepository {
  final db.AppDatabase database;

  LocalStyleRepository(this.database);

  @override
  Stream<List<Style>> watchAllStyles() {
    return database.stylesDao
        .watchAllStyles()
        .map((styles) => styles.map((s) => s.toDomain()).toList());
  }

  @override
  Future<void> addStyle(Style style) async {
    await database.stylesDao.insertStyle(style.toCompanion());
  }

  @override
  Future<void> updateStyle(Style style) async {
    await database.stylesDao.updateStyle(style.toCompanion());
  }

  @override
  Future<void> deleteStyle(String id) async {
    await database.stylesDao.deleteStyle(
      db.StylesCompanion(id: Value(id)),
    );
  }
}
