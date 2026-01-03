import 'package:equatable/equatable.dart';

class AssetDataDomain extends Equatable {
  final String? id;
  final String assetId;
  final String name; // Added
  final DateTime date;
  final double value;
  final double quantity;
  final String? assetType;
  final String? description;
  final int preset;

  const AssetDataDomain({
    this.id,
    required this.assetId,
    required this.name, // Added
    required this.date,
    required this.value,
    this.quantity = 1.0,
    this.assetType,
    this.description,
    this.preset = 1,
  });

  @override
  List<Object?> get props => [
    id,
    assetId,
    name, // Added
    date,
    value,
    quantity,
    assetType,
    description,
    preset,
  ];

  AssetDataDomain copyWith({
    String? id,
    String? assetId,
    String? name, // Added
    DateTime? date,
    double? value,
    double? quantity,
    String? assetType,
    String? description,
    int? preset,
  }) {
    return AssetDataDomain(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      name: name ?? this.name, // Added
      date: date ?? this.date,
      value: value ?? this.value,
      quantity: quantity ?? this.quantity,
      assetType: assetType ?? this.assetType,
      description: description ?? this.description,
      preset: preset ?? this.preset,
    );
  }
}
