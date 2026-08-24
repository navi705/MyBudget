import 'package:json_annotation/json_annotation.dart';

part 'world_bank_inflation_model.g.dart';

class WorldBankInflationResponse {
  final List<InflationDataPoint> data;

  WorldBankInflationResponse({required this.data});

  /// Reads a World Bank answer, which is `[header, rows]`.
  ///
  /// Every level is checked instead of cast. The answer is not always the
  /// shape the happy path assumes: the API replies `[header, null]` for a
  /// country and date range it has no series for, and replies with a message
  /// object for an indicator or country code it does not know. Both used to
  /// come back as a `TypeError` from inside this factory, wrapped by the
  /// caller into 'Failed to fetch inflation data', which reads like the
  /// network was down rather than like there is nothing to fetch.
  ///
  /// A row that cannot be read is skipped rather than taken as the end of the
  /// series: twenty-five years of inflation are worth more than the one row
  /// that arrived undated.
  factory WorldBankInflationResponse.fromJson(dynamic json) {
    if (json is! List || json.length < 2) {
      return WorldBankInflationResponse(data: []);
    }
    final rows = json[1];
    if (rows is! List) {
      return WorldBankInflationResponse(data: []);
    }
    final dataPoints = <InflationDataPoint>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      if (row['date'] is! String) continue;
      // A missing reading is a real answer - the series has gaps - but one
      // rendered as anything but a number is not a reading this can use.
      final value = row['value'];
      if (value != null && value is! num) continue;
      dataPoints.add(InflationDataPoint.fromJson(row));
    }
    return WorldBankInflationResponse(data: dataPoints);
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
