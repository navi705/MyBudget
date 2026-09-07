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

/// The startup work that does not have to finish before the app is shown.
///
/// Named `_fetchApiDataInIsolate` until now, which was the source of a
/// persistent misreading: this runs on the *calling* isolate - the UI one -
/// and always has. `app_wrapper.dart` fires it without awaiting, and that only
/// takes it off the critical path. Anything heavy in here still competes with
/// frames, which is why the multi-megabyte currency-history decodes inside
/// [ImportDataUtils.getCurrenciesInitial] now post themselves to a real worker
/// rather than relying on this call being un-awaited.
Future<void> _runBackgroundStartupWork(bool shouldInit) async {
  // DI is already initialized on the main isolate, which is where this runs.
  // The guard is for a caller that is genuinely somewhere else.
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
    // The result is deliberately dropped, so the failure has to be caught here:
    // an un-awaited Future that throws goes to the zone's uncaught-error
    // handler, and on a release build that is a crash report for work the app
    // is explicitly happy to do without.
    _runBackgroundStartupWork(true).catchError((Object e) {
      debugPrint('[INIT_DEBUG] Background startup work failed: $e');
    });
  }

  static Future<void> initilizate() async {
    fetchApiDataInBackground();
  }
}
