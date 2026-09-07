import 'package:my_budget_server/data/database_client.dart';
import 'package:my_budget_server/rates/rate_provider.dart';
import 'package:postgres/postgres.dart';

/// `device_id` stamped on every rate this server fetched for itself.
///
/// It is what separates provider data from a rate the user typed on a phone.
/// The two live in the same table and must not be treated the same: the user's
/// own rows are budget data and belong in the sync stream, while these are a
/// shared reference data set that would drown it — a full history is hundreds
/// of thousands of rows, and a sync pull would hand every one of them to every
/// device on its next cursor move. Devices read these through `/api/rates`
/// instead, a page at a time, for the pairs they actually use.
const String kServerRateDeviceId = 'server:rates';

/// `preset` value the app uses for automatically fetched rates.
///
/// 0 is an imported rate, 1 is fetched, 2 comes from a user's custom API. The
/// app's own conversion paths look for 1, so that is what is written here.
const int kFetchedRatePreset = 1;

/// A single stored quote, in the shape the HTTP layer hands to a client.
typedef RateRow = ({
  String fromCurrencyCode,
  String toCurrencyCode,
  double rate,
  int preset,
  DateTime date,
  String? sourceId,
  int modifiedAt,
});

/// Reads and writes the server's own copy of the published exchange rates.
///
/// Deliberately separate from `SyncRepository`: that class moves whatever a
/// client sends and is keyed on sync cursors, while this one owns a reference
/// data set the server fetches on its own schedule and serves by pair and
/// date. They share only the table.
class RateStore {
  /// Takes the same pool the sync repository uses: the rates live in the
  /// budget database, not beside it.
  RateStore(this._dbClient);

  final DatabaseClient _dbClient;

  /// Rows written per statement.
  ///
  /// Each row binds two parameters of its own and Postgres caps a statement at
  /// 65535, so this leaves an order of magnitude of headroom while still
  /// collapsing a day's ~700 quotes into two round trips instead of 700.
  static const int _chunkSize = 500;

  /// Creates the table the refresher uses to remember dead days.
  ///
  /// Kept here rather than in `DatabaseClient.ensureSchema` so the rate module
  /// owns everything it needs: nothing outside it reads this table, and a
  /// server running with rate fetching switched off never creates it.
  ///
  /// Runs on every refresh, which is cheap (`IF NOT EXISTS` on an existing
  /// table is a catalogue lookup) and removes the ordering question of whether
  /// the refresher can start before the main schema is up.
  Future<void> ensureSchema() async {
    await _dbClient.pool.execute(
      'CREATE TABLE IF NOT EXISTS rate_fetch_gaps ( '
      'date TIMESTAMP PRIMARY KEY, '
      'attempts INTEGER NOT NULL DEFAULT 0, '
      'last_attempt_at BIGINT NOT NULL DEFAULT 0, '
      'reason TEXT '
      ')',
    );
  }

  /// Records that the provider published nothing for [day].
  ///
  /// Counted rather than flagged: a day can be missing because it has not been
  /// published *yet*, so a single miss must not retire it permanently. The
  /// refresher stops asking only after several runs have said the same thing.
  Future<void> recordGap({
    required DateTime day,
    required String reason,
  }) async {
    await _dbClient.pool.execute(
      Sql.named(
        'INSERT INTO rate_fetch_gaps (date, attempts, last_attempt_at, reason) '
        'VALUES (@date, 1, @at, @reason) '
        'ON CONFLICT (date) DO UPDATE SET '
        'attempts = rate_fetch_gaps.attempts + 1, '
        'last_attempt_at = EXCLUDED.last_attempt_at, '
        'reason = EXCLUDED.reason',
      ),
      parameters: {
        'date': normalizeDay(day),
        'at': DateTime.now().millisecondsSinceEpoch,
        'reason': reason,
      },
    );
  }

  /// Forgets a recorded gap, because the day turned up after all.
  Future<void> clearGap(DateTime day) async {
    await _dbClient.pool.execute(
      Sql.named('DELETE FROM rate_fetch_gaps WHERE date = @date'),
      parameters: {'date': normalizeDay(day)},
    );
  }

