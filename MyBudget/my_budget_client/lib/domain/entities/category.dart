class Category {
  final int? id;
  final String name;
  final int? parentId;
  final int? styleId;

  Category({
    this.id,
    required this.name,
    this.parentId,
    this.styleId,
  });

  Category copyWith({
    int? id,
    String? name,
    int? parentId,
    int? styleId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      styleId: styleId ?? this.styleId,
    );
  }
}
