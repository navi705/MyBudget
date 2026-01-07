import 'package:my_budget_client/domain/entities/inflation_rate.dart';

abstract class InflationRepository {
  Future<List<InflationRateDomain>> getInflationRates();
  Future<List<InflationRateDomain>> getInflationRatesFiltered({
    DateTime? date,
    String? country,
  });
  Future<void> addInflationRate(InflationRateDomain rate);
  Future<void> updateInflationRate(InflationRateDomain rate);
  Future<void> deleteInflationRate(DateTime date, String? country, int preset);
  Future<List<String>> getAvailableCountries();
}
