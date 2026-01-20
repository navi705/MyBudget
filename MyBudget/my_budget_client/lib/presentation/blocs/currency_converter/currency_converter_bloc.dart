import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
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
  }

  Future<void> _onLoadCurrencyConverter(
    LoadCurrencyConverter event,
    Emitter<CurrencyConverterState> emit,
  ) async {
    emit(CurrencyConverterLoadInProgress());
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
        final exchangeRates = await _currencyRepository.getLatestExchangeRates(
          event.date,
        );
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
