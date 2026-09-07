import 'dart:convert';
import 'package:my_budget_client/core/utils/calendar_day.dart';
import 'package:my_budget_client/core/utils/import_file_data.dart';
import 'package:path/path.dart' as p;
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/services/server_rate_service.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as di;
import 'package:my_budget_client/core/utils/currency_history_binary_io.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:flutter/services.dart';

class OneMoneyRecord {
  final DateTime date;
  final String type;
  final String from;
  final String to;
  final double amount;
  final String currency;
  final double? amount2;
  final String? currency2;
  final String notes;

  OneMoneyRecord({
    required this.date,
    required this.type,
    required this.from,
    required this.to,
    required this.amount,
    required this.currency,
    this.amount2,
    this.currency2,
    required this.notes,
  });

  @override
  String toString() {
    return 'OneMoneyRecord{date: $date, type: $type, from: $from, to: $to, amount: $amount, currency: $currency, amount2: $amount2, currency2: $currency2, notes: $notes}';
  }
}

class AccountBalanceRecord {
  final String name;
  final double balance;
  final String currency;

  AccountBalanceRecord({
    required this.name,
    required this.balance,
    required this.currency,
  });

  @override
  String toString() {
    return 'AccountBalanceRecord{name: $name, balance: $balance, currency: $currency}';
  }
}

class ParsedCsvData {
  final List<OneMoneyRecord> records;
  final List<AccountBalanceRecord> accountBalances;

  ParsedCsvData({required this.records, required this.accountBalances});
}

class ImportDataUtils {
  static const List<String> _expectedHeadersRu = [
    "ДАТА",
    "ТИП",
    "СО СЧЁТА",
    "НА СЧЁТ / НА КАТЕГОРИЮ",
    "СУММА",
    "ВАЛЮТА",
    "СУММА 2",
    "ВАЛЮТА 2",
    "МЕТКИ",
    "ЗАМЕТКИ",
  ];

  static const List<String> _expectedHeadersEn = [
    "DATE",
    "TYPE",
    "FROM ACCOUNT",
    "TO ACCOUNT/TO CATEGORY",
    "AMOUNT",
    "CURRENCY",
    "AMOUNT 2",
    "CURRENCY 2",
    "TAGS",
    "NOTES",
  ];

  /// A money column read as a number, with the file's comma decimal mark
  /// rewritten to a dot.
  ///
  /// Throws for anything that is not a finite amount, which the row-level
  /// catch below turns into the same skip a letter in the column already got.
  /// `double.parse` reads 'NaN', 'Infinity' and '-Infinity' as happily as it
  /// reads '12.5', and any of the three imported as an amount makes every
  /// total that ever sums the row NaN - a balance that no edit to any other
  /// transaction can repair.
  @visibleForTesting
  static double parseMoney(Object? raw) {
    final text = raw.toString().replaceAll(',', '.');
    final value = double.parse(text);
    if (!value.isFinite) {
      throw FormatException('Not a finite amount', text);
    }
    return value;
  }

