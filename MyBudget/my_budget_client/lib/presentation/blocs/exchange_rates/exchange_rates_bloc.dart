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
    emit(state.copyWith(status: ExchangeRatesStatus.loading));
    try {
      final rates = await _currencyRepository.getLatestExchangeRatesAll();
      final currencies = await _currencyRepository.getCurrencies();
      emit(
        state.copyWith(
          status: ExchangeRatesStatus.success,
          exchangeRates: rates,
          filteredExchangeRates: _applyFilters(
            rates,
            state.dateFilter,
            state.fromCurrencyFilter,
            state.toCurrencyFilter,
          ),
          currencies: currencies,
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
      final rates = await _currencyRepository.getLatestExchangeRatesAll();
      emit(
        state.copyWith(
          exchangeRates: rates,
          filteredExchangeRates: _applyFilters(
            rates,
            state.dateFilter,
            state.fromCurrencyFilter,
            state.toCurrencyFilter,
          ),
        ),
      );
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  void _onChangeExchangeRatesFilters(
    ChangeExchangeRatesFilters event,
    Emitter<ExchangeRatesState> emit,
  ) {
    emit(
      state.copyWith(
        dateFilter: event.date,
        fromCurrencyFilter: event.fromCurrency,
        toCurrencyFilter: event.toCurrency,
        clearDateFilter: event.date == null,
        clearFromCurrencyFilter: event.fromCurrency == null,
        clearToCurrencyFilter: event.toCurrency == null,
        filteredExchangeRates: _applyFilters(
          state.exchangeRates,
          event.date,
          event.fromCurrency,
          event.toCurrency,
        ),
      ),
    );
  }

  List<ExchangeRateDomain> _applyFilters(
    List<ExchangeRateDomain> rates,
    DateTime? date,
    String? fromCurrency,
    String? toCurrency,
  ) {
    return rates.where((rate) {
      bool dateMatch = true;
      if (date != null) {
        dateMatch =
            rate.date.year == date.year &&
            rate.date.month == date.month &&
            rate.date.day == date.day;
      }
      final fromMatch =
          fromCurrency == null || rate.fromCurrencyCode == fromCurrency;
      final toMatch = toCurrency == null || rate.toCurrencyCode == toCurrency;
      return dateMatch && fromMatch && toMatch;
    }).toList();
  }
}
