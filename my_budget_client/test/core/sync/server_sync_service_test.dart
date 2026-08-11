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

/// [ServerSyncService]'s wire-mapping logic (`_upsertTransaction`,
/// `_upsertAccount`, `_applyChanges`, `_pull`, `_push`) is private and
/// reachable only through [ServerSyncService.sync]. The service now takes its
/// `http.Client` through the constructor, so a [MockClient] can stand in for
/// the server and the whole pull loop runs here without touching the network.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;
  late ServerSyncService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Drift opens the connection lazily: onCreate/_seedData (which stamps
    // every seeded row, including all 283k exchange rates, with
    // DateTime.now() at seed time) does not actually run until the first
    // real query touches the DB. Force that here, before any test captures
    // a DateTime.now() watermark - otherwise seeding can run *after* the
    // watermark is captured, making seeded rows look newer than the
    // watermark and breaking every "pending changes" assertion below.
    await db.select(db.styles).get();
    settingsRepository = LocalSettingsRepository(db);
    service = ServerSyncService(
      database: db,
      settingsRepository: settingsRepository,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('sync() disabled path', () {
    test('returns immediately, without a network call, when no server_sync_enabled setting exists', () async {
      // _isEnabled() reads server_sync_enabled and treats anything other
      // than the literal string 'true' (including a missing setting) as
      // disabled - there is nothing here for sync() to reach the network
      // with, so a real http call would only happen if this test hangs or
      // throws a SocketException.
      await expectLater(service.sync(), completes);
    });

    test('stays disabled - and network-free - for any value other than the literal "true"', () async {
      await settingsRepository.setSetting(
        const domain.Settings(
          key: 'server_sync_enabled',
          value: 'false',
          device: 'test-device',
        ),
      );

      await expectLater(service.sync(), completes);
    });
  });

  group('getPendingChangesCount', () {
    Future<void> setWatermark(int value) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('server_last_push_timestamp', value);
    }

    test('is 0 once the watermark is at least as new as everything seeded', () async {
      // Drift opens its connection lazily: setUp()'s forcing query
      // (db.select(db.styles).get()) is what guarantees seeding has already
      // run by the time this watermark is captured. Without it, seeding
      // (which stamps every row with DateTime.now() at seed time) can run
      // *after* this watermark, making seeded rows look newer than it.
      final watermark = DateTime.now().millisecondsSinceEpoch;
      await setWatermark(watermark);

      expect(await service.getPendingChangesCount(), 0);
    });

    test('counts a row inserted after the watermark, summed across tables', () async {
      final watermark = DateTime.now().millisecondsSinceEpoch;
      await setWatermark(watermark);
      expect(await service.getPendingChangesCount(), 0);

      await db.stylesDao.insertStyle(
        StylesCompanion.insert(
          id: const Value('s1'),
          name: 'New Style',
          iconName: 'star',
          colorHex: '#123456',
        ),
      );
      expect(await service.getPendingChangesCount(), 1);

      await db.accountTypesDao.insertAccountType(
        AccountTypesCompanion.insert(
          id: const Value('at1'),
          name: 'New Account Type',
          languageCode: 'en',
        ),
      );
      expect(
        await service.getPendingChangesCount(),
        2,
        reason: 'the count sums matching rows across every synced table, not just one',
      );
    });

    test('a row modified exactly at the watermark is not counted (comparison is strict)', () async {
      await db.stylesDao.insertStyle(
        StylesCompanion.insert(
          id: const Value('s1'),
          name: 'New Style',
          iconName: 'star',
          colorHex: '#123456',
        ),
      );
      final style = await db.stylesDao.getStyleById('s1');
      await setWatermark(style!.modifiedAt);

      expect(await service.getPendingChangesCount(), 0);
    });
  });

  group('pull cursor', () {
    /// The pull URLs `sync()` asked for, in order. One entry per iteration of
    /// the pull loop.
    late List<Uri> pulls;

    /// The headers of each pull, same order as [pulls]. `http` lowercases
    /// header names on the way through, so look them up in lower case.
    late List<Map<String, String>> pullHeaders;

    /// One JSON body per pull, served in order. The last one is repeated if the
    /// loop asks for more pages than were queued, so a test that expects the
    /// loop to STOP fails by hanging on its own guard rather than by throwing
    /// an out-of-range error somewhere unrelated.
    late List<Map<String, dynamic>> pages;

    Map<String, dynamic> page({
      required int serverTimestamp,
      required bool hasMore,
      List<Map<String, dynamic>> styles = const [],
    }) {
      return {
        'changes': {'styles': styles},
        'server_timestamp': serverTimestamp,
        'has_more': hasMore,
      };
    }

    Map<String, dynamic> style(String id, {int modifiedAt = 1000}) {
      return {
        'id': id,
        'name': 'Pulled $id',
        'colorHex': '#abcdef',
        'iconName': 'star',
        'iconType': 0,
        'modifiedAt': modifiedAt,
        'isDeleted': false,
      };
    }

    setUp(() async {
      pulls = [];
      pullHeaders = [];
      pages = [];

      // Push is not what these tests are about, and the seeded DB carries
      // ~283k exchange rates. Parking the push watermark at "now" leaves the
      // push half of the cycle with nothing to send, so the only requests the
      // mock client sees are pulls. Pulled rows below carry small modifiedAt
      // values, which keeps them under this watermark too.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'server_last_push_timestamp',
        DateTime.now().millisecondsSinceEpoch,
      );

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
            return http.Response('{"status":"ok"}', 200);
          }
          pulls.add(request.url);
          pullHeaders.add(request.headers);
          final body = pages.isEmpty
              ? page(serverTimestamp: 0, hasMore: false)
              : pages[pulls.length <= pages.length
                    ? pulls.length - 1
                    : pages.length - 1];
          return http.Response(jsonEncode(body), 200);
        }),
      );
    });

    test('drops the pre-sequence cursor and re-pulls the budget from 0', () async {
      // The old key held a wall-clock millisecond value. Reused as a sequence
      // it would sit far above every server_seq the server will ever hand out,
      // so the client would pull nothing, forever, with no error anywhere.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('server_last_sync_timestamp', 1712345678901);
      pages = [
        page(serverTimestamp: 7, hasMore: false, styles: [style('s1')]),
      ];

      await service.sync();

      expect(pulls.single.queryParameters['last_sync'], '0');
      expect(
        prefs.containsKey('server_last_sync_timestamp'),
        isFalse,
        reason: 'the legacy key must be removed, not left to be picked up again',
      );
      expect(prefs.getInt(serverPullCursorKey), 7);
      expect(await db.stylesDao.getStyleById('s1'), isNotNull);
    });

    test('resumes from the stored sequence on the next sync', () async {
      pages = [
        page(serverTimestamp: 7, hasMore: false, styles: [style('s1')]),
        page(serverTimestamp: 0, hasMore: false),
      ];

      await service.sync();
      await service.sync();

      expect(pulls.map((u) => u.queryParameters['last_sync']), ['0', '7']);
    });

    test('follows the sequence across pages while has_more is set', () async {
      pages = [
        page(serverTimestamp: 5, hasMore: true, styles: [style('s1')]),
        page(serverTimestamp: 9, hasMore: false, styles: [style('s2')]),
      ];

      await service.sync();

      expect(pulls.map((u) => u.queryParameters['last_sync']), ['0', '5']);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(serverPullCursorKey), 9);
      expect(await db.stylesDao.getStyleById('s2'), isNotNull);
    });

    test('stops when the server hands back a cursor that does not advance', () async {
      // A server that keeps replying with the same high mark while still
      // claiming has_more would otherwise be re-asked for the identical page
      // until the 200-iteration cap - 200 full batches applied to the DB for
      // nothing.
      pages = [
        page(serverTimestamp: 5, hasMore: true, styles: [style('s1')]),
        page(serverTimestamp: 5, hasMore: true, styles: [style('s1')]),
      ];

      await service.sync();

      expect(pulls.length, 2);
    });

    test('sends the configured token as a bearer header, never in the URL', () async {
      await settingsRepository.setSetting(
        const domain.Settings(
          key: 'server_sync_token',
          value: 'sekret',
          device: 'test-device',
        ),
      );
      pages = [page(serverTimestamp: 0, hasMore: false)];

      await service.sync();

      expect(pulls.single.path, '/api/sync/pull');
      expect(pulls.single.queryParameters['limit'], '20000');
      expect(pullHeaders.single['authorization'], 'Bearer sekret');
      expect(
        pulls.single.toString(),
        isNot(contains('sekret')),
        reason: 'a token in the URL ends up in access and proxy logs',
      );
    });
  });
}