  static Future<ParsedCsvData> parseOneMoneyCsv(ImportFileData file) async {
    try {
      final String fileContent;
      if (file.bytes != null) {
        fileContent = utf8.decode(file.bytes!);
      } else {
        fileContent = await IoHelper.readAsString(file.path!);
      }

      // The parser was pinned to `eol: '\n'`, which does not mean "accept LF" -
      // it means "\r is ordinary text". OneMoney, Excel and every other
      // spreadsheet write CRLF, so the last cell of every row arrived with a
      // `\r` welded to it: the header check below compares the last cell
      // against "ЗАМЕТКИ"/"NOTES" and read "ЗАМЕТКИ\r", so a perfectly valid
      // export was rejected outright as "headers do not match".
      const converter = CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        csvSettingsDetector: FirstOccurrenceSettingsDetector(
          eols: ['\r\n', '\n'],
        ),
      );

      final List<List<dynamic>> csvData = converter.convert(fileContent);

      if (csvData.isEmpty) {
        throw const FormatException("CSV file is empty.");
      }

      // Validate headers
      final List<dynamic> rawHeaders = csvData[0];
      if (rawHeaders.isNotEmpty &&
          rawHeaders[0] is String &&
          rawHeaders[0].startsWith('\uFEFF')) {
        rawHeaders[0] = (rawHeaders[0] as String).substring(1);
      }

      // Trimmed: the comparison below is exact, so one trailing space anywhere
      // in the header line - which a spreadsheet adds without asking - failed
      // the whole file.
      final headers = rawHeaders
          .map((e) => e.toString().trim().toUpperCase())
          .toList();

      List<String> expectedHeaders;
      DateFormat dateFormat;
      bool isRussian = false;

      // 'en' on a parser, not a label: these read the digits in somebody
      // else's export file, which are ASCII whatever language this app is
      // being read in. An unqualified DateFormat follows Intl.defaultLocale,
      // so on a Bengali device it would expect native digits and refuse every
      // date in the file.
      if (listEquals(_expectedHeadersRu, headers)) {
        expectedHeaders = _expectedHeadersRu;
        dateFormat = DateFormat('dd.MM.yyyy', 'en');
        isRussian = true;
      } else if (listEquals(_expectedHeadersEn, headers)) {
        expectedHeaders = _expectedHeadersEn;
        dateFormat = DateFormat('MM/dd/yy', 'en');
      } else {
        throw FormatException(
          "CSV headers do not match the expected format. Expected: $_expectedHeadersRu or $_expectedHeadersEn, but got: ${rawHeaders.map((e) => e.toString()).toList()}",
        );
      }

      final records = <OneMoneyRecord>[];
      final accountBalances = <AccountBalanceRecord>[];
      bool parsingBalances = false;

      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];

        if (row.every(
          (element) => element == null || element.toString().trim().isEmpty,
        )) {
          parsingBalances = true;
          continue;
        }

