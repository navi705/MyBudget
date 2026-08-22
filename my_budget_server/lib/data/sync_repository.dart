import 'package:postgres/postgres.dart';
import 'package:my_budget_server/data/database_client.dart';

/// One table's slice of a pull page, before the slices are merged into the
/// single cursor the client stores.
typedef _TablePage = ({
  String tableName,
  List<Map<String, dynamic>> rows,
  int cursor,
  bool hitLimit,
});

/// One column of an upsert.
///
/// `key` is the JSON key the client sends the value under. Unless `always` is
/// set, the column is written *only when the payload actually contains that
/// key* — see `SyncRepository._bind` for why absence and an explicit null are
/// not the same thing. `always` is for the columns a row cannot be stored
/// without: primary keys, and the two the conflict guard is built on.
///
/// `convert` is handed the whole row rather than the single value, because a
/// few columns are computed from more than the key they are named after and
/// because the ones that log a rejection want the row's identity in the
/// message.
typedef _ColumnSpec = ({
  String column,
  String key,
  Object? Function(Map<String, dynamic> row)? convert,
  bool always,
});

/// Everything the statement builder needs to know about one synced table.
typedef _TableSpec = ({
  List<String> conflictColumns,
  List<_ColumnSpec> columns,
  int bulkChunkSize,
  String? Function(Map<String, dynamic> row)? reject,
});

/// A column bound for one row: the column it writes, the parameter name it is
/// bound under, and the value itself.
typedef _Bound = ({String column, String param, Object? value});

_ColumnSpec _c(
  String column,
  String key, {
  Object? Function(Map<String, dynamic> row)? convert,
  bool always = false,
}) =>
    (column: column, key: key, convert: convert, always: always);

/// A column carried through untouched.
_ColumnSpec _cRaw(String column, String key, {bool always = false}) =>
    _c(column, key, always: always);

/// A double column, normalised to eight decimals.
_ColumnSpec _cNum(String column, String key, {bool always = false}) =>
    _c(column, key, convert: (row) => _round(row[key]), always: always);

/// An exact-minor-units column (cents), which must never be coerced to 0.
_ColumnSpec _cMinor(String column, String key, {bool always = false}) =>
    _c(column, key, convert: (row) => _minorUnits(row[key]), always: always);

/// A boolean column. SQLite has no bool, so the client sends 1/0.
_ColumnSpec _cBool(String column, String key, {bool always = false}) =>
    _c(column, key, convert: (row) => _asBool(row[key]), always: always);

/// A TIMESTAMP column.
_ColumnSpec _cDate(String column, String key, {bool always = false}) =>
    _c(column, key, convert: (row) => _parseDate(row[key]), always: always);

/// Normalises SQLite's 1/0 into a real boolean.
bool _asBool(Object? value) => value is bool ? value : value == 1;

/// Returns null when the value is missing or unparseable.
///
/// Never substitute DateTime.now() here: a fabricated timestamp is
/// indistinguishable from a real one once it is stored, and it silently wins
/// against the client's real date on the next comparison.
///
/// A string with no zone designator is a *wall clock*, not an instant, and is
/// taken as one: it is re-flagged UTC so that `package:postgres`, which
/// encodes every DateTime as `input.toUtc()`, stores the very digits the
/// client sent. Parsed as a local DateTime instead, the same push landed on a
/// different row depending on the TZ the server container happened to run in,
/// and `date` is part of the primary key of `exchange_rates`.
DateTime? _parseDate(dynamic val) {
  if (val is int) {
    // Epoch milliseconds are an instant, not a wall clock, so they keep their
    // absolute meaning; the driver's toUtc() then stores the UTC wall clock of
    // that instant, which is server-timezone independent either way.
    return DateTime.fromMillisecondsSinceEpoch(val);
  } else if (val is String) {
    final parsed = DateTime.tryParse(val);
    if (parsed == null) return null;
    // tryParse flags the result UTC only when the text carried 'Z' or an
    // offset. Anything else is naive and is kept digit for digit.
    if (parsed.isUtc) return parsed;
    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
      parsed.microsecond,
    );
  }
  return null;
}

