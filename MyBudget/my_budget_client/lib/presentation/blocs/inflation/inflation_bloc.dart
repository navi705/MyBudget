import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';

import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/core/utils/device_utils.dart'; // Added import

part 'inflation_event.dart';
part 'inflation_state.dart';

class InflationBloc extends Bloc<InflationEvent, InflationState> {
  final InflationRepository _inflationRepository;
  final SettingsRepository _settingsRepository;

  InflationBloc({
    required InflationRepository inflationRepository,
    required SettingsRepository settingsRepository,
  }) : _inflationRepository = inflationRepository,
       _settingsRepository = settingsRepository,
       super(
         InflationState(
           dateStep: DateStep.year,
           activeDate: DateTime(
             DateTime.now().year,
             DateTime.now().month,
             DateTime.now().day,
           ),
         ),
       ) {
    on<LoadInflationRates>(_onLoadInflationRates);
    on<LoadMoreInflationRates>(_onLoadMoreInflationRates);
    on<ChangeInflationDateStep>(_onChangeDateStep);
    on<ChangeInflationFilterMode>(_onChangeFilterMode);
    on<ChangeInflationActiveDate>(_onChangeActiveDate);
    on<ChangeInflationActiveDateRange>(_onChangeActiveDateRange);
    on<ChangeInflationSort>(_onChangeSort);
    on<ChangeInflationFilters>(_onChangeFilters);
    on<AddInflationRate>(_onAddInflationRate);
    on<UpdateInflationRate>(_onUpdateInflationRate);
    on<DeleteInflationRate>(_onDeleteInflationRate);
    on<ToggleInflationSelection>(_onToggleSelection);
    on<SelectAllInflationRates>(_onSelectAll);
    on<DeselectAllInflationRates>(_onDeselectAll);
    on<DeleteSelectedInflationRates>(_onDeleteSelected);
  }

