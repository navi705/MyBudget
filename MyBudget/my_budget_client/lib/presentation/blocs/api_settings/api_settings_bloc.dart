import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/api_settings_repository.dart';
import 'package:my_budget_client/domain/repositories/custom_data_source_repository.dart';
import 'package:my_budget_client/domain/entities/custom_data_source.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';
import 'package:my_budget_client/core/services/custom_api_service.dart';
import 'api_settings_event.dart';
import 'api_settings_state.dart';

class ApiSettingsBloc extends Bloc<ApiSettingsEvent, ApiSettingsState> {
  final SettingsRepository _settingsRepository;
  final ExchangeRateApiService _exchangeRateApiService;
  final SteamInventoryApiService _steamInventoryApiService;
  final InflationApiService _inflationApiService;
  final ApiSettingsRepository _apiSettingsRepository;
  final CustomDataSourceRepository _customDataSourceRepository;
  final CustomApiService _customApiService;

  ApiSettingsBloc(
    this._settingsRepository,
    this._exchangeRateApiService,
    this._steamInventoryApiService,
    this._inflationApiService, {
    required ApiSettingsRepository apiSettingsRepository,
    required CustomDataSourceRepository customDataSourceRepository,
    required CustomApiService customApiService,
  }) : _apiSettingsRepository = apiSettingsRepository,
       _customDataSourceRepository = customDataSourceRepository,
       _customApiService = customApiService,
       super(ApiSettingsInitial()) {
    on<LoadApiSettings>(_onLoadApiSettings);
    on<ManualFetchRange>(_onManualFetchRange);
    on<FetchSteamInventory>(_onFetchSteamInventory);
    on<SaveSteamId>(_onSaveSteamId);
    on<FetchInflationData>(_onFetchInflationData);
    on<UpdateApiSetting>(_onUpdateApiSetting);
    on<AddCustomDataSource>(_onAddCustomDataSource);
    on<DeleteCustomDataSource>(_onDeleteCustomDataSource);
    on<UpdateCustomDataSource>(_onUpdateCustomDataSource);
    on<ToggleStartupSync>(_onToggleStartupSync);
    on<TestCustomDataSource>(_onTestCustomDataSource);
  }

  Future<void> _onLoadApiSettings(
    LoadApiSettings event,
    Emitter<ApiSettingsState> emit,
  ) async {
    emit(ApiSettingsLoadInProgress());
    try {
      final steamIdSetting = await _settingsRepository.getSetting('steam_id');
      final apiSettings = await _apiSettingsRepository.getAllSettings();
      final customDataSources = await _customDataSourceRepository
          .getAllDataSources();
      final startupSyncSetting = await _settingsRepository.getSetting(
        'startup_sync_enabled',
      );
      final startupSyncEnabled =
          startupSyncSetting?.value.toLowerCase() == 'true';

      emit(
        ApiSettingsLoadSuccess(
          steamId: steamIdSetting?.value,
          apiSettings: apiSettings,
          customDataSources: customDataSources,
          startupSyncEnabled: startupSyncEnabled,
        ),
      );
    } catch (e) {
      emit(ApiSettingsFailure(e.toString()));
    }
  }

  Future<void> _onToggleStartupSync(
    ToggleStartupSync event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        await _settingsRepository.saveSetting(
          'startup_sync_enabled',
          event.enabled.toString(),
        );
        emit(currentState.copyWith(startupSyncEnabled: event.enabled));
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
    }
  }

  Future<void> _onUpdateApiSetting(
    UpdateApiSetting event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        final setting = currentState.apiSettings.firstWhere(
          (s) => s.id == event.id,
        );
        final updatedSetting = setting.copyWith(
          enabled: event.enabled,
          autoFetch: event.autoFetch,
        );
        await _apiSettingsRepository.saveSetting(updatedSetting);
        add(LoadApiSettings());
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
    }
  }

  Future<void> _onAddCustomDataSource(
    AddCustomDataSource event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        final newSource = CustomDataSourceDomain(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: event.name,
          url: event.url,
          dataType: ApiDataType.values[event.dataType],
          enabled: true,
          autoFetch: false,
        );
        await _customDataSourceRepository.saveDataSource(newSource);
        add(LoadApiSettings());
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
    }
  }

  Future<void> _onDeleteCustomDataSource(
    DeleteCustomDataSource event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        await _customDataSourceRepository.deleteDataSource(event.id);
        add(LoadApiSettings());
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
    }
  }

  Future<void> _onUpdateCustomDataSource(
    UpdateCustomDataSource event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        final source = currentState.customDataSources.firstWhere(
          (s) => s.id == event.id,
        );
        final updatedSource = source.copyWith(
          enabled: event.enabled,
          autoFetch: event.autoFetch,
        );
        await _customDataSourceRepository.saveDataSource(updatedSource);
        add(LoadApiSettings());
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
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
        await _exchangeRateApiService.fetchRatesForRange(
          event.start,
          event.end,
        );
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
        await _steamInventoryApiService.fetchSteamInventoryValue(
          event.accountId,
          event.game,
        );
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

  Future<void> _onFetchInflationData(
    FetchInflationData event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      emit(currentState.copyWith(isOperationInProgress: true));
      try {
        await _inflationApiService.fetchInflationForCountry(
          event.countryCode,
          event.dateRange,
        );
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

  Future<void> _onTestCustomDataSource(
    TestCustomDataSource event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      emit(currentState.copyWith(isOperationInProgress: true));
      try {
        final result = await _customApiService.testConnection(event.url);
        emit(
          currentState.copyWith(
            isOperationInProgress: false,
            testResult: result,
          ),
        );
      } catch (e) {
        emit(
          currentState.copyWith(
            isOperationInProgress: false,
            lastError: e.toString(),
            testResult: false,
          ),
        );
      }
    }
  }
}
