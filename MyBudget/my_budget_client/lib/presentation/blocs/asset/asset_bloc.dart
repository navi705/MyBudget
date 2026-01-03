import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/utils/performance_logger.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'asset_event.dart';
import 'asset_state.dart';

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  final AssetRepository _repository;

  AssetBloc(this._repository) : super(AssetInitial()) {
    on<LoadAssetData>(_onLoadAssetData);
    on<AddAssetData>(_onAddAssetData);
    on<UpdateAssetData>(_onUpdateAssetData);
    on<DeleteAssetData>(_onDeleteAssetData);
  }

  Future<void> _onLoadAssetData(
    LoadAssetData event,
    Emitter<AssetState> emit,
  ) async {
    PerformanceLogger().start('Asset Data Load');
    emit(AssetLoadInProgress());
    try {
      final data = await _repository.getAssetData(assetId: event.assetId);
      await PerformanceLogger().stop('Asset Data Load');
      emit(AssetLoadSuccess(data));
    } catch (e) {
      PerformanceLogger().stop('Asset Data Load');
      emit(AssetFailure(e.toString()));
    }
  }

  Future<void> _onAddAssetData(
    AddAssetData event,
    Emitter<AssetState> emit,
  ) async {
    try {
      await _repository.addAssetData(event.data);
      add(LoadAssetData(assetId: event.data.assetId));
    } catch (e) {
      emit(AssetFailure(e.toString()));
    }
  }

  Future<void> _onUpdateAssetData(
    UpdateAssetData event,
    Emitter<AssetState> emit,
  ) async {
    try {
      await _repository.updateAssetData(event.data);
      add(LoadAssetData(assetId: event.data.assetId));
    } catch (e) {
      emit(AssetFailure(e.toString()));
    }
  }

  Future<void> _onDeleteAssetData(
    DeleteAssetData event,
    Emitter<AssetState> emit,
  ) async {
    try {
      await _repository.deleteAssetData(event.id);
      add(const LoadAssetData());
    } catch (e) {
      emit(AssetFailure(e.toString()));
    }
  }
}
