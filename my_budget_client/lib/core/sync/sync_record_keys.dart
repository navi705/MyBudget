/// Parsers and formatters for the composite `sync_log.record_id` strings the
/// rate tables use.
///
/// `exchange_rates` and `inflation_rates` have no single-column primary key, so
/// their DAOs synthesise a record id out of the key columns:
///
/// * `exchange_rates`: `'${from}_${to}_${yyyy-MM-dd}_${preset}'`
///   (`ExchangeRatesDao.addExchangeRate` / `updateExchangeRate` /
///   `replaceExchangeRate`)
/// * `inflation_rates`: `'${yyyy-MM-dd}_${country}_${preset}'`
///   (`InflationRatesDao._recordId`)
///
/// The sync engine has to turn those strings back into a `WHERE` clause, which
/// is the only reason this file exists. It is deliberately free of any database
/// or Flutter dependency so both sides of the wire - and the tests - can use it
/// without spinning up a schema.
///
/// Every parser is total: a record id written by an older build, by a peer with
/// a different idea of the format, or by a corrupted file must yield `null`
/// rather than throw. `SyncService._applyChange` runs inside a loop over an
/// entire imported packet, and one unparsable id must not cost the other
/// changes in that packet.
library;

import 'package:intl/intl.dart';

/// The exact format the DAOs embed in a record id.
///
/// Reused rather than reimplemented with `padLeft` so the formatting side stays
/// byte-identical to `app_database.dart`: an id this file formats differently
/// from the one the DAO wrote would silently never match on export or import.
///
/// The locale is pinned because this is a key, not a label. An unqualified
/// `DateFormat` follows `Intl.defaultLocale`, which the app now points at the
/// language the user reads in, and `bn` is a shipped locale whose CLDR data
/// carries native digits — so a Bengali device would have written
/// `EUR_USD_২০২৬-০৮-১২_0` and matched nothing any other device (or its own
/// parser, on the next language change) ever wrote.
final DateFormat _recordIdDateFormat = DateFormat('yyyy-MM-dd', 'en');

/// Formats [date] the way a `sync_log` record id spells a day.
///
/// Only the calendar day survives; the time of day of the stored column does
/// not appear in the id, which is why lookups by a parsed key have to match a
/// whole day rather than an exact instant.
String formatSyncRecordDate(DateTime date) => _recordIdDateFormat.format(date);

/// Parses the `yyyy-MM-dd` segment of a record id, or null when [value] is not
/// one.
///
/// Strict on purpose: `'notadate'`, `'2024-13-45'` and `'2024-01-15junk'` are
/// all rejected instead of being coerced into some nearby date, because a
/// silently mis-parsed date would key a row onto the wrong day.
DateTime? tryParseSyncRecordDate(String value) {
  if (value.isEmpty) return null;
  try {
    return _recordIdDateFormat.parseStrict(value);
  } catch (_) {
    return null;
  }
}

/// The `exchange_rates` primary key as carried in a `sync_log` record id.
class ExchangeRateKey {
  final String fromCurrencyCode;
  final String toCurrencyCode;

  /// The rate's date. Only its calendar day is part of the record id, so use
  /// [dayStart] / [dayAfter] to match the stored column, which may carry a time
  /// of day (not every caller normalises to midnight).
  final DateTime date;

  final int preset;

  const ExchangeRateKey({
    required this.fromCurrencyCode,
    required this.toCurrencyCode,
    required this.date,
    required this.preset,
  });

  /// The record id `ExchangeRatesDao` would write for this key.
  String format() =>
      '${fromCurrencyCode}_${toCurrencyCode}_${formatSyncRecordDate(date)}_$preset';

  /// Local midnight of [date], the inclusive lower bound of the day the record
  /// id names.
  DateTime get dayStart => DateTime(date.year, date.month, date.day);

  /// Local midnight of the following day, the exclusive upper bound.
  ///
  /// Built through the [DateTime] constructor rather than `add(Duration(days:
  /// 1))` so a day that is 23 or 25 hours long across a DST switch still ends
  /// where the next one starts.
  DateTime get dayAfter => DateTime(date.year, date.month, date.day + 1);

  /// Parses [recordId], or returns null when it is not an `exchange_rates` id.
  ///
  /// Read positionally from the end - last segment is the preset, the one
  /// before it the date - and required to have exactly four segments. A
  /// currency code containing an underscore would make `from` and `to`
  /// genuinely ambiguous, so such an id is rejected outright instead of being
  /// split at a guessed position and quietly pointed at the wrong row.
  static ExchangeRateKey? tryParse(String recordId) {
    final parts = recordId.split('_');
    if (parts.length != 4) return null;

    final preset = int.tryParse(parts[3]);
    if (preset == null) return null;

    final date = tryParseSyncRecordDate(parts[2]);
    if (date == null) return null;

    final from = parts[0];
    final to = parts[1];
    if (from.isEmpty || to.isEmpty) return null;

    return ExchangeRateKey(
      fromCurrencyCode: from,
      toCurrencyCode: to,
      date: date,
      preset: preset,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExchangeRateKey &&
      other.fromCurrencyCode == fromCurrencyCode &&
      other.toCurrencyCode == toCurrencyCode &&
      other.date == date &&
      other.preset == preset;

  @override
  int get hashCode =>
      Object.hash(fromCurrencyCode, toCurrencyCode, date, preset);

  @override
  String toString() => 'ExchangeRateKey(${format()})';
}

/// The `inflation_rates` primary key as carried in a `sync_log` record id.
class InflationRateKey {
  /// See [ExchangeRateKey.date]: the id spells only the calendar day.
  final DateTime date;

  /// Never null and never empty in the database - the worldwide series is
  /// stored under the `globalInflationCountry` sentinel (`'global'`), because
  /// SQLite treats NULLs in a primary key as distinct and a nullable column let
  /// the same worldwide month be inserted over and over.
  final String country;

  final int preset;

  const InflationRateKey({
    required this.date,
    required this.country,
    required this.preset,
  });

  /// The record id `InflationRatesDao._recordId` would write for this key.
  String format() => '${formatSyncRecordDate(date)}_${country}_$preset';

  /// See [ExchangeRateKey.dayStart].
  DateTime get dayStart => DateTime(date.year, date.month, date.day);

  /// See [ExchangeRateKey.dayAfter].
  DateTime get dayAfter => DateTime(date.year, date.month, date.day + 1);

  /// Parses [recordId], or returns null when it is not an `inflation_rates` id.
  ///
  /// The date is pinned to the first segment and the preset to the last, so
  /// whatever lies between them is the country and can be rejoined verbatim.
  /// Unlike an exchange rate id there is nothing to guess at here: a country
  /// containing an underscore round-trips exactly.
  static InflationRateKey? tryParse(String recordId) {
    final parts = recordId.split('_');
    if (parts.length < 3) return null;

    final preset = int.tryParse(parts.last);
    if (preset == null) return null;

    final date = tryParseSyncRecordDate(parts.first);
    if (date == null) return null;

    final country = parts.sublist(1, parts.length - 1).join('_');
    if (country.isEmpty) return null;

    return InflationRateKey(date: date, country: country, preset: preset);
  }

  @override
  bool operator ==(Object other) =>
      other is InflationRateKey &&
      other.date == date &&
      other.country == country &&
      other.preset == preset;

  @override
  int get hashCode => Object.hash(date, country, preset);

  @override
  String toString() => 'InflationRateKey(${format()})';
}
