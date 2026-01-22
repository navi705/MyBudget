import 'package:flutter/foundation.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/api_settings_repository.dart';
import 'package:my_budget_client/domain/repositories/custom_data_source_repository.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';
import 'package:my_budget_client/core/services/custom_api_service.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:my_budget_client/core/utils/region_utils.dart';
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

    // 2. Detect region on first launch if not set
    final inflationCountryRef = await _settingsRepository.getSetting(
      'default_inflation_country',
    );
    if (inflationCountryRef == null) {
      final alpha2 = RegionUtils.detectDeviceRegion();
      if (alpha2 != null) {
        final alpha3 = RegionUtils.mapAlpha2ToAlpha3(alpha2);
        if (alpha3 != null) {
          debugPrint(
            '[StartupSyncService] First launch detected. Auto-setting inflation country to $alpha3 (from $alpha2)',
          );
          await _settingsRepository.saveSetting(
            'default_inflation_country',
            alpha3,
          );
        }
      }
    }

    // 3. Process Built-in APIs
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
          final countrySetting = await _settingsRepository.getSetting(
            'default_inflation_country',
          );
          final countryCode = countrySetting?.value ?? 'SRB';

          debugPrint(
            '[StartupSyncService] Fetching inflation for $countryCode...',
          );
          // Auto-fetch for the last 25 years
          final currentYear = DateTime.now().year;
          final range = '${currentYear - 25}:$currentYear';

          await _inflationApiService.fetchInflationForCountry(
            countryCode,
            range,
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
      // Update lastFetchAt after successful fetch
      final setting = await _apiSettingsRepository.getSettingById(id);
      if (setting != null) {
        await _apiSettingsRepository.saveSetting(
          setting.copyWith(lastFetchAt: DateTime.now()),
        );
      }
    } catch (e) {
      debugPrint('[StartupSyncService] Error fetching $id: $e');
    }
  }
}
