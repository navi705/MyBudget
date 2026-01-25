import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';

/// Handles Binary + Gzip IO for currency history.
class CurrencyHistoryBinaryIO {
  static const _header = 'CURR';
  static const _version = 1;

  /// Writes the currency history map to a GZIP-compressed binary file.
  static Future<void> write(
    File file,
    Map<String, Map<String, double>> history,
  ) async {
    final buffer = BytesBuilder();

    // 1. Header & Version (Uncompressed)
    buffer.add(utf8.encode(_header));
    buffer.addByte(_version);

    // 2. Prepare Data for Compression
    final dataBuffer = BytesBuilder();

    // Date Count
    final sortedDates = history.keys.toList()..sort();
    dataBuffer.add(_int32ToBytes(sortedDates.length));

    for (final date in sortedDates) {
      // Date String
      final dateBytes = utf8.encode(date);
      dataBuffer.addByte(dateBytes.length);
      dataBuffer.add(dateBytes);

      final rates = history[date]!;
      // Currency Count
      dataBuffer.add(_int16ToBytes(rates.length));

      for (final entry in rates.entries) {
        final codeBytes = utf8.encode(entry.key);
        // Code Length
        dataBuffer.addByte(codeBytes.length);
        // Code
        dataBuffer.add(codeBytes);
        // Rate (Double)
        dataBuffer.add(_doubleToBytes(entry.value));
      }
    }

    // 3. Compress Data
    final encoder = GZipEncoder();
    final compressed = encoder.encode(dataBuffer.toBytes());

    if (compressed != null) {
      buffer.add(compressed);
    }

    await file.writeAsBytes(buffer.toBytes());
  }

  /// Reads and decompresses the currency history map from a File.
  static Future<Map<String, Map<String, double>>> read(File file) async {
    final bytes = await file.readAsBytes();
    return readFromBytes(bytes);
  }

  /// Reads and decompresses the currency history map from raw bytes.
  static Map<String, Map<String, double>> readFromBytes(Uint8List bytes) {
    final iterator = bytes.iterator;

    // Helper to read N bytes
    Uint8List readBytes(int count) {
      final list = Uint8List(count);
      for (int i = 0; i < count; i++) {
        if (!iterator.moveNext()) throw Exception('Unexpected end of file');
        list[i] = iterator.current;
      }
      return list;
    }

    // 1. Check Header
    final headerBytes = readBytes(4);
    final header = utf8.decode(headerBytes);
    if (header != _header) {
      throw Exception('Invalid file header: $header');
    }

    // 2. Check Version
    final version = readBytes(1)[0];
    if (version != _version) {
      throw Exception('Unsupported version: $version');
    }

    // 3. Read Remaining (Compressed) Data
    final compressedData = BytesBuilder();
    while (iterator.moveNext()) {
      compressedData.addByte(iterator.current);
    }

    // 4. Decompress
    final decoder = GZipDecoder();
    final decompressed = decoder.decodeBytes(compressedData.toBytes());
    final dataIterator = decompressed.iterator;

    // Helper for Decompressed Stream
    Uint8List readData(int count) {
      final list = Uint8List(count);
      for (int i = 0; i < count; i++) {
        if (!dataIterator.moveNext()) throw Exception('Unexpected end of data');
        list[i] = dataIterator.current;
      }
      return list;
    }

    // 5. Parse Data
    final result = <String, Map<String, double>>{};

    // Date Count
    final dateCount = _bytesToInt32(readData(4));

    for (int i = 0; i < dateCount; i++) {
      // Date String
      final dateLen = readData(1)[0];
      final dateStr = utf8.decode(readData(dateLen));

      final rates = <String, double>{};

      // Currency Count
      final currCount = _bytesToInt16(readData(2));

      for (int j = 0; j < currCount; j++) {
        // Code
        final codeLen = readData(1)[0];
        final code = utf8.decode(readData(codeLen));
        // Rate
        final rate = _bytesToDouble(readData(8));

        rates[code] = rate;
      }
      result[dateStr] = rates;
    }

    return result;
  }

  static Uint8List _int32ToBytes(int value) {
    return Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);
  }

  static int _bytesToInt32(Uint8List bytes) {
    return bytes.buffer.asByteData().getInt32(0, Endian.little);
  }

  static Uint8List _int16ToBytes(int value) {
    return Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);
  }

  static int _bytesToInt16(Uint8List bytes) {
    return bytes.buffer.asByteData().getInt16(0, Endian.little);
  }

  static Uint8List _doubleToBytes(double value) {
    return Uint8List(8)
      ..buffer.asByteData().setFloat64(0, value, Endian.little);
  }

  static double _bytesToDouble(Uint8List bytes) {
    return bytes.buffer.asByteData().getFloat64(0, Endian.little);
  }
}
