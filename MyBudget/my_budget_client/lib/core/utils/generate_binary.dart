import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
    final Map<String, dynamic> jsonMap = jsonDecode(jsonContent);
    print('JSON Decoded. Keys: ${jsonMap.length}');

    print('Step 3: Encoding to Binary...');
    final binaryBytes = CurrencyHistoryBinaryIO.encode(jsonMap);

    print('Step 4: Writing Binary file to $binPath...');
    await binFile.writeAsBytes(binaryBytes);

    print('Success!');
    print('Original JSON size: ${jsonContent.length} bytes');
    print('New Binary size:  ${binaryBytes.length} bytes');
    print(
      'Compression ratio: ${(binaryBytes.length / jsonContent.length * 100).toStringAsFixed(2)}%',
    );

    // Verify Decoding
    print('Step 5: Verifying consistency...');
    final decodedMap = CurrencyHistoryBinaryIO.decode(binaryBytes);
    if (decodedMap.keys.length == jsonMap.keys.length) {
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

class CurrencyHistoryBinaryIO {
  static const int _version = 1;

  static Uint8List encode(Map<String, dynamic> historyMap) {
    final builder = BytesBuilder();

    // 1. Header / Version
    builder.addByte(_version);

    // 2. Build Dictionary
    final Set<String> allCurrencies = {};
    historyMap.forEach((date, rates) {
      if (rates is Map) {
        rates.forEach((currency, rate) {
          allCurrencies.add(
            currency.toString().toUpperCase(),
          ); // Normalize to upper case
        });
      }
    });

    final List<String> sortedCurrencies = allCurrencies.toList()..sort();
    final Map<String, int> currencyToIndex = {
      for (int i = 0; i < sortedCurrencies.length; i++) sortedCurrencies[i]: i,
    };

    // Write Dictionary Size
    _writeUint16(builder, sortedCurrencies.length);

    // Write Dictionary Items
    for (final currency in sortedCurrencies) {
      final bytes = utf8.encode(currency);
      builder.addByte(bytes.length);
      builder.add(bytes);
    }

    // 3. Write Records
    final sortedDates = historyMap.keys.toList()..sort();

    // Write Date Count
    _writeUint32(builder, sortedDates.length);

    for (final dateStr in sortedDates) {
      final parts = dateStr.split('-');
      if (parts.length != 3) continue;

      final dateInt =
          int.parse(parts[0]) * 10000 +
          int.parse(parts[1]) * 100 +
          int.parse(parts[2]);
      _writeUint32(builder, dateInt);

      final rates = historyMap[dateStr];
      if (rates is Map) {
        final validRates = <MapEntry<int, double>>[];
        rates.forEach((key, value) {
          if (value is num) {
            final index = currencyToIndex[key.toString().toUpperCase()];
            if (index != null) {
              validRates.add(MapEntry(index, value.toDouble()));
            }
          }
        });

        // Write Rate Count
        _writeUint16(builder, validRates.length);

        // Write Rates
        for (final entry in validRates) {
          _writeUint16(builder, entry.key); // Currency Index
          _writeFloat64(builder, entry.value); // Rate Value
        }
      } else {
        _writeUint16(builder, 0);
      }
    }

    // Compress with GZip
    final rawBytes = builder.toBytes();
    final compressed = gzip.encode(rawBytes);
    return Uint8List.fromList(compressed);
  }

  static Map<String, Map<String, double>> decode(Uint8List bytes) {
    final result = <String, Map<String, double>>{};
    if (bytes.isEmpty) return {};

    // Decompress GZip
    final decompressed = Uint8List.fromList(gzip.decode(bytes));

    var offset = 0;
    final view = ByteData.view(decompressed.buffer);

    // 1. Check Version
    final version = view.getUint8(offset);
    offset += 1;

    if (version != _version) {
      throw FormatException('Unsupported binary version: $version');
    }

    // 2. Read Dictionary
    final currencyCount = view.getUint16(offset);
    offset += 2;

    final currencyIndexMap = <int, String>{};
    for (int i = 0; i < currencyCount; i++) {
      final len = view.getUint8(offset);
      offset += 1;

      final stringBytes = decompressed.sublist(offset, offset + len);
      currencyIndexMap[i] = utf8.decode(stringBytes);
      offset += len;
    }

    // 3. Read Records
    final dateCount = view.getUint32(offset);
    offset += 4;

    for (int i = 0; i < dateCount; i++) {
      final dateInt = view.getUint32(offset);
      offset += 4;

      final year = dateInt ~/ 10000;
      final month = (dateInt % 10000) ~/ 100;
      final day = dateInt % 100;
      final dateStr =
          '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

      final rateCount = view.getUint16(offset);
      offset += 2;

      final rates = <String, double>{};
      for (int r = 0; r < rateCount; r++) {
        final currencyIndex = view.getUint16(offset);
        offset += 2;

        final rateValue = view.getFloat64(offset);
        offset += 8;

        final currencyCode = currencyIndexMap[currencyIndex];
        if (currencyCode != null) {
          rates[currencyCode] = rateValue;
        }
      }
      result[dateStr] = rates;
    }

    return result;
  }

  static void _writeUint16(BytesBuilder builder, int value) {
    var b = Uint8List(2);
    ByteData.view(b.buffer).setUint16(0, value);
    builder.add(b);
  }

  static void _writeUint32(BytesBuilder builder, int value) {
    var b = Uint8List(4);
    ByteData.view(b.buffer).setUint32(0, value);
    builder.add(b);
  }

  static void _writeFloat64(BytesBuilder builder, double value) {
    var b = Uint8List(8);
    ByteData.view(b.buffer).setFloat64(0, value);
    builder.add(b);
  }
}
