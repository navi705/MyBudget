import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class CurrencyHistoryBinaryIO {
  static const int _version = 1;

  /// Encodes the [historyMap] (formatted as Map<DateString, Map<CurrencyCode, Rate>>)
  /// into a specialized binary format.
  ///
  /// Format Structure:
  /// - Version (1 byte)
  /// - Currency Dictionary:
  ///   - Count (2 bytes)
  ///   - [Length (1 byte) + StringBytes] for each unique currency
  /// - Data:
  ///   - Date Count (4 bytes)
  ///   - For each date:
  ///     - Date (4 bytes, integer YYYYMMDD)
  ///     - Rate Count (2 bytes)
  ///     - [CurrencyIndex (2 bytes) + RateValue (8 bytes Double)] for each rate
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
    // Sort dates ensures deterministic output
    final sortedDates = historyMap.keys.toList()..sort();

    // Write Date Count
    _writeUint32(builder, sortedDates.length);

    for (final dateStr in sortedDates) {
      // Parse Date "YYYY-MM-DD" -> YYYYMMDD int
      // Expecting standard ISO8601 "YYYY-MM-DD"
      final parts = dateStr.split('-');
      if (parts.length != 3) continue; // Skip malformed dates

      final dateInt =
          int.parse(parts[0]) * 10000 +
          int.parse(parts[1]) * 100 +
          int.parse(parts[2]);
      _writeUint32(builder, dateInt);

      final rates = historyMap[dateStr];
      if (rates is Map) {
        // Filter valid rates
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

  /// Decodes binary data back into the standard Map format.
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

      final stringBytes = bytes.sublist(offset, offset + len);
      currencyIndexMap[i] = utf8.decode(stringBytes);
      offset += len;
    }

    // 3. Read Records
    final dateCount = view.getUint32(offset);
    offset += 4;

    for (int i = 0; i < dateCount; i++) {
      final dateInt = view.getUint32(offset);
      offset += 4;

      // Convert YYYYMMDD -> "YYYY-MM-DD"
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
    final b = Uint8List(2);
    ByteData.view(b.buffer).setUint16(0, value);
    builder.add(b);
  }

  static void _writeUint32(BytesBuilder builder, int value) {
    final b = Uint8List(4);
    ByteData.view(b.buffer).setUint32(0, value);
    builder.add(b);
  }

  static void _writeFloat64(BytesBuilder builder, double value) {
    final b = Uint8List(8);
    ByteData.view(b.buffer).setFloat64(0, value);
    builder.add(b);
  }
}
