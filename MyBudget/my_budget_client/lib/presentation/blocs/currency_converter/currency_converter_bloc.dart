import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/core/database/app_database.dart' show Setting;
import 'package:rxdart/rxdart.dart';

part 'currency_converter_event.dart';
part 'currency_converter_state.dart';

class CurrencyConverterBloc
    extends Bloc<CurrencyConverterEvent, CurrencyConverterState> {
  final CurrencyRepository _currencyRepository;
  final AccountRepository _accountRepository;
  final SettingsRepository _settingsRepository;

  CurrencyConverterBloc({
    required CurrencyRepository currencyRepository,
    required AccountRepository accountRepository,
    required SettingsRepository settingsRepository,
  })  : _currencyRepository = currencyRepository,
        _accountRepository = accountRepository,
        _settingsRepository = settingsRepository,
        super(CurrencyConverterInitial()) {
    on<LoadCurrencyConverter>(_onLoadCurrencyConverter);
    on<_CurrencyConverterDataUpdated>(_onDataUpdated);
    on<AddSelectedCurrency>(_onAddSelectedCurrency);
    on<RemoveSelectedCurrency>(_onRemoveSelectedCurrency);
  }

  void _onLoadCurrencyConverter(
    LoadCurrencyConverter event,
    Emitter<CurrencyConverterState> emit,
  ) {
    emit(CurrencyConverterLoadInProgress());
    Rx.combineLatest5(
      _currencyRepository.watchCurrencies(),
      _currencyRepository.watchAllExchangeRates(),
      _accountRepository.watchAccounts(),
      _settingsRepository.watchSetting('conversion_base_currency_code'),
      _settingsRepository.watchSetting('selected_currencies'),
      (
        List<Currency> currencies,
        List<ExchangeRate> rates,
        List<Account> accounts,
        Setting? baseCurrencySetting,
        Setting? selectedCurrenciesSetting,
      ) =>
          _CurrencyConverterDataUpdated(
        allCurrencies: currencies,
        exchangeRates: rates,
        accounts: accounts,
        baseCurrencySetting: baseCurrencySetting,
        selectedCurrenciesSetting: selectedCurrenciesSetting,
      ),
    ).listen(
      (update) => add(update),
      onError: (error, stackTrace) {
        emit(CurrencyConverterLoadFailure());
      },
    );
  }

  void _onDataUpdated(
    _CurrencyConverterDataUpdated event,
    Emitter<CurrencyConverterState> emit,
  ) {
    final baseCode = event.baseCurrencySetting?.value ?? 'USD';
    final currentState = state;
    List<Currency> selected = [];

    if (currentState is CurrencyConverterLoadSuccess) {
      selected = currentState.selectedCurrencies;
    } else {
      final selectedCodes =
          event.selectedCurrenciesSetting?.value.split(',') ?? [];
      if (selectedCodes.isNotEmpty) {
        selected = event.allCurrencies
            .where((c) => selectedCodes.contains(c.code))
            .toList();
      } else if (event.allCurrencies.isNotEmpty) {
        final baseCurrency =
            event.allCurrencies.firstWhereOrNull((c) => c.code == baseCode);
        if (baseCurrency != null) {
          selected.add(baseCurrency);
        }
      }
    }

    emit(CurrencyConverterLoadSuccess(
      allCurrencies: event.allCurrencies,
      exchangeRates: event.exchangeRates,
      accounts: event.accounts,
      baseCurrencyCode: baseCode,
      selectedCurrencies: selected,
    ));
  }

  Future<void> _onAddSelectedCurrency(
    AddSelectedCurrency event,
    Emitter<CurrencyConverterState> emit,
  ) async {
    final currentState = state;
    if (currentState is CurrencyConverterLoadSuccess) {
      final updatedSelected =
          List<Currency>.from(currentState.selectedCurrencies)
            ..add(event.currency);
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
      final updatedSelected =
          List<Currency>.from(currentState.selectedCurrencies)
            ..remove(event.currency);
      emit(currentState.copyWith(selectedCurrencies: updatedSelected));
      await _saveSelectedCurrencies(updatedSelected);
    }
  }

  Future<void> _saveSelectedCurrencies(List<Currency> currencies) async {
    final deviceName =
        (await _settingsRepository.getSetting('device_name'))?.value ?? 'default';
    final currencyCodes = currencies.map((c) => c.code).join(',');
    await _settingsRepository.setSetting(
      Setting(
        key: 'selected_currencies',
        value: currencyCodes,
        device: deviceName,
      ),
    );
  }
}
