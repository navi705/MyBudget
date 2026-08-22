import 'package:my_budget_server/data/database_client.dart';
import 'package:my_budget_server/data/sync_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

/// The shape `getChanges` returns from its transaction body. Records are
/// structural, so this matches the repository's own private typedef and lets
/// the `runTx` stub be written with the exact type argument mocktail matches
/// on.
typedef _TablePage = ({
  String tableName,
  List<Map<String, dynamic>> rows,
  int cursor,
  bool hitLimit,
});

class _MockDatabaseClient extends Mock implements DatabaseClient {}

class _MockPool extends Mock implements Pool<dynamic> {}

class _MockTxSession extends Mock implements TxSession {}

class _MockResult extends Mock implements Result {}

/// A pull page. Only `map` is exercised: `_mapResult` walks the rows and asks
/// each one for its column map.
class _FakeResult extends Fake implements Result {
  _FakeResult(this._rows);

  final List<ResultRow> _rows;

  @override
  Iterable<T> map<T>(T Function(ResultRow) toElement) => _rows.map(toElement);
}

class _FakeRow extends Fake implements ResultRow {
  _FakeRow(this._columns);

  final Map<String, dynamic> _columns;

  @override
  Map<String, dynamic> toColumnMap() => Map<String, dynamic>.from(_columns);
}

/// Reads the SQL a `Sql.named` description was built from.
///
/// `Sql.named` has no *public* accessor for its source string, but the
/// implementation it returns keeps it in a plain `sql` field, which a dynamic
/// read reaches. Three of the rules this repository has to obey live purely in
/// the statement text and leave no trace at all in the parameter map: which
/// columns the ON CONFLICT SET list assigns (a column a push never mentioned
/// must not be in it), and the two halves of the conflict guard (the NULL-safe
/// comparison and the device-id tiebreak). They have to be assertable
/// somewhere, and this is the only place they exist.
String _sqlTextOf(Object? query) {
  final text = (query as dynamic).sql;
  return text is String ? text : '';
}

/// Records every `execute` the repository issues, in order, so a test can
/// assert on the statement and the parameters that reach PostgreSQL.
///
/// Each table's parameter map has a distinct shape (`amountMinor` only exists
/// on transactions, `balanceMinor` only on accounts), so ordering and identity
/// are both recoverable from the parameters alone.
class _ExecuteRecorder {
  final calls = <Map<String, dynamic>>[];
  final sql = <String>[];

