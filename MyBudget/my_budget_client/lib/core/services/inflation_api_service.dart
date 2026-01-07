import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:drift/drift.dart';

class InflationApiService {
  final InflationRatesDao _inflationRatesDao;

  InflationApiService(this._inflationRatesDao);

  Future<void> fetchInflationForCountry(String countryCode, String dateRange) async {
    final dataPoints = await ExternalData.getInflationFromWorldBank(countryCode, dateRange);

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
