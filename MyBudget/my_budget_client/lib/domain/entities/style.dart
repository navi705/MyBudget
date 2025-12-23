import 'package:my_budget_client/domain/entities/icon_type.dart';

class Style {
  final String? id;
  final String name;
  final String iconName;
  final String colorHex;
  final IconType iconType;

  Style({
    this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.iconType,
  });

  Style copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    IconType? iconType,
  }) {
    return Style(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      iconType: iconType ?? this.iconType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconName': iconName,
      'colorHex': colorHex,
      'iconType': iconType.name,
    };
  }
}
