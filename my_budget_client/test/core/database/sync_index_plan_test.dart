import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;

/// Index coverage for the server push's row lookup, asserted by asking SQLite
/// what it would actually do rather than by reading the schema.
///
/// `_pushQueuedTable` (lib/core/services/server_sync_service.dart) reads a
/// batch of queued keys and resolves them back to rows with
/// `SELECT * FROM <table> WHERE <syncPushQueueKeyExpression(table)> IN (?, …)`,
/// 500 keys per statement. For the fourteen tables whose key is a bare column
/// that is also the primary key, the primary key's own index serves it. For
/// `exchange_rates` and `inflation_rates` the key is a concatenation of the
/// primary-key columns, and an expression is servable only by an index built on
/// that same expression — without one SQLite reads the whole table, once per
/// chunk, over the ~283 000 bundled exchange rates the v12→v13 step queues.
///
/// The statement under test is built from `syncPushQueueKeyExpression`, the
/// same function the push and the index both go through. That is the point of
/// the test: SQLite matches an expression index only when the query's
/// expression parses to the same thing, so a hand-copied spelling on either
/// side would pass a schema check and still scan.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  /// The exact lookup `_pushQueuedTable` issues, with [keyCount] bound keys.
  String pushLookupSql(String table, {int keyCount = 2}) {
    final placeholders = List.filled(keyCount, '?').join(', ');
    return 'SELECT * FROM $table '
        'WHERE ${syncPushQueueKeyExpression(table)} IN ($placeholders)';
  }

  /// The plan SQLite would run for [sql]. The bound values matter: type
  /// affinity is part of what decides whether an index is usable, so a
  /// placeholder is bound with the kind of value the push binds there.
  Future<List<String>> planFor(
    String sql,
    int keyCount, {
    List<Variable>? variables,
  }) async {
    final rows = await db
        .customSelect(
          'EXPLAIN QUERY PLAN $sql',
          variables:
              variables ??
              [for (var i = 0; i < keyCount; i++) Variable.withString('k$i')],
        )
        .get();
    return rows.map((r) => r.read<String>('detail')).toList();
  }

  group('push-queue key lookups', () {
    for (final table in syncPushQueueTables) {
      test(
        '$table resolves queued keys through an index, not a scan',
        () async {
          final plan = await planFor(pushLookupSql(table), 2);
          expect(
            plan,
            everyElement(isNot(contains('SCAN $table'))),
            reason:
                'the push resolves 500 keys per statement; a scan here is one '
                'full pass over $table per chunk. Plan: $plan',
          );
          expect(
            plan.join(' | '),
            contains('SEARCH $table'),
            reason: 'plan was: $plan',
          );
        },
      );
    }

    test(
      'the two concatenated keys are served by their own expression index',
      () async {
        // Named rather than folded into the loop above: these are the only two
        // that needed an index adding, and the assertion is specifically that
        // SQLite picked *that* index — a plan that searched some other index and
        // then filtered would still not be O(1) per key.
        for (final table in ['exchange_rates', 'inflation_rates']) {
          final indexName = syncPushQueueKeyIndexName(table);
          expect(indexName, isNotNull, reason: '$table has a concatenated key');
          final plan = await planFor(pushLookupSql(table, keyCount: 3), 3);
          expect(plan.join(' | '), contains('USING INDEX $indexName'));
        }
      },
    );

    test('the settings row filter does not cost the key its index', () async {
      // `settings` is pushed with an extra `AND (key NOT IN (…))` that keeps the
      // device-local keys on the device. A predicate SQLite cannot index is
      // free to be applied as a filter — as long as it does not make it give up
      // on the key.
      const filter = "key NOT IN ('local_device_id', 'sync_folder_path')";
      final plan = await planFor(
        '${pushLookupSql('settings')} AND ($filter)',
        2,
      );
      expect(plan, everyElement(isNot(contains('SCAN settings'))));
    });

    test('reading a batch out of the queue is a range scan of one index, not '
        'of the queue', () async {
      // The statement that feeds the loop above, from the same method. It is
      // the other half of the same perf target: the queue is read once per
      // 20 000-row batch and per table, so a full pass over a queue holding
      // every seeded rate would be paid 16 times per push.
      final plan = await planFor(
        'SELECT id, record_key FROM sync_push_queue '
        'WHERE changed_table_name = ? AND id <= ? ORDER BY id LIMIT 20000',
        2,
        variables: [
          Variable.withString('exchange_rates'),
          Variable.withInt(20000),
        ],
      );
      expect(plan, everyElement(isNot(contains('SCAN sync_push_queue'))));
      expect(plan.join(' | '), contains('idx_sync_push_queue_table'));
    });

    test('every table with a bare-column key relies on its primary key, so no '
        'index is created for it', () async {
      // The fourteen single-column keys are all primary keys. Asserting it here
      // stops a future key changing shape unnoticed: a column that stopped
      // being the primary key would still return null from
      // syncPushQueueKeyIndexName and would then scan, which the per-table
      // plans above would catch.
      final indexed = syncPushQueueTables
          .where((t) => syncPushQueueKeyIndexName(t) != null)
          .toList();
      expect(indexed, ['exchange_rates', 'inflation_rates']);
    });
  });
}
