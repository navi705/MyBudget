import 'dart:convert';
import 'dart:io';
import 'package:my_budget_client/core/utils/currency_history_binary_io.dart';

void main() async {
  print('Step 1: Script Started');
  final jsonPath =
      r'c:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.json';
  final binPath =
      r'c:\Users\vrclu\Documents\NewFilePC\Programing\Projects\MyBudget\MyBudget\my_budget_client\lib\data\currency_history.bin';

  final jsonFile = File(jsonPath);
  final binFile = File(binPath);

  if (!await jsonFile.exists()) {
    print('Error: JSON file not found at $jsonPath');
    return;
  }

  print('Step 2: Reading JSON...');
  try {
    final jsonContent = await jsonFile.readAsString();
    print('JSON size: ${jsonContent.length}');
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

    print('JSON Decoded. Dates: ${historyMap.length}');

    print('Step 3: Writing Binary file to $binPath...');
    // We use the centralized CurrencyHistoryBinaryIO which handles GZip
    await CurrencyHistoryBinaryIO.write(binFile, historyMap);

    print('Success!');
    final finalBinSize = await binFile.length();
    print('Original JSON size: ${jsonContent.length} bytes');
    print('New Binary size:  $finalBinSize bytes');
    print(
      'Compression ratio: ${(finalBinSize / jsonContent.length * 100).toStringAsFixed(2)}%',
    );

    // Verify Decoding
    print('Step 4: Verifying consistency...');
    final decodedMap = await CurrencyHistoryBinaryIO.read(binFile);
    if (decodedMap.keys.length == historyMap.keys.length) {
      print(
        'Verification Passed: Keys count matches (${decodedMap.keys.length}).',
      );
    } else {
      print('Verification Failed: Key count mismatch.');
    }
  } catch (e, s) {
    print('Error during conversion: $e');
    print(s);
  }
}
