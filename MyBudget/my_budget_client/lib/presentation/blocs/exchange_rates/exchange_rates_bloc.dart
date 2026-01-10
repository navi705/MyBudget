import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';

part 'exchange_rates_event.dart';
part 'exchange_rates_state.dart';

class ExchangeRatesBloc extends Bloc<ExchangeRatesEvent, ExchangeRatesState> {
  final CurrencyRepository _currencyRepository;

  ExchangeRatesBloc({required CurrencyRepository currencyRepository})
    : _currencyRepository = currencyRepository,
      super(ExchangeRatesState()) {
    on<LoadExchangeRates>(_onLoadExchangeRates);
    on<AddExchangeRate>(_onAddExchangeRate);
    on<ChangeExchangeRatesFilters>(_onChangeExchangeRatesFilters);
    on<ChangeExchangeRatesDateStep>((event, emit) {
      emit(state.copyWith(dateStep: event.dateStep));
      add(const LoadExchangeRates(isRefresh: true));
    });
    on<ChangeExchangeRatesFilterMode>((event, emit) {
      emit(state.copyWith(filterMode: event.filterMode));
      add(const LoadExchangeRates(isRefresh: true));
    });
    on<ChangeExchangeRatesSort>((event, emit) {
      emit(state.copyWith(sort: event.sort));
      // Sorting is not supported by Repository yet, but we store state.
      // If we did in-memory sorting, we'd do it here or in success state.
      // For now just reload to be safe.
      add(const LoadExchangeRates(isRefresh: true));
    });
    on<ChangeExchangeRatesActiveDate>((event, emit) {
      emit(state.copyWith(activeDate: event.date));
      add(const LoadExchangeRates(isRefresh: true));
    });
    on<ChangeExchangeRatesActiveDateRange>((event, emit) {
      emit(state.copyWith(activeDateRange: event.dateRange));
      add(const LoadExchangeRates(isRefresh: true));
    });
    on<ToggleSelectionMode>(_onToggleSelectionMode);
    on<ToggleExchangeRateSelection>(_onToggleExchangeRateSelection);
    on<SelectAllExchangeRates>(_onSelectAllExchangeRates);
    on<ClearSelection>(_onClearSelection);
    on<DeleteSelectedExchangeRates>(_onDeleteSelectedExchangeRates);
    on<UpdateSelectedExchangeRatesPreset>(_onUpdateSelectedExchangeRatesPreset);
  }

