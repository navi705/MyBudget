import 'package:flutter/foundation.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/di/injection_container.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';

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
        await Future.delayed(const Duration(seconds: 5)); // To avoid API rate limiting
    }
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
