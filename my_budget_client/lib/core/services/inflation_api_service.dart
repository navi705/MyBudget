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
    // The newest year already stored, which is what decides whether the
    // provider has anything left to tell us. A published year never changes,
    // so there is nothing to gain by asking again for one we hold.
    final newest =
        await (_inflationRatesDao.select(_inflationRatesDao.inflationRates)
              ..where((t) => t.country.equals(countryCode))
              ..orderBy([
                (t) =>
                    OrderingTerm(expression: t.date, mode: OrderingMode.desc),
              ])
              ..limit(1))
            .getSingleOrNull();

    if (!shouldFetch(newest?.date.year, dateRange)) {
      return;
    }

    debugPrint('[InflationApiService] Fetching inflation from API...');
    final dataPoints = await _fetchInflationData(
      _InflationFetchArgs(countryCode, dateRange),
    );

    debugPrint(
      '[InflationApiService] Received ${dataPoints.length} data points.',
    );

    final stored =
        await (_inflationRatesDao.select(_inflationRatesDao.inflationRates)
              ..where((t) => t.country.equals(countryCode)))
            .get();

    final companions = changedOnly(
      stored,
      companionsFor(countryCode, dataPoints),
    );

    if (companions.isNotEmpty) {
      await _inflationRatesDao.insertAllInflationRates(companions);
      debugPrint(
        '[InflationApiService] Saved ${companions.length} data points to DB.',
      );
    }
  }

  /// The companions in [candidates] that say something [stored] does not.
  ///
  /// The write is an insert-or-replace that stamps `modifiedAt` with now, and
  /// every synced table has a trigger queueing whatever it writes for upload.
  /// Rewriting a row with the number it already holds therefore costs a push
  /// of the whole history - and now that the fetch repeats until the provider
  /// publishes the year being asked for, that would have been every day of the
  /// months a country's newest year is still unpublished.
  @visibleForTesting
  static List<InflationRatesCompanion> changedOnly(
    List<InflationRate> stored,
    List<InflationRatesCompanion> candidates,
  ) {
    final byKey = {
      for (final row in stored) (row.date.year, row.preset): row.percent,
    };
    return candidates.where((c) {
      if (!c.date.present || !c.percent.present) return true;
      final was = byKey[(
        c.date.value.year,
        c.preset.present ? c.preset.value : 1,
      )];
      return was != c.percent.value;
    }).toList();
  }

  /// The last year [dateRange] asks for, or null if it asks for no year this
  /// can make sense of.
  ///
  /// The World Bank takes `date` as either a single year or `first:last`.
  @visibleForTesting
  static int? lastYearOf(String dateRange) {
    final parts = dateRange.split(':');
    if (parts.isEmpty || parts.length > 2) return null;
    final years = parts
        .map((p) => int.tryParse(p.trim()))
        .whereType<int>()
        .toList();
    if (years.length != parts.length) return null;
    return years.reduce((a, b) => a > b ? a : b);
  }

  /// Whether the provider is worth asking, given the newest year already
  /// stored for the country.
  ///
  /// This used to be "does the country have ANY row", which froze a country's
  /// inflation at whatever the first fetch happened to return: every later
  /// launch saw the seeded rows and returned before asking, so the year that
  /// had just been published never arrived and the range the caller widened
  /// never took effect. The check is now about the range's end, so a stored
  /// history is re-asked exactly when it stops covering what was requested.
  ///
  /// An unreadable range is fetched rather than skipped: the provider is the
  /// one that gets to reject it, and refusing here would silently do nothing.
  @visibleForTesting
  static bool shouldFetch(int? newestStoredYear, String dateRange) {
    if (newestStoredYear == null) return true;
    final last = lastYearOf(dateRange);
    if (last == null) return true;
    return newestStoredYear < last;
  }

  /// The rows worth storing out of what the provider answered with.
  ///
  /// Every point is read on its own. The year used to be read with a bare
  /// `int.parse`, so a single point the provider dated in any other shape -
  /// a quarter, a blank, a range - threw out of the middle of the loop and
  /// took the whole country's history with it: twenty-five years of inflation
  /// were dropped over one row, and the caller logged it as a failed fetch
  /// with nothing to say which row had done it.
  ///
  /// A percent is stored as a real and read straight into arithmetic, so a
  /// non-finite one is not a slightly wrong figure but one that turns every
  /// total it reaches into NaN.
  @visibleForTesting
  static List<InflationRatesCompanion> companionsFor(
    String countryCode,
    List<InflationDataPoint> dataPoints,
  ) {
    final List<InflationRatesCompanion> companions = [];
    for (final dataPoint in dataPoints) {
      final value = dataPoint.value;
      if (value == null) continue;
      if (!value.isFinite) {
        debugPrint(
          '[InflationApiService] Skipping ${dataPoint.date}: percent $value',
        );
        continue;
      }
      final year = int.tryParse(dataPoint.date.trim());
      if (year == null) {
        debugPrint(
          '[InflationApiService] Skipping point dated "${dataPoint.date}".',
        );
        continue;
      }
      companions.add(
        InflationRatesCompanion(
          country: Value(countryCode),
          percent: Value(value),
          date: Value(DateTime(year, 1, 1)),
          preset: const Value(1),
        ),
      );
    }
    return companions;
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
