import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_server/data/sync_repository.dart';
import 'package:test/test.dart';

import '../../../../routes/api/sync/push/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late _MockRequestContext context;
  late _MockSyncRepository repo;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  RequestContext contextFor(Request request) {
    when(() => context.request).thenReturn(request);
    when(() => context.read<SyncRepository>()).thenReturn(repo);
    return context;
  }

  Request post(Object? body, {String query = ''}) => Request.post(
        Uri.parse('http://localhost/api/sync/push$query'),
        body: jsonEncode(body),
        headers: {'content-type': 'application/json'},
      );

  setUp(() {
    context = _MockRequestContext();
    repo = _MockSyncRepository();
    when(() => repo.upsertBatch(any())).thenAnswer((_) async {});
  });

  /// The route broadcasts over the WebSocket registry, which prints. Swallow
  /// it so the suite output stays readable, and return what was logged.
  Future<(Response, List<String>)> call(RequestContext ctx) async {
    late final Response response;
    final logged = <String>[];
    await runZoned(
      () async => response = await route.onRequest(ctx),
      zoneSpecification: ZoneSpecification(
        print: (_, __, ___, line) => logged.add(line),
      ),
    );
    return (response, logged);
  }

  group('POST /api/sync/push', () {
    test('a non-POST method is rejected without touching the repository',
        () async {
      final (response, _) = await call(
        contextFor(Request.get(Uri.parse('http://localhost/api/sync/push'))),
      );

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      verifyNever(() => repo.upsertBatch(any()));
    });

    test('a JSON array body is rejected as a bad request', () async {
      // The batch format is {table: [rows]}; a bare list has no table names.
      final (response, _) = await call(contextFor(post([1, 2, 3])));

      expect(response.statusCode, HttpStatus.badRequest);
      verifyNever(() => repo.upsertBatch(any()));
    });

    test('a well-formed batch is handed to the repository verbatim', () async {
      final batch = {
        'accounts': [
          {'id': 'a1', 'modifiedAt': 7},
        ],
      };

      final (response, _) = await call(contextFor(post(batch)));

      expect(response.statusCode, HttpStatus.ok);
      final captured =
          verify(() => repo.upsertBatch(captureAny())).captured.single;
      expect((captured as Map)['accounts'], hasLength(1));
    });

    test('the response carries a timestamp the client can store', () async {
      final before = DateTime.now().millisecondsSinceEpoch;
      final (response, _) = await call(contextFor(post(<String, dynamic>{})));
      final after = DateTime.now().millisecondsSinceEpoch;

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['timestamp'], inInclusiveRange(before, after));
    });

    test('the pushing device is excluded from the broadcast it caused',
        () async {
      final (_, logged) = await call(
        contextFor(post(<String, dynamic>{}, query: '?device_id=phone-1')),
      );

      expect(logged.join('\n'), contains('excluding device phone-1'));
    });

    test('an X-Device-Id header identifies the pusher too', () async {
      final request = Request.post(
        Uri.parse('http://localhost/api/sync/push'),
        body: '{}',
        headers: {
          'content-type': 'application/json',
          'X-Device-Id': 'laptop-2',
        },
      );

      final (_, logged) = await call(contextFor(request));

      expect(logged.join('\n'), contains('excluding device laptop-2'));
    });

    test('an unidentified push notifies everyone', () async {
      final (_, logged) = await call(contextFor(post(<String, dynamic>{})));

      expect(logged.join('\n'), isNot(contains('excluding device')));
    });

    test('a repository failure does not leak the exception to the client',
        () async {
      const leak = 'duplicate key value violates constraint accounts_pkey';
      when(() => repo.upsertBatch(any())).thenThrow(Exception(leak));

      final (response, logged) =
          await call(contextFor(post(<String, dynamic>{})));

      expect(response.statusCode, HttpStatus.internalServerError);
      final body = await response.body();
      expect(body, isNot(contains(leak)));
      expect(body, contains('internal_error'));
      expect(logged.join('\n'), contains(leak));
    });

    test('a malformed JSON body fails closed rather than half-applying',
        () async {
      final request = Request.post(
        Uri.parse('http://localhost/api/sync/push'),
        body: '{"accounts": [',
        headers: {'content-type': 'application/json'},
      );

      final (response, _) = await call(contextFor(request));

      expect(response.statusCode, HttpStatus.internalServerError);
      verifyNever(() => repo.upsertBatch(any()));
    });
  });
}
