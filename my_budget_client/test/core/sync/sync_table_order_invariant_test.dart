// The order the client sends tables in is a correctness constraint, not a
// style choice, and nothing enforced it.
//
// The server's schema declares real foreign keys - `transactions.account_id`
// references `accounts(id)`, `accounts.currency_designation_id` references
// `currency_designations(id)`, and four more. A push body is applied inside
// one Postgres transaction, so a child row that arrives before its parent
// does not degrade: the whole batch fails with a 23503, the client throws
// without draining its queue, and it retries the same doomed batch on every
// sync from then on. Uploads from that device stop, permanently, with nothing
// on screen to say so.
//
// The same order matters on the way back down. Pull applies with
// `PRAGMA foreign_keys = OFF`, so a child written before its parent does not
// throw - it wins the last-write-wins comparison against a parent row that is
// then overwritten a moment later by the same page. The failure is silent
// rather than loud, which is worse.
//
// So both orders are read off disk here, along with the server's own FK
// graph, and every parent is required to precede every child. Reading the
// schema rather than restating it means a foreign key added to the server
// tomorrow is checked against the client that ships with it.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    show AppDatabase, syncPushQueueSeedTables, syncPushQueueTables;

/// Where the two ends live, relative to the client package root.
const String _clientSyncService = 'lib/core/services/server_sync_service.dart';
const String _serverSchema = '../my_budget_server/lib/data/database_client.dart';
const String _serverRepository = '../my_budget_server/lib/data/sync_repository.dart';

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    fail(
      'Cannot read $path from ${Directory.current.path}. Both packages live in '
      'the same repository and this test compares one against the other; if '
      'the layout moved, point the constant at the new path rather than '
      'dropping the check.',
    );
  }
  return file.readAsStringSync();
}

/// The wire names of the tables `_push` uploads, in the order it uploads them.
///
/// Taken from the SECOND argument of each `_pushQueuedTable` call - the first
/// is the local drift table, which differs for `api_settings_table`.
List<String> _pushOrder(String source) {
  final calls = RegExp(
    r"_pushQueuedTable\(\s*'[^']+',\s*'([^']+)'",
  ).allMatches(source);
  return [for (final m in calls) m.group(1)!];
}

/// The LOCAL drift table names `_push` uploads, in call order.
///
/// The first argument, not the second: `api_settings_table` is the drift table
/// and `api_settings` is what goes on the wire, and the push-queue triggers
/// are named after the former.
List<String> _pushLocalTables(String source) {
  final calls = RegExp(r"_pushQueuedTable\(\s*'([^']+)'").allMatches(source);
  return [for (final m in calls) m.group(1)!];
}

/// The wire names `_applyChanges` walks, in the order it walks them.
List<String> _pullOrder(String source) {
  final list = RegExp(
    r'_pullTableOrder\s*=\s*\[(.*?)\n  \];',
    dotAll: true,
  ).firstMatch(source);
  expect(
    list,
    isNotNull,
    reason:
        '_pullTableOrder is no longer a list literal in $_clientSyncService, '
        'so this test can no longer see what order pull applies in',
  );
  return [
    for (final m in RegExp(r"\(key:\s*'([^']+)'").allMatches(list!.group(1)!))
      m.group(1)!,
  ];
}

/// Every server table mapped to the tables its columns reference.
Map<String, List<String>> _foreignKeys(String schema) {
  final tables = RegExp(
    r'CREATE TABLE IF NOT EXISTS (\w+)\s*\((.*?)\n\s*\)',
    dotAll: true,
  ).allMatches(schema);
  return {
    for (final table in tables)
      table.group(1)!: [
        for (final ref in RegExp(
          r'REFERENCES (\w+)\(',
        ).allMatches(table.group(2)!))
          ref.group(1)!,
      ],
  };
}

/// The tables the server's `upsertBatch` is willing to apply.
List<String> _serverTables(String repository) {
  final list = RegExp(
    r'final tablesList = \[(.*?)\];',
    dotAll: true,
  ).firstMatch(repository);
  expect(
    list,
    isNotNull,
    reason: 'tablesList is no longer a list literal in $_serverRepository',
  );
  return [
    for (final m in RegExp(r"'([^']+)'").allMatches(list!.group(1)!)) m.group(1)!,
  ];
}

/// Fails naming the offending pair rather than dumping two lists.
void _expectParentsFirst(List<String> order, Map<String, List<String>> fks) {
  final position = {for (var i = 0; i < order.length; i++) order[i]: i};
  for (final entry in fks.entries) {
    final childAt = position[entry.key];
    if (childAt == null) continue;
    for (final parent in entry.value) {
      final parentAt = position[parent];
      expect(
        parentAt,
        isNotNull,
        reason:
            '${entry.key} references $parent, which this order never carries '
            'at all',
      );
      expect(
        parentAt,
        lessThan(childAt),
        reason:
            '$parent must come before ${entry.key}: ${entry.key} rows hold a '
            'foreign key into $parent',
      );
    }
  }
}

