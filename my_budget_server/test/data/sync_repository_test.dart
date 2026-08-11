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

/// Records every `execute` the repository issues, in order, so a test can
/// assert on the parameters that reach PostgreSQL.
///
/// The SQL text is deliberately not asserted: `Sql.named` returns an opaque
/// query description with no public accessor for its source string. Each
/// table's parameter map has a distinct shape (`amountMinor` only exists on
/// transactions, `balanceMinor` only on accounts), so ordering and identity
/// are both recoverable from the parameters alone.
class _ExecuteRecorder {
  final calls = <Map<String, dynamic>>[];

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

  int indexOfKey(String key) =>
      calls.indexWhere((call) => call.containsKey(key));
}

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
  }) => {
    'id': 'a1',
    'name': 'Main',
    'description': null,
    'balance': 100.0,
    'balanceMinor': balanceMinor,
    'currencyCode': 'EUR',
    'currencyDesignationId': 'd1',
    'styleId': null,
    'accountTypeId': 'at1',
    'creationDate': creationDate,
    'country': null,
    'assetId': null,
    'assetQuantity': null,
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

      final params = recorder.withKey('cnt_0')!;
      expect(params['cnt_0'], 'global');
      expect(params['cnt_59'], 'global');
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
}
