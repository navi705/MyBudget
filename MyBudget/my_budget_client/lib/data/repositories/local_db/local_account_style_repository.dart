import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/account_style_mapper.dart';
import 'package:my_budget_client/domain/entities/account_style.dart';
import 'package:my_budget_client/domain/repositories/account_style_repository.dart';

class LocalAccountStyleRepository implements AccountStyleRepository {
  final db.AppDatabase database;

  LocalAccountStyleRepository(this.database);

  @override
  Stream<List<AccountStyle>> watchAllStyles() {
    return database.accountStylesDao
        .watchAllStyles()
        .map((styles) => styles.map((s) => s.toDomain()).toList());
  }

  @override
  Future<void> addStyle(AccountStyle style) async {
    await database.accountStylesDao.insertStyle(style.toCompanion());
  }

  @override
  Future<void> updateStyle(AccountStyle style) async {
    await database.accountStylesDao.updateStyle(style.toCompanion());
  }

  @override
  Future<void> deleteStyle(int id) async {
    await database.accountStylesDao.deleteStyle(
      db.AccountStylesCompanion(id: Value(id)),
    );
  }
}
