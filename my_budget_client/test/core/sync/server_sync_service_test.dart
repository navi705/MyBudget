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
    test(
      'returns immediately, without a network call, when no server_sync_enabled setting exists',
      () async {
        // _isEnabled() reads server_sync_enabled and treats anything other
        // than the literal string 'true' (including a missing setting) as
        // disabled - there is nothing here for sync() to reach the network
        // with, so a real http call would only happen if this test hangs or
        // throws a SocketException.
        await expectLater(service.sync(), completes);
      },
    );

    test(
      'stays disabled - and network-free - for any value other than the literal "true"',
      () async {
        await settingsRepository.setSetting(
          const domain.Settings(
            key: 'server_sync_enabled',
            value: 'false',
            device: 'test-device',
          ),
        );

        await expectLater(service.sync(), completes);
      },
    );
  });

  group('getPendingChangesCount', () {
    /// Every setting written by these tests, so a count can talk about the row
    /// under test rather than about the harness.
    Future<int> settingEntries() async {
      final row = await db
          .customSelect(
            "SELECT COUNT(*) AS c FROM sync_push_queue "
            "WHERE changed_table_name = 'settings'",
          )
          .getSingle();
      return row.read<int>('c');
    }

    test(
      'is 0 on a fresh database: the bundled seed is not a pending change',
      () async {
        // onCreate seeds ~283k exchange rates and then creates the triggers, in
        // that order and deliberately: every install lays down the same rows, so
        // counting them as unsent would put a six-figure backlog in front of a
        // user who has not typed anything yet.
        expect(await service.getPendingChangesCount(), 0);
      },
    );

    test('counts a newly written row, summed across tables', () async {
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
        reason:
            'the count sums matching rows across every synced table, not just one',
      );
    });

    test('counts a row once no matter how many times it was edited', () async {
      await db.stylesDao.insertStyle(
        StylesCompanion.insert(
          id: const Value('s1'),
          name: 'New Style',
          iconName: 'star',
          colorHex: '#123456',
        ),
      );
      for (var i = 0; i < 3; i++) {
        await db.customStatement(
          "UPDATE styles SET name = 'Renamed $i', modified_at = ${2000 + i} "
          "WHERE id = 's1'",
        );
      }

      expect(
        await service.getPendingChangesCount(),
        1,
        reason:
            'four queue entries, but one row to upload - the number is '
            'shown to a user as work outstanding, not as keystrokes',
      );
    });

    test('a row modified below any clock watermark is still counted', () async {
      // The point of the queue. `modifiedAt` here is older than the oldest
      // seeded row, which is exactly the shape of a row arriving from a peer
      // through the file engine; the old count asked
      // `modified_at > server_last_push_timestamp` and answered 0.
      await db.customStatement(
        "INSERT INTO styles (id, name, color_hex, icon_name, icon_type, "
        "modified_at, is_deleted) VALUES ('old', 'From a peer', '#000000', "
        "'star', 0, 1, 0)",
      );

      expect(await service.getPendingChangesCount(), 1);
      expect(await settingEntries(), 0);
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
      List<Map<String, dynamic>> accounts = const [],
      List<Map<String, dynamic>> transactions = const [],
    }) {
      return {
        'changes': {
          'styles': styles,
          'accounts': accounts,
          'transactions': transactions,
        },
        'server_timestamp': serverTimestamp,
        'has_more': hasMore,
      };
    }

    Map<String, dynamic> account(String id, {int modifiedAt = 1000}) {
      return {
        'id': id,
        'name': 'Pulled $id',
        'balance': 0.0,
        'openingBalance': 100.0,
        'currencyCode': 'USD',
        'accountTypeId': 'account_type_checking',
        'creationDate': '2024-01-01T00:00:00.000',
        'modifiedAt': modifiedAt,
        'isDeleted': false,
      };
    }

    Map<String, dynamic> transaction(
      String id, {
      required String accountId,
      double amount = 25.0,
      int modifiedAt = 1000,
      Object? modifiedAtOverride,
    }) {
      return {
        'id': id,
        'description': 'Pulled $id',
        'amount': amount,
        'date': '2024-02-01T00:00:00.000',
        'accountId': accountId,
        'categoryId': '',
        'currencyCode': 'USD',
        'modifiedAt': modifiedAtOverride ?? modifiedAt,
        'isDeleted': false,
      };
    }

    /// How many rows the tables a page can touch are holding, plus the size of
    /// the push queue — the numbers a second apply of the same page must not
    /// move.
    Future<List<int>> tableCounts() async {
      final counts = <int>[];
      for (final table in [
        'styles',
        'accounts',
        'transactions',
        'sync_push_queue',
      ]) {
        final row = await db
            .customSelect('SELECT COUNT(*) AS c FROM $table')
            .getSingle();
        counts.add(row.read<int>('c'));
      }
      return counts;
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

    test(
      'drops the pre-sequence cursor and re-pulls the budget from 0',
      () async {
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
          reason:
              'the legacy key must be removed, not left to be picked up again',
        );
        expect(prefs.getInt(serverPullCursorKey), 7);
        expect(await db.stylesDao.getStyleById('s1'), isNotNull);
      },
    );

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

    test(
      'stops when the server hands back a cursor that does not advance',
      () async {
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
      },
    );

    test(
      'a page that fails half way applies nothing and leaves the cursor put',
      () async {
        // Invariant 6. `_applyChanges` is ONE transaction over all sixteen
        // tables and the caller advances the cursor only after it returns; both
        // halves of that have to hold. The poison is a transactions row whose
        // `modifiedAt` is a string, so the row that fails sits behind a styles
        // row and an accounts row that have already been written inside the same
        // transaction — the exact shape that a regression to one transaction per
        // table would commit and then lose the rest of.
        final prefs = await SharedPreferences.getInstance();
        pages = [
          page(
            serverTimestamp: 7,
            hasMore: false,
            styles: [style('s1')],
            accounts: [account('a1')],
            transactions: [
              transaction('t1', accountId: 'a1', modifiedAtOverride: 'later'),
            ],
          ),
          page(serverTimestamp: 7, hasMore: false, styles: [style('s2')]),
        ];

        await expectLater(service.sync(), throwsA(isA<TypeError>()));

        expect(
          await db.stylesDao.getStyleById('s1'),
          isNull,
          reason: 'the tables applied before the failure must roll back too',
        );
        expect(await db.accountsDao.getAccountById('a1'), isNull);
        expect(
          prefs.containsKey(serverPullCursorKey),
          isFalse,
          reason: 'a page that did not commit must not move the watermark',
        );

        // And the next sync asks for the same page again rather than skipping it.
        await service.sync();

        expect(pulls.map((u) => u.queryParameters['last_sync']), ['0', '0']);
        expect(await db.stylesDao.getStyleById('s2'), isNotNull);
      },
    );

    test(
      'applying the same page twice changes nothing the second time',
      () async {
        // Invariant 4. The second apply must be a no-op: no duplicated rows, no
        // doubled balance, and nothing left behind in sync_push_queue — the
        // queue matters because every upsert trips the push triggers, so a
        // replay that leaked entries would upload the server's own page back to
        // it on the next cycle.
        final identical = page(
          serverTimestamp: 7,
          hasMore: false,
          styles: [style('s1')],
          accounts: [account('a1')],
          transactions: [transaction('t1', accountId: 'a1')],
        );
        pages = [identical, identical];

        await service.sync();
        final afterFirst = await tableCounts();
        final balanceAfterFirst = (await db.accountsDao.getAccountById(
          'a1',
        ))!.balance;

        // The server hands back the same page from the same cursor - which is
        // also what a re-delivered page looks like.
        await service.sync();

        expect(await tableCounts(), afterFirst);
        expect(
          (await db.accountsDao.getAccountById('a1'))!.balance,
          balanceAfterFirst,
          reason:
              'a replayed transaction must not be counted into the balance twice',
        );
        expect(await db.stylesDao.getStyleById('s1'), isNotNull);
      },
    );

    test(
      'sends the configured token as a bearer header, never in the URL',
      () async {
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
      },
    );
  });
}
