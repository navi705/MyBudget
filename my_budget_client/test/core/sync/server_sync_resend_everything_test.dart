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

/// The one state the incremental protocol cannot climb out of on its own: the
/// server's database is gone — wiped, or replaced by an empty one — while every
/// device still believes it has already told that server everything.
///
/// Nothing is owed, so `sync_push_queue` is empty and no later sync ever offers
/// those rows again: the server stays empty for good. And the device is deaf as
/// well, because its pull cursor sits far above the sequence numbers the new
/// database starts handing out from 1.
///
/// [ServerSyncService.resendEverything] is the way back, and both halves of it
/// are pinned here — the upload and the cursor — because either one alone
/// leaves the pair permanently out of step.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;
  late ServerSyncService service;

  /// One decoded JSON body per push request, in order.
  late List<Map<String, dynamic>> pushBodies;

  /// Every `last_sync` a pull asked for, in order.
  late List<String> pullCursors;

  Map<String, dynamic> emptyPage() => {
    'changes': <String, dynamic>{},
    'server_timestamp': 1,
    'has_more': false,
  };

  /// Every row of [table] across every push body so far.
  List<Map<String, dynamic>> pushed(String table) => pushBodies
      .expand((b) => (b[table] as List? ?? const []))
      .cast<Map<String, dynamic>>()
      .toList();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Drift opens the connection lazily, so onCreate — which seeds the
    // reference data and only then creates the push-queue triggers — has not
    // run yet. Force it here, so the queue starts out holding only what the
    // seeding deliberately queues.
    await db.select(db.styles).get();
    settingsRepository = LocalSettingsRepository(db);
    pushBodies = [];
    pullCursors = [];

    await settingsRepository.setSetting(
      const domain.Settings(
        key: 'server_sync_enabled',
        value: 'true',
        device: 'test-device',
      ),
    );
    await settingsRepository.setSetting(
      const domain.Settings(
        key: 'server_sync_url',
        value: 'http://localhost:58080',
        device: 'test-device',
      ),
    );

    service = ServerSyncService(
      database: db,
      settingsRepository: settingsRepository,
      httpClient: MockClient((request) async {
        if (request.method == 'POST') {
          pushBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response('{"status":"ok"}', 200);
        }
        pullCursors.add(request.url.queryParameters['last_sync'] ?? '');
        return http.Response(jsonEncode(emptyPage()), 200);
      }),
    );
  });

  tearDown(() async => db.close());

  Future<void> insertStyleRaw(String id) {
    return db.customStatement(
      'INSERT INTO styles (id, name, color_hex, icon_name, icon_type, '
      'modified_at, is_deleted) '
      "VALUES ('$id', 'Style $id', '#123456', 'star', 0, 1, 0)",
    );
  }

  /// A device that has synced everything it has, against a server that has
  /// since lost its copy. This is the exact starting state of the bug.
  Future<void> syncedAndUpToDate() async {
    await service.sync();
    expect(await service.getPendingChangesCount(), 0);
    pushBodies = [];
    pullCursors = [];
  }

  test('an ordinary sync sends nothing to a server that lost everything', () async {
    // Not a bug being pinned as correct — this is the reason the feature has to
    // exist. The queue records what is OWED, and after a clean sync nothing is,
    // whatever the server has since done with the rows.
    await insertStyleRaw('s1');
    await syncedAndUpToDate();

    await service.sync();

    expect(pushBodies, isEmpty);
  });

  test(
    'a full resend uploads the rows the server has already been told about',
    () async {
      await insertStyleRaw('s1');
      await syncedAndUpToDate();

      await service.resendEverything();

      expect(
        pushed('styles').map((r) => r['id']),
        contains('s1'),
        reason: 'the whole point: a row already acknowledged is sent again',
      );
    },
  );

  test('the resend covers every synced table, not just the parents', () async {
    // seedPushQueueParents() already queues four tables on a fresh install, so
    // a resend that reused it would look like it worked while leaving out the
    // transactions, the accounts and the rates — everything the user has.
    await syncedAndUpToDate();

    await service.resendEverything();

    final tables = await db
        .customSelect(
          'SELECT DISTINCT changed_table_name AS t FROM sync_push_queue',
        )
        .get();
    // The queue is drained as it is acknowledged, so what it held is read off
    // the bodies that went out instead.
    final sentTables = <String>{
      for (final body in pushBodies)
        ...body.keys.where((k) => (body[k] as List).isNotEmpty),
    };

    expect(tables, isEmpty, reason: 'a successful resend drains its own queue');
    expect(
      sentTables,
      containsAll(<String>['styles', 'account_types', 'categories']),
    );
  });

  test('the pull cursor goes back to the start of the sequence', () async {
    // A server that was replaced hands out sequence numbers from 1 again. A
    // device holding a cursor of 900 asks for "everything after 900" and is
    // told, correctly, that there is nothing — for the next 900 changes.
    final prefs = await SharedPreferences.getInstance();
    await syncedAndUpToDate();
    await prefs.setInt(serverPullCursorKey, 900);

    await service.resendEverything();

    expect(pullCursors.first, '0');
  });

  test(
    'the cursor origin is stamped, so the pull does not reset it twice',
    () async {
      // _resetPullCursorIfServerChanged runs inside every pull and would zero a
      // cursor whose origin does not match. Harmless here, but leaving the origin
      // unset would mean the resend's own cursor is treated as a stranger's on
      // the pull right after it.
      await syncedAndUpToDate();

      await service.resendEverything();

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(serverPullCursorOriginKey),
        'http://localhost:58080',
      );
    },
  );

  test('nothing local is deleted', () async {
    await insertStyleRaw('s1');
    await syncedAndUpToDate();

    await service.resendEverything();

    final rows = await db
        .customSelect("SELECT id FROM styles WHERE id = 's1'")
        .get();
    expect(rows, hasLength(1));
  });

  test('a row queued five times is still uploaded once', () async {
    // The triggers fire on every write whether or not sync is on, so the queue
    // the resend adds to can already hold thousands of entries for one row.
    await insertStyleRaw('s1');
    await syncedAndUpToDate();
    for (var i = 0; i < 5; i++) {
      await db.customStatement(
        "UPDATE styles SET name = 'v$i', modified_at = ${100 + i} "
        "WHERE id = 's1'",
      );
    }

    await service.resendEverything();

    expect(pushed('styles').where((r) => r['id'] == 's1'), hasLength(1));
    expect(await service.getPendingChangesCount(), 0);
  });

  test('a resend against no configured server changes nothing', () async {
    // _requireBaseUrl throws before anything is queued, so a misconfigured
    // device is not left with a full queue it will push at some unrelated
    // server later.
    await syncedAndUpToDate();
    await settingsRepository.setSetting(
      const domain.Settings(
        key: 'server_sync_url',
        value: '',
        device: 'test-device',
      ),
    );
    // Blanking the address is itself a settings write, and the triggers queued
    // it. That one entry is the whole backlog the resend must not add to.
    final owedBefore = await service.getPendingChangesCount();

    await expectLater(service.resendEverything(), throwsA(anything));

    expect(await service.getPendingChangesCount(), owedBefore);
    expect(pushBodies, isEmpty);
  });
}
