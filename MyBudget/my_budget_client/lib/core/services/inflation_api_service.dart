import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:drift/drift.dart';

class InflationApiService {
  final InflationRatesDao _inflationRatesDao;

  InflationApiService(this._inflationRatesDao);

  Future<void> fetchInflationForCountry(
    String countryCode,
    String dateRange,
  ) async {
    // Basic check: if we already have data for the latest year in the range, maybe skip?
    // Or better, just fetch and use insertOnConflictUpdate if the DAO supports it.
    // However, the World Bank API is quite slow, so skipping is better.

    // For now, let's at least check if we have ANY data for this country to avoid repeated calls every launch
    final existing =
        await (_inflationRatesDao.select(_inflationRatesDao.inflationRates)
              ..where((t) => t.country.equals(countryCode))
              ..limit(1))
            .getSingleOrNull();

    if (existing != null) {
      // If we have data, we might want to check if it's "fresh" (e.g., from this year)
      // but for inflation, older years don't change.
      // Simplest: only fetch if DB is empty for this country.
      return;
    }

    final dataPoints = await ExternalData.getInflationFromWorldBank(
      countryCode,
      dateRange,
    );

    for (var dataPoint in dataPoints) {
      if (dataPoint.value != null) {
        final companion = InflationRatesCompanion(
          country: Value(countryCode),
          percent: Value(dataPoint.value!),
          date: Value(DateTime(int.parse(dataPoint.date), 1, 1)),
          preset: const Value(1),
        );
        await _inflationRatesDao.insertInflationRate(companion);
      }
    }
  }
}
