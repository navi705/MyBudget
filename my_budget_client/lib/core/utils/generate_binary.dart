import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:my_budget_client/core/utils/currency_history_binary_io.dart';

void main() async {
  debugPrint('Step 1: Script Started');
  final jsonPath =
      r'c:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.json';
  final binPath =
      r'c:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.bin';

  final jsonFile = File(jsonPath);
  final binFile = File(binPath);

  if (!await jsonFile.exists()) {
    debugPrint('Error: JSON file not found at $jsonPath');
    return;
  }

  debugPrint('Step 2: Reading JSON...');
  try {
    final jsonContent = await jsonFile.readAsString();
    debugPrint('JSON size: ${jsonContent.length}');
    final Map<String, dynamic> rawJsonMap = jsonDecode(jsonContent);

    // Convert dynamic map to typed map
    final Map<String, Map<String, double>> historyMap = {};
    rawJsonMap.forEach((date, rates) {
      if (rates is Map && date != '_metadata') {
        final dateRates = <String, double>{};
        rates.forEach((key, value) {
          if (value is num) {
            dateRates[key.toString().toUpperCase()] = value.toDouble();
          }
        });
        historyMap[date] = dateRates;
      }
    });

    debugPrint('JSON Decoded. Dates: ${historyMap.length}');

    debugPrint('Step 3: Writing Binary file to $binPath...');
    // We use the centralized CurrencyHistoryBinaryIO which handles GZip
    await CurrencyHistoryBinaryIO.write(binFile, historyMap);

    debugPrint('Success!');
    final finalBinSize = await binFile.length();
    debugPrint('Original JSON size: ${jsonContent.length} bytes');
    debugPrint('New Binary size:  $finalBinSize bytes');
    debugPrint(
      'Compression ratio: ${(finalBinSize / jsonContent.length * 100).toStringAsFixed(2)}%',
    );

    // Verify Decoding
    debugPrint('Step 4: Verifying consistency...');
    final decodedMap = await CurrencyHistoryBinaryIO.read(binFile);
    if (decodedMap.keys.length == historyMap.keys.length) {
      debugPrint(
        'Verification Passed: Keys count matches (${decodedMap.keys.length}).',
      );
    } else {
      debugPrint('Verification Failed: Key count mismatch.');
    }
  } catch (e, s) {
    debugPrint('Error during conversion: $e');
    debugPrint(s.toString());
  }
}
