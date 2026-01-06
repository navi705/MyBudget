import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'package:my_budget_client/core/di/injection_container.dart';

class IntilizationData {
  static Future<void> initilizate() async {
    final service = sl<ExchangeRateApiService>();
    final end = DateTime.now();
    final start = end.subtract(const Duration(days: 30));
    await service.fetchRatesForRange(start, end);
  }

}
