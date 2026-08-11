import 'dart:convert';
import 'package:my_budget_client/core/utils/import_file_data.dart';
import 'package:path/path.dart' as p;
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/data/api/external_data.dart';
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
                  balance: double.parse(row[1].toString()),
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
            final double amount = double.parse(
              row[4].toString().replaceAll(',', '.'),
            );
            final notes = row[9].toString();
            final double? amount2 =
                row.length > 6 && row[6].toString().isNotEmpty
                ? double.parse(row[6].toString().replaceAll(',', '.'))
                : null;
            final String? currency2 = row.length > 7 ? row[7].toString() : null;

            debugPrint("Parsing row $i, notes: $notes");

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

  static String filePathCurrenciesRatePath = r'assets/currency_history.json';

  // Binary file path (Production asset or local debug file)
  static String filePathCurrenciesBinary =
      r'C:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.bin';
  static String filePathCurrenciesBinaryAsset =
      r'lib/data/currency_history.bin';

  static Future<void> getCurrenciesInitial() async {
    try {
      final DateFormat keyFormatter = DateFormat('yyyy-MM-dd', 'en');
      final currenciesRep = di.sl<CurrencyRepository>();

      // 1. Get existing dates from DB (preset=1 means seeded data)
      debugPrint('[INIT_DEBUG] getCurrenciesInitial: Checking DB history...');
      final dbRatesList = await currenciesRep.getLatestExchangeRatesAll();
      final Set<String> existingDbDates = dbRatesList
          .where((e) => e.preset == 1)
          .map((e) => keyFormatter.format(e.date))
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
            final content = await IoHelper.readAsString(filePathCurrenciesRate);
            final jsonMap = jsonDecode(content);
            if (jsonMap is Map) {
              jsonMap.forEach((k, v) {
                if (v is Map) {
                  Map<String, double> rates = {};
                  v.forEach((curr, rate) {
                    if (rate is num) {
                      rates[curr.toString().toUpperCase()] = rate.toDouble();
                    }
                  });
                  fileHistoryMap[k.toString()] = rates;
                }
              });
            }
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
            fileHistoryMap = CurrencyHistoryBinaryIO.readFromBytes(bytes);
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
      Map<String, Map<String, double>> dataToInsertMap = {};
      bool dataWasUpdated = false;
      DateTime currentDate = startDate;

      while (!currentDate.isAfter(endDate)) {
        String dateKey = keyFormatter.format(currentDate);

        if (!existingDbDates.contains(dateKey)) {
          // Case 1: Use file data if loaded
          if (fileHistoryMap.containsKey(dateKey)) {
            dataToInsertMap[dateKey] = fileHistoryMap[dateKey]!;
          }
          // Case 2: Fetch via API
          else {
            try {
              // Throttle API requests slightly in the background
              await Future.delayed(const Duration(milliseconds: 100));
              final apiRates =
                  await ExternalData.getCurrencyRatesFromFreeExchangeRates(
                    currentDate,
                  );

              if (apiRates.isNotEmpty) {
                dataToInsertMap[dateKey] = apiRates;
                if (shouldLoadFile) {
                  fileHistoryMap[dateKey] = apiRates;
                  dataWasUpdated = true;
                }
              }
            } catch (e) {
              debugPrint("API Error for $dateKey: $e");
            }
          }
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 4. Batch insert into DB
      final List<ExchangeRateDomain> listToInsert =
          convertCurreniesRateFromJson(dataToInsertMap);

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
    debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder: kDebugMode=$kDebugMode isDesktop=$isDesktop');

    if (kDebugMode && isDesktop) {
      // DEBUG (PC): Load from JSON File
      debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder: checking JSON file at $filePathCurrenciesRate...');
      if (!await IoHelper.exists(filePathCurrenciesRate)) {
        debugPrint(
          '[IMPORT_UTILS] Seeder: JSON file not found at $filePathCurrenciesRate, falling back to assets.',
        );
      } else {
        try {
          debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder: reading JSON file...');
          final content = await IoHelper.readAsString(filePathCurrenciesRate);
          debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder: JSON read (${content.length} chars), calling compute()...');
          final result = await compute(_parseCurrencyHistoryJson, content);
          debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder: compute() done, ${result.length} rates from JSON');
          return result;
        } catch (e) {
          debugPrint(
            '[IMPORT_UTILS] Error reading/parsing currency history for seeder (JSON): $e',
          );
        }
      }
    }

    // RELEASE or MOBILE: Load from Assets
    debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder: loading binary asset $filePathCurrenciesBinaryAsset...');
    try {
      final ByteData blob = await rootBundle.load(
        filePathCurrenciesBinaryAsset,
      );
      debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder: asset loaded (${blob.lengthInBytes} bytes), parsing...');
      final Uint8List bytes = blob.buffer.asUint8List();
      final historyMap = CurrencyHistoryBinaryIO.readFromBytes(bytes);
      debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder: binary parsed, converting...');
      final result = convertCurreniesRateFromJson(historyMap);
      debugPrint('[IMPORT_UTILS] getCurrenciesRateToSeeder END: ${result.length} rates from binary asset');
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

    while (!currentDate.isAfter(endDate)) {
      String dateKey = keyFormatter.format(currentDate);

      if (!fullHistory.containsKey(dateKey)) {
        try {
          fullHistory[dateKey] =
              await ExternalData.getCurrencyRatesFromFreeExchangeRates(
                currentDate,
              );

          final String jsonContent = const JsonEncoder.withIndent(
            '  ',
          ).convert(fullHistory);
          await IoHelper.writeAsString(filePathCurrenciesRate, jsonContent);
          // ignore: empty_catches
        } catch (e) {}
        await Future.delayed(const Duration(milliseconds: 100));
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }
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
