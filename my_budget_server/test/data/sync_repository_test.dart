import 'package:my_budget_server/data/database_client.dart';
import 'package:my_budget_server/data/sync_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgres/postgres.dart';
import 'package:test/test.dart';

class _MockDatabaseClient extends Mock implements DatabaseClient {}

class _MockPool extends Mock implements Pool<dynamic> {}

class _MockTxSession extends Mock implements TxSession {}

class _MockResult extends Mock implements Result {}

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

      expect(recorder.calls, isEmpty);
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

      expect(recorder.calls, isEmpty);
    });

    test('a transaction with a null date is not written', () async {
      await repository.upsertBatch({'transactions': [txRow(date: null)]});

      expect(recorder.calls, isEmpty);
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
}
