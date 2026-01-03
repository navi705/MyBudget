import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/di/injection_container.dart';

class IntilizationData {
  static Future<void> initilizate() async {
    // Standard initialization will now use the service for the last 30 days
    final service = sl<ExchangeRateApiService>();
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    await service.fetchRatesForRange(start, end);
  }

  static Future<void> initilizateDebug() async {
    // In debug mode, we can fetch a larger range if needed,
    // but the service handles the logic of JSON vs API
    await initilizate();
  }
}
