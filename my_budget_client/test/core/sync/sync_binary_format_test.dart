import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';

/// Pure encode/decode coverage for the P2P wire format: no DB, no file I/O.
///
/// [SyncBinaryFormat] is the shared substrate both the packet round-trip test
/// and the malformed-input test rely on, so its own contract - byte layout,
/// header/version checks, and how corrupt input fails - is verified in
/// isolation here first.
void main() {
  group('encode/decode round trip', () {
    test('single upsert change preserves table, record id, action and data', () {
      final bytes = SyncBinaryFormat.encode(
        deviceId: 'device-123',
        timestamp: 1700000000000,
        changes: [
          SyncChange(
            tableId: SyncTableId.styles,
            recordId: 'style-1',
            action: SyncAction.upsert,
            data: {
              'id': 'style-1',
              'name': 'Ocean',
              'colorHex': '#00AABB',
              'nested': {'a': 1, 'b': null},
              'list': [1, 2, 3],
              'unicode': 'héllo wörld 日本語',
              'nullField': null,
              'boolField': true,
              'floatField': 12.5,
            },
          ),
        ],
      );

      final packet = SyncBinaryFormat.decode(bytes);

      expect(packet.deviceId, 'device-123');
      expect(packet.timestamp, 1700000000000);
      expect(packet.changes, hasLength(1));

      final change = packet.changes.single;
      expect(change.tableId, SyncTableId.styles);
      expect(change.recordId, 'style-1');
      expect(change.action, SyncAction.upsert);
      expect(change.data!['name'], 'Ocean');
      expect(change.data!['nested'], {'a': 1, 'b': null});
      expect(change.data!['list'], [1, 2, 3]);
      expect(change.data!['unicode'], 'héllo wörld 日本語');
      expect(change.data!['nullField'], isNull);
      expect(change.data!.containsKey('nullField'), isTrue);
      expect(change.data!['boolField'], true);
      expect(change.data!['floatField'], 12.5);
    });

    test('delete change carries no data and round trips with null data', () {
      final bytes = SyncBinaryFormat.encode(
        deviceId: 'device-123',
        timestamp: 42,
        changes: [
          SyncChange(
            tableId: SyncTableId.accounts,
            recordId: 'acc-1',
            action: SyncAction.delete,
          ),
        ],
      );

      final packet = SyncBinaryFormat.decode(bytes);
      final change = packet.changes.single;
      expect(change.action, SyncAction.delete);
      expect(change.data, isNull);
    });

    test('every SyncTableId value round trips through encode/decode', () {
      final changes = SyncTableId.values
          .map(
            (id) => SyncChange(
              tableId: id,
              recordId: 'rec-${id.value}',
              action: SyncAction.upsert,
              data: {'marker': id.value},
            ),
          )
          .toList();

      final bytes = SyncBinaryFormat.encode(
        deviceId: 'device-x',
        timestamp: 1,
        changes: changes,
      );
      final packet = SyncBinaryFormat.decode(bytes);

      expect(packet.changes, hasLength(SyncTableId.values.length));
      for (var i = 0; i < SyncTableId.values.length; i++) {
        expect(packet.changes[i].tableId, SyncTableId.values[i]);
        expect(packet.changes[i].data!['marker'], SyncTableId.values[i].value);
      }
    });

    test('multiple changes preserve order', () {
      final bytes = SyncBinaryFormat.encode(
        deviceId: 'device-x',
        timestamp: 1,
        changes: [
          SyncChange(
            tableId: SyncTableId.transactions,
            recordId: 'first',
            action: SyncAction.upsert,
            data: {'n': 1},
          ),
          SyncChange(
            tableId: SyncTableId.transactions,
            recordId: 'second',
            action: SyncAction.delete,
          ),
          SyncChange(
            tableId: SyncTableId.transactions,
            recordId: 'third',
            action: SyncAction.upsert,
            data: {'n': 3},
          ),
        ],
      );

      final packet = SyncBinaryFormat.decode(bytes);
      expect(
        packet.changes.map((c) => c.recordId).toList(),
        ['first', 'second', 'third'],
      );
    });

    test('device id shorter than 36 bytes round trips exactly (padding trimmed)', () {
      final bytes = SyncBinaryFormat.encode(
        deviceId: 'abc',
        timestamp: 1,
        changes: [],
      );
      expect(SyncBinaryFormat.decode(bytes).deviceId, 'abc');
    });

    test('device id of exactly 36 bytes round trips exactly', () {
      final id36 = 'a1b2c3d4-e5f6-4789-9abc-def012345678'; // 36 chars
      expect(id36.length, 36);
      final bytes = SyncBinaryFormat.encode(
        deviceId: id36,
        timestamp: 1,
        changes: [],
      );
      expect(SyncBinaryFormat.decode(bytes).deviceId, id36);
    });

    test('record id at the 255-byte length-prefix limit round trips exactly', () {
      final longId = 'x' * 255;
      final bytes = SyncBinaryFormat.encode(
        deviceId: 'device-x',
        timestamp: 1,
        changes: [
          SyncChange(
            tableId: SyncTableId.categories,
            recordId: longId,
            action: SyncAction.upsert,
            data: {'ok': true},
          ),
        ],
      );
      final packet = SyncBinaryFormat.decode(bytes);
      expect(packet.changes.single.recordId, longId);
    });

    test('empty change list round trips to an empty change list', () {
      final bytes = SyncBinaryFormat.encode(
        deviceId: 'device-x',
        timestamp: 999,
        changes: [],
      );
      final packet = SyncBinaryFormat.decode(bytes);
      expect(packet.changes, isEmpty);
      expect(packet.timestamp, 999);
    });
  });

  group('malformed input is rejected, not silently accepted', () {
    test('empty byte array throws rather than returning an empty packet', () {
      expect(
        () => SyncBinaryFormat.decode(Uint8List(0)),
        throwsA(anything),
      );
    });

    test('non-gzip bytes throw', () {
      final plainText = Uint8List.fromList(utf8.encode('this is not gzip data'));
      expect(() => SyncBinaryFormat.decode(plainText), throwsA(anything));
    });

    test('gzip payload with a valid-but-wrong header throws FormatException', () {
      // Valid gzip stream, but the decompressed payload does not start with
      // the "SYNC" magic bytes.
      final wrongHeader = Uint8List.fromList(
        GZipEncoder().encode(utf8.encode('NOPE and then some padding bytes'))!,
      );
      expect(
        () => SyncBinaryFormat.decode(wrongHeader),
        throwsA(isA<FormatException>()),
      );
    });

    test('gzip payload shorter than the 4-byte header throws FormatException', () {
      final tooShort = Uint8List.fromList(GZipEncoder().encode([0x53, 0x59])!);
      expect(
        () => SyncBinaryFormat.decode(tooShort),
        throwsA(isA<FormatException>()),
      );
    });

    test('unsupported version byte throws FormatException', () {
      final valid = SyncBinaryFormat.encode(
        deviceId: 'device-x',
        timestamp: 1,
        changes: [],
      );
      final decompressed = GZipDecoder().decodeBytes(valid);
      decompressed[4] = 99; // version byte, right after the 4-byte header
      final tampered = Uint8List.fromList(
        GZipEncoder().encode(decompressed)!,
      );

      expect(
        () => SyncBinaryFormat.decode(tampered),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Unsupported sync version'),
          ),
        ),
      );
    });

    test('unknown table id byte is skipped and the rest of the packet survives',
        () {
      // Table ids are append-only, so a peer on a newer build sends ids this
      // build has never heard of. Failing the whole decode there (the old
      // `firstWhere` threw StateError) threw away every other change in the
      // packet along with the one unreadable block.
      final valid = SyncBinaryFormat.encode(
        deviceId: 'device-x',
        timestamp: 1,
        changes: [
          SyncChange(
            tableId: SyncTableId.styles,
            recordId: 'r1',
            action: SyncAction.upsert,
            data: {'x': 1},
          ),
          SyncChange(
            tableId: SyncTableId.transactions,
            recordId: 'tx-1',
            action: SyncAction.upsert,
            data: {'amount': 42},
          ),
        ],
      );
      final decompressed = GZipDecoder().decodeBytes(valid);
      // Layout: 4 header + 1 version + 36 deviceId + 8 timestamp + 4 count =
      // 53 bytes before the first change's table id byte.
      const tableIdOffset = 4 + 1 + 36 + 8 + 4;
      expect(decompressed[tableIdOffset], SyncTableId.styles.value);
      decompressed[tableIdOffset] = 200; // not a valid SyncTableId value
      final tampered = Uint8List.fromList(
        GZipEncoder().encode(decompressed)!,
      );

      final packet = SyncBinaryFormat.decode(tampered);

      expect(packet.changes, hasLength(1));
      expect(packet.changes.single.recordId, 'tx-1');
      expect(packet.changes.single.tableId, SyncTableId.transactions);
      expect(packet.changes.single.data, {'amount': 42});
    });

    test('unknown action byte is skipped without desyncing the byte stream',
        () {
      final valid = SyncBinaryFormat.encode(
        deviceId: 'device-x',
        timestamp: 1,
        changes: [
          SyncChange(
            tableId: SyncTableId.styles,
            recordId: 'r1',
            action: SyncAction.upsert,
            data: {'x': 1},
          ),
          SyncChange(
            tableId: SyncTableId.accounts,
            recordId: 'acc-1',
            action: SyncAction.upsert,
            data: {'name': 'Cash'},
          ),
        ],
      );
      final decompressed = GZipDecoder().decodeBytes(valid);
      // header/version/deviceId/timestamp/count, then table id (1) +
      // recordId length byte (1) + 'r1' (2) lands on the action byte.
      const actionOffset = 4 + 1 + 36 + 8 + 4 + 1 + 1 + 2;
      expect(decompressed[actionOffset], SyncAction.upsert.value);
      decompressed[actionOffset] = 77; // not a valid SyncAction value
      final tampered = Uint8List.fromList(
        GZipEncoder().encode(decompressed)!,
      );

      final packet = SyncBinaryFormat.decode(tampered);

      expect(packet.changes, hasLength(1));
      expect(packet.changes.single.recordId, 'acc-1');
    });

    test('a currencies change round-trips', () {
      // Table id 14, added so a currency created by CSV import reaches peers
      // instead of leaving them with transactions in an unknown code.
      final encoded = SyncBinaryFormat.encode(
        deviceId: 'device-x',
        timestamp: 7,
        changes: [
          SyncChange(
            tableId: SyncTableId.currencies,
            recordId: 'XBT',
            action: SyncAction.upsert,
            data: {'code': 'XBT', 'name': 'Bitcoin', 'type': 1},
          ),
        ],
      );

      final packet = SyncBinaryFormat.decode(encoded);

      expect(packet.changes.single.tableId, SyncTableId.currencies);
      expect(packet.changes.single.recordId, 'XBT');
      expect(packet.changes.single.data!['name'], 'Bitcoin');
    });

    test('truncated packet (change data cut short) throws rather than returning partial data', () {
      final valid = SyncBinaryFormat.encode(
        deviceId: 'device-x',
        timestamp: 1,
        changes: [
          SyncChange(
            tableId: SyncTableId.transactions,
            recordId: 'tx-1',
            action: SyncAction.upsert,
            data: {'description': 'a fairly long description field here'},
          ),
        ],
      );
      final decompressed = GZipDecoder().decodeBytes(valid);
      // Chop off the last 20 bytes: the declared dataLen no longer matches
      // the actual number of bytes available.
      final truncated = decompressed.sublist(0, decompressed.length - 20);
      final tamperedGzip = Uint8List.fromList(
        GZipEncoder().encode(truncated)!,
      );

      expect(
        () => SyncBinaryFormat.decode(tamperedGzip),
        throwsA(anything),
      );
    });
  });
}
