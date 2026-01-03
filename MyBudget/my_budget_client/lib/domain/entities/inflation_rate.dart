import 'package:equatable/equatable.dart';

class InflationRateDomain extends Equatable {
  final String? country;
  final int preset;
  final double percent;
  final DateTime date;

  const InflationRateDomain({
    this.country,
    required this.preset,
    required this.percent,
    required this.date,
  });

  @override
  List<Object?> get props => [country, preset, percent, date];

  InflationRateDomain copyWith({
    String? country,
    int? preset,
    double? percent,
    DateTime? date,
  }) {
    return InflationRateDomain(
      country: country ?? this.country,
      preset: preset ?? this.preset,
      percent: percent ?? this.percent,
      date: date ?? this.date,
    );
  }
}
