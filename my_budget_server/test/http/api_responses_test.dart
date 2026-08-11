import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/http/api_responses.dart';
import 'package:test/test.dart';

/// Runs [body] with `print` captured instead of written to stdout.
List<String> capturePrints(void Function() body) {
  final lines = <String>[];
  runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, __, ___, line) => lines.add(line),
    ),
  );
  return lines;
}

void main() {
  group('parsePullLimit', () {
    test('a missing limit falls back to the default page size', () {
      expect(parsePullLimit(null), defaultPullLimit);
    });

    test('an unparseable limit falls back to the default page size', () {
      expect(parsePullLimit('all'), defaultPullLimit);
      expect(parsePullLimit(''), defaultPullLimit);
      expect(parsePullLimit('5000; DROP TABLE accounts'), defaultPullLimit);
    });

    test('a reasonable limit is used as given', () {
      expect(parsePullLimit('1'), 1);
      expect(parsePullLimit('250'), 250);
      expect(parsePullLimit('$maxPullLimit'), maxPullLimit);
    });

    test('a limit above the ceiling is clamped to it', () {
      // The pull issues one LIMIT-ed SELECT per table and awaits them
      // together, so an unclamped value lets the caller pick how much memory
      // the server allocates for it.
      expect(parsePullLimit('100000000'), maxPullLimit);
      expect(parsePullLimit('9223372036854775807'), maxPullLimit);
    });

    test('zero and negative limits become 1 rather than 0', () {
      // LIMIT 0 returns no rows and no has_more, which the client reads as
      // "fully synced" — the sync stops for good on a typo.
      expect(parsePullLimit('0'), 1);
      expect(parsePullLimit('-1'), 1);
    });
  });

  group('parseLastSync', () {
    test('a missing cursor starts from the beginning', () {
      expect(parseLastSync(null), 0);
    });

    test('an unparseable cursor starts from the beginning', () {
      expect(parseLastSync('yesterday'), 0);
    });

    test('a negative cursor starts from the beginning', () {
      expect(parseLastSync('-1000'), 0);
    });

    test('a real cursor is passed through', () {
      expect(parseLastSync('1700000000000'), 1700000000000);
    });
  });

  group('internalError', () {
    test('the response body carries no detail from the exception', () async {
      const leak = 'relation "accounts" does not exist at host db.internal';

      late final Response response;
      capturePrints(() {
        response = internalError(
          'GET /api/sync/pull',
          Exception(leak),
          StackTrace.current,
        );
      });

      expect(response.statusCode, HttpStatus.internalServerError);

      final body = await response.body();
      expect(body, isNot(contains(leak)));
      expect(body, isNot(contains('accounts')));
      expect(body, isNot(contains('db.internal')));

      final decoded = jsonDecode(body) as Map<String, dynamic>;
      expect(decoded['error'], 'internal_error');
      expect(decoded['message'], isA<String>());
    });

    test('the detail is written to the server log instead', () {
      const leak = 'FATAL: password authentication failed for user "budget"';

      final logged = capturePrints(() {
        internalError('POST /api/sync/push', Exception(leak), StackTrace.current);
      });

      expect(logged.join('\n'), contains(leak));
      expect(logged.join('\n'), contains('POST /api/sync/push'));
    });
  });
}
