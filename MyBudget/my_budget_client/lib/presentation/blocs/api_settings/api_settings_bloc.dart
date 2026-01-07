import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';
import 'api_settings_event.dart';
import 'api_settings_state.dart';

class ApiSettingsBloc extends Bloc<ApiSettingsEvent, ApiSettingsState> {
  final SettingsRepository _settingsRepository;
  final ExchangeRateApiService _exchangeRateApiService;
  final SteamInventoryApiService _steamInventoryApiService;

  ApiSettingsBloc(
    this._settingsRepository,
    this._exchangeRateApiService,
    this._steamInventoryApiService,
  ) : super(ApiSettingsInitial()) {
    on<LoadApiSettings>(_onLoadApiSettings);
    on<ManualFetchRange>(_onManualFetchRange);
    on<FetchSteamInventory>(_onFetchSteamInventory);
    on<SaveSteamId>(_onSaveSteamId);
  }

  Future<void> _onLoadApiSettings(
    LoadApiSettings event,
    Emitter<ApiSettingsState> emit,
  ) async {
    emit(ApiSettingsLoadInProgress());
    try {
      var steamIdSetting = await _settingsRepository.getSetting('steam_id');
      if (steamIdSetting == null && kDebugMode) {
        const defaultSteamId = '76561198085715972';
        await _settingsRepository.saveSetting('steam_id', defaultSteamId);
        steamIdSetting = await _settingsRepository.getSetting('steam_id');
      }
      emit(ApiSettingsLoadSuccess(steamId: steamIdSetting?.value));
    } catch (e) {
      emit(ApiSettingsFailure(e.toString()));
    }
  }

  Future<void> _onManualFetchRange(
    ManualFetchRange event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      emit(currentState.copyWith(isOperationInProgress: true));
      try {
        await _exchangeRateApiService.fetchRatesForRange(event.start, event.end);
        emit(currentState.copyWith(isOperationInProgress: false));
      } catch (e) {
        emit(
          currentState.copyWith(
            isOperationInProgress: false,
            lastError: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _onFetchSteamInventory(
    FetchSteamInventory event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      emit(currentState.copyWith(isOperationInProgress: true));
      try {
        await _steamInventoryApiService.fetchSteamInventoryValue(event.accountId, event.game);
        emit(currentState.copyWith(isOperationInProgress: false));
      } catch (e) {
        emit(
          currentState.copyWith(
            isOperationInProgress: false,
            lastError: e.toString(),
          ),
        );
      }
    }
  }

  Future<void> _onSaveSteamId(
    SaveSteamId event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        await _settingsRepository.saveSetting('steam_id', event.steamId);
        emit(currentState.copyWith(steamId: event.steamId));
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
    }
  }
} 