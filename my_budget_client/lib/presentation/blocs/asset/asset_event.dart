import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';

abstract class AssetEvent extends Equatable {
  const AssetEvent();

  @override
  List<Object?> get props => [];
}

class LoadAssetData extends AssetEvent {
  final String? assetId;
  const LoadAssetData({this.assetId});
  @override
  List<Object?> get props => [assetId];
}

class LoadMoreAssetData extends AssetEvent {
  final String? assetId;
  const LoadMoreAssetData({this.assetId});
  @override
  List<Object?> get props => [assetId];
}

class ChangeAssetDateStep extends AssetEvent {
  final DateStep dateStep;
  const ChangeAssetDateStep(this.dateStep);
  @override
  List<Object?> get props => [dateStep];
}

class ChangeAssetFilterMode extends AssetEvent {
  final FilterMode filterMode;
  const ChangeAssetFilterMode(this.filterMode);
  @override
  List<Object?> get props => [filterMode];
}

class ChangeAssetActiveDate extends AssetEvent {
  final DateTime date;
  const ChangeAssetActiveDate(this.date);
  @override
  List<Object?> get props => [date];
}

class ChangeAssetActiveDateRange extends AssetEvent {
  final DateTimeRange dateRange;
  const ChangeAssetActiveDateRange(this.dateRange);
  @override
  List<Object?> get props => [dateRange];
}

class ChangeAssetSort extends AssetEvent {
  final Sort sort;
  const ChangeAssetSort(this.sort);
  @override
  List<Object?> get props => [sort];
}

class ChangeAssetFilters extends AssetEvent {
  final String? assetId;
  final String? name;
  final List<String>? assetTypes;
  final String? description;
  final List<String>? currencyCodes;
  final List<String>? sources;
  final List<int>? presets;
  final double? minValue;
  final double? maxValue;

  const ChangeAssetFilters({
    this.assetId,
    this.name,
    this.assetTypes,
    this.description,
    this.currencyCodes,
    this.sources,
    this.presets,
    this.minValue,
    this.maxValue,
  });

  @override
  List<Object?> get props => [
    assetId,
    name,
    assetTypes,
    description,
    currencyCodes,
    sources,
    presets,
    minValue,
    maxValue,
  ];
}

class AddAssetData extends AssetEvent {
  final AssetDataDomain data;
  const AddAssetData(this.data);
  @override
  List<Object?> get props => [data];
}

class UpdateAssetData extends AssetEvent {
  final AssetDataDomain data;
  const UpdateAssetData(this.data);
  @override
  List<Object?> get props => [data];
}

class DeleteAssetData extends AssetEvent {
  final String id;
  const DeleteAssetData(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleAssetSelection extends AssetEvent {
  final AssetDataDomain asset;
  const ToggleAssetSelection(this.asset);
  @override
  List<Object?> get props => [asset];
}

class SelectAllAssets extends AssetEvent {}

class DeselectAllAssets extends AssetEvent {}

class DeleteSelectedAssets extends AssetEvent {}

class AssetDataUpdated extends AssetEvent {
  final List<AssetDataDomain> data;
  const AssetDataUpdated(this.data);
  @override
  List<Object?> get props => [data];
}
