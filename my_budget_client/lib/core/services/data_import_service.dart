import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';

import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/value_objects/amount.dart';
import 'package:uuid/uuid.dart';
import 'package:my_budget_client/core/services/android_file_picker_service.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart'
    show serverPullCursorKey;
import 'package:shared_preferences/shared_preferences.dart';

/// Parses CSV without assuming a line ending.
///
/// The parser was pinned to `eol: '\n'`, which does not mean "accept LF" — it
/// means "\r is ordinary text". Every CRLF file (Excel, most banks, and this
/// app's own export, which writes the RFC-conform \r\n) therefore arrived with
/// a `\r` welded onto the last column of every row: an account named `Cash`
/// read as `Cash\r` and was imported as a second, different account, and the
/// exchange-rate importer rejected valid files outright because its last
/// header cell read `rate\r`.
const _csvConverter = CsvToListConverter(
  csvSettingsDetector: FirstOccurrenceSettingsDetector(eols: ['\r\n', '\n']),
);

/// Exact integer minor units for a fiat [major] amount in [code], or null for
/// crypto/commodity, whose minor columns stay NULL. Mirrors the transaction and
/// account mappers, the app's single definition of the money encoding.
int? _minorOrNull(double major, String code) {
  final amount = Amount.fromMajorCode(major, code);
  return amount is FiatAmount ? amount.minorUnits : null;
}

/// Rewrites a backed-up inflation row's missing country to the sentinel the
/// column stores the worldwide series under as of schema v10.
///
/// Before v10 the worldwide series was a null country. The generated
/// `InflationRate.fromJson` now deserialises that field as a non-null String
/// and throws on null, and the restore runs as one transaction - so a single
/// pre-v10 worldwide row would abort the entire restore, not just its table.
Map<String, dynamic> withGlobalInflationCountry(Map<String, dynamic> row) {
  final country = row['country'];
  if (country is String && country.isNotEmpty) return row;
  return {...row, 'country': globalInflationCountry};
}

/// Every table a backup document can carry, in the order the restore has to
/// insert them (a table's foreign keys point only at tables before it).
const _backupTableKeys = <String>[
  'languages',
  'styles',
  'account_types',
  'currencies',
  'currency_designations',
  'accounts',
  'categories',
  'exchange_rates',
  'inflation_rates',
  'asset_entries',
  'transactions',
  'settings',
  'custom_themes',
  'custom_data_sources',
  'api_settings',
  'sms_presets',
];

/// The backup tables whose rows are keyed by a single `id` column.
const _idKeyedBackupTables = <String>[
  'styles',
  'account_types',
  'currency_designations',
  'accounts',
  'categories',
  'asset_entries',
  'transactions',
  'custom_themes',
  'custom_data_sources',
  'sms_presets',
];

/// Values for columns that did not exist yet when an older backup was written.
///
/// The generated `fromJson` factories read every non-nullable column through
/// `serializer.fromJson<T>`, where an absent key arrives as `null as T` and
/// throws — and the restore is a single transaction, so one column added after
/// the backup was written aborts every other table with it.
/// `accounts.openingBalance` (schema v11) is the live case: without this, no
/// backup taken before v11 could be restored at all, and the failure named a
/// type cast rather than the missing column.
///
/// Each value is that column's own SQL default, and only an absent (or null)
/// key is filled, so a row that carries the column is never touched.
const _backupColumnDefaults = <String, Map<String, Object>>{
  'transactions': {'fee': 0.0, 'isDeleted': false},
  'accounts': {'openingBalance': 0.0, 'assetQuantity': 0.0, 'isDeleted': false},
  'categories': {'type': 0, 'isDeleted': false},
  'styles': {'iconType': 0, 'isDeleted': false},
  'account_types': {'isDeleted': false},
  'currencies': {'type': 6},
  'currency_designations': {'isDeleted': false},
  'asset_entries': {'quantity': 1.0, 'preset': 1, 'isDeleted': false},
  'custom_themes': {
    'backgroundImageOpacity': 1.0,
    'backgroundImageBlur': 0.0,
    'effectOpacity': 1.0,
    'surfaceOpacity': 1.0,
    'isPreset': false,
    'isActive': false,
    'isDeleted': false,
  },
  'custom_data_sources': {
    'enabled': true,
    'autoFetch': false,
    'isDeleted': false,
  },
  'api_settings': {'enabled': true, 'autoFetch': false},
  'sms_presets': {'isBuiltIn': false, 'isEnabled': true, 'isDeleted': false},
};

/// Fills in [_backupColumnDefaults] on every row of [data], in place.
@visibleForTesting
void applyBackupColumnDefaults(Map<String, dynamic> data) {
  _backupColumnDefaults.forEach((tableKey, defaults) {
    final rows = data[tableKey];
    if (rows is! List) return;
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      defaults.forEach((column, value) => row[column] ??= value);
    }
  });
}

