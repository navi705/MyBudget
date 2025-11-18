import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:rxdart/rxdart.dart';

part 'currency_event.dart';
part 'currency_state.dart';

class CurrencyBloc extends Bloc<CurrencyEvent, CurrencyState> {
  final CurrencyRepository _currencyRepository;
  StreamSubscription? _currenciesSubscription;
  StreamSubscription? _designationsSubscription;

  CurrencyBloc({required CurrencyRepository currencyRepository})
      : _currencyRepository = currencyRepository,
        super(CurrencyInitial()) {
    on<LoadCurrencies>(_onLoadCurrencies);
    on<_CurrenciesAndDesignationsUpdated>(_onCurrenciesAndDesignationsUpdated);
  }

  void _onLoadCurrencies(LoadCurrencies event, Emitter<CurrencyState> emit) {
    emit(CurrencyLoadInProgress());
    _currenciesSubscription?.cancel();
    _designationsSubscription?.cancel();

    _currenciesSubscription = Rx.combineLatest2(
      _currencyRepository.watchCurrencies(),
      _currencyRepository.watchAllCurrencyDesignations(),
      (List<Currency> currencies, List<CurrencyDesignation> designations) =>
          add(_CurrenciesAndDesignationsUpdated(currencies, designations)),
    ).listen(
      null,
      onError: (error, stackTrace) {
        emit(CurrencyLoadFailure());
      },
    );
  }

  void _onCurrenciesAndDesignationsUpdated(
    _CurrenciesAndDesignationsUpdated event,
    Emitter<CurrencyState> emit,
  ) {
    emit(CurrencyLoadSuccess(
      currencies: event.currencies,
      designations: event.designations,
    ));
  }

  @override
  Future<void> close() {
    _currenciesSubscription?.cancel();
    _designationsSubscription?.cancel();
    return super.close();
  }
}