/// creation_date is nullable and nothing is keyed on it, so an account with a
/// bad one is stored with NULL instead of being dropped — dropping it would
/// break the accounts(id) foreign key for every transaction it owns.
DateTime? _accountCreationDate(Map<String, dynamic> row) {
  final parsed = _parseDate(row['creationDate']);
  if (parsed == null && row['creationDate'] != null) {
    print(
        '[SYNC] Account ${row['id']}: unparseable creationDate (${row['creationDate']}), storing NULL');
  }
  return parsed;
}

/// Null in, null out — a NULL amount/rate/fee must stay NULL rather than
/// becoming 0.0, which would silently rewrite the value on every device.
///
/// Values under [_roundingFloor] are passed through untouched. `toStringAsFixed(8)`
/// cannot represent them at all: an exchange rate of 2.4e-10 — a real figure for a
/// hyperinflated currency priced against BTC — renders as `0.00000000` and parses
/// back as exactly 0.0, which then divides into infinity on the far side. Mirrors
/// `ServerSyncService._round` on the client, so both ends of a round trip agree.
double? _round(dynamic value) {
  if (value == null) return null;
  final numVal = value is num ? value : num.tryParse(value.toString());
  if (numVal == null) return null;
  final asDouble = numVal.toDouble();
  if (asDouble == 0 || asDouble.abs() < _roundingFloor) return asDouble;
  return double.parse(asDouble.toStringAsFixed(8));
}

/// The smallest magnitude `toStringAsFixed(8)` can still represent.
const double _roundingFloor = 1e-8;

/// Exact integer minor units (cents) for fiat money.
///
/// Nullable end to end: NULL marks a row whose value is not expressible in
/// minor units (crypto/commodity), where the double column is authoritative.
/// Never coerce to 0 and never route these through [_round].
int? _minorUnits(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  final numVal = value is num ? value : num.tryParse(value.toString());
  return numVal?.round();
}

/// The stamp last-write-wins compares on, never null.
///
/// `modified_at BIGINT DEFAULT 0` only applies when the column is omitted, and
/// the upserts always name it, so an absent `modifiedAt` used to be written as
/// a real NULL. From that moment `EXCLUDED.modified_at > t.modified_at`
/// evaluated to NULL — not TRUE — for every later push, so the row froze: the
/// writes were answered 200, the client dropped its queue entry, and the row
/// was never updated and never re-handed to any peer again. Missing means
/// "oldest possible", which loses every comparison, not "unbeatable".
int _modifiedAt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

class SyncRepository {
  final DatabaseClient _dbClient;

  SyncRepository(this._dbClient);

  /// Arbitrary constant identifying the push lock. Any value works as long as
  /// every push uses the same one and nothing else in the database picks it.
  static const int _pushLockId = 795118301;

  /// The country an inflation rate that applies worldwide is stored under.
  ///
  /// Must match `globalInflationCountry` on the client.
  static const String _globalInflationCountry = 'global';

  /// Names the worldwide series for a client that still sends it as a null
  /// country.
  ///
  /// `country` is part of `inflation_rates`' primary key, so Postgres has it as
  /// NOT NULL. A push carries every table in one transaction, so a single such
  /// row would not merely be dropped — it would abort the whole batch, and that
  /// client would then fail every push it ever makes with nothing on its side
  /// reporting why.
  static String _inflationCountry(Object? raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    return _globalInflationCountry;
  }

  /// A row that cannot be keyed at all, with the message to log.
  static String? _needsDate(String what, Map<String, dynamic> row) =>
      _parseDate(row['date']) == null
          ? 'Skipping $what: missing or unparseable date (${row['date']})'
          : null;

