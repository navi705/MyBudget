import 'package:my_budget_client/domain/entities/style.dart';

abstract class StyleRepository {
  Stream<List<Style>> watchAllStyles();
  Future<Style?> getStyleById(String id); 
  Future<List<Style>> getStylesByIds(List<String> ids); 
  Future<void> addStyle(Style style);
  Future<void> addStyles(List<Style> styles);
  Future<void> updateStyle(Style style);
  Future<void> deleteStyle(String id);
}
