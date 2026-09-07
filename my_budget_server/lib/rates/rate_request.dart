import 'package:my_budget_server/rates/rate_provider.dart';
import 'package:my_budget_server/rates/rate_store.dart';

/// Largest page `/api/rates` will hand back.
///
/// A day carries roughly 700 quotes, so this is about two weeks of everything
/// or several years of one pair. The cap exists because the rows are
/// materialised into Dart objects and then into JSON before anything is sent:
/// an unclamped `?limit=` lets any caller size the server's peak memory for it,
/// the same reason `maxPullLimit` exists on the sync route.
const int maxRateLimit = 20000;

/// Page size when the caller does not ask for one.
const int defaultRateLimit = 5000;

/// Most currency codes one request may name.
///
/// The list becomes a single `= ANY(@to)` parameter, so a caller naming ten
/// thousand codes builds a ten-thousand-element array server-side to answer a
/// question about a handful. The whole ISO list plus every crypto the app
/// knows is well under this.
const int maxRateCurrencies = 500;

/// A parsed, validated `/api/rates` request.
class RateQuery {
  /// Every field is already validated; the route builds one only through
  /// [parseRateQuery].
  const RateQuery({
    required this.fromCurrencyCode,
    required this.toCurrencyCodes,
    required this.limit,
    this.dateFrom,
    this.dateTo,
    this.preset,
  });

  /// The currency every returned rate is quoted against.
  final String fromCurrencyCode;

  /// The quoted currencies, or empty for every one the server holds.
  final List<String> toCurrencyCodes;

  /// Start of the window, inclusive. `null` reaches back as far as there is
  /// data.
  final DateTime? dateFrom;

  /// End of the window, inclusive of the whole day.
  final DateTime? dateTo;

  /// `null` means every preset — an imported rate and a fetched one both.
  /// The default is [kFetchedRatePreset]: a client asking for "the rate" means
  /// the published one, and its own manual rows already live on the device.
  final int? preset;

  /// Largest number of rows the caller will accept.
  final int limit;
}

/// Why a request was refused, in a form the route turns into a 400.
class RateQueryError {
  /// [message] names the parameter and the rule it broke, never the value.
  const RateQueryError(this.message);

  /// Safe to hand to the caller: it echoes no input back.
  final String message;
}

/// Reads query parameters into a [RateQuery], or explains why it cannot.
///
/// Errors are returned rather than thrown, and they are specific: a client
/// getting a bare 400 for `to=US D` has no way to tell a typo from an outage.
/// Nothing here echoes an unbounded slice of the input back — the messages name
/// the parameter and the rule, not the value.
({RateQuery? query, RateQueryError? error}) parseRateQuery(
  Map<String, String> params,
) {
  final from = (params['from']?.trim().isNotEmpty ?? false)
      ? params['from']!.trim().toUpperCase()
      : 'EUR';
  if (!_isCurrencyCode(from)) {
    return (
      query: null,
      error: const RateQueryError('`from` is not a currency code.'),
    );
  }

  final to = <String>[];
  final rawTo = params['to']?.trim() ?? '';
  if (rawTo.isNotEmpty) {
    for (final piece in rawTo.split(',')) {
      final code = piece.trim().toUpperCase();
      if (code.isEmpty) continue;
      if (!_isCurrencyCode(code)) {
        return (
          query: null,
          error: const RateQueryError(
            '`to` must be a comma-separated list of currency codes.',
          ),
        );
      }
      if (!to.contains(code)) to.add(code);
    }
    if (to.length > maxRateCurrencies) {
      return (
        query: null,
        error: const RateQueryError(
          '`to` names more than $maxRateCurrencies currencies.',
        ),
      );
    }
  }

  // `date` is shorthand for a one-day window. Every caller that wants a single
  // day would otherwise have to send the same value twice and get it right
  // twice.
  DateTime? dateFrom;
  DateTime? dateTo;
  final single = params['date']?.trim();
  if (single != null && single.isNotEmpty) {
    final parsed = DateTime.tryParse(single);
    if (parsed == null) {
      return (
        query: null,
        error: const RateQueryError('`date` is not a date.'),
      );
    }
    dateFrom = normalizeDay(parsed);
    dateTo = normalizeDay(parsed);
  } else {
    final rawFrom = params['date_from']?.trim();
    if (rawFrom != null && rawFrom.isNotEmpty) {
      final parsed = DateTime.tryParse(rawFrom);
      if (parsed == null) {
        return (
          query: null,
          error: const RateQueryError('`date_from` is not a date.'),
        );
      }
      dateFrom = normalizeDay(parsed);
    }
    final rawTo = params['date_to']?.trim();
    if (rawTo != null && rawTo.isNotEmpty) {
      final parsed = DateTime.tryParse(rawTo);
      if (parsed == null) {
        return (
          query: null,
          error: const RateQueryError('`date_to` is not a date.'),
        );
      }
      dateTo = normalizeDay(parsed);
    }
  }

  if (dateFrom != null && dateTo != null && dateFrom.isAfter(dateTo)) {
    return (
      query: null,
      error: const RateQueryError('`date_from` is after `date_to`.'),
    );
  }

  // `preset=all` is the escape hatch for a screen that lists everything the
  // server holds for a pair, including rates a device pushed up itself.
  int? preset = kFetchedRatePreset;
  final rawPreset = params['preset']?.trim().toLowerCase();
  if (rawPreset != null && rawPreset.isNotEmpty) {
    if (rawPreset == 'all') {
      preset = null;
    } else {
      final parsed = int.tryParse(rawPreset);
      if (parsed == null) {
        return (
          query: null,
          error: const RateQueryError('`preset` must be a number or `all`.'),
        );
      }
      preset = parsed;
    }
  }

  return (
    query: RateQuery(
      fromCurrencyCode: from,
      toCurrencyCodes: to,
      dateFrom: dateFrom,
      dateTo: dateTo,
      preset: preset,
      limit: parseRateLimit(params['limit']),
    ),
    error: null,
  );
}

/// Clamps a caller-supplied `?limit=` into a usable page size.
///
/// Missing or unparseable falls back to [defaultRateLimit]; anything else is
/// clamped into `1..maxRateLimit`. Zero is clamped rather than rejected, for
/// the reason the sync route gives: `LIMIT 0` reads as "nothing to fetch" and
/// stalls the caller silently, which is worse than a small page.
int parseRateLimit(String? raw) {
  if (raw == null) return defaultRateLimit;
  final parsed = int.tryParse(raw.trim());
  if (parsed == null) return defaultRateLimit;
  if (parsed < 1) return 1;
  if (parsed > maxRateLimit) return maxRateLimit;
  return parsed;
}

/// Currency codes here are three-letter ISO codes and longer crypto tickers
/// alike, so the rule is a length band and an alphabet rather than a fixed
/// length. The point is to keep anything that is not a code out of the SQL
/// parameter, not to police the app's currency list from here.
bool _isCurrencyCode(String value) {
  if (value.length < 2 || value.length > 12) return false;
  for (final unit in value.codeUnits) {
    final isUpper = unit >= 0x41 && unit <= 0x5A;
    final isDigit = unit >= 0x30 && unit <= 0x39;
    if (!isUpper && !isDigit) return false;
  }
  return true;
}
