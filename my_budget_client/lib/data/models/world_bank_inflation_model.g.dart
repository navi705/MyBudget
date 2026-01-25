// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world_bank_inflation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InflationDataPoint _$InflationDataPointFromJson(Map<String, dynamic> json) =>
    InflationDataPoint(
      date: json['date'] as String,
      value: (json['value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$InflationDataPointToJson(InflationDataPoint instance) =>
    <String, dynamic>{'date': instance.date, 'value': instance.value};
