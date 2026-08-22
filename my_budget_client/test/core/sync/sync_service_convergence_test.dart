import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:path/path.dart' as p;

/// Invariant 1: two devices that exchange every packet, in ANY order and with
/// any number of duplicate deliveries, end with identical rows in every synced
/// table.
///
/// Every other P2P test in this directory is one-directional and
/// single-delivery: A exports, B imports, one field of one row is asserted. A
/// rule that is merely deterministic per device passes all of them and still
/// leaves two real devices holding different data forever - which is exactly
/// what the `modifiedAt` tie used to do, and what nothing here would have
/// caught. So this suite compares FULL table dumps of both databases, under
/// three delivery schedules.
///
/// Each device gets its OWN folder and a packet is "delivered" by copying the
/// file across, which is what Syncthing does and what lets the test dictate the
/// order and the number of deliveries. Every clock the script writes is pinned
/// to a fixed value so that all six dumps (two devices x three schedules) are
/// comparable byte for byte: convergence means the merged state depends on the
/// set of changes alone, not on the route they took.
void main() {
  // `sync_record_keys.dart` and the exchange-rate DAO pin their DateFormat to
  // 'en' so a record id spells the same day on every device; a pinned locale
  // needs its CLDR data loaded, which `flutter test` does not do for us.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  /// Every table the P2P importer can write. `settings`, `sync_log`,
  /// `sync_processed_files` and `conflict_history` are deliberately absent:
  /// they are device-local bookkeeping and are SUPPOSED to differ.
  const syncedTables = <String>[
    'accounts',
    'account_types',
    'api_settings_table',
    'asset_entries',
    'categories',
    'currencies',
    'currency_designations',
    'custom_data_sources',
    'custom_themes',
    'exchange_rates',
    'inflation_rates',
    'styles',
    'transactions',
  ];

  /// Every row of every synced table, as sorted JSON, so two databases can be
  /// compared without knowing any table's primary key or row order.
  ///
  /// [tombstonePayload] false compares a soft-deleted row by identity, delete
  /// flag and clock alone, and ignores the columns underneath. Those columns
  /// legitimately differ and cannot be made to agree: a delete carries no
  /// payload, so the device that authored the edit a delete then beat keeps its
  /// own last value under the tombstone, while the device that never applied
  /// that edit keeps the value it had. Both agree the row is gone and both hide
  /// it everywhere it could be read, and only a delete that shipped the row it
  /// killed could make the dead bytes match. Live rows are always compared in
  /// full.
  Future<Map<String, List<String>>> dumpOf(
    AppDatabase db, {
    bool tombstonePayload = true,
  }) async {
    final dump = <String, List<String>>{};
    for (final table in syncedTables) {
      final rows = await db.customSelect('SELECT * FROM $table').get();
      dump[table] = [
        for (final row in rows)
          jsonEncode(
            Map.fromEntries(
              (!tombstonePayload && row.data['is_deleted'] == 1
                      ? {
                          'id': row.data['id'],
                          'is_deleted': row.data['is_deleted'],
                          'modified_at': row.data['modified_at'],
                        }
                      : row.data)
                  .entries
                  .sortedBy((e) => e.key),
            ),
          ),
      ]..sort();
    }
    return dump;
  }

  void expectSameDump(
    Map<String, List<String>> left,
    Map<String, List<String>> right,
    String what,
  ) {
    for (final table in syncedTables) {
      expect(left[table], right[table], reason: '$what: `$table` differs');
    }
  }

  Future<SyncService> configuredService(
    AppDatabase db,
    String deviceId,
    Directory folder,
  ) async {
    await db.settingsDao.setSetting(
      SettingsCompanion(
        key: const Value('local_device_id'),
        value: Value(deviceId),
      ),
    );
    final service = SyncService(db);
    await service.startSync(folder.path);
    // Kills the periodic export timer and the folder watcher, so every
    // export and import below happens exactly when the script says.
    await service.stopSync();
    return service;
  }

  /// Both installs lay the seed down under the same stable ids but stamp it
  /// with `DateTime.now()`, so the two copies differ in `modified_at` alone.
  /// Levelling them here is what makes "the databases are identical" a
  /// meaningful starting point, and drains the seed out of the export queues.
  Future<void> levelSeed(AppDatabase db) async {
    for (final table in syncedTables) {
      await db.customStatement(
        'UPDATE $table SET modified_at = 1, device_id = NULL',
      );
    }
    await db.customStatement('UPDATE sync_log SET exported = 1');
  }

  Future<void> stamp(
    AppDatabase db,
    String table,
    String whereSql,
    int modifiedAt,
  ) => db.customStatement('UPDATE $table SET modified_at = ? WHERE $whereSql', [
    modifiedAt,
  ]);

  Future<void> insertStyle(AppDatabase db, String id, String name) =>
      db.stylesDao.insertStyle(
        StylesCompanion.insert(
          id: Value(id),
          name: name,
          iconName: 'star',
          colorHex: '#123456',
        ),
      );

  Future<void> insertCategory(AppDatabase db, String id, String name) => db
      .categoriesDao
      .insertCategory(CategoriesCompanion.insert(id: Value(id), name: name));

  Future<void> insertAccount(AppDatabase db, String id) async {
    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    await db.accountsDao.insertAccount(
      AccountsCompanion.insert(
        id: Value(id),
        name: id,
        balance: 0.0,
        balanceMinor: const Value(0),
        currencyCode: 'EUR',
        currencyDesignationId: designationId,
        accountTypeId: accountTypeId,
        // Pinned: a creationDate of DateTime.now() would make the three
        // schedules incomparable for no reason of substance.
        creationDate: Value(DateTime(2024, 1, 1)),
      ),
    );
  }

  Future<void> addTransaction(
    AppDatabase db,
    String id,
    double amount,
    String accountId,
  ) async {
    final categoryId = (await db.select(db.categories).get()).first.id;
    await db.transaction(() async {
      await db.transactionsDao.insertTransaction(
        TransactionsCompanion.insert(
          id: Value(id),
          description: id,
          amount: amount,
          amountMinor: Value((amount * 100).round()),
          date: DateTime(2024, 6, 1),
          accountId: accountId,
          categoryId: categoryId,
          currencyCode: 'EUR',
        ),
      );
      await db.accountsDao.adjustBalance(
        accountId,
        amount,
        currencyCode: 'EUR',
      );
    });
  }

  Future<void> addRate(AppDatabase db, String to, double rate) =>
      db.exchangeRatesDao.addExchangeRate(
        ExchangeRatesCompanion.insert(
          fromCurrencyCode: 'USD',
          toCurrencyCode: to,
          rate: rate,
          preset: 7,
          date: DateTime(2024, 6, 1),
        ),
      );

  Future<Set<String>> packetNames(Directory folder) async => {
    for (final e in await folder.list().toList())
      if (e is File && e.path.endsWith('.sync')) p.basename(e.path),
  };

  Future<File> exportFrom(
    SyncService service,
    AppDatabase db,
    Directory folder,
  ) async {
    // Packets are named '${deviceId}_$timestamp.sync'; two exports inside one
    // millisecond would reuse a name.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final before = await packetNames(folder);
    await service.exportNow();
    await db.customStatement(
      'UPDATE sync_log SET exported = 1 WHERE exported = 0',
    );
    final written = (await packetNames(folder)).difference(before);
    expect(written, hasLength(1), reason: 'one export, one packet');
    return File(p.join(folder.path, written.single));
  }

  /// Copies a packet into the peer's folder and imports it. [prefix] gives a
  /// re-delivery a name the peer has not marked processed - the same file
  /// arriving again, which is what a resynced Syncthing folder produces.
  Future<void> deliver(
    File packet,
    Directory into,
    SyncService importer, {
    String prefix = '',
  }) async {
    await packet.copy(p.join(into.path, '$prefix${p.basename(packet.path)}'));
    await importer.importNow();
  }

  /// One full run: two fresh devices, the same scripted writes, the packets
  /// delivered according to [reverse]/[duplicate]. Returns both dumps.
  Future<(Map<String, List<String>>, Map<String, List<String>>)> runSchedule({
    required bool reverse,
    required bool duplicate,
  }) async {
    final folderA = await Directory.systemTemp.createTemp('mybudget_conv_a_');
    final folderB = await Directory.systemTemp.createTemp('mybudget_conv_b_');
    final dbA = AppDatabase.forTesting(NativeDatabase.memory());
    final dbB = AppDatabase.forTesting(NativeDatabase.memory());

    final serviceA = await configuredService(dbA, 'device-a', folderA);
    final serviceB = await configuredService(dbB, 'device-b', folderB);

    try {
      await levelSeed(dbA);
      await levelSeed(dbB);

      // --- rows both devices already agree on -------------------------------
      for (final db in [dbA, dbB]) {
        await insertStyle(db, 's-shared', 'Shared');
        await insertStyle(db, 's-race', 'Raced');
        await insertAccount(db, 'acc-1');
        await levelSeed(db);
      }

      // --- device A, offline batch 1 ---------------------------------------
      await insertStyle(dbA, 's-only-a', 'Only on A');
      await insertCategory(dbA, 'c-only-a', 'Only on A');
      await addTransaction(dbA, 'tx-a', 100.0, 'acc-1');
      await addRate(dbA, 'EUR', 1.1);
      await stamp(dbA, 'styles', "id = 's-only-a'", 2000);
      await stamp(dbA, 'categories', "id = 'c-only-a'", 2000);
      await stamp(dbA, 'transactions', "id = 'tx-a'", 2000);
      await stamp(dbA, 'exchange_rates', "to_currency_code = 'EUR'", 2000);
      await stamp(dbA, 'accounts', "id = 'acc-1'", 2100);
      final packetA1 = await exportFrom(serviceA, dbA, folderA);

      // --- device A, offline batch 2 ---------------------------------------
      // s-shared is edited at the SAME clock B edits it at, and s-race is
      // DELETED at the same clock B edits it at: two ties, one of them across
      // the delete/upsert boundary, which is precisely the pair that used to
      // leave the two devices permanently apart.
      await dbA.stylesDao.updateStyle(
        StylesCompanion(
          id: const Value('s-shared'),
          name: const Value('A version'),
          iconName: const Value('star'),
          colorHex: const Value('#123456'),
          modifiedAt: const Value(3000),
        ),
      );
      await dbA.stylesDao.deleteStyle(
        const StylesCompanion(id: Value('s-race')),
      );
      await dbA.customStatement(
        "UPDATE styles SET modified_at = 4000 WHERE id = 's-race'",
      );
      await dbA.customStatement(
        "UPDATE sync_log SET timestamp = 4000 "
        "WHERE record_id = 's-race' AND action = 'delete'",
      );
      final packetA2 = await exportFrom(serviceA, dbA, folderA);

      // --- device B, offline batch 1 ---------------------------------------
      await insertStyle(dbB, 's-only-b', 'Only on B');
      await insertCategory(dbB, 'c-only-b', 'Only on B');
      await addTransaction(dbB, 'tx-b', 50.0, 'acc-1');
      await addRate(dbB, 'GBP', 0.8);
      await stamp(dbB, 'styles', "id = 's-only-b'", 2000);
      await stamp(dbB, 'categories', "id = 'c-only-b'", 2000);
      await stamp(dbB, 'transactions', "id = 'tx-b'", 2000);
      await stamp(dbB, 'exchange_rates', "to_currency_code = 'GBP'", 2000);
      await stamp(dbB, 'accounts', "id = 'acc-1'", 2200);
      final packetB1 = await exportFrom(serviceB, dbB, folderB);

      // --- device B, offline batch 2 ---------------------------------------
      await dbB.stylesDao.updateStyle(
        StylesCompanion(
          id: const Value('s-shared'),
          name: const Value('B version'),
          iconName: const Value('star'),
          colorHex: const Value('#123456'),
          modifiedAt: const Value(3000),
        ),
      );
      await dbB.stylesDao.updateStyle(
        StylesCompanion(
          id: const Value('s-race'),
          name: const Value('B keeps it'),
          iconName: const Value('star'),
          colorHex: const Value('#123456'),
          modifiedAt: const Value(4000),
        ),
      );
      final packetB2 = await exportFrom(serviceB, dbB, folderB);

      // --- delivery --------------------------------------------------------
      final toB = reverse ? [packetA2, packetA1] : [packetA1, packetA2];
      final toA = reverse ? [packetB2, packetB1] : [packetB1, packetB2];
      for (final packet in toB) {
        await deliver(packet, folderB, serviceB);
        if (duplicate) {
          await deliver(packet, folderB, serviceB, prefix: 'again-');
        }
      }
      for (final packet in toA) {
        await deliver(packet, folderA, serviceA);
        if (duplicate) {
          await deliver(packet, folderA, serviceA, prefix: 'again-');
        }
      }

      return (await dumpOf(dbA), await dumpOf(dbB));
    } finally {
      await dbA.close();
      await dbB.close();
      for (final folder in [folderA, folderB]) {
        if (await folder.exists()) await folder.delete(recursive: true);
      }
    }
  }

  test('two devices converge whatever order the packets arrive in, however '
      'many times', () async {
    final (naturalA, naturalB) = await runSchedule(
      reverse: false,
      duplicate: false,
    );
    expectSameDump(naturalA, naturalB, 'in-order delivery');

    // A tie must not be settled by the direction of the last packet, and the
    // winner is the higher device id on both sides: 'device-b' > 'device-a'.
    expect(
      naturalA['styles']!.where((row) => row.contains('B version')),
      hasLength(1),
    );
    expect(
      naturalA['styles']!.where((row) => row.contains('B keeps it')),
      hasLength(1),
      reason: "B's edit ties with A's delete and wins it on both devices",
    );

    final (reversedA, reversedB) = await runSchedule(
      reverse: true,
      duplicate: false,
    );
    expectSameDump(reversedA, reversedB, 'reverse-order delivery');
    expectSameDump(
      naturalA,
      reversedA,
      'reversing the order changed the state',
    );

    final (replayedA, replayedB) = await runSchedule(
      reverse: true,
      duplicate: true,
    );
    expectSameDump(replayedA, replayedB, 'reverse order, every packet twice');
    expectSameDump(
      naturalA,
      replayedA,
      'replaying every packet changed the state',
    );
  });

  /// [exportFrom] for a device that may have nothing to say.
  ///
  /// The generated script can hand a whole batch to one device, and it can also
  /// leave a device holding changes that cancel out — an insert the same device
  /// deleted before the export, which the exporter drops and logs as "all
  /// changes were skipped". Either way no packet is written, which is correct
  /// and is not what [exportFrom]'s one-export-one-packet assertion is for.
  Future<File?> exportMaybe(
    SyncService service,
    AppDatabase db,
    Directory folder,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final before = await packetNames(folder);
    await service.exportNow();
    await db.customStatement(
      'UPDATE sync_log SET exported = 1 WHERE exported = 0',
    );
    final written = (await packetNames(folder)).difference(before);
    expect(written.length, lessThanOrEqualTo(1), reason: 'one export at most');
    return written.isEmpty ? null : File(p.join(folder.path, written.single));
  }

  /// The same invariant, driven by a script nobody wrote by hand.
  ///
  /// [runSchedule] above is a hand-built worst case: it converges because
  /// someone thought of the delete/upsert tie. This one generates its writes
  /// from [seed] — which table, which row, which clock, on which device — so
  /// the interleavings it hits are ones nobody chose. Every clock it writes is
  /// still pinned to a value the seed decides, and never to `DateTime.now()`,
  /// which is what lets two runs of the SAME seed under DIFFERENT delivery
  /// orders be compared row for row: convergence means the merged state is a
  /// function of the changes alone.
  ///
  /// The clock the script hands out only ever moves FORWARD, and it is shared
  /// by both devices — one story, told in order. That is not a convenience: two
  /// writes to one row from one device whose second stamp is LOWER than its
  /// first cannot converge under last-write-wins by construction, because the
  /// peer that already holds the higher stamp is right to keep it and the
  /// author has no way to say otherwise. Real devices do not do that (a local
  /// write always carries a clock at least as high as the write before it on
  /// the same device); a generator that draws stamps at random does, and would
  /// be reporting a limitation of wall-clock LWW as a defect in this code.
  ///
  /// Ties are still forced, because they are the case that actually broke — but
  /// only ACROSS devices, where they are what a real pair of clocks produces
  /// and where the device-id tie-break is the rule under test.
  Future<(Map<String, List<String>>, Map<String, List<String>>)> runRandom({
    required int seed,
    required bool reverseDelivery,
    required bool duplicate,
  }) async {
    var state = seed & 0x7fffffff;
    int next(int bound) {
      state = (state * 1103515245 + 12345) & 0x7fffffff;
      return state % bound;
    }

    var clock = 1000;
    String? lastDevice;
    const pool = ['s-p0', 's-p1', 's-p2'];
    // What each device has deleted LOCALLY. A deleted style is gone from every
    // screen that could edit it, so the script does not edit one either — and
    // it must not: `_getRecordData` returns null for a soft-deleted row, so the
    // edit would raise that device's clock and export nothing, leaving a stamp
    // no peer can ever reach (see docs/sync-findings.md F38).
    final deleted = <String, Set<String>>{'a': {}, 'b': {}};
    const currencies = ['EUR', 'GBP', 'JPY'];

    final folderA = await Directory.systemTemp.createTemp('mybudget_rnd_a_');
    final folderB = await Directory.systemTemp.createTemp('mybudget_rnd_b_');
    final dbA = AppDatabase.forTesting(NativeDatabase.memory());
    final dbB = AppDatabase.forTesting(NativeDatabase.memory());
    final serviceA = await configuredService(dbA, 'device-a', folderA);
    final serviceB = await configuredService(dbB, 'device-b', folderB);

    /// A delete has TWO clocks — the row's `modified_at` and the tombstone's
    /// `sync_log.timestamp` — and the importer reads the second one. Both are
    /// pinned for the same reason every other stamp here is.
    Future<void> deleteStyleAt(AppDatabase db, String id, int at) async {
      await db.stylesDao.deleteStyle(StylesCompanion(id: Value(id)));
      await db.customStatement(
        'UPDATE styles SET modified_at = ? WHERE id = ?',
        [at, id],
      );
      await db.customStatement(
        "UPDATE sync_log SET timestamp = ? "
        "WHERE record_id = ? AND action = 'delete'",
        [at, id],
      );
    }

    Future<void> applyOp(AppDatabase db, String device, int index) async {
      // A tie only when the previous write came from the OTHER device, so the
      // clock never goes backwards for any one device.
      final tie = lastDevice != null && lastDevice != device && next(3) == 0;
      if (!tie) clock += 10;
      lastDevice = device;
      final at = clock;
      switch (next(6)) {
        case 0:
          final id = 's-$device-$index';
          await insertStyle(db, id, 'New $index');
          await stamp(db, 'styles', "id = '$id'", at);
        case 1:
          final id = pool[next(pool.length)];
          if (deleted[device]!.contains(id)) return;
          await db.stylesDao.updateStyle(
            StylesCompanion(
              id: Value(id),
              name: Value('$device edit $index'),
              iconName: const Value('star'),
              colorHex: const Value('#123456'),
              modifiedAt: Value(at),
            ),
          );
        case 2:
          final id = pool[next(pool.length)];
          if (deleted[device]!.contains(id)) return;
          deleted[device]!.add(id);
          await deleteStyleAt(db, id, at);
        case 3:
          final id = 'c-$device-$index';
          await insertCategory(db, id, 'Cat $index');
          await stamp(db, 'categories', "id = '$id'", at);
        case 4:
          final id = 'tx-$device-$index';
          await addTransaction(db, id, 10.0 + index, 'acc-1');
          await stamp(db, 'transactions', "id = '$id'", at);
          await stamp(db, 'accounts', "id = 'acc-1'", at);
        default:
          final to = currencies[next(currencies.length)];
          await addRate(db, to, 1.0 + index / 100);
          await stamp(db, 'exchange_rates', "to_currency_code = '$to'", at);
      }
    }

    try {
      await levelSeed(dbA);
      await levelSeed(dbB);

      // The rows both devices start out agreeing on, so that an edit on one
      // and a delete on the other are edits to the SAME row.
      for (final db in [dbA, dbB]) {
        for (final id in pool) {
          await insertStyle(db, id, 'Pooled $id');
        }
        await insertAccount(db, 'acc-1');
        await levelSeed(db);
      }

      final fromA = <File>[];
      final fromB = <File>[];
      for (var index = 0; index < 20; index++) {
        final onA = next(2) == 0;
        await applyOp(onA ? dbA : dbB, onA ? 'a' : 'b', index);
        // Export every other op, so a packet carries one or two changes and
        // the batch boundaries fall somewhere the seed picked.
        if (index.isOdd) {
          final a = await exportMaybe(serviceA, dbA, folderA);
          if (a != null) fromA.add(a);
          final b = await exportMaybe(serviceB, dbB, folderB);
          if (b != null) fromB.add(b);
        }
      }
      final lastA = await exportMaybe(serviceA, dbA, folderA);
      if (lastA != null) fromA.add(lastA);
      final lastB = await exportMaybe(serviceB, dbB, folderB);
      if (lastB != null) fromB.add(lastB);

      final toB = reverseDelivery ? fromA.reversed.toList() : fromA;
      final toA = reverseDelivery ? fromB.reversed.toList() : fromB;
      for (final packet in toB) {
        await deliver(packet, folderB, serviceB);
        if (duplicate) {
          await deliver(packet, folderB, serviceB, prefix: 'again-');
        }
      }
      for (final packet in toA) {
        await deliver(packet, folderA, serviceA);
        if (duplicate) {
          await deliver(packet, folderA, serviceA, prefix: 'again-');
        }
      }

      return (
        await dumpOf(dbA, tombstonePayload: false),
        await dumpOf(dbB, tombstonePayload: false),
      );
    } finally {
      await dbA.close();
      await dbB.close();
      for (final folder in [folderA, folderB]) {
        if (await folder.exists()) await folder.delete(recursive: true);
      }
    }
  }

  test(
    'a generated write script converges under every delivery order',
    () async {
      // Six seeds rather than one: a single script is a single interleaving,
      // and the point of generating it is to walk several. Each seed is checked
      // three ways — both devices agree, and the state they agree on does not
      // depend on the order the packets arrived in or on how many times.
      for (final seed in [1, 7, 42, 99, 404, 2026]) {
        final (naturalA, naturalB) = await runRandom(
          seed: seed,
          reverseDelivery: false,
          duplicate: false,
        );
        expectSameDump(naturalA, naturalB, 'seed $seed, in order');

        final (reversedA, reversedB) = await runRandom(
          seed: seed,
          reverseDelivery: true,
          duplicate: false,
        );
        expectSameDump(reversedA, reversedB, 'seed $seed, reversed');
        expectSameDump(
          naturalA,
          reversedA,
          'seed $seed changed with the order',
        );

        final (replayedA, replayedB) = await runRandom(
          seed: seed,
          reverseDelivery: true,
          duplicate: true,
        );
        expectSameDump(
          replayedA,
          replayedB,
          'seed $seed, reversed and doubled',
        );
        expectSameDump(naturalA, replayedA, 'seed $seed changed on replay');
      }
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
