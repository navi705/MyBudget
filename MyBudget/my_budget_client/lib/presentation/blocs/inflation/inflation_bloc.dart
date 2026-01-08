import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';

part 'inflation_event.dart';
part 'inflation_state.dart';

class InflationBloc extends Bloc<InflationEvent, InflationState> {
  final InflationRepository _inflationRepository;

  InflationBloc({required InflationRepository inflationRepository})
    : _inflationRepository = inflationRepository,
      super(
        InflationState(
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
    on<AddInflationRate>(_onAddInflationRate);
    on<UpdateInflationRate>(_onUpdateInflationRate);
    on<DeleteInflationRate>(_onDeleteInflationRate);
  }

  Future<void> _onLoadInflationRates(
    LoadInflationRates event,
    Emitter<InflationState> emit,
  ) async {
    emit(state.copyWith(status: InflationStatus.loading, offset: 0, rates: []));
    try {
      final (dateFrom, dateTo) = _getDateRange();

      final rates = await _inflationRepository.getInflationRatesFiltered(
        limit: state.limit,
        offset: 0,
        dateFrom: dateFrom,
        dateTo: dateTo,
        sortAscending: state.sort == Sort.ascending,
      );

      emit(
        state.copyWith(
          status: InflationStatus.success,
          rates: rates,
          offset: rates.length,
          hasMore: rates.length == state.limit,
          totalCount: 0, // TODO: Implement getCount in repo if needed
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
      final (dateFrom, dateTo) = _getDateRange();

      final rates = await _inflationRepository.getInflationRatesFiltered(
        limit: state.limit,
        offset: state.offset,
        dateFrom: dateFrom,
        dateTo: dateTo,
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

  void _onChangeDateStep(
    ChangeInflationDateStep event,
    Emitter<InflationState> emit,
  ) {
    emit(state.copyWith(dateStep: event.dateStep));
    add(LoadInflationRates());
  }

  void _onChangeFilterMode(
    ChangeInflationFilterMode event,
    Emitter<InflationState> emit,
  ) {
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
}
