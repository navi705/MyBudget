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

/// The correctness properties of the HTTP half of server sync: that one cycle
/// runs at a time, that a pull does not bounce its own page back at the server,
/// that the client resolves a conflict exactly the way the server does, that a
/// field a sender leaves out is not treated as an erasure, and that a date
/// survives the trip in both directions.
///
/// Everything here drives the real [ServerSyncService.sync] against a
/// [MockClient] standing in for the server, because the pull-apply and push
/// paths are private and that is the only honest way in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late LocalSettingsRepository settingsRepository;
  late ServerSyncService service;

  /// One entry per pull request the cycle issued.
  late List<Uri> pulls;

  /// One decoded JSON body per push request, in order.
  late List<Map<String, dynamic>> pushBodies;

  /// Pages served to the pull loop, consumed front to back; an empty page is
  /// served once they run out, which is what stops the loop.
  late List<Map<String, dynamic>> pages;

  /// Runs inside the pull handler before it answers — the window between the
  /// request leaving and the page being applied.
  Future<void> Function()? duringPull;

  Map<String, dynamic> page(
    Map<String, List<Map<String, dynamic>>> changes, {
    int serverTimestamp = 1,
    bool hasMore = false,
  }) => {
    'changes': changes,
    'server_timestamp': serverTimestamp,
    'has_more': hasMore,
  };

  /// Every row of [table] across every push body so far.
  List<Map<String, dynamic>> pushed(String table) => pushBodies
      .expand((b) => (b[table] as List? ?? const []))
      .cast<Map<String, dynamic>>()
      .toList();

  Future<List<({String table, String key})>> queue() async {
    final rows = await db
        .customSelect(
          'SELECT changed_table_name, record_key FROM sync_push_queue '
          'ORDER BY id',
        )
        .get();
    return rows
        .map(
          (r) => (
            table: r.read<String>('changed_table_name'),
            key: r.read<String>('record_key'),
          ),
        )
        .toList();
  }

  /// A style written straight through SQL, the way a peer's row or a pull's
  /// upsert lands: a `modified_at` and a `device_id` chosen by whoever wrote
  /// it, not by this device.
  Future<void> insertStyleRaw(
    String id, {
    required int modifiedAt,
    String name = 'Local',
    String? deviceId,
    bool isDeleted = false,
  }) {
    return db.customInsert(
      'INSERT INTO styles (id, name, color_hex, icon_name, icon_type, '
      'modified_at, device_id, is_deleted) VALUES (?, ?, ?, ?, 0, ?, ?, ?)',
      variables: [
        Variable.withString(id),
        Variable.withString(name),
        Variable.withString('#123456'),
        Variable.withString('star'),
        Variable.withInt(modifiedAt),
        Variable(deviceId),
        Variable.withBool(isDeleted),
      ],
      updates: {db.styles},
    );
  }

  Map<String, dynamic> styleJson(
    String id, {
    required int modifiedAt,
    String name = 'From the server',
    String? deviceId,
  }) => {
    'id': id,
    'name': name,
    'colorHex': '#abcdef',
    'iconName': 'star',
    'iconType': 0,
    'modifiedAt': modifiedAt,
    'deviceId': deviceId,
    'isDeleted': false,
  };

  Future<void> setEnabled(bool enabled) => settingsRepository.setSetting(
    domain.Settings(
      key: 'server_sync_enabled',
      value: enabled ? 'true' : 'false',
      device: 'test-device',
    ),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Drift opens lazily, so onCreate — which seeds ~283k exchange rates and
    // only then creates the push-queue triggers — has not run yet. Force it
    // here so every queue entry a test sees was made by that test.
    await db.select(db.styles).get();
    settingsRepository = LocalSettingsRepository(db);
    pulls = [];
    pushBodies = [];
    pages = [];
    duringPull = null;

    await setEnabled(true);

    service = ServerSyncService(
      database: db,
      settingsRepository: settingsRepository,
      httpClient: MockClient((request) async {
        if (request.method == 'POST') {
          pushBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response('{"status":"ok"}', 200);
        }
        pulls.add(request.url);
        if (duringPull != null) {
          final hook = duringPull;
          duringPull = null;
          await hook!();
        }
        return http.Response(
          jsonEncode(pages.isEmpty ? page(const {}) : pages.removeAt(0)),
          200,
        );
      }),
    );

    // Enabling sync above is a settings write, and the triggers queued it —
    // correctly. Clear it so every entry a test counts is one that test made.
    await db.customStatement('DELETE FROM sync_push_queue');
  });

  tearDown(() async {
    service.dispose();
    await db.close();
  });

  group('one cycle at a time', () {
    test(
      'two sync() calls that overlap run a single cycle, not two in parallel',
      () async {
        // The guard used to be read AFTER `await _isEnabled()`, which is a real
        // database round trip. Startup's sync() and the socket's sync() both
        // suspended on it, both woke to a clear guard, and two whole cycles ran
        // side by side: the same page pulled and applied twice, the same queue
        // uploaded twice, and one cycle restoring `PRAGMA foreign_keys` while
        // the other was still writing.
        await insertStyleRaw('typed-locally', modifiedAt: 1);
        pages = [
          page({
            'styles': [styleJson('from-the-server', modifiedAt: 9000)],
          }),
        ];

        final first = service.sync();
        final second = service.sync();
        await Future.wait([first, second]);

        expect(pulls, hasLength(1), reason: 'one cycle means one pull');
        expect(
          pushBodies,
          hasLength(1),
          reason: 'and one upload of the one queued row',
        );
        expect(await db.stylesDao.getStyleById('from-the-server'), isNotNull);
      },
    );
  });

  group('a pull does not bounce its own page back', () {
    test(
      'nothing the pull applied is uploaded, and the queue ends empty',
      () async {
        // Every upsert the pull performs trips the push-queue triggers, and the
        // push reads its ceiling after the pull has committed — so a device that
        // downloaded a 20 000-row page POSTed the identical 20 000 rows straight
        // back at the server that had just sent them, for the server's own
        // last-write-wins guard to discard one by one.
        pages = [
          page({
            'styles': [styleJson('from-the-server', modifiedAt: 9000)],
          }),
        ];

        await service.sync();

        expect(await db.stylesDao.getStyleById('from-the-server'), isNotNull);
        expect(
          pushBodies,
          isEmpty,
          reason: 'the server already has these rows',
        );
        expect(await queue(), isEmpty);
        expect(
          await service.getPendingChangesCount(),
          0,
          reason:
              'a pull that succeeded must not leave a backlog the user never '
              'created',
        );
      },
    );

    test('an edit made in the same window is not swallowed with it', () async {
      // The suppression is a mark read at the top of the pull transaction and a
      // delete of everything above it at the bottom. A row the user wrote while
      // the page was still in flight is queued below that mark, so it survives
      // — and is the only thing this cycle uploads.
      pages = [
        page({
          'styles': [styleJson('from-the-server', modifiedAt: 9000)],
        }),
      ];
      duringPull = () => insertStyleRaw(
        'typed-mid-pull',
        modifiedAt: 8000,
        name: 'Typed while the page was in flight',
      );

      await service.sync();

      expect(pushed('styles').map((r) => r['id']), ['typed-mid-pull']);
      expect(await queue(), isEmpty, reason: 'and it was acknowledged');
    });
  });

  group('conflict resolution matches the server, rule for rule', () {
    test('a tie is broken by device id, in both directions', () async {
      // Both sides now evaluate `(modified_at, device_id)`. With the strict `>`
      // the client used to use, a tie left the client keeping its own row while
      // the server kept the other one — and because a rejected push never moves
      // the server's sequence, neither device was ever handed the other's
      // version again. Permanent, silent divergence.
      await insertStyleRaw(
        's1',
        modifiedAt: 5000,
        name: 'Written on dev-b',
        deviceId: 'dev-b',
      );

      pages = [
        page({
          'styles': [
            styleJson(
              's1',
              modifiedAt: 5000,
              name: 'Written on dev-a',
              deviceId: 'dev-a',
            ),
          ],
        }),
      ];
      await service.sync();

      expect(
        (await db.stylesDao.getStyleById('s1'))!.name,
        'Written on dev-b',
        reason: "'dev-a' loses the tie to 'dev-b'",
      );

      pages = [
        page(serverTimestamp: 2, {
          'styles': [
            styleJson(
              's1',
              modifiedAt: 5000,
              name: 'Written on dev-c',
              deviceId: 'dev-c',
            ),
          ],
        }),
      ];
      await service.sync();

      expect(
        (await db.stylesDao.getStyleById('s1'))!.name,
        'Written on dev-c',
        reason:
            "'dev-c' wins the same tie — the rule is the ordering of the ids, "
            'not the order the rows arrived in',
      );
    });

    test('a row with no device id loses a tie to one that has one', () async {
      // COALESCE(device_id, ''), so a row written before the column existed
      // still takes part in the comparison instead of turning it into NULL.
      await insertStyleRaw('s2', modifiedAt: 5000, name: 'Anonymous');

      pages = [
        page({
          'styles': [
            styleJson(
              's2',
              modifiedAt: 5000,
              name: 'From a named device',
              deviceId: 'dev-a',
            ),
          ],
        }),
      ];
      await service.sync();

      expect(
        (await db.stylesDao.getStyleById('s2'))!.name,
        'From a named device',
      );
    });
  });

  group('a field the sender left out is not an erasure', () {
    late String categoryId;

    setUp(() async {
      categoryId = (await db.select(db.categories).get()).first.id;
      final designationId =
          (await db.select(db.currencyDesignations).get()).first.id;
      final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
      await db.accountsDao.insertAccount(
        AccountsCompanion.insert(
          id: const Value('a1'),
          name: 'Current',
          balance: 0,
          balanceMinor: const Value(0),
          currencyCode: 'EUR',
          currencyDesignationId: designationId,
          accountTypeId: accountTypeId,
        ),
      );
      await db.customStatement('DELETE FROM sync_push_queue');
    });

    Future<Transaction> transaction(String id) =>
        (db.select(db.transactions)..where((t) => t.id.equals(id))).getSingle();

    Map<String, dynamic> transactionJson(int modifiedAt, String description) =>
        {
          'id': 't1',
          'description': description,
          'amount': -25.5,
          'date': DateTime(2024, 6, 1).toIso8601String(),
          'accountId': 'a1',
          'categoryId': categoryId,
          'currencyCode': 'EUR',
          'exchangeRate': 1.0,
          'fee': 0.0,
          'modifiedAt': modifiedAt,
          'deviceId': 'dev-a',
          'isDeleted': false,
        };

    test(
      'an absent key keeps the stored value; an explicit null clears it',
      () async {
        // `amount_minor` is a column added by migration, so senders that predate
        // it exist and send no key for it. Assigning it unconditionally wrote
        // NULL, which by this codebase's own contract reclassifies a fiat
        // transaction as crypto and demotes its exact minor units to an
        // 8-decimal double — for every device, permanently.
        await db.customInsert(
          'INSERT INTO transactions (id, description, amount, amount_minor, '
          'date, account_id, category_id, currency_code, exchange_rate, fee, '
          'fee_minor, modified_at, device_id, is_deleted) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          variables: [
            Variable.withString('t1'),
            Variable.withString('coffee'),
            Variable.withReal(-25.5),
            Variable.withInt(-2550),
            Variable.withDateTime(DateTime(2024, 6, 1)),
            Variable.withString('a1'),
            Variable.withString(categoryId),
            Variable.withString('EUR'),
            Variable.withReal(1.0),
            Variable.withReal(0.0),
            Variable.withInt(0),
            Variable.withInt(1000),
            Variable.withString('dev-a'),
            Variable.withBool(false),
          ],
          updates: {db.transactions},
        );

        pages = [
          page({
            'transactions': [transactionJson(2000, 'coffee, renamed')],
          }),
        ];
        await service.sync();

        final afterAbsent = await transaction('t1');
        expect(afterAbsent.description, 'coffee, renamed');
        expect(
          afterAbsent.amountMinor,
          -2550,
          reason:
              'the sender said nothing about minor units, so nothing changed',
        );

        pages = [
          page(serverTimestamp: 2, {
            'transactions': [
              {
                ...transactionJson(3000, 'now a crypto amount'),
                'amountMinor': null,
              },
            ],
          }),
        ];
        await service.sync();

        expect(
          (await transaction('t1')).amountMinor,
          isNull,
          reason:
              'an explicit null is a statement about the column and still '
              'clears it — only silence is silence',
        );
      },
    );

    test('an absent isDeleted does not resurrect a tombstone', () async {
      // The boolean shape of the same bug, one step worse: absent read as
      // `false`, so a sender that knows nothing about tombstones undid a delete
      // the rest of the fleet had already agreed on.
      await insertStyleRaw(
        's3',
        modifiedAt: 1000,
        name: 'Deleted everywhere',
        isDeleted: true,
      );

      pages = [
        page({
          'styles': [
            {
              'id': 's3',
              'name': 'Renamed by an old client',
              'colorHex': '#abcdef',
              'iconName': 'star',
              'iconType': 0,
              'modifiedAt': 2000,
            },
          ],
        }),
      ];
      await service.sync();

      final row = await (db.select(
        db.styles,
      )..where((s) => s.id.equals('s3'))).getSingle();
      expect(row.name, 'Renamed by an old client');
      expect(row.isDeleted, isTrue, reason: 'deletes stay deleted');
    });
  });

  group('dates survive the round trip', () {
    test('a wall clock goes out and the same wall clock comes back', () async {
      // The two halves of this are mutually exclusive and the server owns one
      // of them: it treats a zone-less string as a WALL CLOCK and hands the
      // same digits back. So the client must keep sending a zone-less local
      // string — stamping it .toUtc() here would shift every date by the
      // device's offset, which for `exchange_rates` means a different primary
      // key and a second row on a different calendar day.
      final localMidnight = DateTime(2026, 8, 12);
      await db.customInsert(
        'INSERT INTO exchange_rates (from_currency_code, to_currency_code, '
        'rate, preset, date, modified_at) VALUES (?, ?, ?, ?, ?, ?)',
        variables: [
          Variable.withString('USD'),
          Variable.withString('EUR'),
          Variable.withReal(0.9),
          Variable.withInt(7),
          Variable.withDateTime(localMidnight),
          Variable.withInt(1000),
        ],
        updates: {db.exchangeRates},
      );

      await service.sync();

      final sent = pushed(
        'exchange_rates',
      ).singleWhere((r) => r['preset'] == 7);
      final sentDate = sent['date'] as String;
      expect(
        sentDate,
        isNot(endsWith('Z')),
        reason:
            'the server reads a zone-less string as the wall clock it is; a '
            "'Z' would make it an instant and move the day",
      );

      // Exactly what the server stores and returns: the digits it was given.
      pages = [
        page(serverTimestamp: 2, {
          'exchange_rates': [
            {...sent, 'rate': 0.95, 'modifiedAt': 2000},
          ],
        }),
      ];
      await service.sync();

      final rates = await (db.select(
        db.exchangeRates,
      )..where((r) => r.preset.equals(7))).get();
      expect(
        rates,
        hasLength(1),
        reason:
            'a shifted date is a different primary key, so a shift shows up '
            'as a second row rather than as a wrong one',
      );
      expect(rates.single.date, localMidnight);
      expect(rates.single.rate, 0.95);
    });
  });

  group('the queue while server sync is switched off', () {
    setUp(() async {
      await setEnabled(false);
      await db.customStatement('DELETE FROM sync_push_queue');
    });

    Future<int> queueLength() async {
      final row = await db
          .customSelect('SELECT COUNT(*) AS c FROM sync_push_queue')
          .getSingle();
      return row.read<int>('c');
    }

    test(
      'it is collapsed to one entry per row rather than growing forever',
      () async {
        // The triggers fire whether or not the feature is on, and the only code
        // that removes an entry sits behind the enabled check — so an install
        // with server sync off accumulated one row per write for its whole life,
        // and getPendingChangesCount scanned the lot every time the sync screen
        // refreshed.
        await insertStyleRaw('s1', modifiedAt: 1);
        for (var i = 0; i < 5; i++) {
          await db.customStatement(
            "UPDATE styles SET name = 'Rename $i', modified_at = ${100 + i} "
            "WHERE id = 's1'",
          );
        }
        expect(await queueLength(), 6);

        await service.sync();

        expect(await queueLength(), 1);
        expect((await queue()).single, (table: 'styles', key: 's1'));
      },
    );

    test('and the row is still pushed once sync is switched back on', () async {
      // Collapsing, not deleting: what a row owes the server is that its
      // current state gets uploaded once, and nothing but this queue remembers
      // that it is owed.
      await insertStyleRaw('s1', modifiedAt: 1, name: 'Written while offline');
      await db.customStatement(
        "UPDATE styles SET name = 'Renamed while offline', modified_at = 200 "
        "WHERE id = 's1'",
      );
      await service.sync();

      await setEnabled(true);
      await service.sync();

      expect(
        pushed('styles').where((r) => r['id'] == 's1').map((r) => r['name']),
        ['Renamed while offline'],
      );
      expect(await queueLength(), 0);
    });
  });
}
