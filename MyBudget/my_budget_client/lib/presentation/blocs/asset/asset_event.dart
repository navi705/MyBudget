import 'package:equatable/equatable.dart';
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
