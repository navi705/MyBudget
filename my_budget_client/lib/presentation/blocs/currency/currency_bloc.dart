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

  /// Currencies and designations are watched through a single combined stream,
  /// so there is exactly one subscription to hold.
  StreamSubscription? _currenciesSubscription;

  CurrencyBloc({required CurrencyRepository currencyRepository})
    : _currencyRepository = currencyRepository,
      super(CurrencyInitial()) {
    on<LoadCurrencies>(_onLoadCurrencies);
    on<_CurrenciesAndDesignationsUpdated>(_onCurrenciesAndDesignationsUpdated);
    on<_CurrencyLoadFailed>(_onCurrencyLoadFailed);
  }

  Future<void> _onLoadCurrencies(
    LoadCurrencies event,
    Emitter<CurrencyState> emit,
  ) async {
    emit(CurrencyLoadInProgress());
    // Awaited: an un-awaited cancel lets the outgoing combined stream deliver
    // one last pair after the new subscription is live, so a stale currency
    // list can land on top of the fresh one.
    await _currenciesSubscription?.cancel();

    _currenciesSubscription =
        Rx.combineLatest2(
          _currencyRepository.watchCurrencies(),
          _currencyRepository.watchAllCurrencyDesignations(),
          // The combiner only combines. Dispatching from inside it happened to work
          // because its void return was piped into `listen(null)`, but a combiner
          // is not a delivery callback and must stay free of side effects.
          (List<Currency> currencies, List<CurrencyDesignation> designations) =>
              _CurrenciesAndDesignationsUpdated(currencies, designations),
        ).listen(
          add,
          // Routed as an event rather than emitted here: a stream error arrives
          // long after this handler has returned, and by then this Emitter is
          // completed — emitting on it threw "Emitter is already completed" and
          // CurrencyLoadFailure was never reachable.
          onError: (error, stackTrace) => add(const _CurrencyLoadFailed()),
        );
  }

  void _onCurrencyLoadFailed(
    _CurrencyLoadFailed event,
    Emitter<CurrencyState> emit,
  ) {
    emit(CurrencyLoadFailure());
  }

  void _onCurrenciesAndDesignationsUpdated(
    _CurrenciesAndDesignationsUpdated event,
    Emitter<CurrencyState> emit,
  ) {
    emit(
      CurrencyLoadSuccess(
        currencies: event.currencies,
        designations: event.designations,
      ),
    );
  }

  @override
  Future<void> close() async {
    // Awaited: the listener above calls add(), and adding after the event
    // controller is closed throws. Cancelling without awaiting leaves that race
    // open on every screen dismissal.
    await _currenciesSubscription?.cancel();
    return super.close();
  }
}
