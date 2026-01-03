import 'package:my_budget_client/domain/entities/custom_theme.dart';

abstract class ThemeRepository {
  Future<List<CustomTheme>> getAllThemes();
  Future<CustomTheme?> getActiveTheme();
  Future<void> saveTheme(CustomTheme theme);
  Future<void> deleteTheme(String id);
  Future<void> setActiveTheme(String id);
}
