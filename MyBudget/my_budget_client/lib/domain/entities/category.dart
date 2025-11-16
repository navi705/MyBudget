class Category {
  final int? id;
  final String name;
  final int? parentId;

  Category({
    this.id,
    required this.name,
    this.parentId,
  });

  Category copyWith({
    int? id,
    String? name,
    int? parentId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
    );
  }
}
