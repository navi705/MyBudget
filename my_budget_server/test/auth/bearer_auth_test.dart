import 'package:my_budget_server/auth/bearer_auth.dart';
import 'package:test/test.dart';

void main() {
  const token = 'f3a1c8d90b7e4f2a91c05d6e8b3a7c14';

  group('no token configured', () {
    test('refuses instead of serving openly', () {
      // The whole point of the choice: a server that cannot authenticate
      // anyone must not hand out a full financial history to whoever asks.
      expect(
        BearerAuth(token: null).check(authorizationHeader: 'Bearer $token'),
        AuthResult.notConfigured,
      );
      expect(BearerAuth(token: null).isConfigured, isFalse);
    });

    test('an empty or whitespace-only token counts as unset', () {
      // `SYNC_TOKEN=` in a .env file, or a stray newline from a secret file,
      // would otherwise configure the server with a token nobody can guess
      // *or* supply — and it would answer 401 forever with no hint why.
      for (final raw in ['', '   ', '\n', '\t ']) {
        expect(
          BearerAuth(token: raw).check(authorizationHeader: 'Bearer '),
          AuthResult.notConfigured,
          reason: 'token ${raw.codeUnits}',
        );
      }
    });

    test('the setup hint carries no secret', () {
      // It is returned in a 503 body and printed to the log, both of which
      // are readable by parties who must not learn the token.
      expect(BearerAuth.setupHint, isNot(contains(token)));
      expect(BearerAuth.setupHint, contains('SYNC_TOKEN'));
    });
  });

  group('token configured', () {
    final auth = BearerAuth(token: token);

    test('accepts the exact token in an Authorization header', () {
      expect(
        auth.check(authorizationHeader: 'Bearer $token'),
        AuthResult.ok,
      );
    });

    test('the scheme is case-insensitive, as RFC 7235 requires', () {
      for (final scheme in ['Bearer', 'bearer', 'BEARER', 'BeArEr']) {
        expect(
          auth.check(authorizationHeader: '$scheme $token'),
          AuthResult.ok,
          reason: scheme,
        );
      }
    });

    test('surrounding whitespace does not change the outcome', () {
      expect(
        auth.check(authorizationHeader: '  Bearer   $token  '),
        AuthResult.ok,
      );
    });

    test('a configured token is trimmed before comparison', () {
      // A token read from a file usually arrives with a trailing newline; the
      // client, typing it into a text field, will not have one.
      expect(
        BearerAuth(token: '  $token\n').check(
          authorizationHeader: 'Bearer $token',
        ),
        AuthResult.ok,
      );
    });

    test('rejects a missing header', () {
      expect(auth.check(), AuthResult.denied);
    });

    test('rejects the wrong token', () {
      expect(
        auth.check(authorizationHeader: 'Bearer ${token}x'),
        AuthResult.denied,
      );
      expect(
        auth.check(
          authorizationHeader: 'Bearer ${token.substring(1)}',
        ),
        AuthResult.denied,
      );
    });

    test('rejects a token that only shares a prefix', () {
      // Guards the constant-time comparison against being replaced by a
      // startsWith/prefix check during a refactor.
      expect(
        auth.check(authorizationHeader: 'Bearer ${token.substring(0, 8)}'),
        AuthResult.denied,
      );
    });

    test('rejects another auth scheme carrying the right value', () {
      for (final header in ['Basic $token', 'Token $token', token]) {
        expect(auth.check(authorizationHeader: header), AuthResult.denied,
            reason: header);
      }
    });

    test('rejects a Bearer header with no value', () {
      for (final header in ['Bearer', 'Bearer ', 'Bearer    ']) {
        expect(auth.check(authorizationHeader: header), AuthResult.denied,
            reason: '"$header"');
      }
    });
  });

  group('WebSocket query parameter', () {
    final auth = BearerAuth(token: token);

    test('accepts the token as a query parameter', () {
      // A browser's WebSocket API cannot set request headers, so the web
      // build has no other way to authenticate.
      expect(auth.check(queryToken: token), AuthResult.ok);
    });

    test('rejects a wrong query token', () {
      expect(auth.check(queryToken: 'nope'), AuthResult.denied);
      expect(auth.check(queryToken: ''), AuthResult.denied);
    });

    test('a present header wins over the query parameter', () {
      // Both arriving at once means something is confused; the header is the
      // channel that does not leak into access logs, so it decides.
      expect(
        auth.check(
          authorizationHeader: 'Bearer $token',
          queryToken: 'nope',
        ),
        AuthResult.ok,
      );
      expect(
        auth.check(
          authorizationHeader: 'Bearer wrong',
          queryToken: token,
        ),
        AuthResult.denied,
      );
    });

    test('a malformed header falls through to the query parameter', () {
      // A proxy that rewrites Authorization must not lock out the web build.
      expect(
        auth.check(authorizationHeader: 'Basic zzz', queryToken: token),
        AuthResult.ok,
      );
    });
  });

  test('a multi-byte token compares correctly', () {
    // The constant-time comparison walks UTF-8 bytes, not code units.
    final unicode = BearerAuth(token: 'ключ-🔑-токен');
    expect(
      unicode.check(authorizationHeader: 'Bearer ключ-🔑-токен'),
      AuthResult.ok,
    );
    expect(
      unicode.check(authorizationHeader: 'Bearer ключ-🔒-токен'),
      AuthResult.denied,
    );
  });
}
