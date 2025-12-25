import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class OneMoneyRecord {
  final DateTime date;
  final String type;
  final String from;
  final String to;
  final double amount;
  final String currency;
  final String notes;

  OneMoneyRecord({
    required this.date,
    required this.type,
    required this.from,
    required this.to,
    required this.amount,
    required this.currency,
    required this.notes,
  });

  @override
  String toString() {
    return 'OneMoneyRecord{date: $date, type: $type, from: $from, to: $to, amount: $amount, currency: $currency, notes: $notes}';
  }
}

class ImportDataUtils {
  static const List<String> _expectedHeaders = [
    "ДАТА",
    "ТИП",
    "СО СЧЁТА",
    "НА СЧЁТ / НА КАТЕГОРИЮ",
    "СУММА",
    "ВАЛЮТА",
    "СУММА 2",
    "ВАЛЮТА 2",
    "МЕТКИ",
    "ЗАМЕТКИ"
  ];

  static Future<List<OneMoneyRecord>> parseOneMoneyCsv(String filePath) async {
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
      if (rawHeaders.isNotEmpty && rawHeaders[0] is String && rawHeaders[0].startsWith('\uFEFF')) {
        rawHeaders[0] = (rawHeaders[0] as String).substring(1);
      }

      final headers = rawHeaders.map((e) => e.toString().toUpperCase()).toList();
      if (!listEquals(_expectedHeaders, headers)) {
        throw FormatException(
            "CSV headers do not match the expected format. Expected: $_expectedHeaders, but got: ${rawHeaders.map((e) => e.toString()).toList()}");
      }

      final records = <OneMoneyRecord>[];
      final DateFormat dateFormat = DateFormat('dd.MM.yyyy');

      for (int i = 1; i < csvData.length; i++) {
        final row = csvData[i];
        
        // Skip empty rows
        if (row.every((element) => element == null || element.toString().trim().isEmpty)) {
            continue;
        }

        if (row.length < _expectedHeaders.length) {
            debugPrint("Skipping row $i due to incorrect column count. Expected at least: ${_expectedHeaders.length}, got: ${row.length}. Row data: $row");
            continue;
        }

        try {
          final double amount = double.parse(row[4].toString().replaceAll(',', '.'));
          final notes = row[9].toString();
          debugPrint("Parsing row $i, notes: $notes");

          records.add(OneMoneyRecord(
            date: dateFormat.parse(row[0]),
            type: row[1].toString(),
            from: row[2].toString(),
            to: row[3].toString(),
            amount: amount,
            currency: row[5].toString(),
            notes: notes,
          ));
        } catch (e) {
            debugPrint("Skipping row $i due to parsing error: $e. Row data: $row");
            continue;
        }
      }
      return records;
    } catch (e) {
      debugPrint("Error parsing CSV file: $e");
      rethrow;
    }
  }
}