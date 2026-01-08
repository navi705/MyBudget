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
  const ChangeAssetFilters({this.assetId});
  @override
  List<Object?> get props => [assetId];
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
