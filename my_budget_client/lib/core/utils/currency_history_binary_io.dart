import 'dart:convert';
import 'package:my_budget_client/core/utils/platform/io_helper.dart';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

/// Handles Binary + Gzip IO for currency history.
class CurrencyHistoryBinaryIO {
  static const _header = 'CURR';
  static const _version = 1;

  /// Writes the currency history map to a GZIP-compressed binary file.
  static Future<void> write(
    String path,
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

    await IoHelper.writeAsBytes(path, buffer.toBytes());
  }

  /// Reads and decompresses the currency history map from a File.
  static Future<Map<String, Map<String, double>>> read(String path) async {
    final bytes = await IoHelper.readAsBytes(path);
    return readFromBytes(bytes);
  }

  /// [readFromBytes] on a worker isolate.
  ///
  /// The shipped asset is 2.23 MB compressed and expands into ~283k
  /// `Map<String, double>` entries. Done on the UI isolate - which is where
  /// every caller used to do it - that is a single uninterruptible run of
  /// gzip inflate plus a byte-by-byte walk, and the frame it lands in is
  /// simply dropped. It is only reached on a cold first install or after a
  /// long gap, which is exactly the launch a user judges the app by.
  ///
  /// `compute` is safe here, and safe on Windows: both ends of this call are
  /// plain transferable values. In goes a `Uint8List`, out comes a
  /// `Map<String, Map<String, double>>` of nothing but strings and doubles -
  /// no repository, no database handle, no `RootIsolateToken`-bound plugin
  /// call. See the note on the JSON twin of this method in `import_utils.dart`
  /// for why the old "compute() crashes on Windows" folklore does not apply.
  static Future<Map<String, Map<String, double>>> readFromBytesInIsolate(
    Uint8List bytes,
  ) {
    return compute(readFromBytes, bytes);
  }

  /// Reads and decompresses the currency history map from raw bytes.
  static Map<String, Map<String, double>> readFromBytes(Uint8List bytes) {
    int offset = 0;

    // Helper to read N bytes using offset
    Uint8List readBytes(int count) {
      if (offset + count > bytes.length) {
        throw Exception('Unexpected end of file');
      }
      final result = bytes.sublist(offset, offset + count);
      offset += count;
      return result;
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
    final compressedData = bytes.sublist(offset);

    // 4. Decompress
    final decoder = GZipDecoder();
    final decompressed = decoder.decodeBytes(compressedData);

    // Optimization: Use ByteData with offset-based reading instead of iterator
    //
    // `Uint8List.fromList` unconditionally copied the whole ~11 MB inflated
    // buffer a second time. `GZipDecoder` already hands back a `Uint8List` on
    // every platform we ship, so the copy bought nothing; the `is` check keeps
    // the fallback honest for any decoder that returns a plain `List<int>`.
    final decompressedBytes = decompressed is Uint8List
        ? decompressed
        : Uint8List.fromList(decompressed);
    final byteData = ByteData.sublistView(decompressedBytes);
    int dataOffset = 0;

    // Helper for Decompressed Stream using ByteData
    Uint8List readData(int count) {
      if (dataOffset + count > byteData.lengthInBytes) {
        throw Exception('Unexpected end of data');
      }
      final result = byteData.buffer.asUint8List(
        byteData.offsetInBytes + dataOffset,
        count,
      );
      dataOffset += count;
      return result;
    }

    // 5. Parse Data
    final result = <String, Map<String, double>>{};

    // The file stores the same ~250 currency codes once per day, so a straight
    // `utf8.decode` per entry allocated a decoder and a fresh `String` ~283k
    // times over to produce a couple of hundred distinct values. This cache
    // interns them: the second and every later 'usd' is the same instance the
    // first one produced, which also makes the map's key comparisons pointer
    // equality rather than a character walk.
    final codeCache = <int, String>{};

    // Date Count
    final dateCount = _bytesToInt32(readData(4));

    for (int i = 0; i < dateCount; i++) {
      // Date String
      final dateLen = readData(1)[0];
      final dateStr = _decodeAscii(readData(dateLen));

      final rates = <String, double>{};

      // Currency Count
      final currCount = _bytesToInt16(readData(2));

      for (int j = 0; j < currCount; j++) {
        // Code
        final codeLen = readData(1)[0];
        final codeBytes = readData(codeLen);
        final cacheKey = _packKey(codeBytes);
        final code = cacheKey == null
            ? _decodeAscii(codeBytes)
            : codeCache.putIfAbsent(cacheKey, () => _decodeAscii(codeBytes));
        // Rate
        final rate = _bytesToDouble(readData(8));

        rates[code] = rate;
      }
      result[dateStr] = rates;
    }

    return result;
  }

  /// The bytes as a String, taking the cheap path when they are all ASCII.
  ///
  /// Every date key and every currency code this format holds is ASCII, and
  /// `String.fromCharCodes` over an ASCII run skips the UTF-8 decoder's state
  /// machine and its per-call allocation entirely. Anything with the high bit
  /// set falls through to the real decoder, so a code outside ASCII still
  /// reads back exactly as it was written rather than silently mangled.
  static String _decodeAscii(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      if (bytes[i] >= 0x80) return utf8.decode(bytes);
    }
    return String.fromCharCodes(bytes);
  }

  /// [bytes] packed into a single int, or null when they do not fit.
  ///
  /// Deliberately a packing and not a hash. A hash key would let two different
  /// currency codes collide and hand the second one the first one's string -
  /// every rate for it silently filed under the wrong currency, which is the
  /// one class of bug this file must not introduce to save allocations. Seven
  /// bytes is the widest run that fits below the 63-bit boundary; a longer code
  /// returns null and simply skips the cache.
  static int? _packKey(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > 7) return null;
    // Seeded with the length so 'usd' and a hypothetical '\x00usd' cannot
    // pack to the same value.
    var key = bytes.length;
    for (var i = 0; i < bytes.length; i++) {
      key = (key << 8) | bytes[i];
    }
    return key;
  }

  static Uint8List _int32ToBytes(int value) {
    return Uint8List(4)..buffer.asByteData().setInt32(0, value, Endian.little);
  }

  // The three readers below take `ByteData.sublistView`, not
  // `bytes.buffer.asByteData()`. The latter hands back a view of the *whole*
  // backing buffer, so offset 0 meant the start of the buffer rather than the
  // start of the slice that was passed in. `readData` returns exactly such a
  // slice, so every count and every rate after the first one was read from the
  // wrong place, the parse walked out of step, and a currency code eventually
  // landed on bytes that are not UTF-8:
  // `FormatException: Missing extension byte (at offset 1)`.
  static int _bytesToInt32(Uint8List bytes) {
    return ByteData.sublistView(bytes).getInt32(0, Endian.little);
  }

  static Uint8List _int16ToBytes(int value) {
    return Uint8List(2)..buffer.asByteData().setInt16(0, value, Endian.little);
  }

  static int _bytesToInt16(Uint8List bytes) {
    return ByteData.sublistView(bytes).getInt16(0, Endian.little);
  }

  static Uint8List _doubleToBytes(double value) {
    return Uint8List(8)
      ..buffer.asByteData().setFloat64(0, value, Endian.little);
  }

  static double _bytesToDouble(Uint8List bytes) {
    return ByteData.sublistView(bytes).getFloat64(0, Endian.little);
  }
}
