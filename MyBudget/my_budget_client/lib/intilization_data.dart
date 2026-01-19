import 'package:flutter/foundation.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'dart:convert';
import 'dart:io';

/// Loads local data only (files, no API calls).
/// This is fast and blocks the splash screen.
Future<void> _loadLocalData() async {
  // Ensure currency data is hydrated from local files (JSON/Binary)
  await ImportDataUtils.getCurrenciesInitial();

  // Load Debug Steam Data from local file
  if (kDebugMode) {
    await _loadDebugSteamData();
  }
}

/// Fetches fresh data from APIs.
/// This runs in the background and doesn't block UI.
Future<void> _fetchApiData() async {
  try {
    // Fetch today's exchange rates from API
    final exchangeRateService = sl<ExchangeRateApiService>();
    await exchangeRateService.fetchRatesForDate(DateTime.now());
    debugPrint('API: Exchange rates fetched');
  } catch (e) {
    debugPrint('API: Failed to fetch exchange rates: $e');
  }

  try {
    // Fetch Steam inventory if configured
    final steamService = sl<SteamInventoryApiService>();
    final settingsRepository = sl<SettingsRepository>();
    final steamIdSetting = await settingsRepository.getSetting('steam_id');

    if (steamIdSetting != null && steamIdSetting.value.isNotEmpty) {
      final accountId = int.tryParse(steamIdSetting.value);
      if (accountId != null) {
        await steamService.fetchSteamInventoryValue(
          accountId,
          GameApiSteam.cs2,
        );
        debugPrint('API: Steam inventory fetched');
      }
    }
  } catch (e) {
    debugPrint('API: Failed to fetch Steam inventory: $e');
  }

  try {
    // Fetch inflation data
    final inflationService = sl<InflationApiService>();
    await inflationService.fetchInflationForCountry('SRB', '2000:2024');
    debugPrint('API: Inflation data fetched');
  } catch (e) {
    debugPrint('API: Failed to fetch inflation data: $e');
  }
}

Future<void> _loadDebugSteamData() async {
  try {
    final file = File(
      r'c:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\steam_inventory_history.json',
    );
    if (await file.exists()) {
      final content = await file.readAsString();
      if (content.isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(content);
        final assetRepo = sl<AssetRepository>();

        for (final dateStr in json.keys) {
          if (dateStr == '_metadata') continue;

          final date = DateTime.parse(dateStr);
          final data = json[dateStr] as Map<String, dynamic>;

          for (final game in data.keys) {
            final value = data[game] as double;
            final assetId = 'steam_$game';

            // Check if entry exists
            final existingAssets = await assetRepo.getAssetData(
              assetId: assetId,
              startDate: date,
              endDate: date,
              limit: 1,
            );

            if (existingAssets.isNotEmpty) {
              // Update existing
              final existing = existingAssets.first;
              if (existing.value != value) {
                await assetRepo.updateAssetData(
                  existing.copyWith(value: value),
                );
              }
            } else {
              // Add new
              await assetRepo.addAssetData(
                AssetDataDomain(
                  id: 'temp_${date.millisecondsSinceEpoch}_$game',
                  assetId: assetId,
                  name: 'Steam Inventory ($game)',
                  description: 'Imported from JSON',
                  currency: 'EUR',
                  value: value,
                  quantity: 1.0,
                  date: date,
                  source: 'steam',
                  accountId: null,
                  assetType: 'steam',
                ),
              );
            }
          }
        }
      }
    }
  } catch (e) {
    debugPrint('Failed to load debug steam data: $e');
  }
}

class IntilizationData {
  /// Loads local data synchronously (blocks splash screen).
  /// Returns quickly after loading from files.
  static Future<void> loadLocalData() async {
    await _loadLocalData();
  }

  /// Fetches fresh data from APIs in the background.
  /// Does NOT block UI - fire and forget.
  static void fetchApiDataInBackground() {
    // Fire and forget - don't await
    _fetchApiData();
  }

  /// Legacy method for backwards compatibility.
  /// Runs everything (local + API) together.
  static Future<void> initilizate() async {
    await _loadLocalData();
    await _fetchApiData();
  }
}