  /// Every synced table's write shape, in one place.
  ///
  /// One description per table rather than one hand-written statement per
  /// table: the conflict guard, the "absent means leave alone" rule and the
  /// bulk builder are all consequences of this map, so a table cannot end up
  /// with a different rule than its neighbours by omission.
  static final Map<String, _TableSpec> _tables = {
    'languages': (
      conflictColumns: ['language_code'],
      columns: [
        _cRaw('language_code', 'languageCode', always: true),
        _cRaw('language', 'language'),
      ],
      bulkChunkSize: 1000,
      reject: null,
    ),
    'currencies': (
      conflictColumns: ['code'],
      columns: [
        _cRaw('code', 'code', always: true),
        _cRaw('name', 'name'),
        _cRaw('language_code', 'languageCode'),
        _cRaw('type', 'type'),
      ],
      bulkChunkSize: 1000,
      reject: null,
    ),
    'styles': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('name', 'name'),
        _cRaw('color_hex', 'colorHex'),
        _cRaw('icon_name', 'iconName'),
        _cRaw('icon_type', 'iconType'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 1000,
      reject: null,
    ),
    'account_types': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('name', 'name'),
        _cRaw('language_code', 'languageCode'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 1000,
      reject: null,
    ),
    'currency_designations': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('value', 'value'),
        _cRaw('currency_code', 'currencyCode'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 1000,
      reject: null,
    ),
    'categories': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('name', 'name'),
        _cRaw('parent_id', 'parentId'),
        _cRaw('style_id', 'styleId'),
        _cRaw('type', 'type'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 1000,
      reject: null,
    ),
    'accounts': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('name', 'name'),
        _cRaw('description', 'description'),
        _cNum('balance', 'balance'),
        _cMinor('balance_minor', 'balanceMinor'),
        _cRaw('currency_code', 'currencyCode'),
        _cRaw('currency_designation_id', 'currencyDesignationId'),
        _cRaw('style_id', 'styleId'),
        _cRaw('account_type_id', 'accountTypeId'),
        _c('creation_date', 'creationDate', convert: _accountCreationDate),
        _cRaw('country', 'country'),
        _cRaw('asset_id', 'assetId'),
        _cNum('asset_quantity', 'assetQuantity'),
        _cRaw('fee_structure', 'feeStructure'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 500,
      reject: null,
    ),
    'transactions': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('description', 'description'),
        _cNum('amount', 'amount'),
        _cMinor('amount_minor', 'amountMinor'),
        _cDate('date', 'date', always: true),
        _cRaw('account_id', 'accountId'),
        _cRaw('category_id', 'categoryId'),
        _cRaw('currency_code', 'currencyCode'),
        _cNum('exchange_rate', 'exchangeRate'),
        _cRaw('exchange_rate_preset', 'exchangeRatePreset'),
        _cNum('fee', 'fee'),
        _cMinor('fee_minor', 'feeMinor'),
        _cRaw('linked_transaction_id', 'linkedTransactionId'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 500,
      // A transaction with no usable date cannot be placed on any timeline.
      reject: (row) => _needsDate('transaction ${row['id']}', row),
    ),
    'asset_entries': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('asset_id', 'assetId'),
        _cRaw('name', 'name'),
        _cDate('date', 'date', always: true),
        _cNum('value', 'value'),
        _cNum('quantity', 'quantity'),
        _cRaw('asset_type', 'assetType'),
        _cRaw('description', 'description'),
        _cRaw('currency_code', 'currencyCode'),
        _cRaw('account_id', 'accountId'),
        _cRaw('source', 'source'),
        _cRaw('preset', 'preset'),
        _cRaw('source_id', 'sourceId'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 500,
      // An asset entry is a point on a value timeline — without a date it is
      // meaningless, so skip it rather than inventing one.
      reject: (row) => _needsDate('asset_entry ${row['id']}', row),
    ),
    'sms_presets': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('name', 'name'),
        _cRaw('sender_filter', 'senderFilter'),
        _cBool('is_built_in', 'isBuiltIn'),
        _cBool('is_enabled', 'isEnabled'),
        _cRaw('default_account_id', 'defaultAccountId'),
        _cRaw('default_category_id', 'defaultCategoryId'),
        _cRaw('rules_json', 'rulesJson'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 500,
      reject: null,
    ),
    'settings': (
      conflictColumns: ['key'],
      columns: [
        _cRaw('key', 'key', always: true),
        _cRaw('value', 'value'),
        _cRaw('device', 'device'),
      ],
      bulkChunkSize: 1000,
      reject: null,
    ),
    'exchange_rates': (
      conflictColumns: [
        'from_currency_code',
        'to_currency_code',
        'date',
        'preset'
      ],
      columns: [
        _cRaw('from_currency_code', 'fromCurrencyCode', always: true),
        _cRaw('to_currency_code', 'toCurrencyCode', always: true),
        _cNum('rate', 'rate'),
        _cRaw('preset', 'preset', always: true),
        _cDate('date', 'date', always: true),
        _cRaw('source_id', 'sourceId'),
      ],
      bulkChunkSize: 1000,
      // date is part of the primary key — the row cannot be stored at all.
      reject: (row) => _needsDate(
          'exchange_rate ${row['fromCurrencyCode']}->${row['toCurrencyCode']}',
          row),
    ),
    'inflation_rates': (
      conflictColumns: ['date', 'country', 'preset'],
      columns: [
        _cDate('date', 'date', always: true),
        _cNum('percent', 'percent'),
        _c('country', 'country',
            convert: (row) => _inflationCountry(row['country']), always: true),
        _cRaw('preset', 'preset', always: true),
        _cRaw('source_id', 'sourceId'),
      ],
      bulkChunkSize: 1000,
      // date is part of the primary key — the row cannot be stored at all.
      reject: (row) => _needsDate('inflation_rate for ${row['country']}', row),
    ),
    'custom_themes': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('name', 'name'),
        _cRaw('primary_color_hex', 'primaryColorHex'),
        _cRaw('secondary_color_hex', 'secondaryColorHex'),
        _cRaw('surface_color_hex', 'surfaceColorHex'),
        _cRaw('background_color_hex', 'backgroundColorHex'),
        _cRaw('background_image_path', 'backgroundImagePath'),
        _cRaw('background_image_opacity', 'backgroundImageOpacity'),
        _cRaw('background_image_blur', 'backgroundImageBlur'),
        _cRaw('window_effect_type', 'windowEffectType'),
        _cRaw('effect_opacity', 'effectOpacity'),
        _cRaw('surface_opacity', 'surfaceOpacity'),
        _cRaw('theme_mode', 'themeMode'),
        _cBool('is_preset', 'isPreset'),
        _cBool('is_active', 'isActive'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 500,
      reject: null,
    ),
    'custom_data_sources': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cRaw('name', 'name'),
        _cRaw('url', 'url'),
        _cRaw('data_type', 'dataType'),
        _cBool('enabled', 'enabled'),
        _cBool('auto_fetch', 'autoFetch'),
        _cRaw('last_fetch_at', 'lastFetchAt'),
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 500,
      reject: null,
    ),
    'api_settings': (
      conflictColumns: ['id'],
      columns: [
        _cRaw('id', 'id', always: true),
        _cBool('enabled', 'enabled'),
        _cBool('auto_fetch', 'autoFetch'),
        _cRaw('last_fetch_at', 'lastFetchAt'),
        // The client has always sent this flag and has always read it back;
        // the server was the only end that dropped it, so a provider the user
        // deleted was pushed as deleted, stored as live, and handed back to
        // every other device as live on the next pull.
        _cBool('is_deleted', 'isDeleted'),
      ],
      bulkChunkSize: 500,
      reject: null,
    ),
  };

  Future<void> upsertBatch(Map<String, dynamic> data) async {
    final tablesList = [
      'settings',
      'api_settings',
      'languages',
      'currencies',
      'styles',
      'custom_themes',
      'account_types',
      'currency_designations',
      'categories',
      'exchange_rates',
      'inflation_rates',
      'custom_data_sources',
      'sms_presets',
      // Dependent tables last
      'accounts',
      'asset_entries',
      'transactions',
    ];

    // Optimization: Use bulk upsert for tables with >50 rows to reduce N+1 queries
    final bulkUpsertTables = {
      'exchange_rates',
      'inflation_rates',
      'categories',
      'transactions',
      'accounts',
    };

    // runTx (not run): a batch must be all-or-nothing. `pool.run` is not a
    // transaction, so a mid-batch failure left rows partially applied and
    // visible to concurrent pulls.
    await _dbClient.pool.runTx((session) async {
      // Serialise pushes against each other so that `server_seq` order and
      // commit order agree.
      //
      // The sequence is read when a row is written, not when the transaction
      // commits. Two overlapping pushes can therefore take seq 100 and 101 and
      // commit in the opposite order; a pull landing in between sees 101, moves
      // its cursor past it, and never sees row 100. That is the same permanent
      // skip the cursor rewrite exists to remove, so the writes are serialised
      // instead. Pulls are read-only and never wait on this.
      await session.execute(Sql.named('SELECT pg_advisory_xact_lock(@lockId)'),
          parameters: {'lockId': _pushLockId});

      for (final table in tablesList) {
        if (data.containsKey(table)) {
          final rows = data[table] as List;

          if (rows.length > 50 && bulkUpsertTables.contains(table)) {
            // Use bulk upsert for large tables to reduce query count
            await _bulkUpsert(
                session, table, rows.cast<Map<String, dynamic>>());
          } else {
            for (final row in rows) {
              await _upsertRow(session, table, row as Map<String, dynamic>);
            }
          }
        }
      }
    });
  }

  Future<void> _upsertRow(
      Session session, String table, Map<String, dynamic> row) async {
    final spec = _tables[table];
    if (spec == null) return;

    final rejection = spec.reject?.call(row);
    if (rejection != null) {
      print('[SYNC] $rejection');
      return;
    }

    final bound = _bind(spec, row, suffix: '');
    final sql = _upsertSql(table, spec, [bound]);

    await session.execute(
      Sql.named(sql),
      parameters: {for (final b in bound) b.param: b.value},
    );
  }

  Future<void> _bulkUpsert(
      Session session, String table, List<Map<String, dynamic>> rows) async {
    final spec = _tables[table];
    if (spec == null || rows.isEmpty) return;

    final accepted = <Map<String, dynamic>>[];
    for (final row in rows) {
      final rejection = spec.reject?.call(row);
      if (rejection != null) {
        print('[SYNC] $rejection');
        continue;
      }
      accepted.add(row);
    }
    if (accepted.isEmpty) return;

    // One statement carries a single column list and a single SET list, so
    // rows that carry different fields cannot share one — the columns missing
    // from the odd row out would be bound as NULL and overwrite the stored
    // value, which is exactly what the presence rule exists to prevent. In
    // practice every row in a push comes from one client and one build, so
    // this is one group.
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final row in accepted) {
      final signature = spec.columns
          .where((c) => c.always || row.containsKey(c.key))
          .map((c) => c.column)
          .join(',');
      groups.putIfAbsent(signature, () => []).add(row);
    }

    for (final group in groups.values) {
      for (var i = 0; i < group.length; i += spec.bulkChunkSize) {
        final end = (i + spec.bulkChunkSize < group.length)
            ? i + spec.bulkChunkSize
            : group.length;
        final chunk = group.sublist(i, end);

        final bound = <List<_Bound>>[
          for (var j = 0; j < chunk.length; j++)
            _bind(spec, chunk[j], suffix: '_$j'),
        ];

        await session.execute(
          Sql.named(_upsertSql(table, spec, bound)),
          parameters: {
            for (final row in bound)
              for (final b in row) b.param: b.value,
          },
        );
      }
    }
  }

  /// The columns of [row] that this push actually carried, in column order.
  ///
  /// `containsKey`, not a null check: the two mean opposite things. A key sent
  /// as an explicit null is a real clear — `amount_minor` is nullable on
  /// purpose, and NULL is how a crypto row says "the double column is
  /// authoritative". A key that is not in the payload at all is a client that
  /// has never heard of the column: `amount_minor`, `fee_minor` and
  /// `balance_minor` were all added to this server by migration, which is
  /// proof such clients exist. Writing that silence into the row erased the
  /// exact minor units for every device on the account, and an absent
  /// `isDeleted` (coerced to false) cleared a tombstone the rest of the fleet
  /// had already agreed on.
  ///
  /// [suffix] distinguishes one row's parameters from the next in a multi-row
  /// statement; it is empty for the single-row path.
  List<_Bound> _bind(
    _TableSpec spec,
    Map<String, dynamic> row, {
    required String suffix,
  }) {
    final bound = <_Bound>[];
    for (final column in spec.columns) {
      if (!column.always && !row.containsKey(column.key)) continue;
      bound.add((
        column: column.column,
        param: '${column.key}$suffix',
        value: column.convert == null ? row[column.key] : column.convert!(row),
      ));
    }
    // Always written, whatever the payload says: the conflict guard is built
    // on both, and a missing stamp has to read as "oldest possible" rather
    // than as NULL.
    bound.add((
      column: 'modified_at',
      param: 'modifiedAt$suffix',
      value: _modifiedAt(row['modifiedAt']),
    ));
    bound.add((
      column: 'device_id',
      param: 'deviceId$suffix',
      value: row['deviceId'],
    ));
    return bound;
  }

  /// Builds the one upsert shape every table shares, over one or more rows.
  ///
  /// Every row in [rows] carries the same columns in the same order - the
  /// single-row path has only one, and the bulk path groups by column list
  /// before it gets here - so the first row is representative of all of them.
  String _upsertSql(String table, _TableSpec spec, List<List<_Bound>> rows) {
    final columns = rows.first.map((b) => b.column).join(', ');

    final values = StringBuffer();
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) values.write(', ');
      values.write('(${rows[i].map((b) => '@${b.param}').join(', ')})');
    }

    // Only the columns this push carried are assigned on conflict. The
    // primary key is excluded because it is what matched.
    final assignments = rows.first
        .where((b) => !spec.conflictColumns.contains(b.column))
        .map((b) => '${b.column} = EXCLUDED.${b.column}')
        .join(',\n        ');

    return '''
      INSERT INTO $table ($columns)
      VALUES $values
      ON CONFLICT (${spec.conflictColumns.join(', ')}) DO UPDATE SET
        $assignments
      WHERE ${_lastWriteWins(table)}
    ''';
  }

  /// Last-write-wins, with a tiebreak that does not depend on arrival order.
  ///
  /// Two devices editing the same row in the same millisecond stamp the same
  /// `modified_at`, and a strict `>` then lets whichever push arrived first
  /// keep the row: the second is answered 200, its queue entry is drained, and
  /// because no UPDATE happened `server_seq` never moves, so no peer is ever
  /// handed either version again. The devices diverge permanently and in
  /// silence. `(modified_at, device_id)` is a total order every party can
  /// evaluate independently — higher device id wins — which is the same rule
  /// the clients apply, so all three ends pick the same winner.
  ///
  /// COALESCE, not a bare comparison: a row whose `modified_at` is NULL (an
  /// older client that predates the column) made every later comparison
  /// evaluate to NULL rather than TRUE, freezing the row forever.
  static String _lastWriteWins(String table) =>
      'EXCLUDED.modified_at > COALESCE($table.modified_at, 0) '
      'OR (EXCLUDED.modified_at = COALESCE($table.modified_at, 0) '
      "AND COALESCE(EXCLUDED.device_id, '') > COALESCE($table.device_id, ''))";

  /// Everything written after cursor [lastSync], in server-write order.
  ///
  /// [lastSync] is a `server_seq` value, not a timestamp: paging on
  /// `modified_at` skipped any row a client pushed with a clock below a cursor
  /// its peers had already passed, permanently and silently. `lastTimestamp` in
  /// the returned record is likewise the cursor to send back next time - the
  /// name is kept only because it is the wire field clients already read.
  Future<({Map<String, List<Map<String, dynamic>>> changes, int lastTimestamp, bool hasMore})>
      getChanges(int lastSync, {int limit = 5000}) async {
    final changes = <String, List<Map<String, dynamic>>>{};
    int maxSeq = lastSync;

    final tableConfigsMap = {
      'categories': {
        'parent_id': 'parentId',
        'style_id': 'styleId',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'transactions': {
        'account_id': 'accountId',
        'category_id': 'categoryId',
        'currency_code': 'currencyCode',
        'exchange_rate': 'exchangeRate',
        'exchange_rate_preset': 'exchangeRatePreset',
        'linked_transaction_id': 'linkedTransactionId',
        'amount_minor': 'amountMinor',
        'fee_minor': 'feeMinor',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'accounts': {
        'balance_minor': 'balanceMinor',
        'currency_code': 'currencyCode',
        'currency_designation_id': 'currencyDesignationId',
        'account_type_id': 'accountTypeId',
        'style_id': 'styleId',
        'creation_date': 'creationDate',
        'asset_id': 'assetId',
        'asset_quantity': 'assetQuantity',
        'fee_structure': 'feeStructure',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'styles': {
        'color_hex': 'colorHex',
        'icon_name': 'iconName',
        'icon_type': 'iconType',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'asset_entries': {
        'asset_id': 'assetId',
        'asset_type': 'assetType',
        'currency_code': 'currencyCode',
        'account_id': 'accountId',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'source_id': 'sourceId',
        'is_deleted': 'isDeleted'
      },
      'account_types': {
        'language_code': 'languageCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'currency_designations': {
        'currency_code': 'currencyCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'custom_data_sources': {
        'data_type': 'dataType',
        'auto_fetch': 'autoFetch',
        'last_fetch_at': 'lastFetchAt',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'api_settings': {
        'auto_fetch': 'autoFetch',
        'last_fetch_at': 'lastFetchAt',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        // Renaming it is what makes the delete visible: the client reads
        // `isDeleted` and nothing else.
        'is_deleted': 'isDeleted'
      },
      'sms_presets': {
        'sender_filter': 'senderFilter',
        'is_built_in': 'isBuiltIn',
        'is_enabled': 'isEnabled',
        'default_account_id': 'defaultAccountId',
        'default_category_id': 'defaultCategoryId',
        'rules_json': 'rulesJson',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'settings': {
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
      },
      'exchange_rates': {
        'from_currency_code': 'fromCurrencyCode',
        'to_currency_code': 'toCurrencyCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'source_id': 'sourceId'
      },
      'inflation_rates': {
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'source_id': 'sourceId'
      },
      'languages': {
        'language_code': 'languageCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId'
      },
      'currencies': {
        'language_code': 'languageCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId'
      },
      'custom_themes': {
        'primary_color_hex': 'primaryColorHex',
        'secondary_color_hex': 'secondaryColorHex',
        'surface_color_hex': 'surfaceColorHex',
        'background_color_hex': 'backgroundColorHex',
        'background_image_path': 'backgroundImagePath',
        'background_image_opacity': 'backgroundImageOpacity',
        'background_image_blur': 'backgroundImageBlur',
        'window_effect_type': 'windowEffectType',
        'effect_opacity': 'effectOpacity',
        'surface_opacity': 'surfaceOpacity',
        'theme_mode': 'themeMode',
        'is_preset': 'isPreset',
        'is_active': 'isActive',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
    };

    final tableConfigs = tableConfigsMap.entries.toList();

    // All sixteen reads in one transaction, holding the push lock in shared
    // mode.
    //
    // Run independently, each query saw a different instant. A row written into
    // a table that had already been read took a sequence below the maximum this
    // page reports, so the client's cursor moved past it and it was never
    // handed out again - the same permanent skip in a different disguise. A
    // shared lock keeps pushes out for the duration (they take it exclusively)
    // while letting concurrent pulls run together, so a page is always a prefix
    // of this server's write order.
    final results = await _dbClient.pool.runTx((session) async {
      await session.execute(
        Sql.named('SELECT pg_advisory_xact_lock_shared(@lockId)'),
        parameters: {'lockId': _pushLockId},
      );

      final pages = <_TablePage>[];
      for (final entry in tableConfigs) {
        final tableName = entry.key;
        // Carried through the mapping so the cursor can be read off the rows;
        // stripped again before they are handed to the client.
        final columnMap = {...entry.value, 'server_seq': 'serverSeq'};

        // `server_seq` is unique across every table, so it is already a total
        // order - no primary-key tiebreaker is needed to keep paging stable,
        // and no page can end mid-way through a group of rows sharing a value.
        final result = await session.execute(
          Sql.named(
            'SELECT * FROM $tableName WHERE server_seq > @lastSync '
            'ORDER BY server_seq ASC LIMIT @limit',
          ),
          parameters: {'lastSync': lastSync, 'limit': limit},
        );

        final rows = _mapResult(result, columnMap);
        final hitLimit = rows.isNotEmpty && rows.length >= limit;

        // Cursor for THIS table alone. It is never advanced past a row this
        // table has not returned yet; the caller then takes the minimum over
        // the truncated tables so no table can be skipped by another table's
        // data.
        var cursor = lastSync;
        if (rows.isNotEmpty) {
          cursor = rows.last['serverSeq'] as int;
        }

        pages.add((
          tableName: tableName,
          rows: rows,
          cursor: cursor,
          hitLimit: hitLimit
        ));
      }
      return pages;
    });

    // Aggregate results and compute the next cursor.
    // NOTE: No early break — all tables must be included regardless of count.
    // Breaking early causes tables with lower sequence numbers to be
    // permanently skipped once a high-volume table (e.g. exchange_rates)
    // consumes the entire limit.
    bool hasMore = false;
    int? truncatedCursor;
    for (final result in results) {
      for (final row in result.rows) {
        final seq = row['serverSeq'] as int;
        if (seq > maxSeq) maxSeq = seq;
      }

      // A table that filled its limit still has rows to give
      if (result.hitLimit) {
        hasMore = true;
        if (truncatedCursor == null || result.cursor < truncatedCursor) {
          truncatedCursor = result.cursor;
        }
      }
    }

    // A single global max would skip everything a truncated table has not
    // returned yet, so any truncated table pins the cursor for all tables.
    final nextCursor = truncatedCursor ?? maxSeq;

    // The cursor is decided BEFORE the page is assembled, and every table's
    // slice is then cut down to it. `server_seq` is one global sequence, so a
    // budget whose 283 000 exchange rates were pushed before its 4 000
    // transactions puts every transaction above the rate range: with the page
    // built first, all 4 000 shipped on page 1, and again on each of the 57
    // pages the rates need — 228 000 row applies, and 57 balance rebuilds, for
    // 4 000 rows. Trimmed to the cursor, a page is a true prefix of the write
    // order and every row is handed out exactly once. `hasMore` still drives
    // the loop, and it is necessarily already true whenever anything is
    // trimmed, because only a truncated table can pin the cursor below maxSeq.
    for (final result in results) {
      final rows = result.rows
          .where((row) => (row['serverSeq'] as int) <= nextCursor)
          .toList();
      if (rows.isEmpty) continue;
      for (final row in rows) {
        // Internal bookkeeping: the client stores whatever it is handed, and
        // this column is not one of its own.
        row.remove('serverSeq');
      }
      changes[result.tableName] = rows;
    }

    return (changes: changes, lastTimestamp: nextCursor, hasMore: hasMore);
  }

  // Helper to map DB row (snake_case) to JSON (camelCase or whatever client expects)
  List<Map<String, dynamic>> _mapResult(
      Result result, Map<String, String> columnMap) {
    return result.map((row) {
      final map = <String, dynamic>{};
      final colMap = row.toColumnMap();
      colMap.forEach((key, value) {
        final newKey = columnMap[key] ?? key;
        if (value is DateTime) {
          map[newKey] = _isoWallClock(value);
        } else {
          map[newKey] = value;
        }
      });
      return map;
    }).toList();
  }

  /// A `TIMESTAMP` column as the wall clock it is, with no zone marker.
  ///
  /// The driver decodes `timestamp without time zone` as a `DateTime.utc`, so
  /// `toIso8601String()` stamped a 'Z' onto a value that never carried one.
  /// The client parses what it is handed and stores the resulting *instant*,
  /// so a rate the user entered at local midnight came back as an instant and
  /// re-rendered as 19:00 the previous day west of UTC — a different calendar
  /// day, a different `exchange_rates` primary key, and a transaction moved
  /// into the previous month. The column holds a wall clock, the client sends
  /// a wall clock, so a wall clock is what goes back: the digits that were
  /// pushed are the digits that are returned, in every zone.
  static String _isoWallClock(DateTime value) {
    final iso = value.toIso8601String();
    return iso.endsWith('Z') ? iso.substring(0, iso.length - 1) : iso;
  }
}
