import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';

import 'package:my_budget_client/domain/repositories/settings_repository.dart';
// import 'package:my_budget_client/domain/entities/settings.dart';
// import 'package:my_budget_client/core/utils/device_utils.dart'; // Added import

part 'inflation_event.dart';
part 'inflation_state.dart';

class InflationBloc extends Bloc<InflationEvent, InflationState> {
  final InflationRepository _inflationRepository;
  final SettingsRepository _settingsRepository;
  StreamSubscription? _ratesSubscription;

  /// Set synchronously as the first statement of [close], before any await.
  bool _closeRequested = false;

  /// Guard for anything that resumes after an `await`. `isClosed` on its own is
  /// not enough: Bloc.close() closes the event controller first and only flips
  /// `isClosed` at the very end, and it does not wait for in-flight handlers -
  /// so a handler resuming in that window sees `isClosed == false` while add()
  /// already throws "Cannot add new events after calling close".
  bool get _isShuttingDown => _closeRequested || isClosed;

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
    on<InflationRatesUpdated>(_onInflationRatesUpdated);
  }

  @override
  Future<void> close() async {
    _closeRequested = true;
    // Awaited: the subscription callback calls add(), and an add() that lands
    // after close() throws. Cancelling unawaited left that window open.
    await _ratesSubscription?.cancel();
    return super.close();
  }

  void _onInflationRatesUpdated(
    InflationRatesUpdated event,
    Emitter<InflationState> emit,
  ) {
    emit(
      state.copyWith(
        status: InflationStatus.success,
        rates: event.rates,
        offset: event.rates.length,
        hasMore: false,
        totalCount: event.totalCount,
      ),
    );
  }

  Future<void> _onLoadInflationRates(
    LoadInflationRates event,
    Emitter<InflationState> emit,
  ) async {
    // Captured BEFORE the loading emit below. That emit moves status off
    // 'initial', so re-reading state.status further down can never report a
    // first load - which is why the persisted view settings used to be read
    // from the database and then thrown away on every single load.
    final wasInitial = state.status == InflationStatus.initial;

    if (wasInitial || state.status == InflationStatus.failure) {
      emit(
        state.copyWith(status: InflationStatus.loading, offset: 0, rates: []),
      );
    }
    try {
      // Load persisted settings
      final dateStepSetting = await _settingsRepository.getSetting(
        'inflation_date_step',
      );
      final filterModeSetting = await _settingsRepository.getSetting(
        'inflation_filter_mode',
      );
      // The screen can be popped while the settings reads are in flight.
      if (_isShuttingDown) return;

      DateStep dateStep = state.dateStep;
      if (dateStepSetting != null && wasInitial) {
        // Simple enum parsing by name or index
        try {
          dateStep = DateStep.values.firstWhere(
            (e) => e.toString() == dateStepSetting.value,
          );
        } catch (_) {
          // Falling back to the default is intentional, but log the offending
          // value: a corrupted setting is indistinguishable from "the app
          // ignores my preference" unless it leaves a trace.
          debugPrint(
            '[InflationBloc] Unparseable inflation_date_step '
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
            '[InflationBloc] Unparseable inflation_filter_mode '
            '"${filterModeSetting.value}", keeping $filterMode',
          );
        }
      }

      // Only the very first load restores persisted settings; a later reload
      // must keep whatever the user picked during this session.
      final currentState = wasInitial
          ? state.copyWith(dateStep: dateStep, filterMode: filterMode)
          : state;

      // Emitted before the query so the restored view is on screen while the
      // rates are still being fetched.
      if (wasInitial) {
        emit(currentState);
      }

      final (dateFrom, dateTo) = _getDateRange(currentState);

      // Re-checked here: the settings reads above are awaits, so the bloc may
      // have started closing since - installing a fresh stream now would
      // outlive it.
      if (_isShuttingDown) return;

      // Switch to real-time subscription
      await _ratesSubscription?.cancel();
      _ratesSubscription = _inflationRepository
          .watchInflationRatesFiltered(
            limit: 10000, // Load all for real-time updates
            offset: 0,
            dateFrom: dateFrom,
            dateTo: dateTo,
            countries: state.countryFilters,
            presets: state.presetFilters,
            sortAscending: state.sort == Sort.ascending,
          )
          .listen((rates) {
            if (_isShuttingDown) return;
            add(InflationRatesUpdated(rates, rates.length));
          });
      // We don't emit success here, the event will do it.
    } catch (e) {
      if (_isShuttingDown) return;
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
      if (_isShuttingDown) return;

      emit(
        state.copyWith(
          rates: [...state.rates, ...rates],
          offset: state.offset + rates.length,
          hasMore: rates.length == state.limit,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      if (_isShuttingDown) return;
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
    await _settingsRepository.saveSetting(
      'inflation_date_step',
      event.dateStep.toString(),
    );
    if (_isShuttingDown) return;
    // The reload below only restores the persisted value on the FIRST load, so
    // the new step has to be put into state here - saving alone left the change
    // with no visible effect at all.
    emit(state.copyWith(dateStep: event.dateStep));
    add(LoadInflationRates());
  }

  Future<void> _onChangeFilterMode(
    ChangeInflationFilterMode event,
    Emitter<InflationState> emit,
  ) async {
    await _settingsRepository.saveSetting(
      'inflation_filter_mode',
      event.filterMode.toString(),
    );
    if (_isShuttingDown) return;
    // Same as the date step above: the reload ignores persisted settings once
    // the first load has happened, so emit the new mode explicitly.
    emit(state.copyWith(filterMode: event.filterMode));
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
      if (_isShuttingDown) return;
      add(LoadInflationRates());
    } catch (e) {
      if (_isShuttingDown) return;
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
      if (_isShuttingDown) return;
      add(LoadInflationRates());
    } catch (e) {
      if (_isShuttingDown) return;
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
      if (_isShuttingDown) return;
      add(LoadInflationRates());
    } catch (e) {
      if (_isShuttingDown) return;
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
      if (_isShuttingDown) return;
      emit(state.copyWith(selectedRates: {}, isSelectionModeActive: false));
      add(LoadInflationRates());
    } catch (e) {
      if (_isShuttingDown) return;
      emit(
        state.copyWith(
          status: InflationStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
