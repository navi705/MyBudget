import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as di;
import 'package:my_budget_client/core/utils/currency_history_binary_io.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';

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

  static String filePathCurrenciesRatePath = r'assets/currency_history.json';

  // Binary file path (Production asset or local debug file)
  static String filePathCurrenciesBinary =
      r'C:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.bin';
  static String filePathCurrenciesBinaryAsset =
      r'lib/data/currency_history.bin';

  static Future<void> getCurrenciesInitial() async {
    final DateFormat keyFormatter = DateFormat('yyyy-MM-dd');
    final currenciesRep = di.sl<CurrencyRepository>();

    // 1. Get existing data from DB (Optimization)
    // We already have these dates in DB with preset=1 (seeded data)
    final dbRatesList = await currenciesRep.getLatestExchangeRatesAll();
    final Set<String> existingDbDates = dbRatesList
        .where((e) => e.preset == 1)
        .map((e) => keyFormatter.format(e.date))
        .toSet();

    // 2. Load History Map from File (Binary in Prod/Debug, or JSON in Debug)
    Map<String, Map<String, double>> fileHistoryMap = {};

    // Logic: Desktop & Debug -> Use File Path, otherwise -> Use Assets
    final bool isDesktop = !Platform.isAndroid && !Platform.isIOS;

    if (kDebugMode && isDesktop) {
      // DEBUG (PC ONLY): Read from local JSON file directly
      File jsonFile = File(filePathCurrenciesRate);
      if (await jsonFile.exists()) {
        try {
          final content = await jsonFile.readAsString();
          final jsonMap = jsonDecode(content);
          if (jsonMap is Map) {
            jsonMap.forEach((k, v) {
              if (v is Map) {
                Map<String, double> rates = {};
                v.forEach((curr, rate) {
                  if (rate is num)
                    rates[curr.toString().toUpperCase()] = rate.toDouble();
                });
                fileHistoryMap[k.toString()] = rates;
              }
            });
          }
        } catch (e) {
          debugPrint("Error reading Debug JSON file on PC: $e");
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
        debugPrint("Loaded exchange rates from Binary Asset.");
      } catch (e) {
        debugPrint("Error loading binary asset: $e");
      }
    }

    // 4. Loop through required dates range
    DateTime startDate = DateTime(2024, 4, 1);
    DateTime endDate = DateTime.now();
    DateTime currentDate = startDate;

    Map<String, Map<String, double>> dataToInsertMap = {};
    bool dataWasUpdated = false;

    while (!currentDate.isAfter(endDate)) {
      String dateKey = keyFormatter.format(currentDate);

      // Condition 1: Exists in DB? -> Skip
      if (existingDbDates.contains(dateKey)) {
        currentDate = currentDate.add(const Duration(days: 1));
        continue;
      }

      // Condition 2: Exists in File Map? -> Use it
      if (fileHistoryMap.containsKey(dateKey)) {
        dataToInsertMap[dateKey] = fileHistoryMap[dateKey]!;
      }
      // Condition 3: Missing everywhere -> Fetch from API (Debug & PC only usually)
      else if (kDebugMode && isDesktop) {
        try {
          await Future.delayed(const Duration(milliseconds: 100)); // Throttle
          final apiRates =
              await ExternalData.getCurrencyRatesFromFreeExchangeRates(
                currentDate,
              );

          if (apiRates.isNotEmpty) {
            dataToInsertMap[dateKey] = apiRates;
            // Also update our file map so we can save it later
            fileHistoryMap[dateKey] = apiRates;
            dataWasUpdated = true;
          }
        } catch (e) {
          debugPrint("API Error for $dateKey: $e");
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    // 6. Convert & Insert into DB
    final List<ExchangeRateDomain> listToInsert = convertCurreniesRateFromJson(
      dataToInsertMap, // This helper works with the inner map structure
    );

    if (listToInsert.isNotEmpty) {
      debugPrint("Adding ${listToInsert.length} new records to DB...");
      await currenciesRep.addExchangeRates(listToInsert);
    } else {
      debugPrint("Database is already up to date.");
    }

    // 7. (DEBUG & PC ONLY) Save updated data back to binary/json if changed
    if (kDebugMode && isDesktop && dataWasUpdated) {
      // Save to JSON
      try {
        final File localJsonFile = File(filePathCurrenciesRate);
        if (!await localJsonFile.parent.exists())
          await localJsonFile.parent.create(recursive: true);

        final String jsonContent = const JsonEncoder.withIndent(
          '  ',
        ).convert(fileHistoryMap);
        await localJsonFile.writeAsString(jsonContent);
        debugPrint("Updated local JSON history file.");
      } catch (e) {
        debugPrint("Failed to save JSON: $e");
      }

      // Save to Binary
      try {
        final File localBinaryFile = File(filePathCurrenciesBinary);
        await CurrencyHistoryBinaryIO.write(localBinaryFile, fileHistoryMap);
        debugPrint("Updated local BINARY history file.");
      } catch (e) {
        debugPrint("Failed to save Binary: $e");
      }
    }
  }

  static Future<List<ExchangeRateDomain>> getCurrenciesRateToSeeder() async {
    final bool isDesktop = !Platform.isAndroid && !Platform.isIOS;

    if (kDebugMode && isDesktop) {
      // DEBUG (PC): Load from JSON File
      final file = File(filePathCurrenciesRate);
      if (!await file.exists()) {
        debugPrint(
          'Seeder: JSON file not found at $filePathCurrenciesRate, falling back to assets.',
        );
      } else {
        try {
          final content = await file.readAsString();
          return compute(_parseCurrencyHistoryJson, content);
        } catch (e) {
          debugPrint(
            'Error reading/parsing currency history for seeder (JSON): $e',
          );
        }
      }
    }

    // RELEASE or MOBILE: Load from Assets
    try {
      final ByteData blob = await rootBundle.load(
        filePathCurrenciesBinaryAsset,
      );
      final Uint8List bytes = blob.buffer.asUint8List();
      final historyMap = CurrencyHistoryBinaryIO.readFromBytes(bytes);
      return convertCurreniesRateFromJson(historyMap);
    } catch (e) {
      debugPrint(
        'Error reading/parsing currency history binary asset for seeder: $e',
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
    final File file = File(filePathCurrenciesRate);

    DateTime startDate = DateTime(2024, 4, 1);
    DateTime endDate = DateTime.now();
    DateTime currentDate = startDate;
    final DateFormat keyFormatter = DateFormat('yyyy-MM-dd');

    Map<String, Map<String, double>> fullHistory = {};

    if (await file.exists()) {
      try {
        final String existingContent = await file.readAsString();
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

    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
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
          await file.writeAsString(jsonContent);
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
