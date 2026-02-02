import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:my_budget_client/core/services/startup_sync_service.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'dart:convert';

import 'package:my_budget_client/core/di/injection_container.dart' as di;
import 'package:my_budget_client/core/di/injection_container.dart'; // for sl

Future<void> _fetchApiDataInIsolate(bool shouldInit) async {
  // If we are on the main isolate, DI is already initialized.
  // We only need to init if we are in a truly separate isolate (which we aren't right now).
  if (shouldInit && !sl.isRegistered<StartupSyncService>()) {
    await di.init();
  }

  debugPrint('[INIT_DEBUG] Starting background synchronization...');

  // 1. Load Currency History (Binary/JSON seeder)
  try {
    await ImportDataUtils.getCurrenciesInitial();
  } catch (e) {
    debugPrint('Background Init Error (Seeding): $e');
  }

  // 2. Load Debug Steam Data (Local JSON)
  if (kDebugMode && !kIsWeb) {
    await _loadDebugSteamData();
  }

  try {
    // 3. Execute Startup Sync (Master Switch + Auto-fetch logic)
    if (sl.isRegistered<StartupSyncService>()) {
      debugPrint('[INIT_DEBUG] Delegating to StartupSyncService...');
      final startupService = sl<StartupSyncService>();
      await startupService.executeStartupSync();
    }
  } catch (e) {
    debugPrint('Background Init Error (Startup Sync): $e');
  }

  debugPrint('[INIT_DEBUG] Background synchronization completed.');
}

Future<void> _loadDebugSteamData() async {
  try {
    const filePath =
        r'c:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\steam_inventory_history.json';

    if (await IoHelper.exists(filePath)) {
      final content = await IoHelper.readAsString(filePath);
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
  /// Loads critical local data.
  /// Deprecated: All heavy work moved to background.
  static Future<void> loadLocalData() async {
    return;
  }

  /// Fetches API data and performs seeding in the background.
  static void fetchApiDataInBackground() {
    _fetchApiDataInIsolate(true);
  }

  static Future<void> initilizate() async {
    fetchApiDataInBackground();
  }
}
