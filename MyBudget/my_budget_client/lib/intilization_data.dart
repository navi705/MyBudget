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

Future<void> _loadLocalDataInIsolate(bool shouldInit) async {
  if (shouldInit) {
    await init();
  }

  // Load Currency History (Binary/JSON seeder)
  // This loads from the binary file or JSON debug file into the database
  await ImportDataUtils.getCurrenciesInitial();
}

Future<void> _fetchApiDataInIsolate(bool shouldInit) async {
  if (shouldInit) {
    await init();
  }

  // Load Debug Steam Data (Local JSON) in background
  if (kDebugMode) {
    await _loadDebugSteamData();
  }

  try {
    // 1. Fetch Exchange Rates (Today)
    final exchangeRateService = sl<ExchangeRateApiService>();
    await exchangeRateService.fetchRatesForDate(DateTime.now());
  } catch (e) {
    debugPrint('Background Init Error (Exchange Rates): $e');
  }

  try {
    // 2. Fetch Steam Inventory
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
      }
    }
  } catch (e) {
    debugPrint('Background Init Error (Steam): $e');
  }

  try {
    // 3. Fetch Inflation Data
    final inflationService = sl<InflationApiService>();
    await inflationService.fetchInflationForCountry('SRB', '2000:2024');
  } catch (e) {
    debugPrint('Background Init Error (Inflation): $e');
  }
}

// Deprecated: kept for reference or legacy paths.
// The new flow uses loadLocalData() and fetchApiDataInBackground() separately.
Future<void> _initInIsolate(bool shouldInit) async {
  await _loadLocalDataInIsolate(shouldInit);
  await _fetchApiDataInIsolate(false); // init already done
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
            final value = (data[game] as num).toDouble();
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
  /// Loads critical local data (Currency History, Debug Data).
  /// This should be awaited during the splash screen.
  static Future<void> loadLocalData() async {
    if (kDebugMode) {
      return _loadLocalDataInIsolate(false);
    }
    return compute(_loadLocalDataInIsolate, true);
  }

  /// Fetches API data in the background (Exchange Rates, Steam, Inflation).
  /// This should be called WITHOUT await after the app is interactive.
  static void fetchApiDataInBackground() {
    if (kDebugMode) {
      _fetchApiDataInIsolate(false);
    } else {
      compute(_fetchApiDataInIsolate, true);
    }
  }

  // Legacy method for backward compatibility
  static Future<void> initilizate() async {
    if (kDebugMode) {
      return _initInIsolate(false);
    }
    return compute(_initInIsolate, true);
  }
}