        if (parsingBalances) {
          if (row.length >= 3) {
            final r0 = row[0].toString().toUpperCase();
            final r1 = row[1].toString().toUpperCase();
            if ((r0 == 'NAME' && r1 == 'BALANCE') ||
                (r0 == 'НАЗВАНИЕ' && r1 == 'БАЛАНС')) {
              // This is the header for balances, just skip it.
              continue;
            }

            try {
              accountBalances.add(
                AccountBalanceRecord(
                  name: row[0].toString().trim(), // Trim whitespace
                  // Through the same reader as the amount column below: a
                  // Russian export quotes "1234,56", and without the comma
                  // rewrite the catch under here dropped every balance row of
                  // an otherwise perfectly readable file.
                  balance: parseMoney(row[1]),
                  currency: row[2].toString().trim(),
                ),
              );
            } catch (e) {
              debugPrint(
                "Skipping balance row $i due to parsing error: $e. Row data: $row",
              );
            }
          }
        } else {
          if (row.length < expectedHeaders.length) {
            debugPrint(
              "Skipping row $i due to incorrect column count. Expected at least: ${expectedHeaders.length}, got: ${row.length}. Row data: $row",
            );
            continue;
          }

          try {
            final double amount = parseMoney(row[4]);
            final notes = row[9].toString();
            final double? amount2 =
                row.length > 6 && row[6].toString().isNotEmpty
                ? parseMoney(row[6])
                : null;
            final String? currency2 = row.length > 7 ? row[7].toString() : null;

            String type = row[1].toString();
            if (isRussian) {
              if (type.toLowerCase() == 'доход') {
                type = 'Income';
              } else if (type.toLowerCase() == 'расход') {
                type = 'Expense';
              } else if (type.toLowerCase() == 'перевод') {
                type = 'Transfer';
              }
            }

            records.add(
              OneMoneyRecord(
                date: dateFormat.parse(row[0]),
                type: type,
                from: row[2].toString(),
                to: row[3].toString(),
                amount: amount,
                currency: row[5].toString(),
                amount2: amount2,
                currency2: currency2,
                notes: notes,
              ),
            );
          } catch (e) {
            debugPrint(
              "Skipping row $i due to parsing error: $e. Row data: $row",
            );
            continue;
          }
        }
      }
      return ParsedCsvData(records: records, accountBalances: accountBalances);
    } catch (e) {
      debugPrint("Error parsing CSV file: $e");
      rethrow;
    }
  }

  static String filePathCurrenciesRate =
      r'C:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.json';

  // Binary file path (Production asset or local debug file)
  static String filePathCurrenciesBinary =
      r'C:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.bin';
  static String filePathCurrenciesBinaryAsset =
      r'lib/data/currency_history.bin';

  static Future<void> getCurrenciesInitial() async {
    try {
      final DateFormat keyFormatter = DateFormat('yyyy-MM-dd', 'en');
      final currenciesRep = di.sl<CurrencyRepository>();

      // 1. Get existing dates from DB (preset=1 means seeded data).
      // Uses the narrow getPresetRateDates() query instead of
      // getLatestExchangeRatesAll(): the latter reads every exchange_rates
      // row (hundreds of thousands on a real database) across the isolate
      // boundary just to answer "which days do we already have?", which was
      // the single largest cold-start stall. This returns only the distinct
      // preset dates.
      debugPrint('[INIT_DEBUG] getCurrenciesInitial: Checking DB history...');
      final presetDates = await currenciesRep.getPresetRateDates();
      final Set<String> existingDbDates = presetDates
          .map((d) => keyFormatter.format(d))
          .toSet();

      final todayStr = keyFormatter.format(DateTime.now());

      // Optimization: If we already have data for today, skip the whole process
      if (existingDbDates.contains(todayStr)) {
        debugPrint(
          "[INIT_DEBUG] Exchange rate data is already up to date. Skipping file load.",
        );
        return;
      }

      // 2. Decide if we NEED to load the large history file
      // We only load it if the database is essentially empty or has a massive gap.
      // Small gaps (e.g. < 30 days) are faster to fetch from API in the background.
      DateTime startDate = DateTime(2024, 4, 1);
      DateTime endDate = DateTime.now();

      bool shouldLoadFile =
          existingDbDates.length <
          30; // Heuristic: load file if less than 30 days in DB

      Map<String, Map<String, double>> fileHistoryMap = {};

      if (shouldLoadFile) {
        debugPrint(
          "[INIT_DEBUG] Loading large currency history file (initial/major sync)...",
        );
        final bool isDesktop = !AppPlatform.isAndroid && !AppPlatform.isIOS;

        if (kDebugMode && isDesktop) {
          if (await IoHelper.exists(filePathCurrenciesRate)) {
            // Bytes, not `readAsString`, and then straight into a worker.
            //
            // This used to be `readAsString` + a bare `jsonDecode` + a nested
            // `forEach` on whichever isolate called it - and the only caller is
            // `IntilizationData.fetchApiDataInBackground()`, which
            // `app_wrapper.dart` fires without awaiting. Not awaiting keeps it
            // off the *critical path*; it does not move it off the *UI
            // isolate*. So a 6.86 MB / 285k-line file was UTF-8 decoded, JSON
            // parsed and re-walked into ~283k maps between two frames, and
            // every frame in that window was dropped. `readAsBytes` hands the
            // decode to the worker too, so all the UI isolate does here is the
            // file read.
            final Uint8List bytes = await IoHelper.readAsBytes(
              filePathCurrenciesRate,
            );
            fileHistoryMap = await compute(parseCurrencyHistoryMap, bytes);
          }
        } else {
          try {
            final ByteData blob = await rootBundle.load(
              filePathCurrenciesBinaryAsset,
            );
            final Uint8List bytes = blob.buffer.asUint8List(
              blob.offsetInBytes,
              blob.lengthInBytes,
            );
            fileHistoryMap =
                await CurrencyHistoryBinaryIO.readFromBytesInIsolate(bytes);
          } catch (e) {
            debugPrint("Error loading binary asset: $e");
          }
        }
      } else {
        debugPrint(
          "[INIT_DEBUG] Skipping history file. Database has ${existingDbDates.length} days. Fetching gap via API...",
        );
      }

      // 3. Fill the gap (File or API)
      final Map<String, Map<String, double>> dataToInsertMap = {};
      bool dataWasUpdated = false;
      DateTime currentDate = startDate;

      // Split the walk in two: what the file already answers is settled here
      // and now, and only the genuinely missing days become network work.
      final List<DateTime> datesToFetch = [];

      while (!currentDate.isAfter(endDate)) {
        String dateKey = keyFormatter.format(currentDate);

        if (!existingDbDates.contains(dateKey)) {
          // Case 1: Use file data if loaded
          final fromFile = fileHistoryMap[dateKey];
          if (fromFile != null) {
            dataToInsertMap[dateKey] = fromFile;
          }
          // Case 2: Fetch via API
          else {
            datesToFetch.add(currentDate);
          }
        }
        currentDate = nextDay(currentDate);
      }

      if (datesToFetch.isNotEmpty) {
        debugPrint(
          "[INIT_DEBUG] Fetching ${datesToFetch.length} missing day(s) "
          "from the sync server...",
        );

        // One request for the whole gap, from this device's own server.
        //
        // This was a four-worker pool issuing one request per missing day to
        // cdn.jsdelivr.net, each worker pausing 100 ms between its own calls.
        // The gap is every day since the bundled asset was last regenerated -
        // hundreds on a stale build, and one more every day it is not - so a
        // first launch spent minutes on hundreds of round trips to fetch what
        // is the same answer on every device in the world. The server fetches
        // that history once and hands over any range of it in a single
        // response; nothing needs throttling because nothing is being asked
        // one day at a time any more.
        try {
          final serverRates = di.sl<ServerRateService>();
          final fetched = await serverRates.fetchRange(
            dateFrom: datesToFetch.first,
            dateTo: datesToFetch.last,
          );

          // Only the days that were actually missing are kept: the range asked
          // for spans the gap, and a gap with days in the middle the database
          // already has would otherwise re-write them.
          final wanted = datesToFetch.map(keyFormatter.format).toSet();
          for (final rate in fetched) {
            final dateKey = keyFormatter.format(rate.date);
            if (!wanted.contains(dateKey)) continue;
            (dataToInsertMap[dateKey] ??= {})[rate.toCurrencyCode] = rate.rate;
          }

          if (shouldLoadFile && dataToInsertMap.isNotEmpty) {
            for (final entry in dataToInsertMap.entries) {
              fileHistoryMap[entry.key] = entry.value;
            }
            dataWasUpdated = true;
          }
        } catch (e) {
          // Logged and dropped, exactly as before: an unreachable server must
          // not stop the days that came out of the bundled history from being
          // stored, and the app runs on what it has.
          debugPrint("[INIT_DEBUG] Server rate fetch failed: $e");
        }
      }

      // 4. Batch insert into DB
      //
      // Re-sorted by date because the workers above finish out of order, and
      // the sequential loop this replaced inserted strictly chronologically.
      // The rows are the same either way, but keeping the order identical means
      // the change is provably about *when* the work runs, not what it writes.
      final Map<String, Map<String, double>> orderedToInsert = {
        for (final key in dataToInsertMap.keys.toList()..sort())
          key: dataToInsertMap[key]!,
      };

      final List<ExchangeRateDomain> listToInsert =
          convertCurreniesRateFromJson(orderedToInsert);

      if (listToInsert.isNotEmpty) {
        debugPrint(
          "[INIT_DEBUG] Adding ${listToInsert.length} new records to DB...",
        );
        await currenciesRep.addExchangeRates(listToInsert);
      }

      // 5. (DEBUG & PC ONLY) Save updated data back to binary/json if changed
      if (kDebugMode &&
          !AppPlatform.isAndroid &&
          !AppPlatform.isIOS &&
          dataWasUpdated &&
          shouldLoadFile) {
        try {
          // Ensure parent exists
          // IoHelper doesn't expose get parent, but we can assume basic logical paths if strictly needed,
          // OR iterate.
          // For now, in web, this block is skipped. In desktop, we assume IoHelper works.
          // If we need strict parent creation:
          await IoHelper.createParent(filePathCurrenciesRate);

          final String jsonContent = const JsonEncoder.withIndent(
            '  ',
          ).convert(fileHistoryMap);
          await IoHelper.writeAsString(filePathCurrenciesRate, jsonContent);

          // Use string path
          await CurrencyHistoryBinaryIO.write(
            filePathCurrenciesBinary,
            fileHistoryMap,
          );
          debugPrint("[INIT_DEBUG] Updated local history files.");
        } catch (e) {
          debugPrint("Failed to save updated history files: $e");
        }
      }
    } catch (e, stack) {
      debugPrint('[INIT_DEBUG] getCurrenciesInitial CRITICAL ERROR: $e');
      debugPrint('[INIT_DEBUG] Stack trace: $stack');
    }
  }

  static Future<List<ExchangeRateDomain>> getCurrenciesRateToSeeder() async {
    debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder START');
    final bool isDesktop = !AppPlatform.isAndroid && !AppPlatform.isIOS;
    debugPrint(
      '[IMPORT_UTILS] getCurrenciesRateToSeeder: kDebugMode=$kDebugMode isDesktop=$isDesktop',
    );

    if (kDebugMode && isDesktop) {
      // DEBUG (PC): Load from JSON File
      debugPrint(
        '[IMPORT_UTILS] getCurrenciesRateToSeeder: checking JSON file at $filePathCurrenciesRate...',
      );
      if (!await IoHelper.exists(filePathCurrenciesRate)) {
        debugPrint(
          '[IMPORT_UTILS] Seeder: JSON file not found at $filePathCurrenciesRate, falling back to assets.',
        );
      } else {
        try {
          debugPrint(
            '[IMPORT_UTILS] getCurrenciesRateToSeeder: reading JSON file...',
          );
          final content = await IoHelper.readAsString(filePathCurrenciesRate);
          debugPrint(
            '[IMPORT_UTILS] getCurrenciesRateToSeeder: JSON read (${content.length} chars), calling compute()...',
          );
          final result = await compute(_parseCurrencyHistoryJson, content);
          debugPrint(
            '[IMPORT_UTILS] getCurrenciesRateToSeeder: compute() done, ${result.length} rates from JSON',
          );
          return result;
        } catch (e) {
          debugPrint(
            '[IMPORT_UTILS] Error reading/parsing currency history for seeder (JSON): $e',
          );
        }
      }
    }

    // RELEASE or MOBILE: Load from Assets
    debugPrint(
      '[IMPORT_UTILS] getCurrenciesRateToSeeder: loading binary asset $filePathCurrenciesBinaryAsset...',
    );
    try {
      final ByteData blob = await rootBundle.load(
        filePathCurrenciesBinaryAsset,
      );
      debugPrint(
        '[IMPORT_UTILS] getCurrenciesRateToSeeder: asset loaded (${blob.lengthInBytes} bytes), parsing...',
      );
      // `asUint8List()` with no arguments, which is what this was, is a view of
      // the whole backing buffer rather than of the asset - so the moment
      // `rootBundle` hands back a `ByteData` that starts part way into a larger
      // buffer, which is exactly what it does on Android, the reader starts on
      // the wrong bytes and the seed dies on `Invalid file header`. The sibling
      // call in `getCurrenciesInitial` already passed the offset; this one did
      // not. It also matters now that these bytes cross an isolate port: the
      // bare form would post the entire buffer, not the 2.23 MB asset.
      final Uint8List bytes = blob.buffer.asUint8List(
        blob.offsetInBytes,
        blob.lengthInBytes,
      );
      debugPrint(
        '[IMPORT_UTILS] getCurrenciesRateToSeeder: parsing binary in isolate...',
      );

      // This branch is the one a release build actually takes - on mobile and
      // on desktop alike, since the branch above needs `kDebugMode` - and it is
      // reached from drift's `onCreate`, which runs on the UI isolate: drift
      // ships the *statements* to its background isolate, not the migration
      // callback. So the gzip inflate, the ~283k-entry byte walk and the ~283k
      // `ExchangeRateDomain` allocations all landed on the UI isolate while the
      // very first launch was on screen, in one uninterruptible run.
      //
      // The JSON branch above has been doing exactly this - `compute` on this
      // same payload, returning this same `List<ExchangeRateDomain>` - since it
      // was written, including on debug Windows. That is what settles the
      // "compute() can crash on Windows" note that used to justify leaving this
      // one synchronous.
      final result = await compute(parseCurrencyHistoryBinary, bytes);
      debugPrint(
        '[IMPORT_UTILS] getCurrenciesRateToSeeder END: ${result.length} rates from binary asset',
      );
      return result;
    } catch (e) {
      debugPrint(
        '[IMPORT_UTILS] Error reading/parsing currency history binary asset for seeder: $e',
      );
      return [];
    }
  }

  static List<ExchangeRateDomain> convertCurreniesRateFromJson(
    Map<String, dynamic> jsonMap,
  ) {
    final List<ExchangeRateDomain> list = [];

    // Iterate through the outer map (Dates)
    for (var dateEntry in jsonMap.entries) {
      final String dateKey = dateEntry.key;
      final dynamic dateValue = dateEntry.value;

      // Safely parse the date
      DateTime? recordDate = DateTime.tryParse(dateKey);
      if (recordDate == null) {
        debugPrint('Skipping invalid date: $dateKey');
        continue;
      }

      // Iterate through the inner map (Currencies)
      if (dateValue is Map) {
        for (var currencyEntry in dateValue.entries) {
          final dynamic rateValue = currencyEntry.value;
          final String currencyKey = currencyEntry.key;

          if (rateValue is num) {
            list.add(
              ExchangeRateDomain(
                fromCurrencyCode: 'EUR',
                toCurrencyCode: currencyKey.toUpperCase(),
                rate: rateValue.toDouble(),
                date: recordDate,
                preset: 1,
              ),
            );
          }
        }
      }
    }

    return list;
  }

  static Future<void> getCurrenciesInitialDebug() async {
    DateTime startDate = DateTime(2024, 4, 1);
    DateTime endDate = DateTime.now();
    DateTime currentDate = startDate;
    final DateFormat keyFormatter = DateFormat('yyyy-MM-dd', 'en');

    Map<String, Map<String, double>> fullHistory = {};

    if (await IoHelper.exists(filePathCurrenciesRate)) {
      try {
        final String existingContent = await IoHelper.readAsString(
          filePathCurrenciesRate,
        );
        final Map<String, dynamic> jsonMap = jsonDecode(existingContent);

        jsonMap.forEach((key, value) {
          if (value is Map) {
            Map<String, double> rates = {};
            value.forEach((k, v) {
              if (v is num) rates[k.toString()] = v.toDouble();
            });
            fullHistory[key] = rates;
          }
        });
        // ignore: empty_catches
      } catch (e) {}
    }

    if (!await IoHelper.exists(p.dirname(filePathCurrenciesRate))) {
      // Note: File usage here is unsafe for web.
      // But getCurrenciesInitialDebug calls File(path).parent.path
      // We should use IoHelper.createParent(path)
      await IoHelper.createParent(filePathCurrenciesRate);
    }

    // Every day the working file is missing, in one request to the sync
    // server. The day-at-a-time walk this replaces asked a public CDN for each
    // one and wrote the whole growing file back to disk after every answer.
    final missing = <DateTime>[];
    while (!currentDate.isAfter(endDate)) {
      if (!fullHistory.containsKey(keyFormatter.format(currentDate))) {
        missing.add(currentDate);
      }
      currentDate = nextDay(currentDate);
    }
    if (missing.isEmpty) return;

    try {
      final fetched = await di.sl<ServerRateService>().fetchRange(
        dateFrom: missing.first,
        dateTo: missing.last,
      );
      if (fetched.isEmpty) return;

      final wanted = missing.map(keyFormatter.format).toSet();
      for (final rate in fetched) {
        final dateKey = keyFormatter.format(rate.date);
        if (!wanted.contains(dateKey)) continue;
        (fullHistory[dateKey] ??= {})[rate.toCurrencyCode] = rate.rate;
      }

      await IoHelper.writeAsString(
        filePathCurrenciesRate,
        const JsonEncoder.withIndent('  ').convert(fullHistory),
      );
    } catch (e) {
      debugPrint('[IMPORT_UTILS] getCurrenciesInitialDebug failed: $e');
    }
  }
}