  Future<void> _onLoadInflationRates(
    LoadInflationRates event,
    Emitter<InflationState> emit,
  ) async {
    emit(
      state.copyWith(status: InflationStatus.loading, offset: 0, rates: []),
    ); // Modified
    try {
      // Load persisted settings
      final dateStepSetting = await _settingsRepository.getSetting(
        'inflation_date_step',
      );
      final filterModeSetting = await _settingsRepository.getSetting(
        'inflation_filter_mode',
      );

      DateStep dateStep = state.dateStep;
      if (dateStepSetting != null && state.status == InflationStatus.initial) {
        // Simple enum parsing by name or index
        try {
          dateStep = DateStep.values.firstWhere(
            (e) => e.toString() == dateStepSetting.value,
          );
        } catch (_) {}
      }

      FilterMode filterMode = state.filterMode;
      if (filterModeSetting != null &&
          state.status == InflationStatus.initial) {
        try {
          filterMode = FilterMode.values.firstWhere(
            (e) => e.toString() == filterModeSetting.value,
          );
        } catch (_) {}
      }

      // Restore settings first
      // Actually, we should construct the state we expect to be used.
      var currentState = state.copyWith(
        dateStep: dateStep,
        filterMode: filterMode,
      );

      if (state.status == InflationStatus.initial) {
        emit(currentState);
      } else {
        // If not initial, we keep the existing dateStep/filterMode from state and ignore loaded ones
        currentState = state;
      }

      final (dateFrom, dateTo) = _getDateRange(currentState);

      final count = await _inflationRepository.getInflationRatesCount(
        dateFrom: dateFrom,
        dateTo: dateTo,
        countries: state.countryFilters,
        presets: state.presetFilters,
      );

      final rates = await _inflationRepository.getInflationRatesFiltered(
        limit: state.limit,
        offset: 0,
        dateFrom: dateFrom,
        dateTo: dateTo,
        countries: state.countryFilters,
        presets: state.presetFilters,
        sortAscending: state.sort == Sort.ascending,
      );

      emit(
        state.copyWith(
          status: InflationStatus.success,
          rates: rates,
          offset: rates.length,
          hasMore: rates.length == state.limit,
          totalCount: count,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InflationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMoreInflationRates(
    LoadMoreInflationRates event,
    Emitter<InflationState> emit,
  ) async {
    if (state.isLoadingMore || !state.hasMore) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final (dateFrom, dateTo) = _getDateRange(state);

      final rates = await _inflationRepository.getInflationRatesFiltered(
        limit: state.limit,
        offset: state.offset,
        dateFrom: dateFrom,
        dateTo: dateTo,
        countries: state.countryFilters,
        presets: state.presetFilters,
        sortAscending: state.sort == Sort.ascending,
      );

      emit(
        state.copyWith(
          rates: [...state.rates, ...rates],
          offset: state.offset + rates.length,
          hasMore: rates.length == state.limit,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: InflationStatus.failure,
          errorMessage: e.toString(),
          isLoadingMore: false,
        ),
      );
    }
  }

  (DateTime?, DateTime?) _getDateRange([InflationState? stateOverride]) {
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
    ChangeInflationDateStep event,
    Emitter<InflationState> emit,
  ) async {
    final deviceName = await getDeviceName();
    emit(state.copyWith(dateStep: event.dateStep));
    await _settingsRepository.setSetting(
      Settings(
        key: 'inflation_date_step',
        value: event.dateStep.toString(),
        device: deviceName,
      ),
    );
    add(LoadInflationRates());
  }

  Future<void> _onChangeFilterMode(
    ChangeInflationFilterMode event,
    Emitter<InflationState> emit,
  ) async {
    final deviceName = await getDeviceName();
    emit(state.copyWith(filterMode: event.filterMode));
    await _settingsRepository.setSetting(
      Settings(
        key: 'inflation_filter_mode',
        value: event.filterMode.toString(),
        device: deviceName,
      ),
    );
    add(LoadInflationRates());
  }

  void _onChangeActiveDate(
    ChangeInflationActiveDate event,
    Emitter<InflationState> emit,
  ) {
    emit(state.copyWith(activeDate: event.date));
    add(LoadInflationRates());
  }

  void _onChangeActiveDateRange(
    ChangeInflationActiveDateRange event,
    Emitter<InflationState> emit,
  ) {
    emit(state.copyWith(activeDateRange: event.dateRange));
    add(LoadInflationRates());
  }

  void _onChangeSort(ChangeInflationSort event, Emitter<InflationState> emit) {
    emit(state.copyWith(sort: event.sort));
    add(LoadInflationRates());
  }

  void _onChangeFilters(
    ChangeInflationFilters event,
    Emitter<InflationState> emit,
  ) {
    emit(
      state.copyWith(
        countryFilters: event.countries,
        forceNullCountryFilters: event.countries == null,
        presetFilters: event.presets,
        forceNullPresetFilters: event.presets == null,
      ),
    );
    add(LoadInflationRates());
  }

  Future<void> _onAddInflationRate(
    AddInflationRate event,
    Emitter<InflationState> emit,
  ) async {
    try {
      await _inflationRepository.addInflationRate(event.rate);
      add(LoadInflationRates());
    } catch (e) {
      emit(
        state.copyWith(
          status: InflationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateInflationRate(
    UpdateInflationRate event,
    Emitter<InflationState> emit,
  ) async {
    try {
      await _inflationRepository.updateInflationRate(event.rate);
      add(LoadInflationRates());
    } catch (e) {
      emit(
        state.copyWith(
          status: InflationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteInflationRate(
    DeleteInflationRate event,
    Emitter<InflationState> emit,
  ) async {
    try {
      await _inflationRepository.deleteInflationRate(
        event.date,
        event.country,
        event.preset,
      );
      add(LoadInflationRates());
    } catch (e) {
      emit(
        state.copyWith(
          status: InflationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void _onToggleSelection(
    ToggleInflationSelection event,
    Emitter<InflationState> emit,
  ) {
    final selectedRates = Set<InflationRateDomain>.from(state.selectedRates);
    if (selectedRates.contains(event.rate)) {
      selectedRates.remove(event.rate);
    } else {
      selectedRates.add(event.rate);
    }

    emit(
      state.copyWith(
        selectedRates: selectedRates,
        isSelectionModeActive: selectedRates.isNotEmpty,
      ),
    );
  }

  void _onSelectAll(
    SelectAllInflationRates event,
    Emitter<InflationState> emit,
  ) {
    emit(
      state.copyWith(
        selectedRates: Set.from(state.rates),
        isSelectionModeActive: true,
      ),
    );
  }

  void _onDeselectAll(
    DeselectAllInflationRates event,
    Emitter<InflationState> emit,
  ) {
    emit(state.copyWith(selectedRates: {}, isSelectionModeActive: false));
  }

  Future<void> _onDeleteSelected(
    DeleteSelectedInflationRates event,
    Emitter<InflationState> emit,
  ) async {
    try {
      final ratesToDelete = state.selectedRates.toList();
      await _inflationRepository.deleteInflationRates(ratesToDelete);
      emit(state.copyWith(selectedRates: {}, isSelectionModeActive: false));
      add(LoadInflationRates());
    } catch (e) {
      emit(
        state.copyWith(
          status: InflationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
