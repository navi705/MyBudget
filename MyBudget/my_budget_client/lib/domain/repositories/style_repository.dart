import 'package:my_budget_client/domain/entities/style.dart';

abstract class StyleRepository {
  Stream<List<Style>> watchAllStyles();
  Future<void> addStyle(Style style);
  Future<void> updateStyle(Style style);
  Future<void> deleteStyle(String id);
}