/// The currency-history JSON file parsed into the `date -> CODE -> rate` shape
/// [CurrencyHistoryBinaryIO.readFromBytes] produces for the binary twin.
///
/// Top-level, and bytes in / plain map out, because this is a `compute` entry
/// point: a `compute` callback may not be a closure, and everything crossing
/// the port has to be transferable. A `Uint8List` goes in and a map of nothing
/// but `String`s and `double`s comes back - no `CurrencyRepository`, no drift
/// handle, nothing holding one.
///
/// On the old "compute() can crash on Windows" note that used to sit over this
/// call site: it does not hold, and this file already disproved it.
/// [ImportDataUtils.getCurrenciesRateToSeeder] has been running `compute()` on
/// this same 6.86 MB history - as a String rather than bytes - on debug Windows
/// since it was written, and so does `sync_binary_format.dart` on every sync
/// packet. The real constraint is not the platform, it is
/// that a worker isolate has no plugin messenger and no DI container - which
/// is why this function is handed bytes rather than a path or a repository.
///
/// The `.toUpperCase()` on the code is not new: the map is written back to disk
/// on debug desktop in step 5 of [ImportDataUtils.getCurrenciesInitial], so
/// normalising it differently here would rewrite the developer's history file
/// in a different case.
@visibleForTesting
Map<String, Map<String, double>> parseCurrencyHistoryMap(Uint8List bytes) {
  final result = <String, Map<String, double>>{};

  final decoded = jsonDecode(utf8.decode(bytes));
  if (decoded is! Map) return result;

  decoded.forEach((k, v) {
    if (v is Map) {
      final Map<String, double> rates = {};
      v.forEach((curr, rate) {
        if (rate is num) {
          rates[curr.toString().toUpperCase()] = rate.toDouble();
        }
      });
      result[k.toString()] = rates;
    }
  });

  return result;
}

