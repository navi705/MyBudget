import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as di;
import 'package:flutter/services.dart' show rootBundle;
import 'package:my_budget_client/core/utils/currency_history_binary_io.dart';

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

  static Future<ParsedCsvData> parseOneMoneyCsv(String filePath) async {
    try {
      final fileContent = await File(filePath).readAsString();

      const converter = CsvToListConverter(
        fieldDelimiter: ',',
        textDelimiter: '"',
        eol: '\n',
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

      final headers = rawHeaders
          .map((e) => e.toString().toUpperCase())
          .toList();

      List<String> expectedHeaders;
      DateFormat dateFormat;
      bool isRussian = false;

      if (listEquals(_expectedHeadersRu, headers)) {
        expectedHeaders = _expectedHeadersRu;
        dateFormat = DateFormat('dd.MM.yyyy');
        isRussian = true;
      } else if (listEquals(_expectedHeadersEn, headers)) {
        expectedHeaders = _expectedHeadersEn;
        dateFormat = DateFormat('MM/dd/yy');
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
  static String filePathCurrenciesRateBin =
      r'C:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.bin';

  static String filePathCurrenciesRatePath = r'assets/currency_history.json';
  static String filePathCurrenciesRatePathBin =
      r'lib/data/currency_history.bin';

  /// Main entry point for initial currency hydration.
  /// Seeds the DB from file (JSON/Binary) and fetches new data from API (Debug only).
  static Future<void> getCurrenciesInitial() async {
    final currenciesRep = di.sl<CurrencyRepository>();
    final DateFormat keyFormatter = DateFormat('yyyy-MM-dd');

    // --- 1. Get Known Currencies (for FOREIGN KEY protection) ---
    final knownCurrenciesList = await currenciesRep.getCurrencies();
    final Set<String> knownCurrencyCodes = knownCurrenciesList
        .map((c) => c.code.toUpperCase())
        .toSet();
    debugPrint("Known currencies in DB: ${knownCurrencyCodes.length}");

    // --- 2. Get Existing Rate Keys from DB (for duplicate protection) ---
    // Key format: "YYYY-MM-DD_FROM_TO"
    final dbRatesList = await currenciesRep.getLatestExchangeRatesAll();
    final Set<String> existingDbKeys = dbRatesList.map((e) {
      final dateStr = keyFormatter.format(e.date);
      return '${dateStr}_${e.fromCurrencyCode}_${e.toCurrencyCode}';
    }).toSet();
    debugPrint("Existing rate keys in DB: ${existingDbKeys.length}");

    // --- 3. Load History from File ---
    final Map<String, dynamic> fullHistoryMap =
        await _loadCurrencyHistoryFile();
    debugPrint("Dates loaded from file: ${fullHistoryMap.keys.length}");

    // --- 4. Build Insert List (Filtered) ---
    final List<ExchangeRateDomain> listToInsert = [];
    bool dataWasUpdated = false;

    // Determine date range to process
    DateTime startDate = DateTime(2024, 4, 1);
    DateTime endDate = DateTime.now();
    DateTime currentDate = startDate;

    while (!currentDate.isAfter(endDate)) {
      final dateKey = keyFormatter.format(currentDate);

      Map<String, double>? ratesForDate;

      // --- 4a. Check File Data ---
      if (fullHistoryMap.containsKey(dateKey)) {
        final rawData = fullHistoryMap[dateKey];
        if (rawData is Map) {
          ratesForDate = {};
          rawData.forEach((k, v) {
            if (v is num)
              ratesForDate![k.toString().toUpperCase()] = v.toDouble();
          });
        }
      }
      // --- 4b. (DEBUG ONLY) Fetch from API if missing in file ---
      else if (kDebugMode) {
        try {
          await Future.delayed(const Duration(milliseconds: 100)); // Throttle
          final apiRates =
              await ExternalData.getCurrencyRatesFromFreeExchangeRates(
                currentDate,
              );
          if (apiRates.isNotEmpty) {
            ratesForDate = apiRates.map((k, v) => MapEntry(k.toUpperCase(), v));
            fullHistoryMap[dateKey] = ratesForDate; // Update file cache
            dataWasUpdated = true;
          }
        } catch (e) {
          debugPrint("API Error for $dateKey: $e");
        }
      }

      // --- 4c. Add to insert list (with filters) ---
      if (ratesForDate != null) {
        for (final entry in ratesForDate.entries) {
          final currencyCode = entry.key;
          final rate = entry.value;
          final rateKey = '${dateKey}_EUR_$currencyCode';

          // Filter 1: Currency must exist in DB
          if (!knownCurrencyCodes.contains(currencyCode)) continue;
          // Filter 2: Rate must not already be in DB
          if (existingDbKeys.contains(rateKey)) continue;

          listToInsert.add(
            ExchangeRateDomain(
              fromCurrencyCode: 'EUR',
              toCurrencyCode: currencyCode,
              rate: rate,
              date: currentDate,
              preset: 1,
            ),
          );
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    // --- 5. Insert to DB ---
    if (listToInsert.isNotEmpty) {
      debugPrint(
        "Inserting ${listToInsert.length} new exchange rates to DB...",
      );
      await currenciesRep.addExchangeRates(listToInsert);
    } else {
      debugPrint("Currency history: DB is already up to date.");
    }

    // --- 6. (DEBUG ONLY) Save Files ---
    if (kDebugMode) {
      final bool binaryExists = await File(filePathCurrenciesRateBin).exists();
      if (dataWasUpdated || !binaryExists) {
        await _saveCurrencyHistoryFiles(fullHistoryMap, dataWasUpdated);
      }
    }
  }

  /// Loads history from JSON (Debug) or Binary (Prod).
  static Future<Map<String, dynamic>> _loadCurrencyHistoryFile() async {
    if (kDebugMode) {
      final fileJson = File(filePathCurrenciesRate);
      if (await fileJson.exists()) {
        try {
          final content = await fileJson.readAsString();
          return jsonDecode(content);
        } catch (e) {
          debugPrint("Error reading JSON history: $e");
        }
      }
    } else {
      try {
        final byteData = await rootBundle.load(filePathCurrenciesRatePathBin);
        return CurrencyHistoryBinaryIO.decode(byteData.buffer.asUint8List());
      } catch (e) {
        debugPrint("Binary load failed ($e), trying JSON fallback...");
        try {
          final content = await rootBundle.loadString(
            filePathCurrenciesRatePath,
          );
          return jsonDecode(content);
        } catch (e2) {
          debugPrint("JSON fallback also failed: $e2");
        }
      }
    }
    return {};
  }

  /// Saves history to JSON and Binary files. Debug mode only.
  static Future<void> _saveCurrencyHistoryFiles(
    Map<String, dynamic> fullHistoryMap,
    bool saveJson,
  ) async {
    if (saveJson) {
      try {
        final fileJson = File(filePathCurrenciesRate);
        const encoder = JsonEncoder.withIndent('  ');
        await fileJson.writeAsString(encoder.convert(fullHistoryMap));
        debugPrint("Updated currency_history.json.");
      } catch (e) {
        debugPrint("Failed to write JSON: $e");
      }
    }
    try {
      final fileBin = File(filePathCurrenciesRateBin);
      final bytes = CurrencyHistoryBinaryIO.encode(fullHistoryMap);
      await fileBin.writeAsBytes(bytes);
      debugPrint("Updated currency_history.bin (${bytes.length} bytes).");
    } catch (e) {
      debugPrint("Failed to write Binary: $e");
    }
  }

  // Deprecated: getCurrenciesRateToSeeder and getCurrenciesInitialDebug
  // can essentially be removed or redirected if used elsewhere.
  // Keeping this for compatibility if it's called from tests, but updating to use new logic.
  static Future<List<ExchangeRateDomain>> getCurrenciesRateToSeeder() async {
    // Simplified: Just load what we have available
    Map<String, dynamic> map = {};
    if (kDebugMode) {
      final file = File(filePathCurrenciesRate);
      if (await file.exists()) {
        map = jsonDecode(await file.readAsString());
      }
    } else {
      // Try binary first
      try {
        final byteData = await rootBundle.load(filePathCurrenciesRatePathBin);
        map = CurrencyHistoryBinaryIO.decode(byteData.buffer.asUint8List());
      } catch (e) {
        final str = await rootBundle.loadString(filePathCurrenciesRatePath);
        map = jsonDecode(str);
      }
    }
    return convertCurreniesRateFromJson(map);
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
}
