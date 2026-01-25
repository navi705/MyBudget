import 'package:equatable/equatable.dart';

enum ApiDataType { exchange, inflation, asset }

class CustomDataSourceDomain extends Equatable {
  final String id;
  final String name;
  final String url;
  final ApiDataType dataType; // 0=exchange, 1=inflation, 2=asset
  final bool enabled;
  final bool autoFetch;
  final DateTime? lastFetchAt;

  const CustomDataSourceDomain({
    required this.id,
    required this.name,
    required this.url,
    required this.dataType,
    this.enabled = true,
    this.autoFetch = false,
    this.lastFetchAt,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    url,
    dataType,
    enabled,
    autoFetch,
    lastFetchAt,
  ];

  CustomDataSourceDomain copyWith({
    String? id,
    String? name,
    String? url,
    ApiDataType? dataType,
    bool? enabled,
    bool? autoFetch,
    DateTime? lastFetchAt,
  }) {
    return CustomDataSourceDomain(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      dataType: dataType ?? this.dataType,
      enabled: enabled ?? this.enabled,
      autoFetch: autoFetch ?? this.autoFetch,
      lastFetchAt: lastFetchAt ?? this.lastFetchAt,
    );
  }
}
