import 'dart:convert';
import 'dart:typed_data';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:flutter/foundation.dart'
    show kDebugMode, kIsWeb, debugPrint, visibleForTesting;
import 'package:my_budget_client/core/utils/calendar_day.dart';
import 'package:my_budget_client/core/utils/exchange_rate_validation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:my_budget_client/core/utils/currency_history_binary_io.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/server_rate_service.dart';
import 'package:drift/drift.dart';

class ExchangeRateApiService {
  final ExchangeRatesDao _exchangeRatesDao;
  final ApiFetchStatusesDao _apiFetchStatusesDao;
  final CurrenciesDao _currenciesDao;

  /// Where a day the device does not have comes from.
  ///
  /// Optional because the app has to run without a server: with none
  /// configured - or none reachable - every path here falls back to the
  /// bundled history and to what is already stored, which is what a bare
  /// install has always used.
  final ServerRateService? _serverRates;

  ExchangeRateApiService(
    this._exchangeRatesDao,
    this._apiFetchStatusesDao,
    this._currenciesDao, {
    ServerRateService? serverRates,
  }) : _serverRates = serverRates;

  static const String _jsonPath = 'lib/data/currency_history.json';
  static const String _prodBinAssetPath = 'lib/data/currency_history.bin';
  static const String _metadataJsonPath =
      'lib/data/currency_history_metadata.json';
  static const String _metadataKey = '_metadata';
  static const String _attemptsKey = 'attempts';

  /// Midnight local time on the day [date] falls in.
  ///
  /// Every other writer of `exchange_rates` stores a day rather than an
  /// instant: the bundled history and both import paths parse `yyyy-MM-dd`,
  /// so every seeded row sits at midnight. The table's primary key is
  /// `(from, to, date, preset)`, so a row stamped with the moment of a fetch
  /// is a different key from the same day's seeded row instead of a
  /// replacement for it - and the startup fetch passes `DateTime.now()`.
  static DateTime _dayOf(DateTime date) => startOfDay(date);

  /// Whether today's quote is an acceptable answer for [day].
  ///
  /// Only for today and later. A provider that has not published today yet is
  /// the case the "latest" fallback was written for; a day already past has a
  /// real rate of its own that today's number is not.
  @visibleForTesting
  static bool mayStandInForLatest(DateTime day, DateTime now) =>
      !_dayOf(day).isBefore(_dayOf(now));

  Future<void> fetchRatesForDate(DateTime date) async {
    final day = _dayOf(date);
    final dateKey = DateFormat('yyyy-MM-dd', 'en').format(day);

    // Asked as a range over the day, not an equality on the instant. The
    // startup fetch hands this `DateTime.now()`, which never equals a stored
    // midnight, so the guard matched nothing: every launch re-fetched a day it
    // already had and then wrote a second copy of every EUR pair under a
    // primary key that differed only in the time the app happened to start.
    final dayAfter = nextDay(date);
    final ratesInDb =
        await (_exchangeRatesDao.select(_exchangeRatesDao.exchangeRates)
              ..where(
                (tbl) =>
                    tbl.date.isBiggerOrEqualValue(day) &
                    tbl.date.isSmallerThanValue(dayAfter),
              ))
            .get();

    if (ratesInDb.isNotEmpty) {
      return;
    }

    if (kDebugMode && !kIsWeb) {
      await _handleDebugFetch(day, dateKey);
    } else {
      await _handleProdFetch(day, dateKey);
    }
  }

