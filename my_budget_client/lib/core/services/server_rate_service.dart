import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart'
    show normalizeSyncBaseUrl;
import 'package:my_budget_client/core/utils/calendar_day.dart';
import 'package:my_budget_client/core/utils/exchange_rate_validation.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';

/// One quote as the sync server hands it over.
typedef ServerRate = ({
  String fromCurrencyCode,
  String toCurrencyCode,
  double rate,
  int preset,
  DateTime date,
});

/// Reads published exchange rates from this device's own sync server.
///
/// The rates used to come from `cdn.jsdelivr.net`, once per device and once per
/// day of history — a first launch walked from 2024-04-01 to today one HTTP
/// request at a time. The server now fetches that history once for every device
/// it serves, so this asks it instead: whole ranges in one request, over the
/// connection the device is already authenticated on.
///
/// Nothing here is required for the app to work. A device with no server
/// configured, or one that cannot reach it, falls back to the bundled history
/// and to whatever it already stored — every method answers empty rather than
/// throwing, because a missing rate is a display detail and an exception on the
/// startup path is not.
class ServerRateService {
  ServerRateService({
    required SettingsRepository settingsRepository,
    http.Client? client,
  }) : _settingsRepository = settingsRepository,
       _http = client ?? http.Client();

  final SettingsRepository _settingsRepository;
  final http.Client _http;

  static final DateFormat _dayFormat = DateFormat('yyyy-MM-dd', 'en');

  /// Rows per request.
  ///
  /// A day carries roughly 700 quotes for the full currency list and a handful
  /// for the currencies one user actually holds, so this is days-to-years of
  /// history per round trip. It is also the server's own cap, so asking for
  /// more only means being clamped.
  static const int _pageLimit = 20000;

  /// Requests are given a bound rather than the platform default, which is
  /// effectively none: a server that accepts the connection and then stalls
  /// would otherwise hold the startup path open indefinitely.
  static const Duration _timeout = Duration(seconds: 20);

  /// Whether a server is configured at all.
  ///
  /// Callers use this to skip the network entirely rather than to decide
  /// whether a failure is worth reporting: not configured is a state, not an
  /// error, and the app is expected to run in it.
  Future<bool> isConfigured() async => (await _baseUrl()) != null;

  Future<String?> _baseUrl() async {
    final setting = await _settingsRepository.getSetting('server_sync_url');
    final raw = setting?.value;
    // No row at all means nothing was ever configured on this device; the
    // local dev default is what a debug build has always used.
    if (raw == null) return 'http://localhost:58080';
    return normalizeSyncBaseUrl(raw);
  }

  Future<String> _token() async {
    final setting = await _settingsRepository.getSetting('server_sync_token');
    return setting?.value ?? '';
  }

  /// Every quote the server holds in `[dateFrom, dateTo]`, oldest day last.
  ///
  /// [toCurrencyCodes] empty means every currency the server knows, which is
  /// roughly 700 per day. Callers that know which currencies the user holds
  /// should say so: it is the difference between a few kilobytes and a few
  /// megabytes over the same range.
  Future<List<ServerRate>> fetchRange({
    DateTime? dateFrom,
    DateTime? dateTo,
    String fromCurrencyCode = 'EUR',
    List<String> toCurrencyCodes = const [],
  }) async {
    final collected = <ServerRate>[];
    var upperBound = dateTo;

    // The server answers newest day first and caps the page. Paging by row
    // offset would need a cursor it does not have, so each further page is
    // asked for as a narrower window: the oldest *complete* day of the page
    // just read becomes the next page's upper bound.
    for (var page = 0; page < 64; page++) {
      final result = await _get(
        '/api/rates',
        fromCurrencyCode: fromCurrencyCode,
        toCurrencyCodes: toCurrencyCodes,
        dateFrom: dateFrom,
        dateTo: upperBound,
      );
      if (result == null || result.rates.isEmpty) break;

      if (!result.hasMore) {
        collected.addAll(result.rates);
        break;
      }

      // Truncated. The oldest day in the page may have been cut in half, so it
      // is dropped and re-asked for as the next page's last day rather than
      // stored with a hole in it.
      final oldest = result.rates
          .map((r) => r.date)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final complete = result.rates.where((r) => r.date.isAfter(oldest));

      if (complete.isEmpty) {
        // A single day that does not fit one page. Keep what came back and
        // step past it: re-asking for the same window would return the same
        // truncated page forever.
        collected.addAll(result.rates);
        upperBound = previousDay(oldest);
      } else {
        collected.addAll(complete);
        upperBound = oldest;
      }

      if (dateFrom != null && upperBound.isBefore(dateFrom)) break;
    }

    return collected;
  }

