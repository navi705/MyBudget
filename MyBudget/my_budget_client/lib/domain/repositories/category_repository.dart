import 'dart:convert';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/category_with_total.dart';

import 'package:my_budget_client/domain/entities/category_type.dart';

class CategoryFilters extends Equatable {
  final Sort sort;
  final String? name;
  final double? amountFrom;
  final double? amountTo;
  final CategoryType? type;

  const CategoryFilters({
    this.sort = Sort.ascending,
    this.name,
    this.amountFrom,
    this.amountTo,
    this.type,
  });

  CategoryFilters copyWith({
    Sort? sort,
    String? name,
    double? amountFrom,
    double? amountTo,
    CategoryType? type,
  }) {
    return CategoryFilters(
      sort: sort ?? this.sort,
      name: name ?? this.name,
      amountFrom: amountFrom ?? this.amountFrom,
      amountTo: amountTo ?? this.amountTo,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sort': sort.index,
      'name': name,
      'amountFrom': amountFrom,
      'amountTo': amountTo,
      'type': type?.index,
    };
  }

  factory CategoryFilters.fromJson(Map<String, dynamic> map) {
    return CategoryFilters(
      sort: Sort.values[map['sort'] ?? 0],
      name: map['name'],
      amountFrom: map['amountFrom'],
      amountTo: map['amountTo'],
      type: map['type'] != null ? CategoryType.values[map['type']] : null,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory CategoryFilters.fromJsonString(String source) =>
      CategoryFilters.fromJson(json.decode(source));

  @override
  List<Object?> get props => [sort, name, amountFrom, amountTo, type];
}

abstract class CategoryRepository {
  Stream<List<Category>> watchCategories();
  Future<List<Category>> getCategories();
  Future<List<Category>> getCategoriesPaginated({
    int limit = 10,
    int offset = 0,
  });
  Future<List<CategoryWithTotal>> getCategoriesWithTotalsPaginated({
    int limit = 50,
    int offset = 0,
    CategoryFilters filters = const CategoryFilters(),
    DateTime? dateFrom,
    DateTime? dateTo,
  });
  Future<Category?> getCategoryById(String id);
  Future<List<Category>> getCategoriesByIds(List<String> ids);
  Future<void> addCategory(Category category);
  Future<void> addCategories(List<Category> categories);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);
  Future<void> deleteCategoryWithTransactions(String categoryId);
  Future<void> deleteCategoryAndReassignTransactions(
    String categoryId,
    String newCategoryId,
  );
}
