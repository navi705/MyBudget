import 'package:bloc/bloc.dart';

import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'asset_event.dart';
import 'asset_state.dart';

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  final AssetRepository _repository;

  AssetBloc(this._repository)
    : super(
        AssetState(
          activeDate: DateTime(
            DateTime.now().year,
            DateTime.now().month,
            DateTime.now().day,
          ),
        ),
      ) {
    on<LoadAssetData>(_onLoadAssetData);
    on<LoadMoreAssetData>(_onLoadMoreAssetData);
    on<ChangeAssetDateStep>(_onChangeDateStep);
    on<ChangeAssetFilterMode>(_onChangeFilterMode);
    on<ChangeAssetActiveDate>(_onChangeActiveDate);
    on<ChangeAssetActiveDateRange>(_onChangeActiveDateRange);
    on<ChangeAssetSort>(_onChangeSort);
    on<ChangeAssetFilters>(_onChangeFilters);
    on<AddAssetData>(_onAddAssetData);
    on<UpdateAssetData>(_onUpdateAssetData);
    on<DeleteAssetData>(_onDeleteAssetData);
  }

  Future<void> _onLoadAssetData(
    LoadAssetData event,
    Emitter<AssetState> emit,
  ) async {
    emit(state.copyWith(status: AssetStatus.loading, offset: 0, assetData: []));
    try {
      final (dateFrom, dateTo) = _getDateRange();

      // Update selectedAssetId if provided in event, otherwise keep current state
      if (event.assetId != null) {
        emit(state.copyWith(selectedAssetId: event.assetId));
      }

      final count = await _repository.getAssetDataCount(
        assetId: event.assetId ?? state.selectedAssetId,
        startDate: dateFrom,
        endDate: dateTo,
        name: state.nameFilter,
        assetTypes: state.assetTypeFilters,
        description: state.descriptionFilter,
        currencyCodes: state.currencyCodeFilters,
        sources: state.sourceFilters,
        presets: state.presetFilters,
        minValue: state.minValueFilter,
        maxValue: state.maxValueFilter,
      );

      final data = await _repository.getAssetData(
        limit: state.limit,
        offset: 0,
        assetId: event.assetId ?? state.selectedAssetId,
        startDate: dateFrom,
        endDate: dateTo,
        name: state.nameFilter,
        assetTypes: state.assetTypeFilters,
        description: state.descriptionFilter,
        currencyCodes: state.currencyCodeFilters,
        sources: state.sourceFilters,
        presets: state.presetFilters,
        minValue: state.minValueFilter,
        maxValue: state.maxValueFilter,
        sortAscending: state.sort == Sort.ascending,
      );

      emit(
        state.copyWith(
          status: AssetStatus.success,
          assetData: data,
          offset: data.length,
          hasMore: data.length == state.limit,
          totalCount: count,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(status: AssetStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onLoadMoreAssetData(
    LoadMoreAssetData event,
    Emitter<AssetState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final (dateFrom, dateTo) = _getDateRange();

      final data = await _repository.getAssetData(
        limit: state.limit,
        offset: state.offset,
        assetId: event.assetId,
        startDate: dateFrom,
        endDate: dateTo,
        name: state.nameFilter,
        assetTypes: state.assetTypeFilters,
        description: state.descriptionFilter,
        currencyCodes: state.currencyCodeFilters,
        sources: state.sourceFilters,
        presets: state.presetFilters,
        minValue: state.minValueFilter,
        maxValue: state.maxValueFilter,
        sortAscending: state.sort == Sort.ascending,
      );

      emit(
        state.copyWith(
          assetData: [...state.assetData, ...data],
          offset: state.offset + data.length,
          hasMore: data.length == state.limit,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AssetStatus.failure,
          errorMessage: e.toString(),
          isLoadingMore: false,
        ),
      );
    }
  }

  (DateTime?, DateTime?) _getDateRange() {
    if (state.filterMode == FilterMode.range) {
      return (state.activeDateRange?.start, state.activeDateRange?.end);
    }

    final date = state.activeDate;
    switch (state.dateStep) {
      case DateStep.day:
        final start = DateTime(date.year, date.month, date.day);
        final end = DateTime(date.year, date.month, date.day, 23, 59, 59);
        return (start, end);
      case DateStep.month:
        final start = DateTime(date.year, date.month, 1);
        final end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
        return (start, end);
      case DateStep.year:
        final start = DateTime(date.year, 1, 1);
        final end = DateTime(date.year, 12, 31, 23, 59, 59);
        return (start, end);
    }
  }

  void _onChangeDateStep(ChangeAssetDateStep event, Emitter<AssetState> emit) {
    emit(state.copyWith(dateStep: event.dateStep));
    add(const LoadAssetData());
  }

  void _onChangeFilterMode(
    ChangeAssetFilterMode event,
    Emitter<AssetState> emit,
  ) {
    emit(state.copyWith(filterMode: event.filterMode));
    add(const LoadAssetData());
  }

  void _onChangeActiveDate(
    ChangeAssetActiveDate event,
    Emitter<AssetState> emit,
  ) {
    emit(state.copyWith(activeDate: event.date));
    add(const LoadAssetData());
  }

  void _onChangeActiveDateRange(
    ChangeAssetActiveDateRange event,
    Emitter<AssetState> emit,
  ) {
    emit(state.copyWith(activeDateRange: event.dateRange));
    add(const LoadAssetData());
  }

  void _onChangeSort(ChangeAssetSort event, Emitter<AssetState> emit) {
    emit(state.copyWith(sort: event.sort));
    add(const LoadAssetData());
  }

  void _onChangeFilters(ChangeAssetFilters event, Emitter<AssetState> emit) {
    emit(
      state.copyWith(
        selectedAssetId: event.assetId,
        nameFilter: event.name,
        assetTypeFilters: event.assetTypes,
        descriptionFilter: event.description,
        currencyCodeFilters: event.currencyCodes,
        sourceFilters: event.sources,
        presetFilters: event.presets,
        minValueFilter: event.minValue,
        maxValueFilter: event.maxValue,
      ),
    );
    add(const LoadAssetData());
  }

  Future<void> _onAddAssetData(
    AddAssetData event,
    Emitter<AssetState> emit,
  ) async {
    try {
      await _repository.addAssetData(event.data);
      add(LoadAssetData(assetId: event.data.assetId));
    } catch (e) {
      emit(
        state.copyWith(status: AssetStatus.failure, errorMessage: e.toString()),
      );
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
      emit(
        state.copyWith(status: AssetStatus.failure, errorMessage: e.toString()),
      );
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
      emit(
        state.copyWith(status: AssetStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
