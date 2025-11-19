class Style {
  final int? id;
  final String name;
  final String iconName;
  final String colorHex;

  Style({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
  });

  Style copyWith({
    int? id,
    String? name,
    String? iconName,
    String? colorHex,
  }) {
    return Style(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
