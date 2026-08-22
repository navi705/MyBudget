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

/// Counts and records every statement the executor runs, so a test can talk
/// about how MANY statements a pulled page cost rather than only about what it
/// left in the tables.
///
/// [statements] holds the SQL text of every insert/update/delete/custom
/// statement in the order it ran; selects are counted separately because the
/// apply path issues a fixed handful of them regardless of page size.
class _RecordingInterceptor extends QueryInterceptor {
  final List<String> statements = [];

  /// Time spent inside the recorded statements alone — no HTTP, no JSON, no
  /// test scaffolding — which is what the "N statements per page" target is
  /// about and the only figure the two runs can be compared on fairly.
  Duration elapsed = Duration.zero;

  bool recording = false;

  void reset() {
    statements.clear();
    elapsed = Duration.zero;
  }

  int countMatching(Pattern pattern) =>
      statements.where((s) => s.contains(pattern)).length;

  Future<T> _timed<T>(String statement, Future<T> Function() run) async {
    if (!recording) return run();
    statements.add(statement);
    final stopwatch = Stopwatch()..start();
    try {
      return await run();
    } finally {
      elapsed += stopwatch.elapsed;
    }
  }

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(statement, () => executor.runInsert(statement, args));

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(statement, () => executor.runUpdate(statement, args));

