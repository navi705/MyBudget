import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/api_settings_repository.dart';
import 'package:my_budget_client/domain/repositories/custom_data_source_repository.dart';
import 'package:my_budget_client/domain/entities/custom_data_source.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';
import 'package:my_budget_client/core/services/custom_api_service.dart';
import 'package:my_budget_client/data/api/external_data.dart';
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
    on<ToggleAllCustomSources>(_onToggleAllCustomSources);
    on<SaveSteamGame>(_onSaveSteamGame);
    on<EditCustomDataSource>(_onEditCustomDataSource);
  }

  Future<void> _onEditCustomDataSource(
    EditCustomDataSource event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        final existing = currentState.customDataSources.firstWhere(
          (s) => s.id == event.id,
        );
        final updated = existing.copyWith(
          name: event.name,
          url: event.url,
          dataType: ApiDataType.values[event.dataType],
        );
        await _customDataSourceRepository.saveDataSource(updated);
        add(const LoadApiSettings(silent: true));
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
    }
  }

  Future<void> _onToggleAllCustomSources(
    ToggleAllCustomSources event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        final sourcesToUpdate = currentState.customDataSources
            .where((s) => s.dataType == event.dataType)
            .toList();

        for (final source in sourcesToUpdate) {
          final updated = source.copyWith(enabled: event.enabled);
          await _customDataSourceRepository.saveDataSource(updated);
        }
        add(const LoadApiSettings(silent: true));
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
    }
  }

  Future<void> _onLoadApiSettings(
    LoadApiSettings event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (!event.silent || state is! ApiSettingsLoadSuccess) {
      emit(ApiSettingsLoadInProgress());
    }
    try {
      final steamIdSetting = await _settingsRepository.getSetting('steam_id');
      final steamGameSetting = await _settingsRepository.getSetting(
        'steam_game',
      );
      final apiSettings = (await _apiSettingsRepository.getAllSettings())
        ..sort((a, b) => a.id.compareTo(b.id));
      final customDataSources =
          (await _customDataSourceRepository.getAllDataSources())
            ..sort((a, b) => a.id.compareTo(b.id));
      final startupSyncSetting = await _settingsRepository.getSetting(
        'startup_sync_enabled',
      );
      final startupSyncEnabled =
          startupSyncSetting?.value.toLowerCase() == 'true';

      GameApiSteam? steamGame;
      if (steamGameSetting != null) {
        steamGame = GameApiSteam.values.firstWhere(
          (g) => g.name == steamGameSetting.value,
          orElse: () => GameApiSteam.cs2,
        );
      }

      emit(
        ApiSettingsLoadSuccess(
          steamId: steamIdSetting?.value,
          steamGame: steamGame,
          apiSettings: apiSettings,
          customDataSources: customDataSources,
          startupSyncEnabled: startupSyncEnabled,
        ),
      );
    } catch (e) {
      emit(ApiSettingsFailure(e.toString()));
    }
  }

  Future<void> _onSaveSteamGame(
    SaveSteamGame event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        await _settingsRepository.saveSetting('steam_game', event.game.name);
        emit(currentState.copyWith(steamGame: event.game));
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
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

        bool newEnabled = event.enabled ?? setting.enabled;
        bool newAutoFetch = event.autoFetch ?? setting.autoFetch;

        // "Logic Consolidation" convenience:
        if (event.enabled == true && setting.enabled == false) {
          // Just turned ON: also turn on autoFetch by default
          newAutoFetch = true;
        } else if (event.enabled == false) {
          // Turned OFF: force autoFetch off
          newAutoFetch = false;
        }

        final updatedSetting = setting.copyWith(
          enabled: newEnabled,
          autoFetch: newAutoFetch,
        );
        await _apiSettingsRepository.saveSetting(updatedSetting);
        add(const LoadApiSettings(silent: true));
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
        add(const LoadApiSettings(silent: true));
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
        add(const LoadApiSettings(silent: true));
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

        bool newEnabled = event.enabled ?? source.enabled;
        bool newAutoFetch = event.autoFetch ?? source.autoFetch;

        if (event.enabled == true && source.enabled == false) {
          newAutoFetch = true;
        } else if (event.enabled == false) {
          newAutoFetch = false;
        }

        final updatedSource = source.copyWith(
          enabled: newEnabled,
          autoFetch: newAutoFetch,
        );
        await _customDataSourceRepository.saveDataSource(updatedSource);
        add(const LoadApiSettings(silent: true));
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
        // User requested that "Test" also imports the data immediately.
        // fetchCustomData throws an exception if it fails, so if we get here, it succeeded.
        await _customApiService.fetchCustomData(event.url);

        // Update lastFetchAt in database
        final source = currentState.customDataSources.firstWhere(
          (s) => s.id == event.id,
        );
        final updatedSource = source.copyWith(lastFetchAt: DateTime.now());
        await _customDataSourceRepository.saveDataSource(updatedSource);

        final newResults = Map<String, bool>.from(currentState.testResults);
        newResults[event.url] = true;

        // Note: we don't call LoadApiSettings here because we want to maintain the test result state immediately.
        // But we should update the local list in the state too.
        final newSources = currentState.customDataSources.map((s) {
          return s.id == event.id ? updatedSource : s;
        }).toList();

        emit(
          currentState.copyWith(
            isOperationInProgress: false,
            testResults: newResults,
            customDataSources: newSources,
          ),
        );
      } catch (e) {
        final newResults = Map<String, bool>.from(currentState.testResults);
        newResults[event.url] = false;

        emit(
          currentState.copyWith(
            isOperationInProgress: false,
            lastError: e.toString(),
            testResults: newResults,
          ),
        );
      }
    }
  }
}
