import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';

part 'exchange_rates_event.dart';
part 'exchange_rates_state.dart';

class ExchangeRatesBloc extends Bloc<ExchangeRatesEvent, ExchangeRatesState> {
  final CurrencyRepository _currencyRepository;

  ExchangeRatesBloc({required CurrencyRepository currencyRepository})
    : _currencyRepository = currencyRepository,
      super(const ExchangeRatesState()) {
    on<LoadExchangeRates>(_onLoadExchangeRates);
    on<AddExchangeRate>(_onAddExchangeRate);
    on<ChangeExchangeRatesFilters>(_onChangeExchangeRatesFilters);
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
        date: state.dateFilter,
        fromCurrency: state.fromCurrencyFilter,
        toCurrency: state.toCurrencyFilter,
      );

      final totalCount = await _currencyRepository.getExchangeRatesCount(
        date: state.dateFilter,
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
    emit(
      state.copyWith(
        dateFilter: event.date,
        fromCurrencyFilter: event.fromCurrency,
        toCurrencyFilter: event.toCurrency,
        clearDateFilter: event.date == null,
        clearFromCurrencyFilter: event.fromCurrency == null,
        clearToCurrencyFilter: event.toCurrency == null,
        status: ExchangeRatesStatus.loading,
      ),
    );
    add(const LoadExchangeRates(isRefresh: true));
  }
}
