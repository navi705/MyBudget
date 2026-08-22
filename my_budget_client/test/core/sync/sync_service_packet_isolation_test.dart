import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_binary_format.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';

/// What one bad change inside an otherwise good packet may cost.
///
/// A packet used to be applied change by change with nothing around the loop:
/// the first change that threw committed everything before it, dropped
/// everything after it, and left the file unmarked - so the next scan replayed
/// the same prefix, threw at the same change, and after three attempts the
/// remaining changes were lost for good while the prefix stayed committed. That
/// is the one outcome no policy allows: neither all-or-nothing nor
/// skip-the-bad-one.
///
/// The policy pinned here is the decoder's own, extended to the payload: an
/// unknown table id or action is skipped rather than thrown on, so a change
/// this build cannot convert is skipped too, inside a transaction that makes
/// anything escaping that guard all-or-nothing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase db;
  late SyncService service;

  setUp(() async {
    syncFolder = await Directory.systemTemp.createTemp(
      'mybudget_sync_isolation_',
    );
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.settingsDao.setSetting(
      SettingsCompanion(
        key: const Value('local_device_id'),
        value: const Value('device-local'),
      ),
    );
    service = SyncService(db);
    // startSync() does one import pass and then stopSync() kills the periodic
    // export timer and the folder watcher, so each test drives importNow()
    // itself and nothing runs behind its back.
    await service.startSync(syncFolder.path);
    await service.stopSync();
  });

  tearDown(() async {
    await db.close();
    if (await syncFolder.exists()) {
      await syncFolder.delete(recursive: true);
    }
  });

  Future<void> writePacket(String name, List<SyncChange> changes) async {
    final bytes = SyncBinaryFormat.encode(
      deviceId: 'device-peer',
      timestamp: 1,
      changes: changes,
    );
    await File('${syncFolder.path}/$name').writeAsBytes(bytes);
  }

  SyncChange styleChange(String id, String name, {Object? iconType = 0}) =>
      SyncChange(
        tableId: SyncTableId.styles,
        recordId: id,
        action: SyncAction.upsert,
        data: {
          'id': id,
          'name': name,
          'colorHex': '#abcdef',
          'iconName': 'star',
          'iconType': iconType,
          'modifiedAt': 5000,
          'isDeleted': false,
        },
      );

  Future<Style?> styleRow(String id) =>
      (db.select(db.styles)..where((t) => t.id.equals(id))).getSingleOrNull();

  test(
    'a change that cannot be converted costs only itself, not the rest of the packet',
    () async {
      await writePacket('peer_mixed.sync', [
        styleChange('s-before', 'Before The Bad One'),
        // `_transactionFromJson` reads `(json['amount'] as num).toDouble()`, so a
        // null amount throws a TypeError before a single column is written -
        // a corrupt file, or a field a peer failed to fill.
        SyncChange(
          tableId: SyncTableId.transactions,
          recordId: 't-bad',
          action: SyncAction.upsert,
          data: {
            'id': 't-bad',
            'description': 'No amount at all',
            'amount': null,
            'date': DateTime(2026, 1, 1).toIso8601String(),
            'modifiedAt': 5000,
            'isDeleted': false,
          },
        ),
        styleChange('s-after', 'After The Bad One'),
      ]);

      await expectLater(service.importNow(), completes);

      expect((await styleRow('s-before'))?.name, 'Before The Bad One');
      expect(
        (await styleRow('s-after'))?.name,
        'After The Bad One',
        reason: 'one unconvertible change must not cost the changes behind it',
      );
      final bad = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals('t-bad'))).getSingleOrNull();
      expect(bad, isNull, reason: 'the unconvertible change itself is skipped');
    },
  );

  test(
    'a packet with an unconvertible change is still marked processed',
    () async {
      await writePacket('peer_marked.sync', [
        SyncChange(
          tableId: SyncTableId.transactions,
          recordId: 't-bad',
          action: SyncAction.upsert,
          data: {'id': 't-bad', 'amount': null, 'modifiedAt': 5000},
        ),
        styleChange('s-good', 'Landed'),
      ]);

      await service.importNow();
      // A second scan must find nothing left to do. Before, the packet threw, was
      // never marked, and every scan re-applied the part of it that did convert.
      await service.importNow();

      expect(
        await db.syncProcessedFilesDao.isProcessed('peer_marked.sync'),
        isTrue,
        reason:
            'a packet whose applicable changes were applied is done with, '
            'and replaying it forever only re-writes conflict history',
      );
      expect((await styleRow('s-good'))?.name, 'Landed');
    },
  );

  test('an upsert carrying no payload is skipped, not dereferenced', () async {
    // The binary format permits DATA_LEN = 0 on any action, so this is a
    // well-formed packet, not a corrupt one - `change.data!` still threw a null
    // check error out of the apply loop and took the rest of the packet with
    // it.
    await writePacket('peer_nodata.sync', [
      SyncChange(
        tableId: SyncTableId.styles,
        recordId: 's-empty',
        action: SyncAction.upsert,
      ),
      styleChange('s-follows', 'Follows An Empty Upsert'),
    ]);

    await expectLater(service.importNow(), completes);

    expect(await styleRow('s-empty'), isNull);
    expect((await styleRow('s-follows'))?.name, 'Follows An Empty Upsert');
  });

  test(
    'an enum index this build does not have falls back instead of throwing',
    () async {
      // Enums travel as their index and enum members are append-only, so a peer
      // on a newer build sends indices this one has never heard of. IconType has
      // two members, CategoryType three.
      await writePacket('peer_enum.sync', [
        styleChange('s-future-icon', 'From A Newer Build', iconType: 99),
        SyncChange(
          tableId: SyncTableId.categories,
          recordId: 'c-future-type',
          action: SyncAction.upsert,
          data: {
            'id': 'c-future-type',
            'name': 'Category From A Newer Build',
            'type': -1,
            'modifiedAt': 5000,
            'isDeleted': false,
          },
        ),
        styleChange('s-last', 'Last In The Packet'),
      ]);

      await expectLater(service.importNow(), completes);

      final style = await styleRow('s-future-icon');
      expect(style, isNotNull);
      expect(
        style!.iconType,
        IconType.values.first,
        reason:
            'an out-of-range index resolves to the same value a missing key '
            'always did, rather than failing the packet',
      );
      final category = await (db.select(
        db.categories,
      )..where((t) => t.id.equals('c-future-type'))).getSingleOrNull();
      expect(category, isNotNull);
      expect((await styleRow('s-last'))?.name, 'Last In The Packet');
    },
  );
}
