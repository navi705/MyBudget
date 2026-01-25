import 'package:equatable/equatable.dart';

class ApiSettingDomain extends Equatable {
  final String id;
  final bool enabled;
  final bool autoFetch;
  final DateTime? lastFetchAt;

  const ApiSettingDomain({
    required this.id,
    this.enabled = true,
    this.autoFetch = false,
    this.lastFetchAt,
  });

  @override
  List<Object?> get props => [id, enabled, autoFetch, lastFetchAt];

  ApiSettingDomain copyWith({
    String? id,
    bool? enabled,
    bool? autoFetch,
    DateTime? lastFetchAt,
  }) {
    return ApiSettingDomain(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      autoFetch: autoFetch ?? this.autoFetch,
      lastFetchAt: lastFetchAt ?? this.lastFetchAt,
    );
  }
}