  /// Days asked for [maxAttempts] times or more with nothing to show for it.
  ///
  /// The refresher skips these so a permanent hole in the upstream data set
  /// cannot consume a whole run's request budget on every run and starve the
  /// days that do exist.
  Future<Set<DateTime>> exhaustedGapDays({
    required DateTime since,
    required int maxAttempts,
  }) async {
    final result = await _dbClient.pool.execute(
      Sql.named(
        'SELECT date FROM rate_fetch_gaps '
        'WHERE date >= @since AND attempts >= @attempts',
      ),
      parameters: {
        'since': normalizeDay(since),
        'attempts': maxAttempts,
      },
    );

    return {
      for (final row in result)
        if (row[0] case final DateTime date) normalizeDay(date),
    };
  }

  /// Stores one day's quotes, replacing anything already there for that key.
  ///
  /// Returns the number of rows written. [modifiedAt] is shared by the whole
  /// day on purpose — it is one fetch, and a per-row timestamp would only make
  /// the rows look independently edited.
  Future<int> saveDay({
    required DateTime day,
    required String baseCurrency,
    required DayRates rates,
    required String sourceId,
    int preset = kFetchedRatePreset,
    int? modifiedAt,
  }) async {
    if (rates.isEmpty) return 0;

    final storedDay = normalizeDay(day);
    final from = baseCurrency.toUpperCase();
    final stamp = modifiedAt ?? DateTime.now().millisecondsSinceEpoch;

    // The base quoted against itself is not stored: every conversion path
    // short-circuits an unchanged pair before it looks for a rate, so the row
    // would only be one more thing to serve.
    final entries = rates.entries.where((e) => e.key != from).toList();
    if (entries.isEmpty) return 0;

    var written = 0;
    await _dbClient.pool.runTx((session) async {
      for (var i = 0; i < entries.length; i += _chunkSize) {
        final end =
            (i + _chunkSize < entries.length) ? i + _chunkSize : entries.length;
        final chunk = entries.sublist(i, end);

        final values = <String>[];
        final parameters = <String, Object?>{
          'from': from,
          'date': storedDay,
          'preset': preset,
          'source': sourceId,
          'modified': stamp,
          'device': kServerRateDeviceId,
        };

        for (var j = 0; j < chunk.length; j++) {
          values.add(
            '(@from, @to_$j, @rate_$j, @preset, @date, @modified, '
            '@device, @source)',
          );
          parameters['to_$j'] = chunk[j].key;
          parameters['rate_$j'] = chunk[j].value;
        }

        final sql = 'INSERT INTO exchange_rates ( '
            'from_currency_code, to_currency_code, rate, preset, date, '
            'modified_at, device_id, source_id '
            ') VALUES ${values.join(', ')} '
            'ON CONFLICT (from_currency_code, to_currency_code, date, preset) '
            'DO UPDATE SET '
            'rate = EXCLUDED.rate, '
            'modified_at = EXCLUDED.modified_at, '
            'device_id = EXCLUDED.device_id, '
            'source_id = EXCLUDED.source_id';

        await session.execute(Sql.named(sql), parameters: parameters);
        written += chunk.length;
      }
    });

    return written;
  }

  /// The days this server already holds provider data for, on or after [since].
  ///
  /// Used by the backfill to work out what is missing without reading the rows
  /// themselves: a full history is hundreds of thousands of rows and the
  /// question is only which of nine hundred dates are present.
  Future<Set<DateTime>> storedDays({
    required String baseCurrency,
    required DateTime since,
    int preset = kFetchedRatePreset,
  }) async {
    final result = await _dbClient.pool.execute(
      Sql.named(
        'SELECT DISTINCT date FROM exchange_rates '
        'WHERE from_currency_code = @from '
        'AND preset = @preset '
        'AND device_id = @device '
        'AND date >= @since',
      ),
      parameters: {
        'from': baseCurrency.toUpperCase(),
        'preset': preset,
        'device': kServerRateDeviceId,
        'since': normalizeDay(since),
      },
    );

    return {
      for (final row in result)
        if (row[0] case final DateTime date) normalizeDay(date),
    };
  }

