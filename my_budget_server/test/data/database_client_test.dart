import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:my_budget_server/data/database_client.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class _MockPool extends Mock implements Pool<dynamic> {}

class _MockResult extends Mock implements Result {}

void main() {
  late _MockPool pool;
  late List<String> statements;

  setUpAll(() => registerFallbackValue(Object()));

  setUp(() {
    pool = _MockPool();
    statements = [];
    when(() => pool.execute(any<Object>())).thenAnswer((invocation) async {
      statements.add('${invocation.positionalArguments.first}');
      return _MockResult();
    });
  });

  /// Runs the startup path with its logging swallowed, and returns every
  /// statement it issued, whitespace collapsed so a multi-line CREATE can be
  /// matched as one string.
  Future<List<String>> schemaStatements() async {
    await runZoned(
      () => DatabaseClient(pool: pool).ensureSchema(),
      zoneSpecification: ZoneSpecification(print: (_, __, ___, ____) {}),
    );
    return [
      for (final sql in statements) sql.replaceAll(RegExp(r'\s+'), ' ').trim(),
    ];
  }

  group('api_settings gains its tombstone column', () {
    // The client has always pushed `isDeleted` for this table and has always
    // read it back, but the table was created without the column, so the
    // delete died on arrival: the row stayed live and every other device
    // pulled the provider the user had removed straight back into its list.
    test('an existing database is migrated', () async {
      final sql = await schemaStatements();

      expect(
        sql,
        contains(
          'ALTER TABLE api_settings ADD COLUMN IF NOT EXISTS is_deleted '
          'BOOLEAN DEFAULT FALSE',
        ),
      );
    });

    test('a fresh database is created with it', () async {
      // Without this the migration is the only thing that ever adds the
      // column, and a server whose first boot creates the table would depend
      // on an ALTER running afterwards to be correct.
      final sql = await schemaStatements();

      final create = sql.firstWhere(
        (s) => s.startsWith('CREATE TABLE IF NOT EXISTS api_settings'),
      );
      expect(create, contains('is_deleted BOOLEAN DEFAULT FALSE'));
    });

    test('the migration is additive and re-runnable', () async {
      // ensureSchema runs on every boot, so a statement that is not
      // conditional takes the whole server down the second time it starts.
      final sql = await schemaStatements();

      for (final alter in sql.where((s) => s.startsWith('ALTER TABLE'))) {
        expect(alter, contains('ADD COLUMN IF NOT EXISTS'));
      }
    });

    test('it lands before the sequence pass that reads every synced table',
        () async {
      // _ensureServerSeq walks the synced tables and rewrites them; the column
      // has to exist by then or the very first pull after an upgrade selects a
      // column that is not there yet.
      final sql = await schemaStatements();

      final migrated = sql.indexWhere(
        (s) => s.startsWith('ALTER TABLE api_settings ADD COLUMN'),
      );
      final sequence = sql.indexOf('CREATE SEQUENCE IF NOT EXISTS sync_seq');
      expect(migrated, greaterThanOrEqualTo(0));
      expect(migrated, lessThan(sequence));
    });
  });
}
