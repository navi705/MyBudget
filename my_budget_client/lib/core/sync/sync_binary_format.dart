import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:archive/archive.dart';
import 'dart:typed_data';

/// Table identifiers for binary sync format
enum SyncTableId {
  transactions(0),
  accounts(1),
  categories(2),
  styles(3),
  exchangeRates(4),
  inflationRates(5),
  assetEntries(6),
  customThemes(7),
  settings(8),
  smsPresets(9),
  customDataSources(10),
  apiSettings(11),
  accountTypes(12),
  currencyDesignations(13),
  currencies(14);

  const SyncTableId(this.value);
  final int value;

  /// Null for a table this build does not know about.
  ///
  /// Wire values are append-only, so a newer peer can send an id this build
  /// has never heard of. Throwing here (the previous `firstWhere`) failed the
  /// decode of the whole packet, losing every other change in it; the decoder
  /// skips the one unknown block instead.
  static SyncTableId? fromValue(int value) {
    for (final id in SyncTableId.values) {
      if (id.value == value) return id;
    }
    return null;
  }
}

/// Action types for sync changes
enum SyncAction {
  upsert(0),
  delete(1);

  const SyncAction(this.value);
  final int value;

  /// Null for an action this build does not know about; see
  /// [SyncTableId.fromValue] for why an unknown value is skipped, not thrown.
  static SyncAction? fromValue(int value) {
    for (final action in SyncAction.values) {
      if (action.value == value) return action;
    }
    return null;
  }
}

/// Represents a single change record for sync
class SyncChange {
  final SyncTableId tableId;
  final String recordId;
  final SyncAction action;

  /// The record's fields for an upsert. A delete has no row left to describe,
  /// so it carries at most the clock it happened at, under the same
  /// `modifiedAt` key an upsert uses.
  final Map<String, dynamic>? data;

  SyncChange({
    required this.tableId,
    required this.recordId,
    required this.action,
    this.data,
  });
}

/// Binary sync file format:
/// [HEADER: 4 bytes "SYNC"]
/// [VERSION: 1 byte]
/// [DEVICE_ID: 36 bytes UUID string]
/// [TIMESTAMP: 8 bytes int64]
/// [CHANGE_COUNT: 4 bytes uint32]
/// [CHANGES: repeated]
///   [TABLE_ID: 1 byte enum]
///   [RECORD_ID_LEN: 1 byte]
///   [RECORD_ID: variable bytes]
///   [ACTION: 1 byte]
///   [DATA_LEN: 4 bytes uint32] (0 when the change carries no payload)
///   [DATA: JSON bytes]
class SyncBinaryFormat {
  static const List<int> _header = [0x53, 0x59, 0x4E, 0x43]; // "SYNC"
  static const int _version = 1;

  /// Encode changes to binary format (gzip compressed).
  ///
  /// Runs on the calling isolate. Prefer [encodeAsync] from anything the user
  /// is waiting on — see the note there for what this costs.
  static Uint8List encode({
    required String deviceId,
    required int timestamp,
    required List<SyncChange> changes,
  }) => encodeSyncPacketJob(_encodeJob(deviceId, timestamp, changes));

  /// [encode] with the per-change `jsonEncode` and the gzip pass moved off the
  /// calling isolate.
  ///
  /// Both are pure CPU proportional to the number of changes, and the one
  /// caller that matters — the export the app fires while it is closing —
  /// ran them on the UI isolate, where they block the frame loop and the
  /// platform's teardown at the exact moment the window is trying to go away.
  /// `compute` is a no-op wrapper on web (no isolates there), so this stays
  /// correct on every platform and is only actually parallel where it can be.
  static Future<Uint8List> encodeAsync({
    required String deviceId,
    required int timestamp,
    required List<SyncChange> changes,
  }) => compute(encodeSyncPacketJob, _encodeJob(deviceId, timestamp, changes));

  /// Flattens the job into nothing but strings, ints, lists and maps.
  ///
  /// [SyncChange] itself would very likely survive the isolate port, but the
  /// port's contract is about transferable *values*, and a change carries an
  /// enum and a free-form payload map. Spelling the four fields out is one
  /// cheap loop with no CPU in it (the encoding is what we are moving), and it
  /// makes the boundary impossible to break by adding a field to [SyncChange]
  /// later.
  static Map<String, Object?> _encodeJob(
    String deviceId,
    int timestamp,
    List<SyncChange> changes,
  ) => {
    'deviceId': deviceId,
    'timestamp': timestamp,
    'changes': [
      for (final change in changes)
        <Object?>[
          change.tableId.value,
          change.recordId,
          change.action.value,
          change.data,
        ],
    ],
  };

