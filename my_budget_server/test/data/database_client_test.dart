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

  group('accounts gain the anchor their balance is rebuilt from', () {
    test('an existing database is migrated', () async {
      final sql = await schemaStatements();

      expect(
        sql,
        contains(
          'ALTER TABLE accounts ADD COLUMN IF NOT EXISTS opening_balance '
          'DOUBLE PRECISION',
        ),
      );
      expect(
        sql,
        contains(
          'ALTER TABLE accounts ADD COLUMN IF NOT EXISTS '
          'opening_balance_minor BIGINT',
        ),
      );
    });

    test('a fresh database is created with both columns', () async {
      // Or the migration is the only thing that ever adds them, and a server
      // whose first boot creates the table would depend on a second boot to
      // finish it.
      final create = (await schemaStatements()).firstWhere(
        (sql) => sql.startsWith('CREATE TABLE IF NOT EXISTS accounts'),
      );

      expect(create, contains('opening_balance DOUBLE PRECISION'));
      expect(create, contains('opening_balance_minor BIGINT'));
    });

    test('nothing backfills the anchor from the stored balance', () async {
      // The stored balance is the sum of an unknown set of transactions, so
      // copying it into the anchor would invent a number instead of waiting
      // for the device that owns the account to push the real one. NULL is
      // already the wire's word for "sender has no anchor".
      final sql = await schemaStatements();

      expect(
        sql.where((s) => s.contains('opening_balance')),
        everyElement(isNot(contains('UPDATE accounts'))),
      );
      expect(
        sql,
        everyElement(isNot(contains('opening_balance = balance'))),
      );
    });

    test('the anchor is 64-bit like every other money column', () async {
      // A float4 anchor would put a rounding error under every balance the
      // fleet rebuilds from it.
      final create = (await schemaStatements()).firstWhere(
        (sql) => sql.startsWith('CREATE TABLE IF NOT EXISTS accounts'),
      );

      expect(create, isNot(matches(RegExp(r'opening_balance\s+REAL'))));
    });
  });

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

  group('money is stored at 64 bits', () {
    // Postgres REAL is float4: about seven significant digits. Both clients
    // hold these as Dart doubles and SQLite stores them as 8-byte floats, so
    // the server was the one narrow link and it narrowed silently. A balance
    // of -1234567.89 pushed by one device came back to the other as
    // -1234567.875, and under last-write-wins neither row is newer, so the
    // two devices disagreed about that account with nothing left to re-sync.
    // Anything outside the float4 range failed the whole push with 22003 -
    // and a failed push keeps its queue, so that device retried the same
    // doomed batch every five minutes.
    const wideColumns = {
      'accounts': ['balance', 'asset_quantity'],
      'transactions': ['amount', 'exchange_rate', 'fee'],
      'asset_entries': ['value', 'quantity'],
      'exchange_rates': ['rate'],
      'inflation_rates': ['percent'],
      'custom_themes': [
        'background_image_opacity',
        'background_image_blur',
        'effect_opacity',
        'surface_opacity',
      ],
    };

    test('a fresh database is created with no float4 column anywhere',
        () async {
      final sql = await schemaStatements();

      for (final create in sql.where((s) => s.startsWith('CREATE TABLE'))) {
        expect(
          create,
          isNot(matches(RegExp(r'\bREAL\b'))),
          reason: 'a table is still created with a 32-bit float column',
        );
      }
    });

    test('every column that holds a number is declared DOUBLE PRECISION',
        () async {
      // The check above only proves the word REAL is gone. This one proves
      // each column is still there and is now wide, so a column that was
      // quietly dropped or renamed cannot pass.
      final sql = await schemaStatements();

      wideColumns.forEach((table, columns) {
        final create = sql.firstWhere(
          (s) => s.startsWith('CREATE TABLE IF NOT EXISTS $table'),
        );
        for (final column in columns) {
          expect(
            create,
            contains('$column DOUBLE PRECISION'),
            reason: '$table.$column',
          );
        }
      });
    });

    test('an existing database is widened in place', () async {
      final sql = await schemaStatements();

      final widen = sql.firstWhere(
        (s) => s.contains('TYPE DOUBLE PRECISION'),
        orElse: () => '',
      );
      expect(widen, isNotEmpty, reason: 'nothing migrates a float4 database');
      expect(widen, contains("data_type = 'real'"));
      expect(widen, startsWith(r'DO $$'));
    });

    test('the widening reaches every synced table', () async {
      // Named one by one rather than trusted to a wildcard: a table left out
      // of the list keeps its float4 columns forever, and nothing else in the
      // system would report it.
      final sql = await schemaStatements();
      final widen = sql.firstWhere((s) => s.contains('TYPE DOUBLE PRECISION'));

      for (final table in DatabaseClient.syncedTables) {
        expect(widen, contains("'$table'"), reason: table);
      }
    });

    test('it is guarded, so a boot with nothing to do rewrites no table',
        () async {
      // ALTER COLUMN TYPE rewrites the whole table. ensureSchema runs on every
      // start, so an unconditional version would rewrite every row of every
      // table on every deploy.
      final sql = await schemaStatements();
      final widen = sql.firstWhere((s) => s.contains('TYPE DOUBLE PRECISION'));

      expect(widen, contains('FROM information_schema.columns'));
      expect(widen, contains('current_schema()'));
    });

    test('it runs before the sequence pass that rewrites every synced table',
        () async {
      final sql = await schemaStatements();

      final widen = sql.indexWhere((s) => s.contains('TYPE DOUBLE PRECISION'));
      final sequence = sql.indexOf('CREATE SEQUENCE IF NOT EXISTS sync_seq');
      expect(widen, greaterThanOrEqualTo(0));
      expect(widen, lessThan(sequence));
    });
  });
}
