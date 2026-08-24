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

    // 1. Initialize Server Sync — runs independently of startup_sync_enabled
    // so that background sync works even when API auto-fetch is disabled.
    try {
      final serverEnabledSetting = await _settingsRepository.getSetting(
        'server_sync_enabled',
      );
      if (serverEnabledSetting?.value == 'true') {
        debugPrint('[StartupSyncService] Starting Server Sync...');
        // Initialize WebSocket connection for the session
        await _serverSyncService.initWebSocket();
        // Initialize DB Auto-Sync (Instant Push) + periodic fallback timer
        await _serverSyncService.initAutoSync();
        // Perform initial sync
        await _serverSyncService.sync();
      }
    } catch (e) {
      debugPrint('[StartupSyncService] Server Sync failed: $e');
    }

    // 2. Check Global Master Switch for API auto-fetches
    final startupSyncEnabledRef = await _settingsRepository.getSetting(
      'startup_sync_enabled',
    );
    final isStartupSyncEnabled = startupSyncEnabledRef?.value == 'true';

    if (!isStartupSyncEnabled) {
      debugPrint(
        '[StartupSyncService] Startup sync is DISABLED. Skipping all API fetches.',
      );
      return;
    }

    final now = DateTime.now();

    // 3. Detect region on first launch if not set
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

    // 4. Process Built-in APIs
    final apiSettings = await _apiSettingsRepository.getAllSettings();
    debugPrint(
      '[DIAG][StartupSync] Found ${apiSettings.length} built-in API settings: ${apiSettings.map((s) => '${s.id}(enabled=${s.enabled},autoFetch=${s.autoFetch},lastFetchAt=${s.lastFetchAt})').join(', ')}',
    );
    for (final setting in apiSettings) {
      debugPrint(
        '[DIAG][StartupSync] Processing built-in API: ${setting.id}, enabled=${setting.enabled}, autoFetch=${setting.autoFetch}',
      );
      if (setting.enabled && setting.autoFetch) {
        if (setting.lastFetchAt != null &&
            _isSameDay(now, setting.lastFetchAt!)) {
          debugPrint(
            '[StartupSyncService] Built-in API ${setting.id} already fetched today. Skipping.',
          );
          continue;
        }
        debugPrint('[StartupSyncService] Fetching ${setting.id}...');
        await _fetchBuiltInApi(setting.id);
      } else {
        debugPrint(
          '[DIAG][StartupSync] Skipping ${setting.id}: enabled=${setting.enabled}, autoFetch=${setting.autoFetch}',
        );
      }
    }

    // 5. Process Custom Data Sources
    final customSources = await _customDataSourceRepository.getAllDataSources();
    debugPrint(
      '[DIAG][StartupSync] Found ${customSources.length} custom data sources: ${customSources.map((s) => '${s.name}(enabled=${s.enabled},autoFetch=${s.autoFetch},dataType=${s.dataType},lastFetchAt=${s.lastFetchAt})').join(', ')}',
    );
    for (final source in customSources) {
      debugPrint(
        '[DIAG][StartupSync] Processing custom source: ${source.name}, enabled=${source.enabled}, autoFetch=${source.autoFetch}',
      );
      if (source.enabled && source.autoFetch) {
        if (source.lastFetchAt != null &&
            _isSameDay(now, source.lastFetchAt!)) {
          debugPrint(
            '[StartupSyncService] Custom source ${source.name} already fetched today. Skipping.',
          );
          continue;
        }
        debugPrint(
          '[StartupSyncService] Fetching custom source: ${source.name} (${source.url})...',
        );
        try {
          await _customApiService.fetchCustomData(source.url);
          // Update lastFetchAt
          await _customDataSourceRepository.saveDataSource(
            source.copyWith(lastFetchAt: DateTime.now()),
          );
        } catch (e) {
          debugPrint(
            '[StartupSyncService] Error fetching custom source ${source.name}: $e',
          );
        }
      } else {
        debugPrint(
          '[DIAG][StartupSync] Skipping custom source ${source.name}: enabled=${source.enabled}, autoFetch=${source.autoFetch}',
        );
      }
    }

    debugPrint('[StartupSyncService] Startup sync completed.');
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// The built-in providers this service knows how to fetch.
  ///
  /// An id outside this set fetches nothing. It used to be stamped
  /// `lastFetchAt` anyway, and the daily guard in [executeStartupSync] then
  /// read that stamp as "already fetched today", so a provider the app could
  /// not fetch looked to every later launch like one that had already
  /// succeeded.
  @visibleForTesting
  static const Set<String> builtInApiIds = {
    'exchange_rates',
    'inflation',
    'steam_inventory',
    'assets',
  };

  /// The Steam inventory this device is set up to read, or null when it is not
  /// set up to read one.
  ///
  /// Null covers a missing id, a blank one and one that is not a number - all
  /// three mean there is nothing to ask Steam for, and none of them is a
  /// failure the user can be told about from here. What matters is that they
  /// are not mistaken for a completed fetch: the id can be filled in an hour
  /// later, and a stamp written now would hold the first real fetch until the
  /// next day.
  @visibleForTesting
  static ({int accountId, GameApiSteam game})? steamTargetFor(
    String? steamId,
    String? steamGame,
  ) {
    final trimmed = steamId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    final accountId = int.tryParse(trimmed);
    if (accountId == null) return null;
    final game = steamGame == null
        ? GameApiSteam.cs2
        : GameApiSteam.values.firstWhere(
            (g) => g.name == steamGame,
            orElse: () => GameApiSteam.cs2,
          );
    return (accountId: accountId, game: game);
  }

  /// Runs [id]'s fetch, stamping `lastFetchAt` only if one actually ran.
  ///
  /// Only a fetch that ran earns a `lastFetchAt` stamp. The stamp is what the
  /// daily guard skips on, so writing it for a branch that fetched nothing -
  /// an unknown id, or Steam with no account configured - suppressed the next
  /// launch's attempt as well, and every launch that day after it.
  Future<void> _fetchBuiltInApi(String id) async {
    debugPrint('[DIAG][StartupSync] _fetchBuiltInApi called with id="$id"');
    if (!builtInApiIds.contains(id)) {
      debugPrint('[StartupSyncService] Unknown built-in API ID: $id');
      return;
    }
    var fetched = false;
    try {
      switch (id) {
        case 'exchange_rates':
          await _exchangeRateApiService.fetchRatesForDate(DateTime.now());
          fetched = true;
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
          fetched = true;
          break;
        case 'steam_inventory':
        case 'assets':
          debugPrint(
            '[DIAG][StartupSync] case "assets"/"steam_inventory" matched for id="$id" — ONLY Steam inventory is handled here. Non-Steam stock assets are NOT fetched by this branch.',
          );
          final steamIdSetting = await _settingsRepository.getSetting(
            'steam_id',
          );
          final steamGameSetting = await _settingsRepository.getSetting(
            'steam_game',
          );
          debugPrint(
            '[DIAG][StartupSync] steam_id setting: ${steamIdSetting?.value}, steam_game setting: ${steamGameSetting?.value}',
          );

          final target = steamTargetFor(
            steamIdSetting?.value,
            steamGameSetting?.value,
          );
          if (target != null) {
            debugPrint(
              '[StartupSyncService] Fetching Steam items for ${target.game}...',
            );
            await _steamInventoryApiService.fetchSteamInventoryValue(
              target.accountId,
              target.game,
            );
            fetched = true;
          }
          break;
      }
      // Update lastFetchAt after successful fetch
      if (!fetched) {
        return;
      }
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
