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

      final limit = 50;
      final offset = event.isRefresh ? 0 : state.exchangeRates.length;

      final rates = await _currencyRepository.getExchangeRatesFiltered(
        limit: limit,
        offset: offset,
        date: state.filterMode == FilterMode.range
            ? state.activeDateRange?.start
            : state.activeDate, // Mapping new state to Repo's date
        fromCurrency: state.fromCurrencyFilter,
        toCurrency: state.toCurrencyFilter,
      );

      final totalCount = await _currencyRepository.getExchangeRatesCount(
        date: state.filterMode == FilterMode.range
            ? state.activeDateRange?.start
            : state.activeDate,
        fromCurrency: state.fromCurrencyFilter,
        toCurrency: state.toCurrencyFilter,
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
        clearFromCurrencyFilter: event.fromCurrency == null,
        clearToCurrencyFilter: event.toCurrency == null,
        status: ExchangeRatesStatus.loading,
      ),
    );
    add(const LoadExchangeRates(isRefresh: true));
  }
}