  @override
  Future<int> runDelete(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(statement, () => executor.runDelete(statement, args));

  @override
  Future<void> runCustom(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) => _timed(statement, () => executor.runCustom(statement, args));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _RecordingInterceptor recorder;
  late LocalSettingsRepository settingsRepository;
  late ServerSyncService service;

  /// The pages the mock server hands back, in order; the last one repeats.
  late List<Map<String, dynamic>> pages;

  /// Every push body the service sent, decoded.
  late List<Map<String, dynamic>> pushes;

  Map<String, dynamic> page(
    Map<String, List<Map<String, dynamic>>> changes, {
    int serverTimestamp = 7,
    bool hasMore = false,
  }) => {
    'changes': changes,
    'server_timestamp': serverTimestamp,
    'has_more': hasMore,
  };

  /// One pulled exchange rate. `date` is day-granular and part of the key, so
  /// [index] walks the calendar to produce distinct rows.
  Map<String, dynamic> rate(
    int index, {
    double value = 1.5,
    int modifiedAt = 1000,
  }) => {
    'fromCurrencyCode': 'USD',
    'toCurrencyCode': 'EUR',
    'rate': value,
    'preset': 1,
    'date': DateTime.utc(
      2020,
      1,
      1,
    ).add(Duration(days: index)).toIso8601String(),
    'modifiedAt': modifiedAt,
    'deviceId': 'server-device',
  };

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    recorder = _RecordingInterceptor();
    db = AppDatabase.forTesting(
      NativeDatabase.memory().interceptWith(recorder),
    );
    // Force the lazy open (and the seed) before anything is measured or
    // recorded, so onCreate's own statements are never counted as a page's.
    await db.select(db.styles).get();

    settingsRepository = LocalSettingsRepository(db);
    await settingsRepository.setSetting(
      const domain.Settings(
        key: 'server_sync_enabled',
        value: 'true',
        device: 'test-device',
      ),
    );

    pages = [];
    pushes = [];
    service = ServerSyncService(
      database: db,
      settingsRepository: settingsRepository,
      httpClient: MockClient((request) async {
        if (request.method == 'POST') {
          pushes.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response('{"status":"ok"}', 200);
        }
        final body = pages.isEmpty
            ? page(const {}, serverTimestamp: 0)
            : pages.removeAt(0);
        if (pages.isEmpty) pages.add(page(const {}, serverTimestamp: 0));
        return http.Response(jsonEncode(body), 200);
      }),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('a pulled page is applied in batches', () {
    test('5 000 rows cost a handful of statements, not 5 000', () async {
      // The size the server actually serves: parsePullLimit clamps the
      // client's limit=20000 to 5 000 rows per table, so this is one real page.
      pages = [
        page({
          'exchange_rates': [for (var i = 0; i < 5000; i++) rate(i)],
        }),
      ];
      // The setting written in setUp is queued for push; clearing it leaves the
      // cycle with nothing to upload, so the recorded statements are the pull's
      // own and nothing else's.
      await db.customStatement('DELETE FROM sync_push_queue');

      recorder.reset();
      recorder.recording = true;
      await service.sync();
      recorder.recording = false;

      final batchedStatements = recorder.countMatching(
        'INSERT INTO exchange_rates',
      );
      final batched = recorder.elapsed;
      expect(await db.exchangeRatesDao.getAllExchangeRates(), hasLength(5000));

      // The control: the same 5 000 rows written the way the applier used to
      // write them, one single-row statement each, with the identical conflict
      // tail — same process, same database, same interceptor holding the clock,
      // so only the batching differs. It writes a disjoint set of keys
      // (preset 2) so neither run does the other's work.
      recorder.reset();
      recorder.recording = true;
      await db.transaction(() async {
        for (var i = 0; i < 5000; i++) {
          await db.customInsert(
            'INSERT INTO exchange_rates (from_currency_code, to_currency_code, '
            'rate, preset, date, modified_at, device_id, source_id) '
            'VALUES (?, ?, ?, ?, ?, ?, ?, ?) '
            'ON CONFLICT (from_currency_code, to_currency_code, date, preset) '
            'DO UPDATE SET rate = EXCLUDED.rate, '
            'modified_at = EXCLUDED.modified_at, device_id = EXCLUDED.device_id '
            'WHERE EXCLUDED.modified_at > COALESCE(exchange_rates.modified_at, 0)',
            variables: [
              Variable.withString('USD'),
              Variable.withString('EUR'),
              Variable.withReal(1.5),
              Variable.withInt(2),
              Variable.withDateTime(
                DateTime.utc(2020, 1, 1).add(Duration(days: i)),
              ),
              Variable.withInt(1000),
              Variable('server-device'),
              Variable(null),
            ],
          );
        }
      });
      recorder.recording = false;
      final rowAtATime = recorder.elapsed;

      // ignore: avoid_print
      print(
        '[PERF] 5 000-row exchange_rates page — row-at-a-time '
        '${rowAtATime.inMilliseconds}ms in 5000 statements, batched '
        '${batched.inMilliseconds}ms in $batchedStatements statements',
      );

      // 8 columns per row, 999 bound variables per statement: 124 rows a
      // statement, so 5 000 rows are 41.
      expect(
        batchedStatements,
        lessThan(50),
        reason:
            'a page of N rows must not cost N statements — that is N round '
            "trips through drift's isolate inside one transaction",
      );
      expect(batched, lessThan(rowAtATime));
    });

    test('a page far past SQLite\'s 999-variable cap still applies', () async {
      // 200 rows x 8 columns is 1 600 bound variables: one statement would be
      // `too many SQL variables` in the middle of a pull, which is why the
      // batch is chunked rather than emitted whole.
      pages = [
        page({
          'exchange_rates': [for (var i = 0; i < 200; i++) rate(i)],
        }),
      ];

      await service.sync();

      expect(await db.exchangeRatesDao.getAllExchangeRates(), hasLength(200));
    });

    test(
      'last-write-wins still decides, row by row, inside one statement',
      () async {
        // Two versions of the same key in one page, the older one second. SQLite
        // applies a multi-row upsert row by row, so the guard has to reject the
        // second the way it would have as a separate statement.
        pages = [
          page({
            'exchange_rates': [
              rate(0, value: 9.0, modifiedAt: 2000),
              rate(0, value: 1.0, modifiedAt: 1000),
            ],
          }),
        ];

        await service.sync();

        final rates = await db.exchangeRatesDao.getAllExchangeRates();
        expect(rates, hasLength(1));
        expect(rates.single.rate, 9.0);
      },
    );

    test('the device-id tiebreak survives batching', () async {
      // Equal modifiedAt: the higher device id wins, on both sides of the wire,
      // or the two ends of the sync disagree about the same pair of writes.
      pages = [
        page({
          'exchange_rates': [
            {...rate(0, value: 1.0, modifiedAt: 1000), 'deviceId': 'aaa'},
            {...rate(0, value: 2.0, modifiedAt: 1000), 'deviceId': 'zzz'},
          ],
        }),
      ];

      await service.sync();

      expect(
        (await db.exchangeRatesDao.getAllExchangeRates()).single.rate,
        2.0,
      );
    });

    test(
      'a column one row omits is not erased for the rows that carry it',
      () async {
        // The SET list is built per payload shape: a sender that does not know
        // about `sourceId` must leave the stored value alone, and it must not be
        // able to do so on behalf of the rows around it either. Both shapes are
        // in one page here, which is exactly the case a single shared statement
        // would get wrong.
        pages = [
          page({
            'exchange_rates': [
              {...rate(0, modifiedAt: 1000), 'sourceId': 'src-a'},
              {...rate(1, modifiedAt: 1000), 'sourceId': 'src-b'},
            ],
          }),
          page({
            'exchange_rates': [
              // No sourceId key at all — the stored one must stand.
              rate(0, value: 3.0, modifiedAt: 2000),
              {...rate(1, value: 4.0, modifiedAt: 2000), 'sourceId': 'src-c'},
            ],
          }, serverTimestamp: 9),
        ];

        await service.sync();
        await service.sync();

        final rows = await db
            .customSelect(
              'SELECT rate, source_id FROM exchange_rates '
              'WHERE preset = 1 ORDER BY date',
            )
            .get();
        expect(rows.map((r) => r.read<double>('rate')), [3.0, 4.0]);
        expect(rows.map((r) => r.read<String?>('source_id')), [
          'src-a',
          'src-c',
        ]);
      },
    );

    test(
      'device-local settings are dropped before the batch, not after',
      () async {
        // `local_device_id` sharing a page with an ordinary setting used to be
        // rejected by a per-row early return. With one statement per chunk the
        // rejection has to happen while the rows are being selected, or the key
        // rides into the database inside its neighbour's statement.
        await settingsRepository.setSetting(
          const domain.Settings(
            key: 'local_device_id',
            value: 'mine',
            device: 'test-device',
          ),
        );
        pages = [
          page({
            'settings': [
              {
                'key': 'local_device_id',
                'value': 'theirs',
                'modifiedAt': 9999999999999,
                'deviceId': 'server-device',
              },
              {
                'key': 'some_shared_setting',
                'value': 'from the server',
                'modifiedAt': 9999999999999,
                'deviceId': 'server-device',
              },
            ],
          }),
        ];

        await service.sync();

        expect(
          (await settingsRepository.getSetting('local_device_id'))?.value,
          'mine',
        );
        expect(
          (await settingsRepository.getSetting('some_shared_setting'))?.value,
          'from the server',
        );
      },
    );
  });

  group('the custom_api dedup', () {
    test('is planned through the partial index, not as a table scan', () async {
      // `idx_asset_entries_custom_api_dedup` is partial (WHERE source =
      // 'custom_api'). SQLite may only use a partial index when the query's
      // WHERE provably implies the index's, so the applier spells the source
      // out as a literal instead of binding it. This asserts the plan the
      // applier's statement actually gets.
      final plan = await db
          .customSelect(
            'EXPLAIN QUERY PLAN DELETE FROM asset_entries '
            "WHERE source = 'custom_api' AND asset_id = ? AND date = ? "
            'AND id != ?',
            variables: [
              Variable.withString('gold'),
              Variable.withDateTime(DateTime.utc(2024, 1, 1)),
              Variable.withString('ae1'),
            ],
          )
          .get();

      expect(
        plan.map((r) => r.read<String>('detail')).join(' | '),
        contains('idx_asset_entries_custom_api_dedup'),
      );
    });

    test('still evicts the pre-fix duplicate holding the same slot', () async {
      await db.customStatement(
        "INSERT INTO asset_entries (id, asset_id, name, date, value, quantity, "
        "currency_code, source, preset, modified_at, is_deleted) VALUES "
        "('old-dupe', 'gold', 'Gold', ?, 1.0, 1.0, 'USD', 'custom_api', 1, 1, 0)",
        [DateTime.utc(2024, 1, 1).millisecondsSinceEpoch ~/ 1000],
      );

      pages = [
        page({
          'asset_entries': [
            {
              'id': 'new-entry',
              'assetId': 'gold',
              'name': 'Gold',
              'date': DateTime.utc(2024, 1, 1).toIso8601String(),
              'value': 2.0,
              'quantity': 1.0,
              'currencyCode': 'USD',
              'source': 'custom_api',
              'preset': 1,
              'modifiedAt': 2000,
              'deviceId': 'server-device',
              'isDeleted': false,
            },
          ],
        }),
      ];

      await service.sync();

      final ids = await db
          .customSelect("SELECT id FROM asset_entries WHERE asset_id = 'gold'")
          .get();
      expect(ids.map((r) => r.read<String>('id')), ['new-entry']);
    });

    test('a page carrying two rows for one slot applies instead of aborting '
        'the whole cycle', () async {
      // Observed live: a server that still holds two `custom_api` entries on
      // the same (asset_id, date) under different ids sends both in one page.
      // The second one hit the partial UNIQUE index, and because a page
      // applies all-or-nothing the device never finished another pull —
      // `[ServerSync] Sync cycle error: SqliteException(2067) ... UNIQUE
      // constraint failed: asset_entries.asset_id, asset_entries.date,
      // asset_entries.source`.
      Map<String, dynamic> entry(String id, int modifiedAt, double value) => {
        'id': id,
        'assetId': 'silver',
        'name': 'Silver',
        'date': DateTime.utc(2024, 5, 1).toIso8601String(),
        'value': value,
        'quantity': 1.0,
        'currencyCode': 'USD',
        'source': 'custom_api',
        'preset': 1,
        'modifiedAt': modifiedAt,
        'deviceId': 'server-device',
        'isDeleted': false,
      };

      pages = [
        page({
          'asset_entries': [
            entry('older-dupe', 1000, 1.0),
            entry('newer-dupe', 2000, 9.0),
          ],
        }),
      ];

      await service.sync();

      final rows = await db
          .customSelect(
            "SELECT id, value FROM asset_entries WHERE asset_id = 'silver'",
          )
          .get();
      expect(rows, hasLength(1));
      expect(rows.single.read<String>('id'), 'newer-dupe');
      expect(rows.single.read<double>('value'), 9.0);
    });

    test('the survivor is picked by (modifiedAt, deviceId), whatever order '
        'the page lists them in', () async {
      // Same stamp on both: the device-id tiebreak decides, and it has to
      // decide the same way the SQL guard and the server would.
      Map<String, dynamic> entry(String id, String device) => {
        'id': id,
        'assetId': 'copper',
        'name': 'Copper',
        'date': DateTime.utc(2024, 6, 1).toIso8601String(),
        'value': 1.0,
        'quantity': 1.0,
        'currencyCode': 'USD',
        'source': 'custom_api',
        'preset': 1,
        'modifiedAt': 4242,
        'deviceId': device,
        'isDeleted': false,
      };

      pages = [
        page({
          'asset_entries': [
            entry('from-zeta', 'zeta-device'),
            entry('from-alpha', 'alpha-device'),
          ],
        }),
      ];

      await service.sync();

      final ids = await db
          .customSelect(
            "SELECT id FROM asset_entries WHERE asset_id = 'copper'",
          )
          .get();
      expect(ids.map((r) => r.read<String>('id')), ['from-zeta']);
    });

    test('manual entries sharing a slot are left alone — the index does not '
        'cover them', () async {
      Map<String, dynamic> entry(String id, double value) => {
        'id': id,
        'assetId': 'art',
        'name': 'Painting',
        'date': DateTime.utc(2024, 7, 1).toIso8601String(),
        'value': value,
        'quantity': 1.0,
        'currencyCode': 'USD',
        'source': 'manual',
        'preset': 1,
        'modifiedAt': 10,
        'deviceId': 'server-device',
        'isDeleted': false,
      };

      pages = [
        page({
          'asset_entries': [entry('manual-a', 1.0), entry('manual-b', 2.0)],
        }),
      ];

      await service.sync();

      final ids = await db
          .customSelect("SELECT id FROM asset_entries WHERE asset_id = 'art'")
          .get();
      expect(ids.map((r) => r.read<String>('id')), ['manual-a', 'manual-b']);
    });
  });

  group('normalisation keeps a value at its own magnitude', () {
    test('a pulled 2.4e-10 rate is stored as 2.4e-10, not 0', () async {
      // 8-decimal normalisation exists to stop 0.30000000000000004 and 0.3
      // fighting a last-write-wins comparison. Applied to a hyperinflated or
      // crypto pair it used to render 2.4e-10 as '0.00000000' and store a
      // zero — and only on the server path, so the peer-to-peer engine and
      // this one disagreed about the same row forever.
      pages = [
        page({
          'exchange_rates': [rate(0, value: 2.4e-10)],
        }),
      ];

      await service.sync();

      expect(
        (await db.exchangeRatesDao.getAllExchangeRates()).single.rate,
        2.4e-10,
      );
    });

    test('a locally stored 2.4e-10 rate is pushed as 2.4e-10', () async {
      await db.customStatement(
        'INSERT INTO exchange_rates (from_currency_code, to_currency_code, '
        'rate, preset, date, modified_at) '
        "VALUES ('IRR', 'BTC', 2.4e-10, 1, ?, 5000)",
        [DateTime.utc(2024, 1, 1).millisecondsSinceEpoch ~/ 1000],
      );

      await service.sync();

      final pushed = pushes
          .expand((body) => (body['exchange_rates'] as List? ?? const []))
          .cast<Map<String, dynamic>>()
          .where((r) => r['fromCurrencyCode'] == 'IRR')
          .toList();
      expect(pushed, hasLength(1));
      expect(pushed.single['rate'], 2.4e-10);
    });

    test('ordinary values are still normalised', () async {
      // Normalisation must not be turned off altogether. 0.1 + 0.2 has to
      // leave here as 0.3, or two devices that computed the same rate
      // differently never agree that they hold the same value.
      pages = [
        page({
          'exchange_rates': [rate(0, value: 0.1 + 0.2)],
        }),
      ];

      await service.sync();

      expect(
        (await db.exchangeRatesDao.getAllExchangeRates()).single.rate,
        0.3,
      );
    });

    test('a small value keeps its own digits, not the decimal point\'s',
        () async {
      // The bug this group is named after, one decade up. Normalisation used
      // to be `toStringAsFixed(8)` behind a `< 1e-8` guard, so how much of a
      // rate survived depended on its magnitude rather than on its precision:
      // 3.7e-8 arrived as 4e-8 and 1.5e-8 as 1e-8, while 9e-9 - under the
      // guard - came through untouched. Every one of these is a rate a
      // hyperinflated or crypto pair really has.
      const rates = <double>[3.7e-8, 1.5e-8, 1.234e-7, 9e-9, 2.4e-10];
      pages = [
        page({
          'exchange_rates': [
            for (var i = 0; i < rates.length; i++) rate(i, value: rates[i]),
          ],
        }),
      ];

      await service.sync();

      final stored = await db.exchangeRatesDao.getAllExchangeRates();
      expect(stored.map((r) => r.rate).toList()..sort(), rates.toList()..sort());
    });

    test('a small value is pushed with its own digits too', () async {
      // Both directions, because a rate mangled on the way up is mangled for
      // every other device rather than just this one.
      const value = 1.234567e-7;
      await db.customStatement(
        'INSERT INTO exchange_rates (from_currency_code, to_currency_code, '
        'rate, preset, date, modified_at) '
        "VALUES ('IRR', 'ETH', ?, 1, ?, 5000)",
        [value, DateTime.utc(2024, 1, 1).millisecondsSinceEpoch ~/ 1000],
      );

      await service.sync();

      final pushed = pushes
          .expand((body) => (body['exchange_rates'] as List? ?? const []))
          .cast<Map<String, dynamic>>()
          .where((r) => r['toCurrencyCode'] == 'ETH')
          .toList();
      expect(pushed, hasLength(1));
      expect(pushed.single['rate'], value);
    });

    test('a large value keeps every digit it had', () async {
      // The other end of the same mistake: eight decimal places on a value
      // this size is not rounding at all, but a rule stated in significant
      // digits has to be checked here too or it silently truncates money.
      const values = <double>[1234567.89, 99999999.99, 1e15, 123456.789012];
      pages = [
        page({
          'exchange_rates': [
            for (var i = 0; i < values.length; i++) rate(i, value: values[i]),
          ],
        }),
      ];

      await service.sync();

      final stored = await db.exchangeRatesDao.getAllExchangeRates();
      expect(
        stored.map((r) => r.rate).toList()..sort(),
        values.toList()..sort(),
      );
    });

    test('two routes to the same number still meet in the middle', () async {
      // What the normalisation is for, at three magnitudes rather than one:
      // if these did not collapse to the same double, two devices holding the
      // same rate would each think the other's was newer on every sync.
      const pairs = <(double, double)>[
        (0.1 + 0.2, 0.3),
        (0.07 * 3, 0.21),
        (1e-9 / 3, 3.33333333333e-10),
      ];
      for (final (computed, written) in pairs) {
        expect(
          double.parse(computed.toStringAsPrecision(12)),
          double.parse(written.toStringAsPrecision(12)),
          reason: '$computed vs $written',
        );
      }
    });
  });
}

