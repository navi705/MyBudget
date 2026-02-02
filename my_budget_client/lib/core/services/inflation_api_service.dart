import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/data/models/world_bank_inflation_model.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

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

    debugPrint('[InflationApiService] Fetching inflation from API...');
    final dataPoints = await _fetchInflationData(
      _InflationFetchArgs(countryCode, dateRange),
    );

    debugPrint(
      '[InflationApiService] Received ${dataPoints.length} data points.',
    );

    final List<InflationRatesCompanion> companions = [];
    for (var dataPoint in dataPoints) {
      if (dataPoint.value != null) {
        companions.add(
          InflationRatesCompanion(
            country: Value(countryCode),
            percent: Value(dataPoint.value!),
            date: Value(DateTime(int.parse(dataPoint.date), 1, 1)),
            preset: const Value(1),
          ),
        );
      }
    }

    if (companions.isNotEmpty) {
      await _inflationRatesDao.insertAllInflationRates(companions);
      debugPrint(
        '[InflationApiService] Saved ${companions.length} data points to DB.',
      );
    }
  }

  static Future<List<InflationDataPoint>> _fetchInflationData(
    _InflationFetchArgs args,
  ) async {
    return ExternalData.getInflationFromWorldBank(
      args.countryCode,
      args.dateRange,
    );
  }
}

class _InflationFetchArgs {
  final String countryCode;
  final String dateRange;

  _InflationFetchArgs(this.countryCode, this.dateRange);
}