/// The shipped binary history asset decoded straight into seedable rows.
///
/// The binary twin of [_parseCurrencyHistoryJson], and a `compute` entry point
/// for the same reason: top-level, `Uint8List` in, and out a list of plain
/// value objects - `String`s, a `double`, a `DateTime`, an `int`. Nothing here
/// touches `di.sl`, a `CurrencyRepository` or a drift handle, which is what
/// would actually fail at the isolate boundary.
///
/// The two steps are deliberately fused into one crossing: splitting them would
/// post the ~283k-entry intermediate map back to the UI isolate only to walk it
/// again there, which is most of the cost this is moving.
@visibleForTesting
List<ExchangeRateDomain> parseCurrencyHistoryBinary(Uint8List bytes) {
  return ImportDataUtils.convertCurreniesRateFromJson(
    CurrencyHistoryBinaryIO.readFromBytes(bytes),
  );
}

List<ExchangeRateDomain> _parseCurrencyHistoryJson(String content) {
  final List<ExchangeRateDomain> list = [];
  try {
    final Map<String, dynamic> jsonMap = jsonDecode(content);

    jsonMap.forEach((dateKey, dateValue) {
      final DateTime? recordDate = DateTime.tryParse(dateKey);

      if (recordDate == null) return;

      if (dateValue is Map) {
        dateValue.forEach((currencyKey, rateValue) {
          if (rateValue is num) {
            list.add(
              ExchangeRateDomain(
                fromCurrencyCode: 'EUR',
                toCurrencyCode: currencyKey.toString().toUpperCase(),
                rate: rateValue.toDouble(),
                date: recordDate,
                preset: 1,
              ),
            );
          }
        });
      }
    });
  } catch (e) {
    debugPrint('Error parsing currency history JSON in isolate: $e');
  }
  return list;
}
