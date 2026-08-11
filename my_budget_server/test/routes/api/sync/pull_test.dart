import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_server/data/sync_repository.dart';
import 'package:my_budget_server/http/api_responses.dart';
import 'package:test/test.dart';

import '../../../../routes/api/sync/pull/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockSyncRepository extends Mock implements SyncRepository {}

typedef _Changes = ({
  Map<String, List<Map<String, dynamic>>> changes,
  int lastTimestamp,
  bool hasMore,
});

_Changes _emptyChanges({int lastTimestamp = 0, bool hasMore = false}) => (
      changes: <String, List<Map<String, dynamic>>>{},
      lastTimestamp: lastTimestamp,
      hasMore: hasMore,
    );

void main() {
  late _MockRequestContext context;
  late _MockSyncRepository repo;

  RequestContext contextFor(Request request) {
    when(() => context.request).thenReturn(request);
    when(() => context.read<SyncRepository>()).thenReturn(repo);
    return context;
  }

  Request get_(String query) =>
      Request.get(Uri.parse('http://localhost/api/sync/pull$query'));

  setUp(() {
    context = _MockRequestContext();
    repo = _MockSyncRepository();
    when(() => repo.getChanges(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => _emptyChanges());
  });

  group('GET /api/sync/pull', () {
    test('a non-GET method is rejected without touching the repository',
        () async {
      final response = await route.onRequest(
        contextFor(Request.post(Uri.parse('http://localhost/api/sync/pull'))),
      );

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      verifyNever(() => repo.getChanges(any(), limit: any(named: 'limit')));
    });

    test('the cursor and page size reach the repository', () async {
      await route.onRequest(
        contextFor(get_('?last_sync=1700000000000&limit=250')),
      );

      verify(() => repo.getChanges(1700000000000, limit: 250)).called(1);
    });

    test('an oversized limit is clamped before it reaches the query', () async {
      // Unclamped, this became `LIMIT 100000000` on each of sixteen tables,
      // all awaited together.
      await route.onRequest(contextFor(get_('?limit=100000000')));

      verify(() => repo.getChanges(0, limit: maxPullLimit)).called(1);
    });

    test('limit=0 becomes 1 rather than a page that returns nothing', () async {
      await route.onRequest(contextFor(get_('?limit=0')));

      verify(() => repo.getChanges(0, limit: 1)).called(1);
    });

    test('a garbage cursor is read as "from the beginning"', () async {
      await route.onRequest(contextFor(get_('?last_sync=never')));

      verify(() => repo.getChanges(0, limit: defaultPullLimit)).called(1);
    });

    test('the repository result is passed through under the wire keys',
        () async {
      when(() => repo.getChanges(any(), limit: any(named: 'limit'))).thenAnswer(
        (_) async => (
          changes: {
            'accounts': [
              {'id': 'a1', 'modifiedAt': 5},
            ],
          },
          lastTimestamp: 5,
          hasMore: true,
        ),
      );

      final response = await route.onRequest(contextFor(get_('')));

      expect(response.statusCode, HttpStatus.ok);
      final body = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(body['server_timestamp'], 5);
      expect(body['has_more'], isTrue);
      expect((body['changes'] as Map)['accounts'], hasLength(1));
    });

    test('a repository failure does not leak the exception to the client',
        () async {
      const leak = 'column accounts.balance_minor does not exist';
      when(() => repo.getChanges(any(), limit: any(named: 'limit')))
          .thenThrow(Exception(leak));

      late final Response response;
      final logged = <String>[];
      await runZoned(
        () async => response = await route.onRequest(contextFor(get_(''))),
        zoneSpecification: ZoneSpecification(
          print: (_, __, ___, line) => logged.add(line),
        ),
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      final body = await response.body();
      expect(body, isNot(contains(leak)));
      expect(body, contains('internal_error'));
      // The operator still gets the detail.
      expect(logged.join('\n'), contains(leak));
    });
  });
}
