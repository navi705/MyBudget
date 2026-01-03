import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';

abstract class AssetState extends Equatable {
  const AssetState();

  @override
  List<Object?> get props => [];
}

class AssetInitial extends AssetState {}

class AssetLoadInProgress extends AssetState {}

class AssetLoadSuccess extends AssetState {
  final List<AssetDataDomain> assetData;
  const AssetLoadSuccess(this.assetData);

  @override
  List<Object?> get props => [assetData];
}

class AssetFailure extends AssetState {
  final String message;
  const AssetFailure(this.message);

  @override
  List<Object?> get props => [message];
}
