import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/mappers/theme_mapper.dart';
import 'package:my_budget_client/domain/entities/custom_theme.dart';
import 'package:my_budget_client/domain/repositories/theme_repository.dart';

class LocalThemeRepository implements ThemeRepository {
  final AppDatabase _db;

  LocalThemeRepository(this._db);

  @override
  Future<List<CustomTheme>> getAllThemes() async {
    final themes = await _db.customThemesDao.getAllThemes();
    return themes.map((e) => e.toDomain()).toList();
  }

  @override
  Future<CustomTheme?> getActiveTheme() async {
    final theme = await _db.customThemesDao.getActiveTheme();
    return theme?.toDomain();
  }

  @override
  Future<void> saveTheme(CustomTheme theme) async {
    await _db.customThemesDao.insertTheme(theme.toCompanion());
  }

  @override
  Future<void> deleteTheme(String id) async {
    await _db.customThemesDao.deleteTheme(id);
  }

  @override
  Future<void> setActiveTheme(String id) async {
    await _db.customThemesDao.setActiveTheme(id);
  }
}
