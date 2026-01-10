import 'package:flutter/foundation.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/services/inflation_api_service.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'dart:convert';
import 'dart:io';

Future<void> _initInIsolate(bool shouldInit) async {
  // Re-initialize the service locator in the new isolate.
  if (shouldInit) {
    await init();
  }

  final exchangeRateService = sl<ExchangeRateApiService>();
  await exchangeRateService.fetchRatesForDate(DateTime.now());

  final steamService = sl<SteamInventoryApiService>();
  final settingsRepository = sl<SettingsRepository>();
  final steamIdSetting = await settingsRepository.getSetting('steam_id');

  if (steamIdSetting != null && steamIdSetting.value.isNotEmpty) {
    final accountId = int.tryParse(steamIdSetting.value);
    if (accountId != null) {
      await steamService.fetchSteamInventoryValue(accountId, GameApiSteam.cs2);
    }
  }

  // Load Debug Steam Data
  if (kDebugMode) {
    await _loadDebugSteamData();
  }

  final inflationService = sl<InflationApiService>();
  await inflationService.fetchInflationForCountry('SRB', '2000:2024');
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
  static Future<void> initilizate() async {
    // Running in a separate isolate
    if (kDebugMode) {
      // In debug mode, run directly to allow for easier debugging.
      return _initInIsolate(false);
    }
    return compute(_initInIsolate, true);
  }
}