  void register(_MockTxSession session) {
    when(
      () => session.execute(
        any<Object>(),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((invocation) async {
      final params = invocation.namedArguments[#parameters];
      calls.add(
        params is Map ? Map<String, dynamic>.from(params) : <String, dynamic>{},
      );
      sql.add(_sqlTextOf(invocation.positionalArguments.first));
      return _MockResult();
    });
  }

  /// Every recorded statement except the advisory lock every batch opens with.
  List<Map<String, dynamic>> get writes =>
      calls.where((call) => !call.containsKey('lockId')).toList();

  Map<String, dynamic>? withKey(String key) {
    for (final call in calls) {
      if (call.containsKey(key)) return call;
    }
    return null;
  }

  /// The statement text of the first write whose parameters carry [key].
  String sqlWithKey(String key) {
    final at = indexOfKey(key);
    return at < 0 ? '' : sql[at];
  }

  int indexOfKey(String key) =>
      calls.indexWhere((call) => call.containsKey(key));
}

/// Matches an upsert whose ON CONFLICT clause writes [column].
///
/// The assignment is `column = CASE WHEN <last-write-wins> THEN EXCLUDED.column
/// ELSE table.column END` rather than a bare `column = EXCLUDED.column`: the
/// guard moved out of the statement's WHERE and into every assignment so that a
/// losing push still rewrites the row, bumps `server_seq` and thereby hands the
/// winning version back to the device that lost. Both halves are checked here,
/// because a CASE that never names EXCLUDED writes nothing at all.
Matcher assigns(String column) => allOf(
      contains('$column = CASE WHEN '),
      contains('THEN EXCLUDED.$column '),
    );

void main() {
  late _MockDatabaseClient dbClient;
  late _MockPool pool;
  late _MockTxSession session;
  late _ExecuteRecorder recorder;
  late SyncRepository repository;

  setUpAll(() {
    registerFallbackValue(Sql.named('SELECT 1'));
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    dbClient = _MockDatabaseClient();
    pool = _MockPool();
    session = _MockTxSession();
    recorder = _ExecuteRecorder()..register(session);
    repository = SyncRepository(dbClient);

    when(() => dbClient.pool).thenReturn(pool);
    // `runTx<Null>`, not `<void>`: the repository writes
    // `pool.runTx((session) async { ... })`, and an async body with no return
    // statement infers R = Null. mocktail matches on type arguments, so a
    // `<void>` stub silently fails to match and the mock returns null into a
    // `Future` slot ("type 'Null' is not a subtype of type 'Future<Null>'").
    when(() => pool.runTx<Null>(any())).thenAnswer((invocation) async {
      final body =
          invocation.positionalArguments.first as Future<void> Function(
        TxSession,
      );
      await body(session);
      return null;
    });
    // The pull half. It reads every table inside one transaction, so it comes
    // through `runTx` too - with a different type argument, which mocktail
    // treats as a different call.
    when(() => pool.runTx<List<_TablePage>>(any())).thenAnswer(
      (invocation) async {
        final body = invocation.positionalArguments.first
            as Future<List<_TablePage>> Function(TxSession);
        return body(session);
      },
    );
  });

  /// A transaction row as the client actually sends it: camelCase JSON keys,
  /// snake_case columns on the far side.
  Map<String, dynamic> txRow({
    Object? amountMinor = -2550,
    Object? feeMinor = 0,
    Object? date = '2024-03-01T00:00:00.000',
    Object? isDeleted = false,
  }) => {
    'id': 't1',
    'description': 'coffee',
    'amount': -25.5,
    'amountMinor': amountMinor,
    'date': date,
    'accountId': 'a1',
    'categoryId': 'c1',
    'currencyCode': 'EUR',
    'exchangeRate': null,
    'exchangeRatePreset': null,
    'fee': 0.0,
    'feeMinor': feeMinor,
    'linkedTransactionId': null,
    'modifiedAt': 1700000000000,
    'deviceId': 'dev-1',
    'isDeleted': isDeleted,
  };

  Map<String, dynamic> accountRow({
    Object? balanceMinor = 10000,
    Object? creationDate = '2024-01-01T00:00:00.000',
    Object? balance = 100.0,
    Object? assetQuantity,
  }) => {
    'id': 'a1',
    'name': 'Main',
    'description': null,
    'balance': balance,
    'balanceMinor': balanceMinor,
    'currencyCode': 'EUR',
    'currencyDesignationId': 'd1',
    'styleId': null,
    'accountTypeId': 'at1',
    'creationDate': creationDate,
    'country': null,
    'assetId': null,
    'assetQuantity': assetQuantity,
    'feeStructure': null,
    'modifiedAt': 1700000000000,
    'deviceId': 'dev-1',
    'isDeleted': false,
  };

  group('upsertBatch ordering', () {
    test('writes accounts before the transactions that reference them',
        () async {
      // The client sends one JSON object with every table in it; insertion
      // order of the map must not decide execution order, or a transaction
      // arrives before its account and the FK rejects the whole batch.
      await repository.upsertBatch({
        'transactions': [txRow()],
        'accounts': [accountRow()],
      });

      final accountAt = recorder.indexOfKey('balanceMinor');
      final txAt = recorder.indexOfKey('amountMinor');
      expect(accountAt, isNonNegative);
      expect(txAt, isNonNegative);
      expect(accountAt, lessThan(txAt));
    });

    test('runs inside a transaction, not a bare connection', () async {
      // A partially applied batch is visible to a concurrent pull, which then
      // caches a half-written state and never re-fetches it.
      await repository.upsertBatch({'accounts': [accountRow()]});

      verify(() => pool.runTx<Null>(any())).called(1);
    });

    test('ignores tables it does not know', () async {
      await repository.upsertBatch({'not_a_table': [<String, dynamic>{}]});

      expect(recorder.writes, isEmpty);
    });

    test('takes the push lock before writing anything', () async {
      // server_seq is drawn when a row is written, not when the transaction
      // commits, so two overlapping pushes can commit in the opposite order to
      // the numbers they took. A pull in between then moves its cursor past the
      // higher number and never sees the lower one. Serialising the writers is
      // what makes sequence order and commit order the same order.
      await repository.upsertBatch({'accounts': [accountRow()]});

      expect(recorder.calls.first.containsKey('lockId'), isTrue,
          reason: 'the lock must be held before the first write, not after');
      expect(recorder.writes, isNotEmpty);
    });
  });

  group('the opening balance crosses the wire', () {
    // Every client throws away the balance it is sent and rebuilds it from
    // this anchor plus the transactions it holds, because balances merge as
    // scalars while transactions merge as a set. The anchor was the one number
    // on an account that nothing could re-derive, and this server dropped it:
    // it was absent from the column list on the way in and from the pull's
    // column map on the way out. A receiver with no anchor works one out from
    // whatever balance it happens to hold, so two devices that each spent from
    // the same account before syncing both derived an anchor inflated by the
    // spend they had not seen yet, then rebuilt a balance that matched it. The
    // account was wrong on both devices, consistently, forever.
    test('a pushed anchor is bound, not dropped', () async {
      await repository.upsertBatch({
        'accounts': [
          {...accountRow(), 'openingBalance': 250.5, 'openingBalanceMinor': 25050},
        ],
      });

      final params = recorder.withKey('balanceMinor')!;
      expect(params['openingBalance'], 250.5);
      expect(params['openingBalanceMinor'], 25050);
    });

    test('and is written on conflict, not only on insert', () async {
      await repository.upsertBatch({
        'accounts': [
          {...accountRow(), 'openingBalance': 250.5, 'openingBalanceMinor': 25050},
        ],
      });

      final sql = recorder.sqlWithKey('balanceMinor');
      expect(sql, contains('opening_balance'));
      expect(sql, contains('opening_balance_minor'));
    });

    test('a client that has never heard of the anchor still pushes', () async {
      // The presence rule, on the column that most needs it: an older client
      // sends no anchor at all, and binding NULL for it would erase the one
      // the fleet had already agreed on.
      await repository.upsertBatch({'accounts': [accountRow()]});

      final params = recorder.withKey('balanceMinor')!;
      expect(params.containsKey('openingBalance'), isFalse);
      expect(recorder.sqlWithKey('balanceMinor'), isNot(contains('opening_balance')));
    });

    test('an anchor explicitly sent as null is a real clear', () async {
      // NULL is the wire's word for "this sender has no anchor", and the
      // receiver reads it as such. It is not the same as saying nothing.
      await repository.upsertBatch({
        'accounts': [
          {...accountRow(), 'openingBalance': null, 'openingBalanceMinor': null},
        ],
      });

      final params = recorder.withKey('balanceMinor')!;
      expect(params.containsKey('openingBalance'), isTrue);
      expect(params['openingBalance'], isNull);
      expect(params['openingBalanceMinor'], isNull);
    });
  });

  group('minor units survive the wire', () {
    test('an exact integer is passed through unchanged', () async {
      await repository.upsertBatch({'transactions': [txRow()]});

      final params = recorder.withKey('amountMinor')!;
      expect(params['amountMinor'], -2550);
      expect(params['feeMinor'], 0);
    });

    test('null minor units stay null and are never coerced to 0', () async {
      // NULL marks a crypto/commodity row whose double column is
      // authoritative. Writing 0 here would silently rewrite the amount on
      // every device that pulls it.
      await repository.upsertBatch({
        'transactions': [txRow(amountMinor: null, feeMinor: null)],
      });

      final params = recorder.withKey('amount')!;
      expect(params['amountMinor'], isNull);
      expect(params['feeMinor'], isNull);
      expect(params['amount'], -25.5);
    });

    test('a numeric string is parsed rather than dropped', () async {
      await repository.upsertBatch({
        'transactions': [txRow(amountMinor: '-2550')],
      });

      expect(recorder.withKey('amountMinor')!['amountMinor'], -2550);
    });

    test('balance_minor is carried on accounts too', () async {
      await repository.upsertBatch({'accounts': [accountRow()]});

      expect(recorder.withKey('balanceMinor')!['balanceMinor'], 10000);
    });

    test('a null double stays null instead of becoming 0.0', () async {
      await repository.upsertBatch({'accounts': [accountRow()]});

      final params = recorder.withKey('balanceMinor')!;
      expect(params['assetQuantity'], isNull);
    });
  });

  group('unusable input is skipped, not guessed at', () {
    test('a transaction with an unparseable date is not written', () async {
      // Stamping it with DateTime.now() would file the transaction under the
      // wrong month on every device, silently.
      await repository.upsertBatch({
        'transactions': [txRow(date: 'not-a-date')],
      });

      expect(recorder.writes, isEmpty);
    });

    test('a transaction with a null date is not written', () async {
      await repository.upsertBatch({'transactions': [txRow(date: null)]});

      expect(recorder.writes, isEmpty);
    });

    test('epoch milliseconds are accepted as a date', () async {
      await repository.upsertBatch({
        'transactions': [txRow(date: 1709251200000)],
      });

      final params = recorder.withKey('date')!;
      expect(params['date'], DateTime.fromMillisecondsSinceEpoch(1709251200000));
    });

    test('an account with a bad creationDate is still written, with NULL',
        () async {
      // Dropping the account would break the accounts(id) foreign key for
      // every transaction it owns — the whole batch would then roll back.
      await repository.upsertBatch({
        'accounts': [accountRow(creationDate: 'garbage')],
      });

      final params = recorder.withKey('balanceMinor')!;
      expect(params['creationDate'], isNull);
      expect(params['id'], 'a1');
    });
  });

  group('isDeleted normalisation', () {
    test('accepts a real bool', () async {
      await repository.upsertBatch({
        'transactions': [txRow(isDeleted: true)],
      });

      expect(recorder.withKey('amountMinor')!['isDeleted'], isTrue);
    });

    test('accepts SQLite integer 1/0, which is what the client sends',
        () async {
      await repository.upsertBatch({'transactions': [txRow(isDeleted: 1)]});
      expect(recorder.withKey('amountMinor')!['isDeleted'], isTrue);

      recorder.calls.clear();
      await repository.upsertBatch({'transactions': [txRow(isDeleted: 0)]});
      expect(recorder.withKey('amountMinor')!['isDeleted'], isFalse);
    });
  });

  group('the worldwide inflation series is always named', () {
    Map<String, dynamic> inflationRow({Object? country}) => {
          'date': '2025-03-01T00:00:00.000',
          'percent': 2.5,
          'country': country,
          'preset': 1,
          'modifiedAt': 100,
          'deviceId': 'd1',
          'sourceId': null,
        };

    // `country` is part of the primary key, so Postgres has it as NOT NULL,
    // and a push is one transaction: a single null would abort the whole
    // batch, and a client still on the old schema would then fail every push
    // it ever made.
    test('a null country becomes the sentinel', () async {
      await repository.upsertBatch({
        'inflation_rates': [inflationRow(country: null)],
      });

      expect(recorder.withKey('percent')!['country'], 'global');
    });

    test('an empty country becomes the sentinel', () async {
      await repository.upsertBatch({
        'inflation_rates': [inflationRow(country: '')],
      });

      expect(recorder.withKey('percent')!['country'], 'global');
    });

    test('a real country is left alone', () async {
      await repository.upsertBatch({
        'inflation_rates': [inflationRow(country: 'RS')],
      });

      expect(recorder.withKey('percent')!['country'], 'RS');
    });

    test('the bulk path names it too', () async {
      // Over fifty rows takes a different statement builder, and it is the one
      // a first sync of a whole inflation history goes through.
      await repository.upsertBatch({
        'inflation_rates': [
          for (var i = 0; i < 60; i++) inflationRow(country: null),
        ],
      });

      // The multi-row builder names its parameters `<jsonKey>_<rowIndex>`.
      final params = recorder.withKey('country_0')!;
      expect(params['country_0'], 'global');
      expect(params['country_59'], 'global');
    });
  });

  group('pull cursor', () {
    /// Queues one result per table query, in the order getChanges issues them
    /// (map order of its table config), and answers an empty page for the rest.
    void answerPages(List<List<Map<String, dynamic>>> pages) {
      var next = 0;
      when(
        () => session.execute(
          any<Object>(),
          parameters: any(named: 'parameters'),
        ),
      ).thenAnswer((invocation) async {
        // The lock the transaction opens with is not a table query, so it must
        // not consume a queued page.
        final params = invocation.namedArguments[#parameters];
        if (params is Map && params.containsKey('lockId')) {
          return _FakeResult(const []);
        }
        final rows =
            next < pages.length ? pages[next] : const <Map<String, dynamic>>[];
        next++;
        return _FakeResult(
          [for (final r in rows) _FakeRow(r)],
        );
      });
    }

    Map<String, dynamic> row(int seq, String id) => {
          'id': id,
          'modified_at': 1,
          'server_seq': seq,
        };

    test('the cursor is the highest sequence handed out', () async {
      answerPages([
        [row(7, 'c1'), row(9, 'c2')],
      ]);

      final result = await repository.getChanges(0, limit: 100);

      expect(result.lastTimestamp, 9);
      expect(result.hasMore, isFalse);
    });

    test('the cursor is a sequence, so a low modified_at cannot hold it back',
        () async {
      // The bug this replaced: a device pushing with a clock behind its peers
      // wrote rows below a cursor everyone had already passed, and no peer ever
      // saw them again. Sequence order is assigned by the server on write, so a
      // stale clock cannot place a row behind the cursor.
      answerPages([
        [
          {'id': 'late', 'modified_at': 1, 'server_seq': 42},
        ],
      ]);

      final result = await repository.getChanges(41, limit: 100);

      expect(result.lastTimestamp, 42);
      expect(result.changes['categories']!.single['id'], 'late');
    });

    test('the anchor comes back under the name the client reads it by',
        () async {
      // `SELECT *` returns every column, and a column the map does not name is
      // handed on under its raw snake_case key. So the anchor did reach the
      // client - as `opening_balance`, which nothing on the client reads -
      // and every pulled account looked anchorless. Being absent from the map
      // is not a no-op here; it is the bug.
      answerPages([
        const [],
        const [],
        [
          {
            'id': 'a1',
            'balance': 90.0,
            'opening_balance': 100.0,
            'opening_balance_minor': 10000,
            'modified_at': 1,
            'server_seq': 5,
          },
        ],
      ]);

      final result = await repository.getChanges(0, limit: 100);

      final account = result.changes['accounts']!.single;
      expect(account['openingBalance'], 100.0);
      expect(account['openingBalanceMinor'], 10000);
      expect(account.containsKey('opening_balance'), isFalse);
    });

    test('a truncated table pins the cursor for every table', () async {
      // categories fills its limit at seq 3 while transactions has already
      // returned seq 900. Advancing to 900 would skip everything categories
      // still owes. The untruncated table just re-sends a few rows next page.
      answerPages([
        [row(1, 'c1'), row(2, 'c2'), row(3, 'c3')],
        [row(900, 't1')],
      ]);

      final result = await repository.getChanges(0, limit: 3);

      expect(result.hasMore, isTrue);
      expect(result.lastTimestamp, 3);
    });

    test('server_seq is bookkeeping and never reaches the client', () async {
      answerPages([
        [row(7, 'c1')],
      ]);

      final result = await repository.getChanges(0, limit: 100);

      expect(result.changes['categories']!.single.containsKey('serverSeq'),
          isFalse);
      expect(result.changes['categories']!.single.containsKey('server_seq'),
          isFalse);
    });

    test('the requested cursor and limit are what reach the query', () async {
      answerPages([]);

      await repository.getChanges(55, limit: 12);

      final captured = verify(
        () => session.execute(
          any<Object>(),
          parameters: captureAny(named: 'parameters'),
        ),
      ).captured.cast<Map<String, dynamic>>();
      final query = captured.firstWhere((c) => c.containsKey('lastSync'));
      expect(query['lastSync'], 55);
      expect(query['limit'], 12);
    });

    test('an untruncated table is trimmed to the cursor the page reports',
        () async {
      // categories fills its limit at seq 3; transactions has already returned
      // seq 900, far past it. The page can only claim up to 3, so the row at
      // 900 is not part of this page at all: handed out now it would be handed
      // out again on every later page too, until the truncated table finally
      // caught up, and each of those re-deliveries is a whole table's delta
      // re-applied for nothing.
      answerPages([
        [row(1, 'c1'), row(2, 'c2'), row(3, 'c3')],
        [row(900, 't1')],
      ]);

      final result = await repository.getChanges(0, limit: 3);

      expect(result.lastTimestamp, 3);
      expect(result.hasMore, isTrue);
      expect(result.changes['categories'], hasLength(3));
      expect(
        result.changes.containsKey('transactions'),
        isFalse,
        reason: 'a page is a prefix of the write order, not a mixture',
      );
    });

    test('a row held back by the cursor arrives on the next page', () async {
      // The other half of trimming: held back is not dropped. The follow-up
      // page asks from 3 and the row at 900 is handed over exactly once.
      answerPages([
        [row(4, 'c4')],
        [row(900, 't1')],
      ]);

      final result = await repository.getChanges(3, limit: 3);

      expect(result.lastTimestamp, 900);
      expect(result.hasMore, isFalse);
      expect(result.changes['transactions']!.single['id'], 't1');
    });

    test('a table that only holds rows past the cursor is left out entirely',
        () async {
      // An empty list for a table is not the same as no key: the client walks
      // the keys it is given, and an empty one costs a transaction and a log
      // line per page for a table that has nothing to say yet.
      answerPages([
        [row(1, 'c1'), row(2, 'c2')],
        [row(500, 't1')],
      ]);

      final result = await repository.getChanges(0, limit: 2);

      expect(result.changes.keys, ['categories']);
    });

    test('api_settings hands back its tombstone', () async {
      // The pull map is the second half of the same gap: even with the column
      // written, a delete that is not selected out never reaches the peer.
      answerPages([
        for (var i = 0; i < 8; i++) const <Map<String, dynamic>>[],
        [
          {
            'id': 'exchange_rates',
            'is_deleted': true,
            'modified_at': 5,
            'server_seq': 5,
          },
        ],
      ]);

      final result = await repository.getChanges(0, limit: 100);

      expect(result.changes['api_settings']!.single['isDeleted'], isTrue);
    });

    test('a stored timestamp goes back out as the wall clock it is', () async {
      // The column is `TIMESTAMP without time zone`, so the driver hands back
      // a DateTime flagged UTC whose fields are the stored wall clock. Sent
      // with its 'Z' the client re-read it as an instant and shifted it to the
      // previous day west of UTC - a different exchange_rates key, and a
      // month-boundary transaction filed under the wrong month.
      answerPages([
        [
          {
            'id': 'c1',
            'date': DateTime.utc(2024, 11, 3, 1, 30),
            'modified_at': 1,
            'server_seq': 1,
          },
        ],
      ]);

      final result = await repository.getChanges(0, limit: 100);

      expect(
        result.changes['categories']!.single['date'],
        '2024-11-03T01:30:00.000',
      );
    });

    test('every table is read inside one locked transaction', () async {
      // Read outside a transaction, the sixteen queries each saw a different
      // instant, and a row written into a table that had already been read fell
      // below the cursor this page reports - gone for good. Holding the push
      // lock for all of them is what makes a page a prefix of the write order.
      //
      // Shared versus exclusive is not observable here: `Sql.named` exposes no
      // accessor for its text, so the lock id is the only assertable evidence,
      // and it is the same id the push takes.
      answerPages([
        [row(7, 'c1')],
      ]);

      await repository.getChanges(0, limit: 100);

      final captured = verify(
        () => session.execute(
          any<Object>(),
          parameters: captureAny(named: 'parameters'),
        ),
      ).captured.cast<Map<String, dynamic>>();
      expect(captured.first.containsKey('lockId'), isTrue);
      expect(
        captured.where((c) => c.containsKey('lastSync')).length,
        greaterThan(1),
        reason: 'all tables are read on the same session, after the lock',
      );
    });
  });

  group('a stamp the push did not carry is the oldest possible one', () {
    // `modified_at BIGINT DEFAULT 0` only fires when the column is left out of
    // the INSERT, and the upsert always named it, so a push with no
    // `modifiedAt` stored a real NULL. `EXCLUDED.modified_at > t.modified_at`
    // then evaluated to NULL - not TRUE - for every later push, so the row
    // froze: the writes were answered 200, the client dropped its queue entry,
    // and no edit ever landed on that row again.
    test('an absent modifiedAt is bound as 0, never as NULL', () async {
      await repository.upsertBatch({
        'currencies': [
          {'code': 'EUR', 'name': 'Euro'},
        ],
      });

      expect(recorder.withKey('code')!['modifiedAt'], 0);
    });

    test('a modifiedAt sent as a numeric string is still a number', () async {
      await repository.upsertBatch({
        'currencies': [
          {'code': 'EUR', 'name': 'Euro', 'modifiedAt': '1700000000000'},
        ],
      });

      expect(recorder.withKey('code')!['modifiedAt'], 1700000000000);
    });

    test('the conflict guard reads a stored NULL as 0', () async {
      // Belt and braces for the rows an older server already froze: coercing
      // the incoming value only fixes what is written from now on, and the
      // frozen rows would stay frozen forever without this.
      await repository.upsertBatch({
        'transactions': [txRow()],
      });

      expect(
        recorder.sqlWithKey('amountMinor'),
        contains('COALESCE(transactions.modified_at, 0)'),
      );
    });
  });

  group('a tie is broken by device id, not by arrival order', () {
    // Two devices editing one row inside the same millisecond stamp the same
    // modified_at. Under a strict `>` whichever push landed first kept the
    // row; the second was answered 200 and drained, and because no UPDATE
    // happened server_seq never moved, so neither device was ever handed the
    // other's version. The two ends diverge permanently and silently.
    test('the guard admits an equal stamp from a higher device id', () async {
      await repository.upsertBatch({
        'transactions': [txRow()],
      });

      final guard = recorder.sqlWithKey('amountMinor');
      expect(
        guard,
        contains(
          'EXCLUDED.modified_at = COALESCE(transactions.modified_at, 0)',
        ),
      );
      expect(
        guard,
        contains(
          "COALESCE(EXCLUDED.device_id, '') > "
          "COALESCE(transactions.device_id, '')",
        ),
      );
    });

    test('every table carries the rule, not just the busy ones', () async {
      // A tiebreak that only some tables apply is not a tiebreak: the tables
      // that lack it still diverge, and the client applies one rule to all of
      // them.
      await repository.upsertBatch({
        'settings': [
          {'key': 'theme', 'value': 'dark', 'modifiedAt': 5, 'deviceId': 'd1'},
        ],
        'api_settings': [
          {
            'id': 'exchange_rates',
            'enabled': true,
            'autoFetch': true,
            'modifiedAt': 5,
          },
        ],
      });

      for (final key in ['key', 'autoFetch']) {
        expect(
          recorder.sqlWithKey(key),
          contains("COALESCE(EXCLUDED.device_id, '') > COALESCE("),
          reason: 'the tiebreak has to be total or the two ends disagree',
        );
      }
    });

    test('the bulk path resolves ties the same way', () async {
      await repository.upsertBatch({
        'transactions': [for (var i = 0; i < 60; i++) txRow()],
      });

      expect(
        recorder.sqlWithKey('amountMinor_0'),
        contains(
          "COALESCE(EXCLUDED.device_id, '') > "
          "COALESCE(transactions.device_id, '')",
        ),
      );
    });
  });

  group('a field the push never mentioned is left alone', () {
    /// [txRow] with [keys] deleted outright - not set to null. That is what an
    /// older build sends: `amount_minor`, `fee_minor` and `balance_minor` were
    /// added to this schema by migration, so clients that predate them exist
    /// by construction, and so does every hand-rolled push.
    Map<String, dynamic> without(List<String> keys) {
      final row = txRow();
      for (final key in keys) {
        row.remove(key);
      }
      return row;
    }

    test('absent minor units are neither bound nor assigned', () async {
      await repository.upsertBatch({
        'transactions': [
          without(['amountMinor', 'feeMinor']),
        ],
      });

      final params = recorder.withKey('id')!;
      expect(params.containsKey('amountMinor'), isFalse);
      expect(params.containsKey('feeMinor'), isFalse);

      final sql = recorder.sqlWithKey('id');
      expect(sql, isNot(contains('amount_minor')));
      expect(sql, isNot(contains('fee_minor')));
      // Everything the push did carry is still written, so this is not
      // "an old client's pushes get ignored".
      expect(sql, assigns('description'));
    });

    test('an explicit null still clears the column', () async {
      // NULL is a real value on this column: it marks a row whose amount lives
      // in the floating-point column instead. Absence and an explicit null are
      // told apart by `containsKey` on the pushed map, never by the value, so
      // a deliberate clear keeps working.
      await repository.upsertBatch({
        'transactions': [txRow(amountMinor: null, feeMinor: null)],
      });

      final params = recorder.withKey('amountMinor')!;
      expect(params.containsKey('amountMinor'), isTrue);
      expect(params['amountMinor'], isNull);
      expect(
        recorder.sqlWithKey('amountMinor'),
        assigns('amount_minor'),
      );
    });

    test('an absent balanceMinor leaves the stored balance alone', () async {
      final row = accountRow()..remove('balanceMinor');

      await repository.upsertBatch({
        'accounts': [row],
      });

      expect(recorder.sqlWithKey('id'), isNot(contains('balance_minor')));
    });

    test('an absent isDeleted does not resurrect a deleted row', () async {
      // The worst case of the whole class: an edit that predates tombstones
      // silently rewrote is_deleted to false and undeleted the row on every
      // device in the fleet.
      await repository.upsertBatch({
        'styles': [
          {'id': 's1', 'name': 'Red', 'modifiedAt': 9, 'deviceId': 'd1'},
        ],
      });

      expect(recorder.sqlWithKey('id'), isNot(contains('is_deleted')));
    });

    test('an explicit isDeleted false is a real undelete', () async {
      await repository.upsertBatch({
        'styles': [
          {
            'id': 's1',
            'name': 'Red',
            'isDeleted': false,
            'modifiedAt': 9,
            'deviceId': 'd1',
          },
        ],
      });

      expect(
        recorder.sqlWithKey('id'),
        assigns('is_deleted'),
      );
    });

    test('the bulk path honours absence too', () async {
      await repository.upsertBatch({
        'transactions': [
          for (var i = 0; i < 60; i++) without(['amountMinor', 'feeMinor']),
        ],
      });

      final params = recorder.withKey('id_0')!;
      expect(params.containsKey('amountMinor_0'), isFalse);
      expect(recorder.sqlWithKey('id_0'), isNot(contains('amount_minor')));
    });

    test('rows carrying different fields do not share one statement', () async {
      // One statement has one column list and one SET list. Folding a row that
      // omits a column into the same statement as one that carries it would
      // have to bind NULL for the first - which is the very overwrite the
      // presence rule exists to prevent - so the rows are grouped by the set
      // of fields they actually carry.
      await repository.upsertBatch({
        'transactions': [
          for (var i = 0; i < 30; i++) txRow(),
          for (var i = 0; i < 30; i++) without(['amountMinor']),
        ],
      });

      expect(recorder.writes.length, 2);
    });
  });

  group('api_settings carries its tombstone', () {
    // The client has always pushed `isDeleted` for this table and has always
    // read it back; the server was the only end that dropped it, because the
    // table was created without the column. So a provider the user deleted
    // was stored live and handed straight back to every other device on the
    // next pull, on every sync, forever.
    test('a deleted provider is written as deleted', () async {
      await repository.upsertBatch({
        'api_settings': [
          {
            'id': 'exchange_rates',
            'enabled': false,
            'autoFetch': false,
            'modifiedAt': 2000,
            'deviceId': 'dev-1',
            'isDeleted': true,
          },
        ],
      });

      final params = recorder.withKey('autoFetch')!;
      expect(params['isDeleted'], isTrue);
      expect(
        recorder.sqlWithKey('autoFetch'),
        assigns('is_deleted'),
      );
    });
  });

  group('a date is a wall clock on the way in', () {
    // The client sends `DateTime.toIso8601String()` of a local DateTime: a
    // naive wall clock with no zone marker. `DateTime.parse` reads that as
    // server-local, and the driver then converts to UTC before writing to a
    // `TIMESTAMP without time zone` column - so the very same push landed on a
    // different instant depending on the TZ the container happened to run in,
    // and shifted the stored day for anyone east or west of it.
    test('a naive push is bound as the wall clock it spells', () async {
      // 01:30 on a DST-transition night, so a server that resolved the string
      // against a local zone would not merely shift it - it would have two
      // instants to choose from.
      await repository.upsertBatch({
        'transactions': [txRow(date: '2024-11-03T01:30:00.000')],
      });

      expect(
        recorder.withKey('date')!['date'],
        DateTime.utc(2024, 11, 3, 1, 30),
      );
    });

    test('a string that does carry a zone keeps its instant', () async {
      await repository.upsertBatch({
        'transactions': [txRow(date: '2024-03-01T05:00:00.000Z')],
      });

      expect(recorder.withKey('date')!['date'], DateTime.utc(2024, 3, 1, 5));
    });

    test('an epoch millisecond push is unaffected', () async {
      // The other shape the client sends. It is an instant already, so it must
      // keep going through unchanged.
      await repository.upsertBatch({
        'transactions': [txRow(date: 1709251200000)],
      });

      expect(
        recorder.withKey('date')!['date'],
        DateTime.fromMillisecondsSinceEpoch(1709251200000),
      );
    });
  });

  group('a push that loses still moves the change log', () {
    // The bug this shape exists for: the guard used to be a WHERE on the
    // statement, so a row that lost last-write-wins was simply not written.
    // No UPDATE meant no `server_seq` bump, and the device that lost had
    // already pulled past that row - so it kept its own version of it forever
    // while every other device showed the winner's, with nothing left in the
    // log that could ever repair it.

    test('losing no longer means not being written', () async {
      await repository.upsertBatch({
        'accounts': [accountRow()],
      });

      final sql = recorder.sqlWithKey('balanceMinor')!;
      expect(sql, contains('ON CONFLICT'));
      // The statement still has a WHERE, but it no longer asks who won: it
      // asks whether there is anything to say. A row that lost and disagrees
      // is written - to the value it lost to - so that `server_seq` moves and
      // the loser is handed the winner on its next pull.
      expect(
        sql,
        contains('balance IS DISTINCT FROM EXCLUDED.balance'),
      );
      expect(
        sql,
        contains('modified_at IS DISTINCT FROM EXCLUDED.modified_at'),
      );
    });

    test('a losing push that agrees with the row is skipped', () async {
      // The other half. A device re-pushing rows it already agrees with -
      // the ~283 000 seeded exchange rates after a repair step - must not
      // stamp a new sequence number on each of them and make every other
      // device re-download the table for nothing.
      await repository.upsertBatch({
        'accounts': [accountRow()],
      });

      final sql = recorder.sqlWithKey('balanceMinor')!;
      final where = sql.substring(sql.indexOf('WHERE'));
      expect(where, contains('IS DISTINCT FROM'));
      // Not <>: that is NULL the moment either side is, so an unchanged NULL
      // column would read as a difference on every push and nothing would
      // ever be skipped.
      expect(where, isNot(contains('<>')));
    });

    test('a column that loses is written back to the value it had', () async {
      // The ELSE branch is what makes the write happen at all. Assigning the
      // column to itself is a real UPDATE in Postgres, and the `server_seq`
      // trigger fires BEFORE UPDATE on every row, unconditionally.
      await repository.upsertBatch({
        'accounts': [accountRow()],
      });

      final sql = recorder.sqlWithKey('balanceMinor')!;
      expect(sql, contains('ELSE accounts.name END'));
      expect(sql, contains('ELSE accounts.balance END'));
    });

    test('the guard itself is unchanged, only where it is asked', () async {
      // Same total order as before and the same one all three ends evaluate:
      // modified_at, then device_id. Moving it must not change who wins.
      await repository.upsertBatch({
        'accounts': [accountRow()],
      });

      final sql = recorder.sqlWithKey('balanceMinor')!;
      expect(
        sql,
        contains('EXCLUDED.modified_at > COALESCE(accounts.modified_at, 0)'),
      );
      expect(
        sql,
        contains("COALESCE(EXCLUDED.device_id, '') > "
            "COALESCE(accounts.device_id, '')"),
      );
    });

    test('the key columns are still not assigned', () async {
      // They are what matched; writing them would be a no-op at best and, on
      // the composite-key tables, a rename at worst.
      await repository.upsertBatch({
        'accounts': [accountRow()],
      });

      final sql = recorder.sqlWithKey('balanceMinor')!;
      // The eight-space indent every assignment carries, so this does not
      // match `asset_id` or `style_id`.
      expect(sql, isNot(contains('        id = ')));
    });

    test('a composite-key table keeps its key columns out of the SET too',
        () async {
      await repository.upsertBatch({
        'exchange_rates': [
          {
            'fromCurrencyCode': 'USD',
            'toCurrencyCode': 'EUR',
            'rate': 0.9,
            'preset': 0,
            'date': '2026-03-15T00:00:00.000',
            'modifiedAt': 1700000000000,
            'deviceId': 'dev-1',
          },
        ],
      });

      final sql = recorder.sqlWithKey('rate')!;
      expect(sql, assigns('rate'));
      expect(sql, isNot(contains('        from_currency_code = ')));
      expect(sql, isNot(contains('        date = ')));
      expect(sql, isNot(contains('        preset = ')));
      // And they are not in the difference test either: they are equal by
      // definition, because they are what the conflict matched on.
      final where = sql.substring(sql.indexOf('WHERE'));
      expect(where, isNot(contains('from_currency_code IS DISTINCT FROM')));
      expect(where, contains('rate IS DISTINCT FROM EXCLUDED.rate'));
    });
  });

  group('a rate keeps its precision whatever its magnitude', () {
    /// An exchange_rates row as the client sends it.
    Map<String, dynamic> rateRow(Object? rate) => {
      'fromCurrencyCode': 'BTC',
      'toCurrencyCode': 'VES',
      'rate': rate,
      'preset': 'default',
      'date': '2024-03-01T00:00:00.000',
      'sourceId': null,
      'modifiedAt': 1700000000000,
      'deviceId': 'dev-1',
    };

    test('2.4e-10 is stored as itself, not as zero', () async {
      // toStringAsFixed(8) renders it '0.00000000', which parses back as
      // exactly 0.0. A zero rate is not a small rate: every conversion through
      // it divides by zero and every amount priced in that currency becomes
      // infinity on the far side.
      await repository.upsertBatch({
        'exchange_rates': [rateRow(2.4e-10)],
      });

      expect(recorder.withKey('rate')!['rate'], 2.4e-10);
    });

    test('a negative value under the floor keeps its sign and magnitude', () async {
      await repository.upsertBatch({
        'exchange_rates': [rateRow(-3.5e-12)],
      });

      expect(recorder.withKey('rate')!['rate'], -3.5e-12);
    });

    test('an ordinary rate is still normalised', () async {
      // Rounding is not optional: two devices that round differently write
      // different bytes for the same rate and never stop pushing it at each
      // other. Twelve significant digits, so the last few bits of
      // floating-point noise go and nothing that was ever typed does.
      await repository.upsertBatch({
        'exchange_rates': [rateRow(1.2345678912345678)],
      });

      expect(recorder.withKey('rate')!['rate'], 1.23456789123);
    });

    test('a rate just above the old eight-decimal floor is not flattened', () async {
      // The case the old rule got exactly backwards. `toStringAsFixed(8)`
      // behind a `< 1e-8` guard protected everything below the guard and
      // mangled everything just above it: this rate came out as 4e-8, a 6%
      // error, while a rate three times smaller passed through untouched.
      await repository.upsertBatch({
        'exchange_rates': [rateRow(3.7e-8)],
      });

      expect(recorder.withKey('rate')!['rate'], 3.7e-8);
    });

    test('a fractional crypto holding keeps every digit it was given', () async {
      // Same defect on the column it costs money on. 1.5e-8 BTC used to be
      // stored as 1e-8 - a third of the holding gone, silently, on the first
      // sync.
      await repository.upsertBatch({
        'accounts': [accountRow(assetQuantity: 1.5e-8)],
      });

      expect(recorder.withKey('assetQuantity')!['assetQuantity'], 1.5e-8);
    });

    test('a large balance does not gain digits it never had', () async {
      // The mirror image: at this magnitude eight decimal places is more
      // precision than a double carries, so the old rule wrote back the noise
      // instead of erasing it, and the two devices disagreed about a balance
      // neither of them had changed.
      await repository.upsertBatch({
        'accounts': [accountRow(balance: 1234567.89)],
      });

      expect(recorder.withKey('balance')!['balance'], 1234567.89);
    });

    test('a null rate is still null', () async {
      await repository.upsertBatch({
        'exchange_rates': [rateRow(null)],
      });

      expect(recorder.withKey('rate')!['rate'], isNull);
    });

    test('a numeric string under the floor is coerced without flattening', () async {
      // Postgres NUMERIC and hand-rolled pushes both arrive as strings.
      await repository.upsertBatch({
        'exchange_rates': [rateRow('0.00000000024')],
      });

      expect(recorder.withKey('rate')!['rate'], 2.4e-10);
    });
  });
}