  /// Quotes matching a pair filter and a date window.
  ///
  /// An empty [toCurrencyCodes] means every quote for the base, which is what
  /// a first sync of the converter screen wants; naming a handful is what
  /// every other caller wants, and is the difference between a page and a
  /// table dump.
  Future<List<RateRow>> query({
    required String fromCurrencyCode,
    required int limit,
    List<String> toCurrencyCodes = const [],
    DateTime? dateFrom,
    DateTime? dateTo,
    int? preset,
  }) async {
    final conditions = <String>['from_currency_code = @from'];
    final parameters = <String, Object?>{
      'from': fromCurrencyCode.toUpperCase(),
      'limit': limit,
    };

    if (toCurrencyCodes.isNotEmpty) {
      conditions.add('to_currency_code = ANY(@to)');
      parameters['to'] = toCurrencyCodes.map((c) => c.toUpperCase()).toList();
    }
    if (dateFrom != null) {
      conditions.add('date >= @dateFrom');
      parameters['dateFrom'] = normalizeDay(dateFrom);
    }
    if (dateTo != null) {
      // Inclusive of the whole end day rather than of its midnight instant: a
      // caller asking for `date_to=2026-01-31` means that day, and a row
      // stamped at any other hour of it is still that day's quote.
      conditions.add('date < @dateTo');
      parameters['dateTo'] = normalizeDay(dateTo).add(const Duration(days: 1));
    }
    if (preset != null) {
      conditions.add('preset = @preset');
      parameters['preset'] = preset;
    }

    final result = await _dbClient.pool.execute(
      Sql.named(
        'SELECT from_currency_code, to_currency_code, rate, preset, date, '
        'source_id, modified_at '
        'FROM exchange_rates '
        'WHERE ${conditions.join(' AND ')} '
        'ORDER BY date DESC, to_currency_code ASC '
        'LIMIT @limit',
      ),
      parameters: parameters,
    );

    return result.map(_rowFrom).whereType<RateRow>().toList();
  }

  /// The newest quote per pair at or before [asOf].
  ///
  /// This is the "give me a rate for everything, as of this date" question the
  /// accounts screen asks. Answered with `DISTINCT ON` rather than by fetching
  /// a window and reducing it here: the window is the whole history.
  ///
  /// A pair with no quote on the requested day falls back to its last one, so
  /// a weekend or a public holiday reads as the Friday before it rather than
  /// as "no rate" — the same rule the app applies to its local rows.
  Future<List<RateRow>> latest({
    required String fromCurrencyCode,
    required int limit,
    List<String> toCurrencyCodes = const [],
    DateTime? asOf,
    int? preset,
  }) async {
    final conditions = <String>['from_currency_code = @from'];
    final parameters = <String, Object?>{
      'from': fromCurrencyCode.toUpperCase(),
      'limit': limit,
    };

    if (toCurrencyCodes.isNotEmpty) {
      conditions.add('to_currency_code = ANY(@to)');
      parameters['to'] = toCurrencyCodes.map((c) => c.toUpperCase()).toList();
    }
    if (asOf != null) {
      conditions.add('date < @asOf');
      parameters['asOf'] = normalizeDay(asOf).add(const Duration(days: 1));
    }
    if (preset != null) {
      conditions.add('preset = @preset');
      parameters['preset'] = preset;
    }

    final result = await _dbClient.pool.execute(
      Sql.named(
        'SELECT DISTINCT ON (to_currency_code, preset) '
        'from_currency_code, to_currency_code, rate, preset, date, '
        'source_id, modified_at '
        'FROM exchange_rates '
        'WHERE ${conditions.join(' AND ')} '
        'ORDER BY to_currency_code ASC, preset ASC, date DESC '
        'LIMIT @limit',
      ),
      parameters: parameters,
    );

    return result.map(_rowFrom).whereType<RateRow>().toList();
  }

  RateRow? _rowFrom(ResultRow row) {
    final from = row[0];
    final to = row[1];
    final rate = row[2];
    final date = row[4];
    if (from is! String || to is! String || date is! DateTime) return null;
    if (rate is! num) return null;

    final preset = row[3];
    final modifiedAt = row[6];

    return (
      fromCurrencyCode: from,
      toCurrencyCode: to,
      rate: rate.toDouble(),
      preset: preset is int ? preset : kFetchedRatePreset,
      date: date.toUtc(),
      sourceId: row[5] as String?,
      modifiedAt: modifiedAt is int ? modifiedAt : 0,
    );
  }
}

/// The wire shape of a quote.
///
/// Keys are the app's own field names rather than the database's column names,
/// so a client can hand the map straight to its DAO without a second mapping
/// table to keep in step with this one.
Map<String, dynamic> rateRowToJson(RateRow row) => {
      'fromCurrencyCode': row.fromCurrencyCode,
      'toCurrencyCode': row.toCurrencyCode,
      'rate': row.rate,
      'preset': row.preset,
      'date': row.date.toIso8601String(),
      'sourceId': row.sourceId,
      'modifiedAt': row.modifiedAt,
    };
