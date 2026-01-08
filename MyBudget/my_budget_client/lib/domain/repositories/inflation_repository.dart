import 'package:my_budget_client/domain/entities/inflation_rate.dart';

abstract class InflationRepository {
  Future<List<InflationRateDomain>> getInflationRates();
  Future<List<InflationRateDomain>> getInflationRatesFiltered({
    required int limit,
    required int offset,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? country,
    int? preset,
    bool sortAscending = false,
  });
  Future<void> addInflationRate(InflationRateDomain rate);
  Future<void> updateInflationRate(InflationRateDomain rate);
  Future<void> deleteInflationRate(DateTime date, String? country, int preset);
  Future<List<String>> getAvailableCountries();
  Future<int> getInflationRatesCount({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? country,
    int? preset,
  });
}