  /// The newest quote per currency at or before [asOf].
  ///
  /// One row per pair, whatever the gap: a Sunday reads as Friday's rate. This
  /// is what the balance screens want — a window would move a year of rows to
  /// keep the last of each.
  Future<List<ServerRate>> fetchLatest({
    DateTime? asOf,
    String fromCurrencyCode = 'EUR',
    List<String> toCurrencyCodes = const [],
  }) async {
    final result = await _get(
      '/api/rates/latest',
      fromCurrencyCode: fromCurrencyCode,
      toCurrencyCodes: toCurrencyCodes,
      dateTo: asOf,
    );
    return result?.rates ?? const [];
  }

  /// One day's quotes as a `code -> rate` map, the shape the seeding and
  /// import paths already speak.
  Future<Map<String, double>> fetchDay(
    DateTime day, {
    String fromCurrencyCode = 'EUR',
    List<String> toCurrencyCodes = const [],
  }) async {
    final result = await _get(
      '/api/rates',
      fromCurrencyCode: fromCurrencyCode,
      toCurrencyCodes: toCurrencyCodes,
      dateFrom: day,
      dateTo: day,
    );
    if (result == null) return const {};
    return {for (final rate in result.rates) rate.toCurrencyCode: rate.rate};
  }

  Future<({List<ServerRate> rates, bool hasMore})?> _get(
    String path, {
    required String fromCurrencyCode,
    required List<String> toCurrencyCodes,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final baseUrl = await _baseUrl();
    if (baseUrl == null) return null;

    final parameters = <String, String>{
      'from': fromCurrencyCode.toUpperCase(),
      'limit': '$_pageLimit',
      if (toCurrencyCodes.isNotEmpty)
        'to': toCurrencyCodes.map((c) => c.toUpperCase()).join(','),
      if (dateFrom != null) 'date_from': _dayFormat.format(dateFrom),
      if (dateTo != null) 'date_to': _dayFormat.format(dateTo),
    };

    try {
      final response = await _http
          .get(
            Uri.parse('$baseUrl$path').replace(queryParameters: parameters),
            headers: {'Authorization': 'Bearer ${await _token()}'},
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        // 401 and 503 are for the sync screen to explain; here they mean the
        // same as a timeout - no rates this time, keep whatever is stored.
        debugPrint('[RATES] $path answered ${response.statusCode}');
        return null;
      }

      final body = jsonDecode(response.body);
      if (body is! Map) return null;
      return (
        rates: _ratesFrom(body['rates']),
        hasMore: body['has_more'] == true,
      );
    } catch (e) {
      debugPrint('[RATES] $path failed: $e');
      return null;
    }
  }

  /// The rows of a response, skipping any that cannot be used.
  ///
  /// A rate is a multiplier, so zero, a negative and a non-finite are not
  /// slightly wrong values but unusable ones - the same check every other
  /// writer of `exchange_rates` applies before storing. A malformed row is
  /// dropped and the rest of the answer is kept, so one bad entry cannot cost
  /// a whole range.
  static List<ServerRate> _ratesFrom(dynamic raw) {
    if (raw is! List) return const [];

    final rates = <ServerRate>[];
    for (final entry in raw) {
      if (entry is! Map) continue;

      final from = entry['fromCurrencyCode'];
      final to = entry['toCurrencyCode'];
      final rate = entry['rate'];
      final date = entry['date'];
      if (from is! String || to is! String || date is! String) continue;

      final value = rate is num ? rate.toDouble() : null;
      if (value == null || !isUsableExchangeRate(value)) continue;

      final parsed = DateTime.tryParse(date);
      if (parsed == null) continue;

      rates.add((
        fromCurrencyCode: from.toUpperCase(),
        toCurrencyCode: to.toUpperCase(),
        rate: value,
        // The server quotes its own fetched rates as preset 1, the same value
        // the bundled history and both import paths use, so a stored row is
        // interchangeable with them and the primary key collides on purpose.
        preset: entry['preset'] is int ? entry['preset'] as int : 1,
        // Stored as a local midnight, because that is what every other writer
        // of this table stores and the primary key carries the date.
        date: startOfDay(parsed.toUtc()),
      ));
    }
    return rates;
  }
}
