class AccountStyle {
  final int? id;
  final String name;
  final String iconName;
  final String colorHex;

  AccountStyle({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
  });

  AccountStyle copyWith({
    int? id,
    String? name,
    String? iconName,
    String? colorHex,
  }) {
    return AccountStyle(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
