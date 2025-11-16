import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';

part 'currency_event.dart';
part 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  final CurrencyRepository _currencyRepository;
  StreamSubscription? _currenciesSubscription;

  CurrencyBloc({required CurrencyRepository currencyRepository})
      : _currencyRepository = currencyRepository,
        super(CurrencyInitial()) {
    on<LoadCurrencies>(_onLoadCurrencies);
    on<_CurrenciesUpdated>(_onCurrenciesUpdated);
  }

  void _onLoadCurrencies(LoadCurrencies event, Emitter<CurrencyState> emit) {
    emit(CurrencyLoadInProgress());
    _currenciesSubscription?.cancel();
    _currenciesSubscription = _currencyRepository.watchCurrencies().listen(
          (currencies) => add(_CurrenciesUpdated(currencies)),
          onError: (error, stackTrace) {
            emit(CurrencyLoadFailure());
          },
        );
  }

  void _onCurrenciesUpdated(
    _CurrenciesUpdated event,
    Emitter<CurrencyState> emit,
  ) {
    emit(CurrencyLoadSuccess(event.currencies));
  }

  @override
  Future<void> close() {
    _currenciesSubscription?.cancel();
    return super.close();
  }
}
