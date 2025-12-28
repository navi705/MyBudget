import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/api/external_data.dart';

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

  static Future<void> getCurrenciesInitial() async {
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
        } catch (e) {}
        await Future.delayed(const Duration(milliseconds: 100));
      }
      currentDate = currentDate.add(const Duration(days: 1));
    }
  }

  static Future<List<ExchangeRatesCompanion>> getCurrenciesRateToSeeder() async {
  final File file = File(filePathCurrenciesRate);

  // Инициализируем пустой список сразу, чтобы вернуть его, если файла нет
  List<ExchangeRatesCompanion> list = [];

  if (await file.exists()) {
    try {
      final String existingContent = await file.readAsString();
      final Map<String, dynamic> jsonMap = jsonDecode(existingContent);

      jsonMap.forEach((dateKey, dateValue) {

        final DateTime recordDate = DateTime.parse(dateKey);

        if (dateValue is Map) {
          dateValue.forEach((currencyKey, rateValue) {


            if (rateValue is num) {
              list.add(
                ExchangeRatesCompanion.insert(
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
      debugPrint('Ошибка при парсинге файла для сидера: $e');
    }
  }
  
  return list; 
}

}
