import 'package:bloc/bloc.dart';

import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/entities/settings.dart'; // Added entity import
import 'package:my_budget_client/core/utils/device_utils.dart';
import 'asset_event.dart';
import 'asset_state.dart';

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  final AssetRepository _assetRepository;
  final SettingsRepository _settingsRepository;

  AssetBloc(this._assetRepository, this._settingsRepository)
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
    // Selection Events
    on<ToggleAssetSelection>(_onToggleSelection);
    on<SelectAllAssets>(_onSelectAll);
    on<DeselectAllAssets>(_onDeselectAll);
    on<DeleteSelectedAssets>(_onDeleteSelected);
  }

  Future<void> _onLoadAssetData(
    LoadAssetData event,
    Emitter<AssetState> emit,
  ) async {
    emit(
      state.copyWith(
        status: AssetStatus.loading,
        offset: 0,
        assetData: [],
        isLoadingMore: false,
      ),
    );
    try {
      // Load persisted settings
      final dateStepSetting = await _settingsRepository.getSetting(
        'asset_date_step',
      );
      final filterModeSetting = await _settingsRepository.getSetting(
        'asset_filter_mode',
      );

      DateStep dateStep = state.dateStep;
      if (dateStepSetting != null && state.status == AssetStatus.initial) {
        try {
          dateStep = DateStep.values.firstWhere(
            (e) => e.toString() == dateStepSetting.value,
          );
        } catch (_) {}
      }

      FilterMode filterMode = state.filterMode;
      if (filterModeSetting != null && state.status == AssetStatus.initial) {
        try {
          filterMode = FilterMode.values.firstWhere(
            (e) => e.toString() == filterModeSetting.value,
          );
        } catch (_) {}
      }

      // We don't emit the restored settings immediately to avoid flickering or double loads
      // We use them in the state.copyWith below or just update local vars?
      // Better to update state so subsequent logic uses correct values.
      var currentState = state.copyWith(
        dateStep: dateStep,
        filterMode: filterMode,
      );
      // But we can't emit yet if we are in 'try' block and want to emit success later?
      // Actually we can emit partial state.

      if (state.status == AssetStatus.initial) {
        emit(currentState);
      } else {
        // If not initial, we keep the existing dateStep/filterMode from state and ignore loaded ones
        currentState = state;
      }

      final (dateFrom, dateTo) = _getDateRange(currentState);

      // Update selectedAssetId if provided in event
      if (event.assetId != null) {
        currentState = currentState.copyWith(selectedAssetId: event.assetId);
        emit(currentState);
      }

      final count = await _assetRepository.getAssetDataCount(
        assetId: currentState.selectedAssetId,
        startDate: dateFrom,
        endDate: dateTo,
        name: currentState.nameFilter,
        assetTypes: currentState.assetTypeFilters,
        description: currentState.descriptionFilter,
        currencyCodes: currentState.currencyCodeFilters,
        sources: currentState.sourceFilters,
        presets: currentState.presetFilters,
        minValue: currentState.minValueFilter,
        maxValue: currentState.maxValueFilter,
      );

      final data = await _assetRepository.getAssetData(
        limit: currentState.limit,
        offset: 0,
        assetId: event.assetId ?? currentState.selectedAssetId,
        startDate: dateFrom,
        endDate: dateTo,
        name: currentState.nameFilter,
        assetTypes: currentState.assetTypeFilters,
        description: currentState.descriptionFilter,
        currencyCodes: currentState.currencyCodeFilters,
        sources: currentState.sourceFilters,
        presets: currentState.presetFilters,
        minValue: currentState.minValueFilter,
        maxValue: currentState.maxValueFilter,
        sortAscending: currentState.sort == Sort.ascending,
      );

      emit(
        currentState.copyWith(
          status: AssetStatus.success,
          assetData: data,
          offset: data.length,
          hasMore: data.length == currentState.limit,
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
      final (dateFrom, dateTo) = _getDateRange(state); // Explicitly pass state

      final data = await _assetRepository.getAssetData(
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

  (DateTime?, DateTime?) _getDateRange([AssetState? stateOverride]) {
    final s = stateOverride ?? state;
    if (s.filterMode == FilterMode.range && s.activeDateRange != null) {
      return (s.activeDateRange!.start, s.activeDateRange!.end);
    }

    final date = s.activeDate;
    switch (s.dateStep) {
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

  Future<void> _onChangeDateStep(
    ChangeAssetDateStep event,
    Emitter<AssetState> emit,
  ) async {
    final deviceName = await getDeviceName();
    emit(state.copyWith(dateStep: event.dateStep));
    await _settingsRepository.setSetting(
      Settings(
        key: 'asset_date_step',
        value: event.dateStep.toString(),
        device: deviceName,
      ),
    );
    add(const LoadAssetData());
  }

  Future<void> _onChangeFilterMode(
    ChangeAssetFilterMode event,
    Emitter<AssetState> emit,
  ) async {
    final deviceName = await getDeviceName();
    emit(state.copyWith(filterMode: event.filterMode));
    await _settingsRepository.setSetting(
      Settings(
        key: 'asset_filter_mode',
        value: event.filterMode.toString(),
        device: deviceName,
      ),
    );
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
        selectedAssetId: event.assetId ?? state.selectedAssetId,
        forceNullSelectedAssetId: false, // Don't force null from filter changes
        nameFilter: event.name,
        forceNullName: event.name == null,
        assetTypeFilters: event.assetTypes,
        forceNullAssetTypes: event.assetTypes == null,
        descriptionFilter: event.description,
        forceNullDescription: event.description == null,
        currencyCodeFilters: event.currencyCodes,
        forceNullCurrencyCodes: event.currencyCodes == null,
        sourceFilters: event.sources,
        forceNullSources: event.sources == null,
        presetFilters: event.presets,
        forceNullPresets: event.presets == null,
        minValueFilter: event.minValue,
        forceNullMinValue: event.minValue == null,
        maxValueFilter: event.maxValue,
        forceNullMaxValue: event.maxValue == null,
      ),
    );
    add(const LoadAssetData());
  }

  Future<void> _onAddAssetData(
    AddAssetData event,
    Emitter<AssetState> emit,
  ) async {
    try {
      await _assetRepository.addAssetData(event.data);
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
      await _assetRepository.updateAssetData(event.data);
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
      await _assetRepository.deleteAssetData(event.id);
      add(const LoadAssetData());
    } catch (e) {
      emit(
        state.copyWith(status: AssetStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  void _onToggleSelection(
    ToggleAssetSelection event,
    Emitter<AssetState> emit,
  ) {
    final selectedAssets = Set<AssetDataDomain>.from(state.selectedAssets);
    if (selectedAssets.contains(event.asset)) {
      selectedAssets.remove(event.asset);
    } else {
      selectedAssets.add(event.asset);
    }

    emit(
      state.copyWith(
        selectedAssets: selectedAssets,
        isSelectionModeActive: selectedAssets.isNotEmpty,
      ),
    );
  }

  void _onSelectAll(SelectAllAssets event, Emitter<AssetState> emit) {
    emit(
      state.copyWith(
        selectedAssets: Set.from(state.assetData),
        isSelectionModeActive: true,
      ),
    );
  }

  void _onDeselectAll(DeselectAllAssets event, Emitter<AssetState> emit) {
    emit(state.copyWith(selectedAssets: {}, isSelectionModeActive: false));
  }

  Future<void> _onDeleteSelected(
    DeleteSelectedAssets event,
    Emitter<AssetState> emit,
  ) async {
    try {
      final idsToDelete = state.selectedAssets
          .map((e) => e.id)
          .whereType<String>()
          .toList();
      await _assetRepository.deleteAssets(idsToDelete);
      emit(state.copyWith(selectedAssets: {}, isSelectionModeActive: false));
      add(const LoadAssetData());
    } catch (e) {
      emit(
        state.copyWith(status: AssetStatus.failure, errorMessage: e.toString()),
      );
    }
  }
}
