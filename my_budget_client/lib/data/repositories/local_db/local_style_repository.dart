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
    return database.stylesDao.watchAllStyles().map(
      (styles) => styles.toDomainList(),
    );
  }

  @override
  Future<Style?> getStyleById(String id) async {
    final styleData = await database.stylesDao.getStyleById(id);
    return styleData?.toDomain();
  }

  @override
  Future<void> addStyle(Style style) async {
    await database.stylesDao.insertStyle(style.toCompanion());
  }

  @override
  Future<void> addStyles(List<Style> styles) async {
    await database.stylesDao.insertAllStyles(styles.toCompanionList());
  }

  @override
  Future<void> updateStyle(Style style) async {
    await database.stylesDao.updateStyle(style.toCompanion());
  }

  @override
  Future<void> deleteStyle(String id) async {
    await database.stylesDao.deleteStyle(db.StylesCompanion(id: Value(id)));
  }
  
  @override
  Future<List<Style>> getStylesByIds(List<String> ids) async{
    final styles = await  database.stylesDao.getStylesByIds(ids);
    return styles.toDomainList();
  }
}