void main() {
  late String service;
  late Map<String, List<String>> foreignKeys;

  setUpAll(() {
    service = _read(_clientSyncService);
    foreignKeys = _foreignKeys(_read(_serverSchema));
  });

  test('the server schema still declares the keys this test exists for', () {
    // A guard on the parser rather than on the product: if the regex above
    // ever matched nothing, every ordering assertion below would pass
    // vacuously and the drift it is here to catch would sail through.
    expect(foreignKeys['transactions'], containsAll(['accounts', 'categories']));
    expect(foreignKeys['accounts'], contains('currency_designations'));
    expect(foreignKeys['asset_entries'], contains('accounts'));
  });

  test('push sends every parent before the rows that reference it', () {
    final order = _pushOrder(service);
    expect(order, isNotEmpty, reason: 'no _pushQueuedTable calls were found');
    _expectParentsFirst(order, foreignKeys);
  });

  test('pull applies every parent before the rows that reference it', () {
    _expectParentsFirst(_pullOrder(service), foreignKeys);
  });

  test('push and pull carry the same tables', () {
    // A table pushed but never pulled syncs one way only: the device that
    // owns the row keeps it and no peer ever sees it, which reads as data
    // loss on the other end rather than as a missing feature.
    expect(_pushOrder(service).toSet(), _pullOrder(service).toSet());
  });

  test('no table is listed twice in either order', () {
    for (final order in [_pushOrder(service), _pullOrder(service)]) {
      expect(order.toSet().length, order.length, reason: '$order');
    }
  });

  test('every table with a push-queue trigger is a table push uploads', () {
    // A trigger with no uploader behind it queues an entry that nothing ever
    // drains. The row is never sent, `getPendingChangesCount` reports a
    // backlog that no amount of syncing clears, and every push from then on
    // re-reads the same dead page before it reaches the live entries.
    expect(
      syncPushQueueTables.toSet().difference(_pushLocalTables(service).toSet()),
      isEmpty,
    );
  });

  test('every table push uploads has a push-queue trigger', () {
    // The other direction is silent rather than noisy: an edit to a table
    // with no trigger queues nothing, the uploader finds no entries for it,
    // and the row simply never leaves the device.
    expect(
      _pushLocalTables(service).toSet().difference(syncPushQueueTables.toSet()),
      isEmpty,
    );
  });

  test('the server accepts every table the client pushes', () {
    // Anything else is silently dropped: `upsertBatch` walks its own list and
    // a key that is not on it is never looked at, so the client drains the
    // queue on a 200 that wrote nothing.
    final accepted = _serverTables(_read(_serverRepository)).toSet();
    expect(_pushOrder(service).toSet().difference(accepted), isEmpty);
  });

  test('the server applies a mixed body parents-first as well', () {
    // The client sends one table per request, so its own order carries it.
    // A body naming several tables at once - which the endpoint accepts -
    // depends on this list instead.
    _expectParentsFirst(_serverTables(_read(_serverRepository)), foreignKeys);
  });

  test(
    'every seeded table the server points a foreign key at is queued on '
    'install',
    () async {
      // The other half of the ordering constraint. Sending parents first is
      // no use if a parent is never sent at all: the push-queue triggers are
      // created AFTER the bundled seed is written, deliberately, so that a
      // fresh install does not upload ~283k identical exchange rates. The
      // four tables the server declares foreign keys into are the exception,
      // and missing one of them is the same permanent 23503 the file above
      // exists to prevent - only with nothing in the ordering to give it
      // away.
      //
      // Read rather than restated on both sides: a foreign key added to the
      // server tomorrow, or a table the seed stops filling, is checked
      // against the client that ships with it.
      final fkTargets = {
        for (final refs in _foreignKeys(_read(_serverSchema)).values) ...refs,
      };

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final seeded = <String>{};
      for (final table in syncPushQueueTables) {
        final row = await db
            .customSelect('SELECT COUNT(*) AS c FROM $table')
            .getSingle();
        if (row.read<int>('c') > 0) seeded.add(table);
      }

      expect(
        seeded,
        isNotEmpty,
        reason: 'a fresh install seeds nothing, so this test proves nothing',
      );
      expect(
        seeded.intersection(fkTargets),
        syncPushQueueSeedTables.toSet(),
        reason:
            'syncPushQueueSeedTables has to be exactly the seeded tables the '
            'server keeps foreign keys into',
      );
    },
  );
}
