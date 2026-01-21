import 'package:flutter/foundation.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/api_settings_repository.dart';
import 'package:my_budget_client/domain/repositories/custom_data_source_repository.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';
import 'package:my_budget_client/core/services/custom_api_service.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:my_budget_client/data/api/external_data.dart';

class StartupSyncService {
  final SettingsRepository _settingsRepository;
  final ApiSettingsRepository _apiSettingsRepository;
  final CustomDataSourceRepository _customDataSourceRepository;
  final ExchangeRateApiService _exchangeRateApiService;
  final InflationApiService _inflationApiService;
  final SteamInventoryApiService _steamInventoryApiService;
  final CustomApiService _customApiService;
  final ServerSyncService _serverSyncService;

  StartupSyncService(
    this._settingsRepository,
    this._apiSettingsRepository,
    this._customDataSourceRepository,
    this._exchangeRateApiService,
    this._inflationApiService,
    this._steamInventoryApiService,
    this._customApiService,
    this._serverSyncService,
  );

  Future<void> executeStartupSync() async {
    debugPrint('[StartupSyncService] Checking startup sync settings...');

    // 1. Check Global Master Switch
    final startupSyncEnabledRef = await _settingsRepository.getSetting(
      'startup_sync_enabled',
    );
    final isStartupSyncEnabled = startupSyncEnabledRef?.value == 'true';

    if (!isStartupSyncEnabled) {
      debugPrint(
        '[StartupSyncService] Startup sync is DISABLED. Skipping all fetches.',
      );
      return;
    }

    debugPrint(
      '[StartupSyncService] Startup sync is ENABLED. Processing sources...',
    );

    // 2. Process Built-in APIs
    final apiSettings = await _apiSettingsRepository.getAllSettings();
    for (final setting in apiSettings) {
      if (setting.enabled && setting.autoFetch) {
        debugPrint('[StartupSyncService] Fetching ${setting.id}...');
        await _fetchBuiltInApi(setting.id);
      }
    }

    // 3. Process Custom Data Sources
    final customSources = await _customDataSourceRepository.getAllDataSources();
    for (final source in customSources) {
      if (source.enabled && source.autoFetch) {
        debugPrint(
          '[StartupSyncService] Fetching custom source: ${source.name} (${source.url})...',
        );
        await _customApiService.fetchCustomData(source.url);
      }
    }

    // 4. Process Server Sync (New)
    try {
      debugPrint('[StartupSyncService] Starting Server Sync...');
      // Initialize WebSocket connection for the session
      _serverSyncService.initWebSocket();
      // Perform initial sync
      await _serverSyncService.sync();
    } catch (e) {
      debugPrint('[StartupSyncService] Server Sync failed: $e');
    }

    debugPrint('[StartupSyncService] Startup sync completed.');
  }

  Future<void> _fetchBuiltInApi(String id) async {
    try {
      switch (id) {
        case 'exchange_rates':
          await _exchangeRateApiService.fetchRatesForDate(DateTime.now());
          break;
        case 'inflation':
          // Default to Serbia and recent range for auto-fetch, or make this configurable later.
          // Currently hardcoded in initialization_data.dart as 'SRB' and '2000:2024'.
          // Ideally, we should store these parameters in the ApiSetting or a separate config.
          // For now, preserving existing behavior:
          await _inflationApiService.fetchInflationForCountry(
            'SRB',
            '2000:2024',
          );
          break;
        case 'steam_inventory': // Assuming 'steam_inventory' is the ID used in seed data, need to verify.
          // Actually, seed data might use a different ID. Let's check or be safe.
          // Based on previous files, 'steam' or similar?
          // Let's check logic in initialization_data.dart: it reads 'steam_id' setting.
          final steamIdSetting = await _settingsRepository.getSetting(
            'steam_id',
          );
          if (steamIdSetting != null && steamIdSetting.value.isNotEmpty) {
            final accountId = int.tryParse(steamIdSetting.value);
            if (accountId != null) {
              await _steamInventoryApiService.fetchSteamInventoryValue(
                accountId,
                GameApiSteam.cs2,
              );
            }
          }
          break;
        case 'assets':
          // Asset prices might be handled by one of the above or a separate service?
          // ExternalData has getCurrenciesFromFreeExchangeRates but that's part of exchange rates.
          // Leaving placeholder for now if 'assets' ID exists.
          break;
        default:
          debugPrint('[StartupSyncService] Unknown built-in API ID: $id');
      }
    } catch (e) {
      debugPrint('[StartupSyncService] Error fetching $id: $e');
    }
  }
}
