import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/core/mappers/category_mapper.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart'
    as domain;

extension CategoryWithTotalMapper on drift.CategoryWithTotal {
  domain.CategoryWithTotal toDomain() {
    return domain.CategoryWithTotal(
      category: category.toDomain(),
      total: total,
    );
  }
}

extension CategoryWithTotalListMapper on List<drift.CategoryWithTotal> {
  List<domain.CategoryWithTotal> toDomainList() {
    return map((e) => e.toDomain()).toList();
  }
}
