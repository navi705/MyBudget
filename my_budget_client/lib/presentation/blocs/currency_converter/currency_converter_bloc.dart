import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/core/utils/currency_converter.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
// import 'package:my_budget_client/domain/entities/settings.dart';

part 'currency_converter_event.dart';
part 'currency_converter_state.dart';

class CurrencyConverterBloc
    extends Bloc<CurrencyConverterEvent, CurrencyConverterState> {
  final CurrencyRepository _currencyRepository;
  final SettingsRepository _settingsRepository;
  List<Currency>? _allCurrenciesCache;

  /// Rate sets already fetched, keyed by the exact date asked for.
  ///
  /// `getLatestExchangeRates` is a self-join with a `GROUP BY from, to` over
  /// the whole rate table, and the accounts screen fires one per date change -
  /// so once per chevron tap, including every tap that walks back onto a month
  /// this session has already priced. Same date, same query, same rows.
  final Map<DateTime, List<ExchangeRateDomain>> _ratesByDate = {};

  /// How many dates the cache above keeps before dropping its oldest entry.
  ///
  /// A rate set is the whole table for one day; a session that scrolls through
  /// years of history should not accumulate them without limit. Insertion
  /// order is eviction order, which is close enough to "least recently first
  /// asked for" at this size.
  static const int _maxCachedRateDates = 24;

  StreamSubscription<void>? _rateChangesSubscription;

  CurrencyConverterBloc({
    required CurrencyRepository currencyRepository,
    required SettingsRepository settingsRepository,
  }) : _currencyRepository = currencyRepository,
       _settingsRepository = settingsRepository,
       super(CurrencyConverterInitial()) {
    on<LoadCurrencyConverter>(_onLoadCurrencyConverter);
    on<DateChanged>(_onDateChanged);
    on<AddSelectedCurrency>(_onAddSelectedCurrency);
    on<RemoveSelectedCurrency>(_onRemoveSelectedCurrency);

    // Which cached dates a written rate row can affect is not worth working
    // out: any write empties the lot. This is the signal that makes the cache
    // safe - without it, a rate refreshed on the Exchange Rates screen would
    // keep being answered from rows fetched before it landed.
    _rateChangesSubscription = _currencyRepository
        .watchExchangeRateChanges()
        .listen((_) => _ratesByDate.clear());
  }

  /// The rate set for [date], from the cache when it is already known.
  Future<List<ExchangeRateDomain>> _ratesFor(DateTime date) async {
    final cached = _ratesByDate[date];
    if (cached != null) return cached;

    final rates = await _currencyRepository.getLatestExchangeRates(date);
    if (_ratesByDate.length >= _maxCachedRateDates) {
      _ratesByDate.remove(_ratesByDate.keys.first);
    }
    _ratesByDate[date] = rates;
    return rates;
  }

  @override
  Future<void> close() async {
    await _rateChangesSubscription?.cancel();
    return super.close();
  }

  Future<void> _onLoadCurrencyConverter(
    LoadCurrencyConverter event,
    Emitter<CurrencyConverterState> emit,
  ) async {
    emit(CurrencyConverterLoadInProgress());
    // A reload exists to re-read everything from the database, so nothing
    // remembered from before it may survive it.
    _ratesByDate.clear();
    try {
      final allCurrencies = _allCurrenciesCache ??= await _currencyRepository
          .getCurrencies();

      final results = await Future.wait([
        _settingsRepository.getSetting('conversion_base_currency_code'),
        _settingsRepository.getSetting('selected_currencies'),
      ]);

      final baseCurrencySetting = results[0];
      final selectedCurrenciesSetting = results[1];

      final baseCode = baseCurrencySetting?.value ?? 'EUR';
      List<Currency> selected = [];

      final selectedCodes = selectedCurrenciesSetting?.value.split(',') ?? [];
      if (selectedCodes.isNotEmpty) {
        selected = allCurrencies
            .where((c) => selectedCodes.contains(c.code))
            .toList();
      } else if (allCurrencies.isNotEmpty) {
        final baseCurrency = allCurrencies.firstWhereOrNull(
          (c) => c.code == baseCode,
        );
        if (baseCurrency != null) {
          selected.add(baseCurrency);
        }
      }

      final exchangeRates = await _currencyRepository.getLatestExchangeRates(
        DateTime.now(),
      );

      emit(
        CurrencyConverterLoadSuccess(
          allCurrencies: allCurrencies,
          exchangeRates: exchangeRates,
          baseCurrencyCode: baseCode,
          selectedCurrencies: selected,
        ),
      );
    } catch (e) {
      emit(CurrencyConverterLoadFailure());
    }
  }

  Future<void> _onDateChanged(
    DateChanged event,
    Emitter<CurrencyConverterState> emit,
  ) async {
    final currentState = state;
    if (currentState is CurrencyConverterLoadSuccess) {
      try {
        final fetched = await _ratesFor(event.date);

        // Most date steps resolve to the rows already on the state: the table
        // stores a rate per pair per fetch, not per day, so a month back
        // usually prices from exactly the same set. Handing `copyWith` the
        // list it already holds is what lets it carry the built converter and
        // its memo over - and it makes the copy equal to the current state, so
        // bloc drops the emit and the accounts screen does not rebuild at all.
        final exchangeRates =
            const ListEquality<ExchangeRateDomain>().equals(
              fetched,
              currentState.exchangeRates,
            )
            ? currentState.exchangeRates
            : fetched;

        emit(currentState.copyWith(exchangeRates: exchangeRates));
      } catch (e) {
        // We can choose to emit a failure state or just log the error
        // and keep the old rates. For now, we keep the old rates.
      }
    }
  }

  Future<void> _onAddSelectedCurrency(
    AddSelectedCurrency event,
    Emitter<CurrencyConverterState> emit,
  ) async {
    final currentState = state;
    if (currentState is CurrencyConverterLoadSuccess) {
      final updatedSelected = List<Currency>.from(
        currentState.selectedCurrencies,
      )..add(event.currency);
      emit(currentState.copyWith(selectedCurrencies: updatedSelected));
      await _saveSelectedCurrencies(updatedSelected);
    }
  }

  Future<void> _onRemoveSelectedCurrency(
    RemoveSelectedCurrency event,
    Emitter<CurrencyConverterState> emit,
  ) async {
    final currentState = state;
    if (currentState is CurrencyConverterLoadSuccess) {
      final updatedSelected = List<Currency>.from(
        currentState.selectedCurrencies,
      )..remove(event.currency);
      emit(currentState.copyWith(selectedCurrencies: updatedSelected));
      await _saveSelectedCurrencies(updatedSelected);
    }
  }

  Future<void> _saveSelectedCurrencies(List<Currency> currencies) async {
    final currencyCodes = currencies.map((c) => c.code).join(',');
    await _settingsRepository.saveSetting('selected_currencies', currencyCodes);
  }
}
