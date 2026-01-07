// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_bank_inflation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorldBankInflationResponse _$WorldBankInflationResponseFromJson(
  Map<String, dynamic> json,
) => WorldBankInflationResponse(
  data: (json['data'] as List<dynamic>)
      .map((e) => InflationDataPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WorldBankInflationResponseToJson(
  WorldBankInflationResponse instance,
) => <String, dynamic>{'data': instance.data};

InflationDataPoint _$InflationDataPointFromJson(Map<String, dynamic> json) =>
    InflationDataPoint(
      date: json['date'] as String,
      value: (json['value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$InflationDataPointToJson(InflationDataPoint instance) =>
    <String, dynamic>{'date': instance.date, 'value': instance.value};