/// Rejects a backup that cannot be restored intact — while the user's existing
/// database is still untouched.
///
/// The restore turns foreign keys off for its duration (it wipes and refills
/// the tables, so they are inconsistent in the middle) and inserts with
/// `insertOrIgnore`. Neither of those says anything when a row is wrong: a
/// transaction naming an account the file does not contain was written anyway,
/// leaving a row no screen can resolve and every balance quietly skips, and a
/// second row reusing an id was dropped on the floor. A restore is
/// all-or-nothing, so both are refused here by name instead.
@visibleForTesting
void validateBackup(Map<String, dynamic> data) {
  final problems = <String>[];

  for (final key in _backupTableKeys) {
    final value = data[key];
    if (value == null) continue;
    if (value is! List) {
      problems.add("'$key' is a ${value.runtimeType}, not a list of rows");
    } else if (value.any((row) => row is! Map<String, dynamic>)) {
      problems.add("'$key' contains an entry that is not a row");
    }
  }
  // The checks below read fields, so they only run on a well-shaped document.
  if (problems.isEmpty) {
    for (final key in _idKeyedBackupTables) {
      final seen = <String>{};
      final duplicates = <String>{};
      for (final row in _backupRows(data, key)) {
        final id = row['id'];
        if (id is String && !seen.add(id)) duplicates.add(id);
      }
      if (duplicates.isNotEmpty) {
        problems.add(
          "'$key' reuses ${duplicates.length} id(s): ${_sample(duplicates)}",
        );
      }
    }

    _checkReferences(problems, data, 'accountId', 'accounts');
    _checkReferences(problems, data, 'categoryId', 'categories');
  }

  if (problems.isNotEmpty) {
    throw Exception('This backup cannot be restored: ${problems.join('; ')}.');
  }
}

/// Flags transactions whose [field] names a row the backup does not contain.
///
/// Only checked when the backup carries [targetTable] at all: a document
/// without that key leaves the existing table in place, so its rows are still
/// there to resolve against.
void _checkReferences(
  List<String> problems,
  Map<String, dynamic> data,
  String field,
  String targetTable,
) {
  if (data[targetTable] == null) return;
  final known = {
    for (final row in _backupRows(data, targetTable))
      if (row['id'] is String) row['id'] as String,
  };
  final missing = <String>{};
  for (final row in _backupRows(data, 'transactions')) {
    final ref = row[field];
    if (ref is String && !known.contains(ref)) missing.add(ref);
  }
  if (missing.isNotEmpty) {
    problems.add(
      "'transactions' reference ${missing.length} $targetTable row(s) that the "
      'backup does not contain: ${_sample(missing)}',
    );
  }
}

List<Map<String, dynamic>> _backupRows(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().toList();
}

String _sample(Iterable<String> ids) {
  final shown = ids.take(3).join(', ');
  return ids.length > 3 ? '$shown, …' : shown;
}

class DataImportService {
  final AppDatabase _db;
  final AndroidFilePickerService _androidFilePicker;

  DataImportService(this._db, this._androidFilePicker);