  /// Decode binary format (gzip compressed)
  static SyncPacket decode(Uint8List data) {
    // Decompress
    final decompressed = Uint8List.fromList(GZipDecoder().decodeBytes(data));

    int offset = 0;

    // Verify header
    if (decompressed.length < 4 ||
        decompressed[0] != _header[0] ||
        decompressed[1] != _header[1] ||
        decompressed[2] != _header[2] ||
        decompressed[3] != _header[3]) {
      throw FormatException('Invalid sync file header');
    }
    offset += 4;

    // Version
    final version = decompressed[offset];
    if (version != _version) {
      throw FormatException('Unsupported sync version: $version');
    }
    offset += 1;

    // Device ID
    final deviceId = utf8
        .decode(decompressed.sublist(offset, offset + 36))
        .trim();
    offset += 36;

    // Timestamp
    final timestamp = _bytesToInt64(decompressed.sublist(offset, offset + 8));
    offset += 8;

    // Change count
    final changeCount = _bytesToUint32(
      decompressed.sublist(offset, offset + 4),
    );
    offset += 4;

    // Changes
    //
    // Every block is length-prefixed, so an unrecognised table or action can
    // be stepped over without losing sync with the byte stream. That keeps a
    // packet from a newer peer usable instead of failing whole.
    final changes = <SyncChange>[];
    for (int i = 0; i < changeCount; i++) {
      // Table ID
      final tableId = SyncTableId.fromValue(decompressed[offset]);
      offset += 1;

      // Record ID
      final recordIdLen = decompressed[offset];
      offset += 1;
      final recordId = utf8.decode(
        decompressed.sublist(offset, offset + recordIdLen),
      );
      offset += recordIdLen;

      // Action
      final action = SyncAction.fromValue(decompressed[offset]);
      offset += 1;

      // Data
      final dataLen = _bytesToUint32(decompressed.sublist(offset, offset + 4));
      offset += 4;

      Map<String, dynamic>? data;
      if (dataLen > 0) {
        final dataBytes = decompressed.sublist(offset, offset + dataLen);
        data = jsonDecode(utf8.decode(dataBytes)) as Map<String, dynamic>;
        offset += dataLen;
      }

      if (tableId == null || action == null) continue;

      changes.add(
        SyncChange(
          tableId: tableId,
          recordId: recordId,
          action: action,
          data: data,
        ),
      );
    }

    return SyncPacket(
      deviceId: deviceId,
      timestamp: timestamp,
      changes: changes,
    );
  }

  static Uint8List _int64ToBytes(int value) {
    final data = ByteData(8);
    data.setInt64(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  static int _bytesToInt64(Uint8List bytes) {
    return ByteData.sublistView(bytes).getInt64(0, Endian.little);
  }

  static Uint8List _uint32ToBytes(int value) {
    final data = ByteData(4);
    data.setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  static int _bytesToUint32(Uint8List bytes) {
    return ByteData.sublistView(bytes).getUint32(0, Endian.little);
  }
}

/// Decoded sync packet
class SyncPacket {
  final String deviceId;
  final int timestamp;
  final List<SyncChange> changes;

  SyncPacket({
    required this.deviceId,
    required this.timestamp,
    required this.changes,
  });
}

/// Builds one gzipped packet out of the flattened job [SyncBinaryFormat] hands
/// it.
///
/// Top-level, and taking a single plain-value argument, because that is what
/// `compute` requires of an isolate entry point — it cannot start from a
/// closure or an instance method. It is the whole of the old `encode` body,
/// unchanged byte for byte in what it produces; the only difference is that a
/// change now arrives as `[tableId, recordId, action, data]` instead of as a
/// [SyncChange].
Uint8List encodeSyncPacketJob(Map<String, Object?> job) {
  final deviceId = job['deviceId']! as String;
  final timestamp = job['timestamp']! as int;
  final changes = job['changes']! as List<Object?>;

  final builder = BytesBuilder();

  // Header
  builder.add(SyncBinaryFormat._header);

  // Version
  builder.addByte(SyncBinaryFormat._version);

  // Device ID (36 bytes UUID)
  final deviceIdBytes = utf8.encode(deviceId.padRight(36).substring(0, 36));
  builder.add(deviceIdBytes);

  // Timestamp (8 bytes)
  builder.add(SyncBinaryFormat._int64ToBytes(timestamp));

  // Change count (4 bytes)
  builder.add(SyncBinaryFormat._uint32ToBytes(changes.length));

  // Changes
  for (final change in changes) {
    final fields = change! as List<Object?>;

    // Table ID (1 byte)
    builder.addByte(fields[0]! as int);

    // Record ID (length + bytes)
    final recordIdBytes = utf8.encode(fields[1]! as String);
    builder.addByte(recordIdBytes.length);
    builder.add(recordIdBytes);

    // Action (1 byte)
    builder.addByte(fields[2]! as int);

    // Data (length + JSON bytes). The block is written for a delete too, so
    // its clock reaches the peer; the layout is unchanged, so a build that
    // reads only an upsert's payload steps over it exactly as before.
    final data = fields[3];
    if (data != null) {
      final dataBytes = utf8.encode(jsonEncode(data));
      builder.add(SyncBinaryFormat._uint32ToBytes(dataBytes.length));
      builder.add(dataBytes);
    } else {
      builder.add(SyncBinaryFormat._uint32ToBytes(0));
    }
  }

  // Compress with gzip
  final uncompressed = builder.takeBytes();
  return Uint8List.fromList(GZipEncoder().encode(uncompressed)!);
}
