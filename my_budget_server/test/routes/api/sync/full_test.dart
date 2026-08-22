import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_server/data/sync_repository.dart';
import 'package:test/test.dart';

import '../../../../routes/api/sync/full/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late _MockRequestContext context;
  late _MockSyncRepository repo;

  RequestContext contextFor(Request request) {
    when(() => context.request).thenReturn(request);
    when(() => context.read<SyncRepository>()).thenReturn(repo);
    return context;
  }

  setUp(() {
    context = _MockRequestContext();
    repo = _MockSyncRepository();
    when(() => repo.getChanges(any(), limit: any(named: 'limit'))).thenAnswer(
      (_) async => (
        changes: <String, List<Map<String, dynamic>>>{},
        lastTimestamp: 0,
        hasMore: false,
      ),
    );
  });

  group('GET /api/sync/full', () {
    test('a non-GET method is rejected without touching the repository',
        () async {
      final response = await route.onRequest(
        contextFor(Request.post(Uri.parse('http://localhost/api/sync/full'))),
      );

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      verifyNever(() => repo.getChanges(any(), limit: any(named: 'limit')));
    });

    test('it asks for everything from the beginning of time', () async {
      await route.onRequest(
        contextFor(Request.get(Uri.parse('http://localhost/api/sync/full'))),
      );

      verify(() => repo.getChanges(0)).called(1);
    });

    test('a client-supplied last_sync cannot narrow a full pull', () async {
      // /full means full. Honouring ?last_sync= here would hand back a partial
      // snapshot to a client that asked to start over.
      await route.onRequest(
        contextFor(
          Request.get(
            Uri.parse('http://localhost/api/sync/full?last_sync=1700000000000'),
          ),
        ),
      );

      verify(() => repo.getChanges(0)).called(1);
    });

    test('has_more is reported so the client knows to keep paging', () async {
      when(() => repo.getChanges(any(), limit: any(named: 'limit'))).thenAnswer(
        (_) async => (
          changes: {
            'transactions': [
              {'id': 't1', 'modifiedAt': 9},
            ],
          },
          lastTimestamp: 9,
          hasMore: true,
        ),
      );

      final response = await route.onRequest(
        contextFor(Request.get(Uri.parse('http://localhost/api/sync/full'))),
      );

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['has_more'], isTrue);
      expect(body['server_timestamp'], 9);
    });

    test('a truncated snapshot says where the rest of it is', () async {
      // This endpoint takes no cursor, so `has_more: true` on its own was an
      // instruction a caller could not carry out: calling /full again returns
      // byte-identical page one forever. Naming the paging endpoint and the
      // cursor to resume from is what makes the flag actionable.
      when(() => repo.getChanges(any(), limit: any(named: 'limit'))).thenAnswer(
        (_) async => (
          changes: {
            'transactions': [
              {'id': 't1', 'modifiedAt': 9},
            ],
          },
          lastTimestamp: 9,
          hasMore: true,
        ),
      );

      final response = await route.onRequest(
        contextFor(Request.get(Uri.parse('http://localhost/api/sync/full'))),
      );

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['next'], '/api/sync/pull?last_sync=9');
    });

    test('a complete snapshot points nowhere', () async {
      // The default stub returns hasMore: false. A continuation key on a page
      // that has no continuation is the same lie in the other direction.
      final response = await route.onRequest(
        contextFor(Request.get(Uri.parse('http://localhost/api/sync/full'))),
      );

      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['has_more'], isFalse);
      expect(body.containsKey('next'), isFalse);
    });

    test('a repository failure does not leak the exception to the client',
        () async {
      const leak = 'relation "transactions" does not exist';
      when(() => repo.getChanges(any(), limit: any(named: 'limit')))
          .thenThrow(Exception(leak));

      late final Response response;
      final logged = <String>[];
      await runZoned(
        () async => response = await route.onRequest(
          contextFor(Request.get(Uri.parse('http://localhost/api/sync/full'))),
        ),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => logged.add(line),
        ),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.body(), isNot(contains(leak)));
      expect(logged.join('\n'), contains(leak));
    });
  });
}
