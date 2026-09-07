import 'dart:convert';
import 'dart:io';

/// A day's rates, all quoted against one base currency.
typedef DayRates = Map<String, double>;

/// Fetches published exchange rates for a single day.
///
/// An interface rather than a bare function so a test can hand the refresher a
/// provider that never touches the network, and so a second provider can be
/// dropped in later without the refresher knowing.
abstract class RateProvider {
  /// The currency every rate is quoted against.
  String get baseCurrency;

  /// The rates published for [day], or `null` when that day has none.
  ///
  /// `null` is not an error: the provider publishes nothing for a day that has
  /// not happened yet, and the upstream data set has gaps. The refresher
  /// records the difference so a gap is not retried forever.
  Future<DayRates?> ratesFor(DateTime day);
}

/// Thrown when the upstream refuses or breaks, as opposed to simply having no
/// data for the day.
///
/// Separated from a `null` result on purpose: a 500 from the CDN is worth
/// retrying tomorrow, a genuinely missing day is not.
class RateProviderException implements Exception {
  /// [message] is for the server log, never for an app: it may name the host.
  RateProviderException(this.message);

  /// What went wrong upstream.
  final String message;

  @override
  String toString() => 'RateProviderException: $message';
}

/// The free `@fawazahmed0/currency-api` data set on jsDelivr.
///
/// The same source the app used to call from every device. Moving it here is
/// the point of the exercise: one machine fetches a day once, and every device
/// reads it from this server instead of each one hitting the CDN for the same
/// bytes and storing its own copy.
///
/// No API key, no account, no rate limit published — which is also why the
/// refresher throttles itself rather than trusting that.
class FawazCurrencyApi implements RateProvider {
  /// [client] is injectable so a test never touches the network.
  FawazCurrencyApi({HttpClient? client, this.baseCurrency = 'EUR'})
      : _client = client ?? HttpClient();

  final HttpClient _client;

  @override
  final String baseCurrency;

  /// The dated endpoint. `@<yyyy-MM-dd>` pins the data set as it stood that
  /// day; `@latest` is the only form that carries today.
  Uri _uriFor(DateTime day, {required bool latest}) {
    final tag = latest ? 'latest' : _isoDay(day);
    final base = baseCurrency.toLowerCase();
    return Uri.parse(
      'https://cdn.jsdelivr.net/npm/@fawazahmed0/currency-api@$tag'
      '/v1/currencies/$base.json',
    );
  }

  @override
  Future<DayRates?> ratesFor(DateTime day) async {
    final utcDay = normalizeDay(day);
    final todayUtc = normalizeDay(DateTime.now().toUtc());

    // Today's quote only exists under `@latest`; the dated tag for today is
    // published some hours later. Asking for the dated one first would 404 on
    // every same-day refresh, which is the refresh that matters most.
    final isToday = utcDay.isAtSameMomentAs(todayUtc);
    final body = await _get(_uriFor(utcDay, latest: isToday));
    if (body == null) return null;

    final parsed = ratesFrom(baseCurrency, body);
    return parsed.isEmpty ? null : parsed;
  }

  Future<dynamic> _get(Uri uri) async {
    HttpClientResponse response;
    try {
      final request = await _client.getUrl(uri);
      response = await request.close();
    } on Object catch (e) {
      throw RateProviderException('$uri: $e');
    }

    if (response.statusCode == HttpStatus.notFound) {
      // The day is not in the data set. Drain the body anyway: an undrained
      // response holds its socket out of the connection pool.
      await response.drain<void>();
      return null;
    }
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw RateProviderException('$uri: HTTP ${response.statusCode}');
    }

    final text = await response.transform(utf8.decoder).join();
    try {
      return jsonDecode(text);
    } on FormatException catch (e) {
      throw RateProviderException('$uri: malformed JSON ($e)');
    }
  }

  /// Reads the provider's `{"eur": {"usd": 1.08, ...}}` shape.
  ///
  /// Rates are validated, not just read. A multiplier of zero converts every
  /// amount to nothing, a negative one flips its sign, and a non-finite one
  /// poisons every total it reaches — and once a bad rate is stored, every
  /// device that syncs inherits it.
  static DayRates ratesFrom(String baseCurrency, dynamic body) {
    if (body is! Map) return {};
    final data = body[baseCurrency.toLowerCase()];
    if (data is! Map) return {};

    final result = <String, double>{};
    data.forEach((key, value) {
      if (key is! String) return;
      final rate = value is num
          ? value.toDouble()
          : value is String
              ? double.tryParse(value.trim())
              : null;
      if (rate == null || !rate.isFinite || rate <= 0) return;
      result[key.toUpperCase()] = rate;
    });
    return result;
  }
}

/// Turns a timestamp into the one instant that stands for its calendar day.
///
/// `date` is part of the primary key of `exchange_rates`, so a row stamped
/// 14:05 is a different row from the same day's midnight one and both survive
/// the upsert. Everything written here therefore lands on one instant per day,
/// expressed in UTC so the row does not move when the container's timezone
/// does.
///
/// The day is read off the value as it stands rather than after a conversion.
/// `DateTime.parse('2026-03-14')` yields local midnight, and converting that to
/// UTC in a container running east of Greenwich lands on the 13th - so a client
/// asking for `?date=2026-03-14` would be answered with the previous day's
/// rates, and only in some deployments. A value that already carries a zone
/// (`...Z` or an offset) is parsed to UTC by `DateTime.parse` before it gets
/// here, so its fields are the UTC ones either way; callers holding a wall
/// clock, such as the refresher's `today`, convert before calling.
DateTime normalizeDay(DateTime value) =>
    DateTime.utc(value.year, value.month, value.day);

String _isoDay(DateTime day) {
  final utc = day.toUtc();
  final month = utc.month.toString().padLeft(2, '0');
  final dayOfMonth = utc.day.toString().padLeft(2, '0');
  return '${utc.year}-$month-$dayOfMonth';
}
