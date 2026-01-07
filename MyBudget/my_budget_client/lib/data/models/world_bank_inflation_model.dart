import 'package:json_annotation/json_annotation.dart';

part 'world_bank_inflation_model.g.dart';

@JsonSerializable()
class WorldBankInflationResponse {
  final List<InflationDataPoint> data;

  WorldBankInflationResponse({required this.data});

  factory WorldBankInflationResponse.fromJson(List<dynamic> json) {
    if (json.length > 1) {
      final dataPoints = (json[1] as List<dynamic>)
          .map((e) => InflationDataPoint.fromJson(e as Map<String, dynamic>))
          .toList();
      return WorldBankInflationResponse(data: dataPoints);
    }
    return WorldBankInflationResponse(data: []);
  }
}

@JsonSerializable()
class InflationDataPoint {
  final String date;
  final double? value;

  InflationDataPoint({required this.date, this.value});

  factory InflationDataPoint.fromJson(Map<String, dynamic> json) =>
      _$InflationDataPointFromJson(json);

  Map<String, dynamic> toJson() => _$InflationDataPointToJson(this);
}