  Future<void> _handleDebugFetch(DateTime date, String dateKey) async {
    if (!await IoHelper.exists(_jsonPath)) return;
    final content = await IoHelper.readAsString(_jsonPath);
    final Map<String, dynamic> fullJson = jsonDecode(content);

    // 1. Read Metadata
    Map<String, dynamic> metadataJson = {};
    if (await IoHelper.exists(_metadataJsonPath)) {
      try {
        metadataJson = jsonDecode(
          await IoHelper.readAsString(_metadataJsonPath),
        );
      } catch (e) {
        debugPrint('Error reading metadata file: $e');
      }
    }

    final attemptsMap =
        (metadataJson[_attemptsKey] as Map<String, dynamic>?) ?? {};
    final int attemptCount = attemptsMap[dateKey] ?? 0;

    if (attemptCount >= 5) {
      return;
    }

    // 2. Read Currency Data (Already read above)

    // Clean up old metadata from main file if present (migration step)
    if (fullJson.containsKey(_metadataKey)) {
      fullJson.remove(_metadataKey);
      await IoHelper.writeAsString(
        _jsonPath,
        const JsonEncoder.withIndent('  ').convert(fullJson),
      );
    }

    if (fullJson.containsKey(dateKey)) {
      final rawRates = fullJson[dateKey] as Map<String, dynamic>;
      final rates = rawRates.map((k, v) => MapEntry(k, (v as num).toDouble()));
      if (rates.isNotEmpty) {
        await _saveRatesToDb(date, rates);
        return;
      }
    }

    // 3. Ask the server for the day the working file does not have, and write
    // it back into that file so the next debug run finds it locally.
    final serverRates = await _serverRates?.fetchDay(date) ?? const {};
    if (serverRates.isNotEmpty) {
      await _saveRatesToDb(date, serverRates);
      fullJson[dateKey] = serverRates;
      await IoHelper.writeAsString(
        _jsonPath,
        const JsonEncoder.withIndent('  ').convert(fullJson),
      );
      return;
    }

    // 4. Nothing anywhere. Counted, so a day the server genuinely has no data
    // for is not re-asked for on every launch forever.
    attemptsMap[dateKey] = attemptCount + 1;
    metadataJson[_attemptsKey] = attemptsMap;
    await IoHelper.writeAsString(
      _metadataJsonPath,
      const JsonEncoder.withIndent('  ').convert(metadataJson),
    );
  }

  /// The last parse of the bundled rate history, for as long as the runtime
  /// is willing to keep it.
  ///
  /// [_handleProdFetch] runs once per missing day and wants exactly one of the
  /// map's ~2900 day entries. It used to inflate and walk the whole 2.23 MB
  /// asset for each of them - and the startup backfill asks for every day since
  /// 2024-04-01, so a first launch paid that price a couple of hundred times
  /// over, on the UI isolate, to read a couple of hundred rows.
  ///
  /// A [WeakReference] rather than a plain field because the parsed map is
  /// ~283 000 entries and the burst that needs it is over in seconds. Holding
  /// it for the life of the process would trade a startup stall for a permanent
  /// footprint; this way a burst reuses one parse and the memory goes back the
  /// moment the collector wants it.
  WeakReference<Map<String, Map<String, double>>>? _bundledHistoryRef;

  /// The parse currently running, so the four concurrent day fetches the
  /// backfill pool issues wait on one worker instead of starting four.
  Future<Map<String, Map<String, double>>>? _bundledHistoryInFlight;

  Future<Map<String, Map<String, double>>?> _bundledHistory() async {
    final cached = _bundledHistoryRef?.target;
    if (cached != null) return cached;

    final inFlight = _bundledHistoryInFlight;
    if (inFlight != null) return inFlight;

    final future = _parseBundledHistory();
    _bundledHistoryInFlight = future;
    try {
      final parsed = await future;
      _bundledHistoryRef = WeakReference(parsed);
      return parsed;
    } finally {
      _bundledHistoryInFlight = null;
    }
  }

  Future<Map<String, Map<String, double>>> _parseBundledHistory() async {
    final ByteData blob = await rootBundle.load(_prodBinAssetPath);
    // Offset and length spelled out: on Android `rootBundle` hands back a view
    // into a larger buffer, and `asUint8List()` with no arguments would start
    // on the wrong bytes and fail the header check.
    final Uint8List bytes = blob.buffer.asUint8List(
      blob.offsetInBytes,
      blob.lengthInBytes,
    );
    // Gzip inflate plus a 283k-entry byte walk. On a worker, because this is
    // called from the startup path and the UI isolate is drawing the splash.
    return CurrencyHistoryBinaryIO.readFromBytesInIsolate(bytes);
  }