  Future<bool> importData(bool isCsv, {String? title}) async {
    final expectedExt = isCsv ? 'csv' : 'json';
    List<String>? pickedPaths;
    FilePickerResult? result;

    if (AppPlatform.isAndroid) {
      pickedPaths = await _androidFilePicker.pickFile(
        mimeType: '*/*',
        title: title ?? (isCsv ? 'Select CSV' : 'Select JSON'),
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [expectedExt],
        // The browser never hands back a usable filesystem path, so the picked
        // file is only reachable through its in-memory bytes — and file_picker
        // skips loading them unless asked. On the other platforms a real path
        // exists, so we leave this off and read from disk instead of holding a
        // whole backup in memory twice.
        withData: kIsWeb,
      );
    }

    if ((pickedPaths != null && pickedPaths.isNotEmpty) ||
        (result != null && result.files.isNotEmpty)) {
      final String content;
      final String extension;

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        extension = platformFile.name.split('.').last.toLowerCase();
        content = await _readPickedFile(platformFile);
      } else {
        final pickedPath = pickedPaths!.first;
        extension = pickedPath.split('.').last.toLowerCase();
        content = await IoHelper.readAsString(pickedPath);
      }

      if (extension != expectedExt) {
        throw Exception(
          'Invalid file type. Please select a .$expectedExt file.',
        );
      }

      await importContent(content, isCsv: isCsv);
      return true;
    }
    return false;
  }

  /// Imports an already-read file body.
  ///
  /// This is everything [importData] does once the native picker has handed
  /// back a file, split out so the formats can be driven without one.
  @visibleForTesting
  Future<void> importContent(String content, {required bool isCsv}) async {
    if (content.trim().isEmpty) {
      throw Exception('The selected file is empty.');
    }

    if (isCsv) {
      await _importCsv(content);
    } else {
      await _importJson(content);
    }
  }

  Future<void> importExchangeRates({String? title}) async {
    FilePickerResult? result;
    List<String>? pickedPaths;

    if (AppPlatform.isAndroid) {
      pickedPaths = await _androidFilePicker.pickFile(
        mimeType: '*/*',
        title: title ?? 'Select CSV or JSON',
      );
    } else {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'json'],
        // See importData: bytes are the only readable source on web.
        withData: kIsWeb,
      );
    }

    if ((pickedPaths != null && pickedPaths.isNotEmpty) ||
        (result != null && result.files.isNotEmpty)) {
      final String content;
      final String extension;

      if (result != null && result.files.isNotEmpty) {
        final platformFile = result.files.first;
        extension = platformFile.name.split('.').last.toLowerCase();
        content = await _readPickedFile(platformFile);
      } else {
        final pickedPath = pickedPaths!.first;
        extension = pickedPath.split('.').last.toLowerCase();
        content = await IoHelper.readAsString(pickedPath);
      }

      if (extension != 'csv' && extension != 'json') {
        throw Exception(
          'Invalid file type. Please select a .csv or .json file.',
        );
      }

      await importExchangeRatesContent(content, isCsv: extension == 'csv');
    }
  }

  /// Imports an already-read exchange-rate file body.
  ///
  /// This is everything [importExchangeRates] does once the native picker has
  /// handed back a file, split out so the formats can be driven without one.
  @visibleForTesting
  Future<void> importExchangeRatesContent(
    String content, {
    required bool isCsv,
  }) async {
    if (content.trim().isEmpty) {
      throw Exception('The selected file is empty.');
    }

    if (isCsv) {
      await _importExchangeRatesCsv(content);
    } else {
      await _importExchangeRatesJson(content);
    }
  }

  /// Decodes a file returned by [FilePicker] as UTF-8 text.
  ///
  /// `bytes` is only populated when the picker was asked for it (web), while
  /// `path` is only meaningful where a filesystem exists. Web fills `path`
  /// with a `data:`/`blob:` URL that the dart:io layer cannot open, so it must
  /// never be handed to [IoHelper] — dereferencing it used to be how the whole
  /// web import died.
  Future<String> _readPickedFile(PlatformFile platformFile) async {
    final bytes = platformFile.bytes;
    if (bytes != null) {
      return utf8.decode(bytes);
    }

    final path = platformFile.path;
    if (kIsWeb || path == null) {
      throw Exception('Could not read the selected file.');
    }
    return IoHelper.readAsString(path);
  }

  /// Reads either shape of exchange-rate JSON, or refuses it by entry.
  ///
  /// The sibling of [_importExchangeRatesCsv], and it used to coerce just as
  /// hard. A list entry went straight into `ExchangeRate.fromJson`, so a
  /// hand-written file missing `modifiedAt` died on a raw
  /// `type 'Null' is not a subtype of type 'int'`, and an unknown currency code
  /// reached SQLite as a bare "FOREIGN KEY constraint failed" naming neither
  /// the entry nor the code. The date-indexed shape was worse: `rateValue is
  /// num` *skipped* everything it could not read, so a file in some other
  /// tool's format imported zero rows and reported success, and a rate of 0,
  /// -1, NaN or Infinity was written as-is for every conversion downstream to
  /// multiply by.
  ///
  /// Two shapes are accepted:
  ///  * a list of rate objects, which is what this app's own export writes;
  ///  * a `{date: {currencyCode: rate}}` map keyed by date, which is the shape
  ///    of the ECB-style `currency_history.json` (quoted against EUR).
  ///
  /// Anything else is refused rather than quietly doing nothing, and the whole
  /// file is validated before a single row is written, so a refused file leaves
  /// the existing rates exactly as they were.
  Future<void> _importExchangeRatesJson(String content) async {
    final dynamic data;
    try {
      data = jsonDecode(content);
    } on FormatException catch (e) {
      throw Exception(
        'Invalid JSON: the file could not be parsed (${e.message}).',
      );
    }

    // Both code columns are foreign keys into `currencies`; see
    // _importExchangeRatesCsv for why an unknown code has to be caught here.
    final knownCodes = {
      for (final currency in await _db.select(_db.currencies).get())
        currency.code.toUpperCase(),
    };

    final List<ExchangeRatesCompanion> rates = [];
    // Every (pair, date, preset) already read, so a file that contradicts
    // itself is caught here rather than resolved by insert order.
    final seen = <String, ({String where, double rate})>{};

    void collect({
      required String from,
      required String to,
      required double rate,
      required DateTime date,
      required int preset,
      required String where,
    }) {
      final key = '$from>$to@${date.toIso8601String()}#$preset';
      final earlier = seen[key];
      if (earlier != null && earlier.rate != rate) {
        throw Exception(
          'Invalid JSON: $where gives $from→$to on '
          '${date.toIso8601String()} a rate of $rate, but ${earlier.where} '
          'already gave it ${earlier.rate}.',
        );
      }
      seen[key] = (where: where, rate: rate);
      rates.add(
        ExchangeRatesCompanion.insert(
          fromCurrencyCode: from,
          toCurrencyCode: to,
          rate: rate,
          date: date,
          preset: preset,
        ),
      );
    }

    if (data is List) {
      for (var i = 0; i < data.length; i++) {
        final entry = data[i];
        final where = 'entry ${i + 1}';
        if (entry is! Map) {
          throw Exception(
            'Invalid JSON: $where is a ${entry.runtimeType}, not a rate object.',
          );
        }
        collect(
          from: _rateCurrencyCode(
            entry['fromCurrencyCode'],
            'JSON',
            where,
            'fromCurrencyCode',
            knownCodes,
          ),
          to: _rateCurrencyCode(
            entry['toCurrencyCode'],
            'JSON',
            where,
            'toCurrencyCode',
            knownCodes,
          ),
          rate: _jsonRate(entry['rate'], where),
          date: _jsonDate(entry['date'], where),
          // Absent means the rates the app fetches itself, which is what a
          // hand-written file is describing. Only the app's own export carries
          // a preset id, and round-tripping one has to keep it.
          preset: _jsonPreset(entry['preset'], where),
          where: where,
        );
      }
    } else if (data is Map) {
      data.forEach((dateKey, dateValue) {
        final dateWhere = 'the entry for "$dateKey"';
        final date = _jsonDate(dateKey, dateWhere);
        if (dateValue is! Map) {
          throw Exception(
            'Invalid JSON: $dateWhere is a ${dateValue.runtimeType}, not a set '
            'of currency rates.',
          );
        }
        dateValue.forEach((currencyKey, rateValue) {
          final where = 'the entry for "$dateKey" ("$currencyKey")';
          collect(
            // This shape carries no base currency of its own: it is the ECB
            // feed, and every column in it is quoted against EUR.
            from: _rateCurrencyCode('EUR', 'JSON', where, 'base', knownCodes),
            to: _rateCurrencyCode(
              currencyKey,
              'JSON',
              where,
              'currency',
              knownCodes,
            ),
            rate: _jsonRate(rateValue, where),
            date: date,
            preset: 0,
            where: where,
          );
        });
      });
    } else {
      throw Exception(
        'Invalid JSON: the file is a ${data.runtimeType}, but exchange rates '
        'have to be a list of rate objects or a map of dates to rates.',
      );
    }

    // An empty list, or an empty map, changed nothing while reporting success,
    // which reads as "your rates are up to date".
    if (rates.isEmpty) {
      throw Exception('Invalid JSON: the file has no rates in it.');
    }

    await _db.batch((batch) {
      batch.insertAll(
        _db.exchangeRates,
        rates,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// The rate in [value], or a refusal naming [where].
  ///
  /// Numeric strings are accepted because plenty of exporters quote their
  /// numbers, but `null`, an object and the word "about one" are refusals
  /// rather than a skipped row. Non-finite, zero and negative rates are refused
  /// for the same reason the CSV path refuses them: nothing downstream
  /// re-checks a rate, so they turn every converted amount into NaN, infinity
  /// or zero.
  double _jsonRate(dynamic value, String where) {
    final rate = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().trim());
    if (rate == null) {
      throw Exception('Invalid JSON: $where has no valid rate ("$value").');
    }
    if (!rate.isFinite || rate <= 0) {
      throw Exception(
        'Invalid JSON: $where has a rate that is not a positive '
        'number ("$value").',
      );
    }
    return rate;
  }

  /// The date in [value], or a refusal naming [where].
  ///
  /// Drift's own `toJson` writes a DateTime as epoch milliseconds, so this
  /// app's export is a number, while every hand-written and third-party file is
  /// an ISO-8601 string. Both are read; `DateTime.parse` used to be called
  /// straight on the map key and threw a bare FormatException naming nothing.
  DateTime _jsonDate(dynamic value, String where) {
    if (value is num && value is! String) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    final text = value.toString().trim();
    final parsed = DateTime.tryParse(text);
    if (parsed == null) {
      throw Exception('Invalid JSON: $where has no valid date ("$text").');
    }
    return parsed;
  }

  /// The preset id in [value], or a refusal naming [where].
  ///
  /// Part of the primary key, so a bad one does not fail - it silently files
  /// the rate under a preset nobody reads.
  int _jsonPreset(dynamic value, String where) {
    if (value == null) return 0;
    final preset = value is int ? value : int.tryParse(value.toString().trim());
    if (preset == null || preset < 0) {
      throw Exception(
        'Invalid JSON: $where has a preset that is not a whole '
        'number ("$value").',
      );
    }
    return preset;
  }

  /// Reads a `Date,From,To,Rate` file, or refuses it by line number.
  ///
  /// Every column here is money: the rate is what every conversion multiplies
  /// by, and the pair and the date are what selects it. The reader coerced all
  /// of them instead — a short row was `continue`d, an unparseable date became
  /// `DateTime.now()` and an unparseable rate became `1.0` — so a mangled file,
  /// or a file in some other tool's format, imported as a set of today-dated
  /// rates of 1 that converted every foreign amount at par, and the user was
  /// told the import had succeeded. It now refuses, naming the line and the
  /// text it could not read, the same treatment the transaction CSV import got.
  ///
  /// The whole file is read before anything is written, so a refused file
  /// leaves the existing rates exactly as they were.
  Future<void> _importExchangeRatesCsv(String content) async {
    final rows = _csvConverter.convert(content);
    if (rows.isEmpty) {
      throw Exception('The selected file is empty.');
    }

    final header = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    // Excel and most exporters write a UTF-8 BOM, which the decoder leaves at
    // the head of the very first cell: a perfectly good file whose first
    // header cell reads U+FEFF followed by 'date' was refused as "missing
    // Date", with nothing in the file to see.
    if (header.isNotEmpty) {
      header[0] = header.first.replaceFirst('\u{FEFF}', '');
    }
    rows.removeAt(0);

    final dateIdx = header.indexOf('date');
    final fromIdx = header.indexOf('from');
    final toIdx = header.indexOf('to');
    final rateIdx = header.indexOf('rate');

    if (dateIdx == -1 || fromIdx == -1 || toIdx == -1 || rateIdx == -1) {
      throw Exception('Invalid CSV format. Missing Date, From, To, or Rate.');
    }

    // The two code columns are foreign keys into `currencies`, so an unknown
    // code cannot be imported at all — it used to reach SQLite as-is and fail
    // the whole batch with "FOREIGN KEY constraint failed", which names neither
    // the line nor the code.
    final knownCodes = {
      for (final currency in await _db.select(_db.currencies).get())
        currency.code.toUpperCase(),
    };

    final List<ExchangeRatesCompanion> rates = [];
    // Every (pair, date) already read, so a file that contradicts itself is
    // caught here rather than resolved by insert order.
    final seen = <String, ({int line, double rate})>{};

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      // The header is line 1, so the first data row is line 2.
      final line = i + 2;

      if (row.every((c) => c == null || c.toString().trim().isEmpty)) {
        continue; // Blank separator line, not data.
      }

      if (row.length < header.length) {
        throw Exception(
          'Invalid CSV: line $line has ${row.length} columns, '
          'but the header declares ${header.length}.',
        );
      }

      final dateStr = row[dateIdx].toString().trim();
      final date = DateTime.tryParse(dateStr);
      if (date == null) {
        throw Exception(
          'Invalid CSV: line $line has no valid date ("$dateStr").',
        );
      }

      final rateStr = row[rateIdx].toString().trim();
      final rate = double.tryParse(rateStr);
      if (rate == null) {
        throw Exception(
          'Invalid CSV: line $line has no valid rate ("$rateStr").',
        );
      }
      // `double.tryParse` also accepts 'NaN' and 'Infinity', and 0 and negative
      // numbers parse fine. None of them is an exchange rate: they turn every
      // converted amount into NaN, infinity or zero rather than into a merely
      // wrong number, and nothing downstream re-checks them.
      if (!rate.isFinite || rate <= 0) {
        throw Exception(
          'Invalid CSV: line $line has a rate that is not a positive '
          'number ("$rateStr").',
        );
      }

      final from = _rateCurrencyCode(
        row[fromIdx],
        'CSV',
        'line $line',
        'From',
        knownCodes,
      );
      final to = _rateCurrencyCode(
        row[toIdx],
        'CSV',
        'line $line',
        'To',
        knownCodes,
      );

      // Rates are keyed by (from, to, date, preset) and inserted with
      // insertOrReplace, so two lines claiming different rates for the same
      // pair on the same date silently left whichever came last.
      final key = '$from>$to@${date.toIso8601String()}';
      final earlier = seen[key];
      if (earlier != null && earlier.rate != rate) {
        throw Exception(
          'Invalid CSV: line $line gives $from→$to on $dateStr a rate of '
          '$rateStr, but line ${earlier.line} already gave it '
          '${earlier.rate}.',
        );
      }
      seen[key] = (line: line, rate: rate);

      rates.add(
        ExchangeRatesCompanion.insert(
          fromCurrencyCode: from,
          toCurrencyCode: to,
          rate: rate,
          date: date,
          preset: 0,
        ),
      );
    }

    // A file that carries a header and nothing else imported as success while
    // changing nothing, which reads as "your rates are up to date".
    if (rates.isEmpty) {
      throw Exception('Invalid CSV: the file has a header but no rates.');
    }

    await _db.batch((batch) {
      batch.insertAll(
        _db.exchangeRates,
        rates,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// The currency code in [cell], or a refusal naming [where] and [column].
  ///
  /// [format] and [where] are how the refusal points at the offending spot in
  /// whatever file this is — `'CSV'` and `'line 4'`, or `'JSON'` and
  /// `'entry 4'` — because the JSON reader has the same foreign key to protect
  /// and no line numbers to name.
  ///
  /// Trimmed and upper-cased, because ' eur ' is the user's spacing rather than
  /// a different currency — untrimmed it reached the foreign key as ' EUR ' and
  /// failed there, looking correct in the file the whole time.
  String _rateCurrencyCode(
    dynamic cell,
    String format,
    String where,
    String column,
    Set<String> knownCodes,
  ) {
    final code = cell.toString().trim().toUpperCase();
    if (code.isEmpty) {
      throw Exception('Invalid $format: $where has an empty $column currency.');
    }
    if (!knownCodes.contains(code)) {
      throw Exception(
        'Invalid $format: $where names a currency this app does not '
        'know ("$code" in $column).',
      );
    }
    return code;
  }

  Future<void> _importJson(String content) async {
    debugPrint('[RESTORE] _importJson: parsing JSON...');
    // RESTORE STRATEGY: Wipe and Replace
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      throw Exception(
        'This is not a My Budget backup: the file is a '
        '${decoded.runtimeType}, not a JSON object.',
      );
    }
    final data = decoded;
    final now = DateTime.now().millisecondsSinceEpoch;
    debugPrint(
      '[RESTORE] backup version: ${data['version']}, timestamp: ${data['timestamp']}',
    );

    // Deduplicate asset_entries BEFORE modifiedAt update so original timestamps are used for dedup
    // Partial UNIQUE INDEX: (asset_id, date, source) WHERE source = 'custom_api'
    // Old backups may contain duplicates created before the index existed.
    if (data['asset_entries'] != null) {
      final rawEntries = data['asset_entries'] as List;
      final deduped = _deduplicateAssetEntries(rawEntries);
      debugPrint(
        '[RESTORE] asset_entries: ${rawEntries.length} raw → ${deduped.length} after dedup',
      );
      data['asset_entries'] = deduped;
    }

    // Mark all imported records as new by updating their modified_at
    data.forEach((key, value) {
      if (value is List) {
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            item['modifiedAt'] = now;
          }
        }
      }
    });

    // Fill in columns that did not exist yet when the backup was written, and
    // reject a file that cannot be restored - both BEFORE the wipe, so a bad
    // backup costs the user nothing.
    applyBackupColumnDefaults(data);
    validateBackup(data);

    // PRAGMA foreign_keys must be set outside transaction in SQLite
    await _db.customStatement('PRAGMA foreign_keys = OFF');

    try {
      await _db.transaction(() async {
        // 1. Delete the existing data this backup is going to replace.
        //
        // A table the backup does not carry at all is left alone. Wiping it
        // regardless is what made an older backup destructive beyond its own
        // contents: a v1 file has no `languages` key, so the restore emptied
        // that table and then re-inserted every currency pointing at a
        // language row that no longer existed.
        debugPrint('[RESTORE] Deleting existing data...');
        // Business Tables
        await _deleteIfPresent(data, 'transactions', _db.transactions);
        await _deleteIfPresent(data, 'accounts', _db.accounts);
        await _deleteIfPresent(data, 'categories', _db.categories);
        await _deleteIfPresent(data, 'exchange_rates', _db.exchangeRates);
        await _deleteIfPresent(data, 'inflation_rates', _db.inflationRates);
        await _deleteIfPresent(data, 'asset_entries', _db.assetEntries);
        await _deleteIfPresent(
          data,
          'currency_designations',
          _db.currencyDesignations,
        );
        await _deleteIfPresent(data, 'currencies', _db.currencies);
        await _deleteIfPresent(data, 'account_types', _db.accountTypes);
        await _deleteIfPresent(data, 'styles', _db.styles);
        await _deleteIfPresent(data, 'languages', _db.languages);

        // Technical/Other Tables
        await _deleteIfPresent(data, 'settings', _db.settings);
        await _deleteIfPresent(data, 'custom_themes', _db.customThemes);
        await _deleteIfPresent(
          data,
          'custom_data_sources',
          _db.customDataSources,
        );
        await _deleteIfPresent(data, 'api_settings', _db.apiSettingsTable);
        await _deleteIfPresent(data, 'sms_presets', _db.smsPresets);

        // Local bookkeeping, never carried in a backup: always reset.
        await _db.delete(_db.syncLog).go();
        await _db.delete(_db.conflictHistory).go();
        await _db.delete(_db.apiFetchStatuses).go();
        await _db.delete(_db.syncProcessedFiles).go();
        debugPrint('[RESTORE] Existing data deleted.');

        // 2. Insert new data
        // Order matters due to foreign key constraints
        if (data['languages'] != null) {
          final list = data['languages'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} languages...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.languages,
              list
                  .map((e) => Language.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['styles'] != null) {
          final list = data['styles'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} styles...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.styles,
              list
                  .map((e) => Style.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['account_types'] != null) {
          final list = data['account_types'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} account_types...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.accountTypes,
              list
                  .map((e) => AccountType.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['currencies'] != null) {
          final list = data['currencies'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} currencies...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.currencies,
              list
                  .map((e) => Currency.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['currency_designations'] != null) {
          final list = data['currency_designations'] as List;
          debugPrint(
            '[RESTORE] Inserting ${list.length} currency_designations...',
          );
          await _db.batch((batch) {
            batch.insertAll(
              _db.currencyDesignations,
              list
                  .map(
                    (e) =>
                        CurrencyDesignation.fromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['accounts'] != null) {
          final list = data['accounts'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} accounts...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.accounts,
              list
                  .map((e) => DbAccount.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['categories'] != null) {
          final list = data['categories'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} categories...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.categories,
              list
                  .map((e) => Category.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['exchange_rates'] != null) {
          final list = data['exchange_rates'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} exchange_rates...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.exchangeRates,
              list
                  .map((e) => ExchangeRate.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['inflation_rates'] != null) {
          final list = data['inflation_rates'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} inflation_rates...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.inflationRates,
              list
                  .map(
                    (e) => InflationRate.fromJson(
                      withGlobalInflationCountry(e as Map<String, dynamic>),
                    ),
                  )
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['asset_entries'] != null) {
          final list = data['asset_entries'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} asset_entries...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.assetEntries,
              list
                  .map((e) => AssetEntry.fromJson(e as Map<String, dynamic>))
                  .toList(),
              // insertOrIgnore: skip duplicates that violate partial UNIQUE INDEX
              mode: InsertMode.insertOrIgnore,
            );
          });
          debugPrint('[RESTORE] asset_entries inserted.');
        }

        if (data['transactions'] != null) {
          final list = data['transactions'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} transactions...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.transactions,
              list
                  .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
          debugPrint('[RESTORE] transactions inserted.');
        }

        // Technical Tables
        if (data['settings'] != null) {
          final list = data['settings'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} settings...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.settings,
              list
                  .map((e) => Setting.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['custom_themes'] != null) {
          final list = data['custom_themes'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} custom_themes...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.customThemes,
              list
                  .map((e) => DbCustomTheme.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['custom_data_sources'] != null) {
          final list = data['custom_data_sources'] as List;
          debugPrint(
            '[RESTORE] Inserting ${list.length} custom_data_sources...',
          );
          await _db.batch((batch) {
            batch.insertAll(
              _db.customDataSources,
              list
                  .map(
                    (e) => CustomDataSource.fromJson(e as Map<String, dynamic>),
                  )
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['api_settings'] != null) {
          final list = data['api_settings'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} api_settings...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.apiSettingsTable,
              list
                  .map(
                    (e) => ApiSettingsTableData.fromJson(
                      e as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        if (data['sms_presets'] != null) {
          final list = data['sms_presets'] as List;
          debugPrint('[RESTORE] Inserting ${list.length} sms_presets...');
          await _db.batch((batch) {
            batch.insertAll(
              _db.smsPresets,
              list
                  .map((e) => SmsPreset.fromJson(e as Map<String, dynamic>))
                  .toList(),
              mode: InsertMode.insertOrIgnore,
            );
          });
        }

        debugPrint('[RESTORE] All tables inserted successfully.');
      });

      // Reset sync state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(serverPullCursorKey, 0);
      await prefs.setInt('server_last_push_timestamp', 0);
      debugPrint('[RESTORE] Sync state reset. Restore complete.');
    } catch (e, stack) {
      debugPrint('[RESTORE] ERROR: $e');
      debugPrint('[RESTORE] Stack: $stack');
      rethrow;
    } finally {
      // Re-enable foreign key checks
      await _db.customStatement('PRAGMA foreign_keys = ON');
    }
  }

  /// Empties [table] only when the backup actually carries [key].
  ///
  /// A key the document does not have at all is not "an empty table", it is a
  /// table this backup says nothing about.
  Future<void> _deleteIfPresent(
    Map<String, dynamic> data,
    String key,
    TableInfo<Table, dynamic> table,
  ) async {
    if (data[key] == null) return;
    await _db.delete(table).go();
  }

  /// Deduplicate asset_entries from backup.
  /// Partial UNIQUE INDEX: (asset_id, date, source) WHERE source = 'custom_api'
  /// Old backups may contain duplicates created before the index existed.
  /// Keep the entry with the highest modifiedAt for each (assetId, date, source) group.
  List<Map<String, dynamic>> _deduplicateAssetEntries(List<dynamic> raw) {
    final seen = <String, Map<String, dynamic>>{};

    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final source = item['source'] as String? ?? '';
      if (source == 'custom_api') {
        final assetId = item['assetId'] as String? ?? '';
        final date = item['date']?.toString() ?? '';
        final key = '$assetId|$date|$source';
        final existing = seen[key];
        if (existing == null) {
          seen[key] = item;
        } else {
          // Keep the one with higher modifiedAt
          final existingModified =
              (existing['modifiedAt'] as num?)?.toInt() ?? 0;
          final itemModified = (item['modifiedAt'] as num?)?.toInt() ?? 0;
          if (itemModified > existingModified) {
            seen[key] = item;
          }
        }
      } else {
        // Non-custom_api entries: deduplicate by id only
        final id = item['id'] as String? ?? '';
        if (id.isNotEmpty && !seen.containsKey('id:$id')) {
          seen['id:$id'] = item;
        } else if (id.isEmpty) {
          // No id — keep as-is (shouldn't happen)
          seen['noid:${seen.length}'] = item;
        }
      }
    }

    return seen.values.toList();
  }

  Future<void> _importCsv(String content) async {
    // APPEND STRATEGY
    // Expected Columns: Date, Amount, Currency, Description, Category, Account, Type
    List<List<dynamic>> rows = _csvConverter.convert(content);
    if (rows.isEmpty) return;

    // Determine indices from header
    final header = rows.first
        .map((e) => e.toString().trim().toLowerCase())
        .toList();
    rows.removeAt(0); // Remove header

    final dateIdx = header.indexOf('date');
    final amountIdx = header.indexOf('amount');
    final currencyIdx = header.indexOf('currency');
    final descIdx = header.indexOf('description');
    final catIdx = header.indexOf('category');
    final accIdx = header.indexOf('account');

    if (dateIdx == -1 || amountIdx == -1 || catIdx == -1 || accIdx == -1) {
      throw Exception('Invalid CSV format. Missing required columns.');
    }

    // Pre-fetch reference data
    final allCategories = await _db.categoriesDao.getAllCategories();
    final allAccounts = await _db.accountsDao.getAllAccounts();

    // Maps for fast lookup by name
    final categoryMap = {
      for (var c in allCategories) c.name.toLowerCase(): c.id,
    };
    final accountMap = {for (var a in allAccounts) a.name.toLowerCase(): a.id};

    // Default values for new creations
    final defaultStyle = (await _db.stylesDao.getAllStyles()).firstOrNull;
    final defaultAccType =
        (await _db.accountTypesDao.getAllAccountTypes()).firstOrNull;
    final defaultDesignation =
        (await _db.currencyDesignationsDao.getAllDesignations()).firstOrNull;

    // Fallback ID if DB is somehow empty, but constraints will fail anyway if missing.
    // We assume seed data exists.
    final defaultAccTypeId = defaultAccType?.id ?? 'general';
    final defaultCurrencyDesId = defaultDesignation?.id ?? 'symbol';

    // We need to generate IDs manually since insert() doesn't return them for batch/void operations
    // and we need them for foreign keys immediately in the loop
    final uuid = const Uuid();

    await _db.transaction(() async {
      for (var i = 0; i < rows.length; i++) {
        final row = rows[i];
        // Header is line 1, so the first data row is line 2.
        final line = i + 2;

        if (row.every((c) => c == null || c.toString().trim().isEmpty)) {
          continue; // Blank separator line, not data.
        }

        // A row that does not line up with the header is not importable, and
        // guessing is worse than refusing: `continue` dropped it without a
        // word, so a file whose middle rows were malformed imported as a
        // shorter history that looked complete.
        if (row.length < header.length) {
          throw Exception(
            'Invalid CSV: line $line has ${row.length} columns, '
            'but the header declares ${header.length}.',
          );
        }

        // Same for the two fields that carry the meaning of the row. An
        // unparseable date used to become "now" and an unparseable amount
        // became 0.00 - both silently, so a mangled file imported as a pile of
        // today-dated, zero-value transactions that the user had to spot alone.
        final dateStr = row[dateIdx].toString().trim();
        final date = DateTime.tryParse(dateStr);
        if (date == null) {
          throw Exception(
            'Invalid CSV: line $line has no valid date '
            '("$dateStr").',
          );
        }

        final amountStr = row[amountIdx].toString().trim();
        final amount = double.tryParse(amountStr);
        if (amount == null) {
          throw Exception(
            'Invalid CSV: line $line has no valid amount '
            '("$amountStr").',
          );
        }

        final currencyCode = currencyIdx != -1
            ? row[currencyIdx].toString().trim().toUpperCase()
            : 'EUR';
        final description = descIdx != -1 ? row[descIdx].toString() : '';

        final categoryName = row[catIdx].toString();
        final accountName = row[accIdx].toString();

        // 1. Resolve Category
        String categoryId;
        if (categoryMap.containsKey(categoryName.toLowerCase())) {
          categoryId = categoryMap[categoryName.toLowerCase()]!;
        } else {
          categoryId = uuid.v4();
          await _db.categoriesDao.insertCategory(
            CategoriesCompanion(
              id: Value(categoryId),
              name: Value(categoryName),
              type: const Value(CategoryType.expense),
              styleId: Value(defaultStyle?.id),
            ),
          );
          categoryMap[categoryName.toLowerCase()] = categoryId;
        }

        // 2. Resolve Account
        String accountId;
        if (accountMap.containsKey(accountName.toLowerCase())) {
          accountId = accountMap[accountName.toLowerCase()]!;
        } else {
          accountId = uuid.v4();
          await _db.accountsDao.insertAccount(
            AccountsCompanion(
              id: Value(accountId),
              name: Value(accountName),
              currencyCode: Value(currencyCode),
              accountTypeId: Value(defaultAccTypeId),
              currencyDesignationId: Value(defaultCurrencyDesId),
              styleId: Value(defaultStyle?.id),
              balance: const Value(
                0.0,
              ), // Initial balance, can be updated later? Or assume transaction affects it.
              // Fiat money lives in the integer minor-unit columns; leaving
              // them NULL on a fiat row is not "no value yet", it is a row the
              // exact-sum SQL skips (SUM ignores NULL), so the account's
              // balance silently came out short of its own transactions.
              balanceMinor: Value(_minorOrNull(0.0, currencyCode)),
              openingBalanceMinor: Value(_minorOrNull(0.0, currencyCode)),
              description: const Value('Imported'),
              creationDate: Value(DateTime.now()),
            ),
          );
          accountMap[accountName.toLowerCase()] = accountId;
        }

        // 3. Insert Transaction
        await _db.transactionsDao.insertTransaction(
          TransactionsCompanion(
            date: Value(date),
            amount: Value(amount),
            amountMinor: Value(_minorOrNull(amount, currencyCode)),
            currencyCode: Value(currencyCode),
            description: Value(description),
            categoryId: Value(categoryId),
            accountId: Value(accountId),
            feeMinor: Value(_minorOrNull(0.0, currencyCode)),
          ),
        );
      }
    });
  }
}
