import 'package:my_budget_client/domain/entities/category_type.dart';

class Category {
  final String? id;
  final String name;
  final String? parentId;
  final String? styleId;
  final CategoryType type;

  Category({
    this.id,
    required this.name,
    this.parentId,
    this.styleId,
    this.type = CategoryType.expense,
  });

  Category copyWith({
    String? id,
    String? name,
    String? parentId,
    String? styleId,
    CategoryType? type,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      styleId: styleId ?? this.styleId,
      type: type ?? this.type,
    );
  }
}