  Future<void> _onLoadExchangeRates(
    LoadExchangeRates event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    if (state.hasReachedMax && !event.isRefresh) return;

    try {
      if (event.isRefresh || state.status == ExchangeRatesStatus.initial) {
        emit(
          state.copyWith(
            status: ExchangeRatesStatus.loading,
            exchangeRates: [],
            hasReachedMax: false,
          ),
        );
      }

      final limit = 100;
      final offset = event.isRefresh ? 0 : state.exchangeRates.length;

      DateTime startDate;
      DateTime endDate;

      if (state.filterMode == FilterMode.range &&
          state.activeDateRange != null) {
        startDate = state.activeDateRange!.start;
        endDate = state.activeDateRange!.end;
      } else {
        final activeDate = state.activeDate;
        switch (state.dateStep) {
          case DateStep.day:
            startDate = DateTime(
              activeDate.year,
              activeDate.month,
              activeDate.day,
            );
            endDate = DateTime(
              activeDate.year,
              activeDate.month,
              activeDate.day,
              23,
              59,
              59,
            );
            break;
          case DateStep.month:
            startDate = DateTime(activeDate.year, activeDate.month, 1);
            endDate = DateTime(
              activeDate.year,
              activeDate.month + 1,
              0,
              23,
              59,
              59,
            );
            break;
          case DateStep.year:
            startDate = DateTime(activeDate.year, 1, 1);
            endDate = DateTime(activeDate.year, 12, 31, 23, 59, 59);
            break;
        }
      }

      final rates = await _currencyRepository.getExchangeRatesFiltered(
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
        fromCurrency: state.fromCurrencyFilter,
        toCurrency: state.toCurrencyFilter,
        presets: state.presetFilters,
        sortAscending: state.sort == Sort.ascending,
      );

      final totalCount = await _currencyRepository.getExchangeRatesCount(
        startDate: startDate,
        endDate: endDate,
        fromCurrency: state.fromCurrencyFilter,
        toCurrency: state.toCurrencyFilter,
        presets: state.presetFilters,
      );

      final currencies = state.currencies.isEmpty
          ? await _currencyRepository.getCurrencies()
          : state.currencies;

      emit(
        state.copyWith(
          status: ExchangeRatesStatus.success,
          exchangeRates: event.isRefresh
              ? rates
              : [...state.exchangeRates, ...rates],
          currencies: currencies,
          hasReachedMax: rates.length < limit,
          totalCount: totalCount,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: ExchangeRatesStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _onAddExchangeRate(
    AddExchangeRate event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    try {
      await _currencyRepository.addExchangeRate(event.exchangeRate);
      add(const LoadExchangeRates(isRefresh: true));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onChangeExchangeRatesFilters(
    ChangeExchangeRatesFilters event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    // Legacy support or if user still uses the old filter way.
    // If date is provided, we update activeDate.
    // If date is null (clear), we might set activeDate to now or keep it?
    // Old logic: clearDateFilter: event.date == null.
    // New logic: activeDate cannot be null.
    // If event.date is null, we do nothing for activeDate or reset it?
    // Let's assume if event.date is set, we update activeDate.

    DateTime? newDate = event.date;
    if (newDate != null) {
      emit(state.copyWith(activeDate: newDate));
    }

    emit(
      state.copyWith(
        fromCurrencyFilter: event.fromCurrency,
        toCurrencyFilter: event.toCurrency,
        presetFilters: event.presets,
        clearFromCurrencyFilter: event.fromCurrency == null,
        clearToCurrencyFilter: event.toCurrency == null,
        status: ExchangeRatesStatus.loading,
      ),
    );
    add(const LoadExchangeRates(isRefresh: true));
  }

  Future<void> _onToggleSelectionMode(
    ToggleSelectionMode event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    emit(state.copyWith(isSelectionModeActive: event.isSelectionModeActive));
    if (!event.isSelectionModeActive) {
      add(const ClearSelection());
    }
  }

  Future<void> _onToggleExchangeRateSelection(
    ToggleExchangeRateSelection event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    final updatedSelection = Set<ExchangeRateDomain>.from(
      state.selectedExchangeRates,
    );
    if (updatedSelection.contains(event.exchangeRate)) {
      updatedSelection.remove(event.exchangeRate);
    } else {
      updatedSelection.add(event.exchangeRate);
    }
    emit(state.copyWith(selectedExchangeRates: updatedSelection));
  }

  Future<void> _onSelectAllExchangeRates(
    SelectAllExchangeRates event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    final allRates = Set<ExchangeRateDomain>.from(state.exchangeRates);
    emit(state.copyWith(selectedExchangeRates: allRates));
  }

  Future<void> _onClearSelection(
    ClearSelection event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    emit(state.copyWith(selectedExchangeRates: const {}));
  }

  Future<void> _onDeleteSelectedExchangeRates(
    DeleteSelectedExchangeRates event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    try {
      if (state.selectedExchangeRates.isEmpty) return;

      final ratesToDelete = state.selectedExchangeRates.toList();
      await _currencyRepository.deleteExchangeRates(ratesToDelete);

      add(const LoadExchangeRates(isRefresh: true));
      add(const ClearSelection());
      add(const ToggleSelectionMode(false));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onUpdateSelectedExchangeRatesPreset(
    UpdateSelectedExchangeRatesPreset event,
    Emitter<ExchangeRatesState> emit,
  ) async {
    try {
      if (state.selectedExchangeRates.isEmpty) return;

      final ratesToUpdate = state.selectedExchangeRates.toList();
      await _currencyRepository.updateExchangeRatePresets(
        ratesToUpdate,
        event.newPreset,
      );

      add(const LoadExchangeRates(isRefresh: true));
      add(const ClearSelection());
      add(const ToggleSelectionMode(false));
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }
}
