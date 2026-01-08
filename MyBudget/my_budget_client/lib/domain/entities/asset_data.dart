import 'package:equatable/equatable.dart';

class AssetDataDomain extends Equatable {
  final String? id;
  final String assetId;
  final String name;
  final DateTime date;
  final double value;
  final double quantity;
  final String? assetType;
  final String? description;
  final String currency;
  final String? accountId; // Added
  final String source;
  final int preset;

  const AssetDataDomain({
    this.id,
    required this.assetId,
    required this.name,
    required this.date,
    required this.value,
    this.quantity = 1.0,
    this.assetType,
    this.description,
    this.currency = 'EUR',
    this.accountId, // Added
    required this.source,
    this.preset = 1,
  });

  @override
  List<Object?> get props => [
    id,
    assetId,
    name,
    date,
    value,
    quantity,
    assetType,
    description,
    currency,
    accountId, // Added
    source,
    preset,
  ];

  AssetDataDomain copyWith({
    String? id,
    String? assetId,
    String? name,
    DateTime? date,
    double? value,
    double? quantity,
    String? assetType,
    String? description,
    String? currency,
    String? accountId, // Added
    String? source,
    int? preset,
  }) {
    return AssetDataDomain(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      name: name ?? this.name,
      date: date ?? this.date,
      value: value ?? this.value,
      quantity: quantity ?? this.quantity,
      assetType: assetType ?? this.assetType,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      accountId: accountId ?? this.accountId, // Added
      source: source ?? this.source,
      preset: preset ?? this.preset,
    );
  }
}
