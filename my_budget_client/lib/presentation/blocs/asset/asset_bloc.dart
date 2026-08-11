import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
// import 'package:my_budget_client/domain/entities/settings.dart'; // Added entity import
// import 'package:my_budget_client/core/utils/device_utils.dart';
import 'asset_event.dart';
import 'asset_state.dart';

class AssetBloc extends Bloc<AssetEvent, AssetState> {
  final AssetRepository _assetRepository;
  final SettingsRepository _settingsRepository;
  StreamSubscription? _assetSubscription;

  /// Set synchronously as the first statement of [close], before any await.
  bool _closeRequested = false;

  /// Guard for anything that resumes after an `await`. `isClosed` on its own is
  /// not enough: Bloc.close() closes the event controller first and only flips
  /// `isClosed` at the very end, and it does not wait for in-flight handlers -
  /// so a handler resuming in that window sees `isClosed == false` while add()
  /// already throws "Cannot add new events after calling close".
  bool get _isShuttingDown => _closeRequested || isClosed;

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
    on<AssetDataUpdated>(_onAssetDataUpdated);
  }

  Future<void> _subscribeToAssets() async {
    // Every caller reaches here after an await, so the bloc may already be on
    // its way out - installing a fresh stream now would outlive it.
    if (_isShuttingDown) return;

    final (dateFrom, dateTo) = _getDateRange(state);

    // Awaited: cancel() only completes asynchronously, so without the await the
    // old drift stream can still deliver one final page into
    // add(AssetDataUpdated) *after* the new subscription is live - a stale page
    // then overwrites the fresh one.
    await _assetSubscription?.cancel();
    _assetSubscription = _assetRepository
        .watchAssetData(
          limit: state.limit,
          offset: 0,
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
        )
        .listen((data) {
          if (_isShuttingDown) return;
          add(AssetDataUpdated(data));
        });
  }

  Future<void> _onAssetDataUpdated(
    AssetDataUpdated event,
    Emitter<AssetState> emit,
  ) async {
    final (dateFrom, dateTo) = _getDateRange(state);
    final count = await _assetRepository.getAssetDataCount(
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

    // The screen can be popped while the count query is in flight; emitting
    // into a closed bloc throws.
    if (_isShuttingDown) return;

    emit(
      state.copyWith(
        status: AssetStatus.success,
        assetData: event.data,
        offset: event.data.length,
        hasMore: event.data.length == state.limit,
        totalCount: count,
        isLoadingMore: false,
      ),
    );
  }

  Future<void> _onLoadAssetData(
    LoadAssetData event,
    Emitter<AssetState> emit,
  ) async {
    // Captured BEFORE the loading emit below. That emit moves status off
    // 'initial', so re-reading state.status further down can never report a
    // first load - which is why the persisted view settings used to be read
    // from the database and then thrown away on every single load.
    final wasInitial = state.status == AssetStatus.initial;

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
      // The screen can be popped while the settings reads are in flight.
      if (_isShuttingDown) return;

      DateStep dateStep = state.dateStep;
      if (dateStepSetting != null && wasInitial) {
        try {
          dateStep = DateStep.values.firstWhere(
            (e) => e.toString() == dateStepSetting.value,
          );
        } catch (_) {
          // Falling back to the default is intentional, but log the offending
          // value: a corrupted setting is indistinguishable from "the app
          // ignores my preference" unless it leaves a trace.
          debugPrint(
            '[AssetBloc] Unparseable asset_date_step '
            '"${dateStepSetting.value}", keeping $dateStep',
          );
        }
      }

      FilterMode filterMode = state.filterMode;
      if (filterModeSetting != null && wasInitial) {
        try {
          filterMode = FilterMode.values.firstWhere(
            (e) => e.toString() == filterModeSetting.value,
          );
        } catch (_) {
          debugPrint(
            '[AssetBloc] Unparseable asset_filter_mode '
            '"${filterModeSetting.value}", keeping $filterMode',
          );
        }
      }

      // Only the very first load restores persisted settings; a later reload
      // must keep whatever the user picked during this session.
      var currentState = wasInitial
          ? state.copyWith(dateStep: dateStep, filterMode: filterMode)
          : state;

      // Emitted before subscribing so _subscribeToAssets() reads the restored
      // dateStep/filterMode off state when it computes the date range.
      if (wasInitial) {
        emit(currentState);
      }

      // Update selectedAssetId if provided
      if (event.assetId != null) {
        currentState = currentState.copyWith(selectedAssetId: event.assetId);
        emit(currentState);
      }

      // Initial subscription
      await _subscribeToAssets();
    } catch (e) {
      if (_isShuttingDown) return;
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

    // For simplicity with streams, "Load More" just increases the limit and resubscribes
    // This maintains reactivity while showing more items
    emit(state.copyWith(isLoadingMore: true, limit: state.limit + 50));
    await _subscribeToAssets();
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
    await _settingsRepository.saveSetting(
      'asset_date_step',
      event.dateStep.toString(),
    );
    if (_isShuttingDown) return;
    // Update state first then resubscribe
    emit(state.copyWith(dateStep: event.dateStep));
    await _subscribeToAssets();
  }

  Future<void> _onChangeFilterMode(
    ChangeAssetFilterMode event,
    Emitter<AssetState> emit,
  ) async {
    await _settingsRepository.saveSetting(
      'asset_filter_mode',
      event.filterMode.toString(),
    );
    if (_isShuttingDown) return;
    emit(state.copyWith(filterMode: event.filterMode));
    await _subscribeToAssets();
  }

  Future<void> _onChangeActiveDate(
    ChangeAssetActiveDate event,
    Emitter<AssetState> emit,
  ) async {
    emit(state.copyWith(activeDate: event.date));
    await _subscribeToAssets();
  }

  Future<void> _onChangeActiveDateRange(
    ChangeAssetActiveDateRange event,
    Emitter<AssetState> emit,
  ) async {
    emit(state.copyWith(activeDateRange: event.dateRange));
    await _subscribeToAssets();
  }

  Future<void> _onChangeSort(
    ChangeAssetSort event,
    Emitter<AssetState> emit,
  ) async {
    emit(state.copyWith(sort: event.sort));
    await _subscribeToAssets();
  }

  Future<void> _onChangeFilters(
    ChangeAssetFilters event,
    Emitter<AssetState> emit,
  ) async {
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
    await _subscribeToAssets();
  }

  Future<void> _onAddAssetData(
    AddAssetData event,
    Emitter<AssetState> emit,
  ) async {
    try {
      await _assetRepository.addAssetData(event.data);
      // add(LoadAssetData(assetId: event.data.assetId)); // No longer needed, stream handles it
    } catch (e) {
      if (_isShuttingDown) return;
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
      // add(LoadAssetData(assetId: event.data.assetId)); // No longer needed, stream handles it
    } catch (e) {
      if (_isShuttingDown) return;
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
      // add(const LoadAssetData()); // No longer needed, stream handles it
    } catch (e) {
      if (_isShuttingDown) return;
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
      if (_isShuttingDown) return;
      emit(state.copyWith(selectedAssets: {}, isSelectionModeActive: false));
      // add(const LoadAssetData()); // No longer needed, stream handles it
    } catch (e) {
      if (_isShuttingDown) return;
      emit(
        state.copyWith(status: AssetStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  @override
  Future<void> close() async {
    _closeRequested = true;
    // Awaited: the subscription callback calls add(), and an add() that lands
    // after close() throws. Cancelling synchronously-but-unawaited left exactly
    // that window open.
    await _assetSubscription?.cancel();
    return super.close();
  }
}
