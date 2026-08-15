import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/services/server_sync_service.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/domain/entities/settings.dart' as domain;

/// The HTTP push used to select what to upload with
/// `modified_at > server_last_push_timestamp`, a reading of this device's wall
/// clock. Anything that entered the database carrying an older stamp — a row
/// handed over by the peer-to-peer file engine, anything written while the
/// clock was skewed forward and then corrected — was born below the mark and
/// was never offered to the server, on that sync or on any later one, with
/// nothing anywhere reporting it as unsent.
///
/// `sync_push_queue` replaces the clock: database triggers record one entry per
/// change, and an entry leaves only when the server has answered 200 for the
/// row that carries it. These tests pin the three properties that make that
/// safe — an old stamp is still sent, an acknowledged row stops being pending,
/// and an edit landing between the upload and the acknowledgement survives.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;
  late ServerSyncService service;

  /// One decoded JSON body per push request, in order.
  late List<Map<String, dynamic>> pushBodies;

  /// Status code the mock server answers a push with.
  late int pushStatus;

  /// Run inside the push handler, before it answers — the window between the
  /// upload leaving and the acknowledgement arriving.
  Future<void> Function()? duringPush;

  Map<String, dynamic> emptyPage() => {
    'changes': <String, dynamic>{},
    'server_timestamp': 1,
    'has_more': false,
  };

  /// The queue as it stands, newest last.
  Future<List<({int id, String table, String key})>> queue() async {
    final rows = await db
        .customSelect(
          'SELECT id, changed_table_name, record_key FROM sync_push_queue '
          'ORDER BY id',
        )
        .get();
    return rows
        .map(
          (r) => (
            id: r.read<int>('id'),
            table: r.read<String>('changed_table_name'),
            key: r.read<String>('record_key'),
          ),
        )
        .toList();
  }

  /// Every row of [table] across every push body so far.
  List<Map<String, dynamic>> pushed(String table) => pushBodies
      .expand((b) => (b[table] as List? ?? const []))
      .cast<Map<String, dynamic>>()
      .toList();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Drift opens the connection lazily, so onCreate — which seeds ~283k
    // exchange rates and only then creates the push-queue triggers — has not
    // run yet. Force it here, so the queue is empty and every entry a test
    // sees was made by that test.
    await db.select(db.styles).get();
    settingsRepository = LocalSettingsRepository(db);
    pushBodies = [];
    pushStatus = 200;
    duringPush = null;

    await settingsRepository.setSetting(
      const domain.Settings(
        key: 'server_sync_enabled',
        value: 'true',
        device: 'test-device',
      ),
    );

    service = ServerSyncService(
      database: db,
      settingsRepository: settingsRepository,
      httpClient: MockClient((request) async {
        if (request.method == 'POST') {
          pushBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          if (duringPush != null) {
            final hook = duringPush;
            duringPush = null;
            await hook!();
          }
          return http.Response('{"status":"ok"}', pushStatus);
        }
        return http.Response(jsonEncode(emptyPage()), 200);
      }),
    );

    // Enabling sync above is itself a settings write, and the triggers queued
    // it — correctly. Clear it so every entry a test counts is one that test
    // made; the entries a test cares about are all created after this line.
    await db.customStatement('DELETE FROM sync_push_queue');
  });

  tearDown(() async => db.close());

  /// A style written straight through SQL, the way both the file-sync importer
  /// and the pull's upserts write rows: no DAO, no bookkeeping call, and a
  /// `modified_at` chosen by whoever wrote it rather than by this device.
  Future<void> insertStyleRaw(String id, {required int modifiedAt}) {
    return db.customStatement(
      'INSERT INTO styles (id, name, color_hex, icon_name, icon_type, '
      'modified_at, is_deleted) '
      "VALUES ('$id', 'Style $id', '#123456', 'star', 0, $modifiedAt, 0)",
    );
  }

  test(
    'a row that arrives stamped before the last push is still pushed',
    () async {
      // The exact sequence that lost data. One clean sync first, which is what
      // used to move `server_last_push_timestamp` up to "now" — and only then a
      // row from a peer, carrying the timestamp of the device that wrote it. It
      // is born below the mark, so `modified_at > lastPush` never selects it
      // again: not on this sync, not on any later one, with nothing anywhere
      // reporting it as unsent.
      await service.sync();
      pushBodies = [];

      await insertStyleRaw('from-a-peer', modifiedAt: 1);
      await service.sync();

      expect(
        pushed('styles').map((r) => r['id']),
        contains('from-a-peer'),
        reason: 'what has been sent cannot be derived from a wall clock',
      );
    },
  );

  test('an acknowledged row stops being pending', () async {
    await insertStyleRaw('s1', modifiedAt: 1);
    expect(await service.getPendingChangesCount(), 1);

    await service.sync();

    expect(await queue(), isEmpty);
    expect(await service.getPendingChangesCount(), 0);

    // And it is not offered again: a second sync has nothing to say.
    pushBodies = [];
    await service.sync();
    expect(pushed('styles'), isEmpty);
  });

  test(
    'an edit landing between the upload and the acknowledgement stays pending',
    () async {
      await insertStyleRaw('s1', modifiedAt: 1);

      // The row changes after its old value has left the device but before the
      // server has confirmed it. Draining by table — or by any timestamp — would
      // delete this entry together with the one just uploaded, and the rename
      // would never be sent to anyone.
      duringPush = () => db.customStatement(
        "UPDATE styles SET name = 'Renamed mid-flight', modified_at = 5000 "
        "WHERE id = 's1'",
      );

      await service.sync();

      expect(
        (await queue()).map((e) => (e.table, e.key)),
        contains(('styles', 's1')),
        reason: 'the edit is unsent, so it has to still be queued',
      );
      expect(await service.getPendingChangesCount(), 1);

      // The next push carries the new value, not the one already acknowledged.
      pushBodies = [];
      await service.sync();
      expect(
        pushed('styles').where((r) => r['id'] == 's1').map((r) => r['name']),
        ['Renamed mid-flight'],
      );
      expect(await queue(), isEmpty);
    },
  );

  test('a push the server rejects leaves the row queued', () async {
    await insertStyleRaw('s1', modifiedAt: 1);
    pushStatus = 500;

    await expectLater(service.sync(), throwsA(isA<Exception>()));

    expect(
      (await queue()).map((e) => e.key),
      contains('s1'),
      reason: 'an unanswered upload is not an acknowledgement',
    );

    pushStatus = 200;
    pushBodies = [];
    await service.sync();
    expect(pushed('styles').map((r) => r['id']), contains('s1'));
    expect(await queue(), isEmpty);
  });

  test(
    'a composite-key row is found again from the key the trigger wrote',
    () async {
      // exchange_rates has no `id`: its key is four columns joined with `|`, and
      // the trigger and the push have to spell it the same way or the entry is
      // re-read and re-skipped on every sync forever.
      await db.customStatement(
        'INSERT INTO exchange_rates (from_currency_code, to_currency_code, '
        'rate, preset, date, modified_at) '
        "VALUES ('USD', 'EUR', 0.9, 7, 1700000000, 1)",
      );
      expect((await queue()).single.key, 'USD|EUR|1700000000|7');

      await service.sync();

      final rates = pushed(
        'exchange_rates',
      ).where((r) => r['preset'] == 7).toList();
      expect(rates, hasLength(1));
      expect(rates.single['fromCurrencyCode'], 'USD');
      expect(rates.single['toCurrencyCode'], 'EUR');
      expect(await queue(), isEmpty);
    },
  );

  test(
    'a device-local setting is never uploaded, and does not sit in the queue forever',
    () async {
      await settingsRepository.setSetting(
        const domain.Settings(
          key: 'server_sync_token',
          value: 'hunter2',
          device: 'test-device',
        ),
      );
      expect(
        (await queue()).where((e) => e.key == 'server_sync_token'),
        hasLength(1),
      );

      await service.sync();

      expect(
        pushed('settings').map((r) => r['key']),
        isNot(contains('server_sync_token')),
        reason: 'the sync token is this device\'s business, not the budget\'s',
      );
      expect(
        await queue(),
        isEmpty,
        reason:
            'an entry that is filtered out of the upload must still be '
            'drained, or it is counted as a backlog no sync can ever clear',
      );
    },
  );
}
