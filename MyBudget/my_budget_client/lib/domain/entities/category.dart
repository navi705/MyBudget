import 'package:my_budget_client/domain/entities/category_type.dart';

class Category {
  final int? id;
  final String name;
  final int? parentId;
  final int? styleId;
  final CategoryType type;

  Category({
    this.id,
    required this.name,
    this.parentId,
    this.styleId,
    this.type = CategoryType.expense,
  });

  Category copyWith({
    int? id,
    String? name,
    int? parentId,
    int? styleId,
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