  Future<void> _handleProdFetch(DateTime date, String dateKey) async {
    final status = await _apiFetchStatusesDao.getStatus(dateKey);
    if (status != null &&
        (status.status == 'success' ||
            status.status == 'permanent_fail' ||
            status.attempts >= 5)) {
      return;
    }

    Map<String, double> rates = {};
    try {
      // Try Binary Asset
      try {
        final historyMap = await _bundledHistory();
        if (historyMap != null && historyMap.containsKey(dateKey)) {
          rates = historyMap[dateKey]!;
        }
      } catch (e) {
        debugPrint('Fetch: Binary asset error or missing: $e');
      }

      if (rates.isEmpty) {
        // The device's own server, not a public CDN. It holds the same
        // history, it is already authenticated, and it answers a whole range
        // in one request instead of one request per day per device.
        final server = _serverRates;
        if (server != null) {
          rates = await server.fetchDay(date);

          if (rates.isEmpty && mayStandInForLatest(date, DateTime.now())) {
            // "Latest" is the newest quote the server holds. It stands in for
            // a day nobody has published yet - the case this fallback was
            // written for - but it is no answer for a day in the past: that
            // day has a real rate of its own, and taking today's numbers for
            // it wrote invented history and then marked the day 'success', so
            // nothing ever went back for the real rates.
            rates = {
              for (final rate in await server.fetchLatest(asOf: date))
                rate.toCurrencyCode: rate.rate,
            };
          }
        }
      }

      if (rates.isNotEmpty) {
        await _saveRatesToDb(date, rates);
        await _apiFetchStatusesDao.upsertStatus(
          ApiFetchStatusesCompanion(
            id: Value(dateKey),
            status: const Value('success'),
            attempts: Value((status?.attempts ?? 0) + 1),
            lastAttempt: Value(DateTime.now()),
          ),
        );
      } else {
        throw Exception('No data returned from API/JSON');
      }
    } catch (e) {
      final attempts = (status?.attempts ?? 0) + 1;
      await _apiFetchStatusesDao.upsertStatus(
        ApiFetchStatusesCompanion(
          id: Value(dateKey),
          status: Value(attempts >= 5 ? 'permanent_fail' : 'failed'),
          attempts: Value(attempts),
          lastAttempt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<void> _saveRatesToDb(DateTime date, Map<String, double> rates) async {
    final existingCodes = (await _currenciesDao.getAllCurrencies())
        .map((c) => c.code)
        .toSet();

    // A rate is a multiplier, so zero, a negative and a non-finite are not
    // slightly wrong values but unusable ones: the file import path has always
    // refused them and the rate editor now does too, while a provider could
    // hand any of them straight into the table this writes.
    final companions = rates.entries
        .where((e) => existingCodes.contains(e.key.toUpperCase()))
        .where((e) => isUsableExchangeRate(e.value))
        .map(
          (e) => ExchangeRatesCompanion(
            fromCurrencyCode: const Value('EUR'),
            toCurrencyCode: Value(e.key.toUpperCase()),
            rate: Value(e.value),
            date: Value(date),
            preset: const Value(1),
          ),
        )
        .toList();

    if (companions.isEmpty) {
      return;
    }

    // Not [insertAllExchangeRates]: every row this service writes is provider
    // data that the server already has, so queueing it for upload would send
    // the server back its own history one day at a time.
    await _exchangeRatesDao.insertFetchedExchangeRates(companions);
  }

  /// Fills `[start, end]` from the server in as few requests as it takes.
  ///
  /// This used to be a day-at-a-time walk with a 200 ms pause between the
  /// days, each one its own round trip to a public CDN: the backfill a stale
  /// build asks for on first launch is hundreds of days, so it took minutes
  /// and grew by one request a day for as long as the bundled asset was not
  /// regenerated. The server holds the whole history, so the range is one
  /// question - and the throttle it needed goes with the provider it was
  /// protecting.
  ///
  /// Days the device already has are left alone: the write is an upsert on
  /// `(from, to, date, preset)`, so re-storing them would be harmless but
  /// pointless, and skipping them keeps a manually corrected rate from being
  /// overwritten by the published one.
  Future<void> fetchRatesForRange(DateTime start, DateTime end) async {
    final first = _dayOf(start);
    final last = _dayOf(end);
    if (first.isAfter(last)) return;

    final server = _serverRates;
    if (server == null) {
      // No server configured. The bundled history is all there is, and
      // [fetchRatesForDate] is what reads it.
      for (var day = first; !day.isAfter(last); day = nextDay(day)) {
        await fetchRatesForDate(day);
      }
      return;
    }

    final rates = await server.fetchRange(dateFrom: first, dateTo: last);
    if (rates.isEmpty) return;

    await _storeServerRates(rates);

    // The per-day status rows exist so a day that failed is not retried
    // forever. A range that came back covers every day in it, so they are
    // marked in one pass rather than by a second walk of the same days.
    final covered = <String>{
      for (final rate in rates) DateFormat('yyyy-MM-dd', 'en').format(rate.date),
    };
    for (final dateKey in covered) {
      await _apiFetchStatusesDao.upsertStatus(
        ApiFetchStatusesCompanion(
          id: Value(dateKey),
          status: const Value('success'),
          attempts: const Value(1),
          lastAttempt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Stores server rows the same way every other fetched row is stored.
  ///
  /// Each row carries its own date, so a range and a "latest" answer go
  /// through the same path: nothing here invents a day, and a currency the
  /// device does not have is dropped rather than creating it as a side effect
  /// of a rate arriving.
  Future<void> _storeServerRates(List<ServerRate> rates) async {
    if (rates.isEmpty) return;

    final existingCodes = (await _currenciesDao.getAllCurrencies())
        .map((c) => c.code)
        .toSet();

    final companions = rates
        .where((r) => existingCodes.contains(r.toCurrencyCode))
        .where((r) => isUsableExchangeRate(r.rate))
        .map(
          (r) => ExchangeRatesCompanion(
            fromCurrencyCode: Value(r.fromCurrencyCode),
            toCurrencyCode: Value(r.toCurrencyCode),
            rate: Value(r.rate),
            date: Value(_dayOf(r.date)),
            preset: Value(r.preset),
          ),
        )
        .toList();

    if (companions.isEmpty) return;
    await _exchangeRatesDao.insertFetchedExchangeRates(companions);
  }

  /// `currency|yyyy-MM` pairs this session has already asked the server for.
  ///
  /// The miss that triggers a fill comes from a conversion, and conversions
  /// run per row of a list: without this, one screen of transactions in a
  /// currency the device has no rate for is one request per row, repeated on
  /// every rebuild. A month is the unit because a "latest" answer covers the
  /// whole neighbourhood of the day asked for, not just that day.
  final Set<String> _requestedFills = {};

  /// Requests never outlive one session's worth of browsing. A device that
  /// genuinely holds thirty-two unseen currencies is not the case this is
  /// for, and an unreachable server must not be asked once per rendered row.
  static const int _maxRequestedFills = 32;

  /// Fetches rates for currencies a conversion could not resolve.
  ///
  /// The user chose local-first with a top-up only on a real miss, so this is
  /// the top-up: nothing polls, nothing prefetches, and a device whose stored
  /// history already answers never reaches here at all. It is fire-and-forget
  /// by design - the caller is a conversion in a render path and must not
  /// wait on a network round trip. The rows land through
  /// [insertFetchedExchangeRates], whose write wakes the rate-change stream,
  /// and the screen re-reads on its own.
  Future<void> fillMissingRates({
    required Iterable<String> currencyCodes,
    required DateTime date,
  }) async {
    final server = _serverRates;
    if (server == null) return;
    if (_requestedFills.length >= _maxRequestedFills) return;

    final day = _dayOf(date);
    final month = DateFormat('yyyy-MM', 'en').format(day);

    // Marked before the first await, so two conversions missing the same pair
    // in the same frame produce one request rather than two.
    final codes = <String>[];
    for (final raw in currencyCodes) {
      final code = raw.toUpperCase();
      if (code.isEmpty) continue;
      if (!_requestedFills.add('$code|$month')) continue;
      codes.add(code);
    }
    if (codes.isEmpty) return;

    try {
      // "Latest" rather than the exact day: a miss is usually a currency with
      // no history at all on this device, and one quote per pair is enough to
      // make the conversion resolve. Asking for the single day would answer
      // empty for a weekend and leave the screen just as blank.
      var rates = await server.fetchLatest(asOf: day, toCurrencyCodes: codes);
      if (rates.isEmpty) {
        // Nothing published at or before that day - the day is older than the
        // server's history. Its newest quote is still better than no rate, and
        // it is stored under its own true date, so it is never mistaken for a
        // rate that was in effect back then.
        rates = await server.fetchLatest(toCurrencyCodes: codes);
      }
      await _storeServerRates(rates);
    } catch (e) {
      // A miss that cannot be filled is the state the app already handles:
      // the conversion stays unresolved and the screen shows what it shows.
      debugPrint('Fetch: on-demand rate fill failed: $e');
    }
  }
}
