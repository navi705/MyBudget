class Style {
  final String? id;
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
    String? id,
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
