import 'dart:convert';
import 'dart:io';

/// Outcome of checking a single request's credentials.
enum AuthResult {
  /// The caller presented the configured token.
  ok,

  /// No token is configured on this server, so it cannot safely serve anyone.
  notConfigured,

  /// A token is configured and the caller did not present it, or presented
  /// the wrong one. The two cases are deliberately not distinguished in the
  /// response — telling a caller "right token, wrong format" narrows a guess.
  denied,
}

/// Shared-secret authentication for the sync API.
///
/// One token guards the whole database: this server holds exactly one budget,
/// and the token is what proves a client is one of its owner's devices. There
/// is no user column anywhere in the schema, so there is nothing finer to
/// authorise against — anyone holding the token can read and overwrite
/// everything, which is precisely the intent for a personal sync server.
///
/// The token comes from the `SYNC_TOKEN` environment variable. When it is
/// unset the server refuses every API and WebSocket request rather than
/// serving them openly: this database can be reachable from another machine,
/// and an unauthenticated financial history is not a safe default to fall
/// back to silently.
class BearerAuth {
  /// Takes [token] verbatim. `null`, empty or whitespace-only all mean "no
  /// token configured", which fails every check closed rather than open.
  BearerAuth({required String? token}) : _token = _normalize(token);

  /// The real server wiring: reads `SYNC_TOKEN`. Kept separate from the
  /// constructor so tests can pin a token without touching the process
  /// environment, and so an unset-token test cannot pass or fail depending on
  /// what the developer happens to have exported.
  factory BearerAuth.fromEnvironment() =>
      BearerAuth(token: Platform.environment['SYNC_TOKEN']);

  final String? _token;

  static String? _normalize(String? raw) {
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  /// True when a token is configured and requests can be authorised at all.
  bool get isConfigured => _token != null;

  /// The message shown to an operator who has not configured a token. Carries
  /// no secret, so it is safe in a response body and in logs.
  static const String setupHint =
      'SYNC_TOKEN is not set. The server refuses all sync requests until it '
      'is. Generate one (for example `openssl rand -hex 32`), set it in the '
      "server's environment, and enter the same value in the app under "
      'Settings > Synchronization > Server token.';

  /// Checks one request.
  ///
  /// [authorizationHeader] is the raw `Authorization` header, if any.
  /// [queryToken] is the `token` query parameter, accepted **only** for the
  /// WebSocket route: a browser's WebSocket API cannot set request headers, so
  /// the web build has no other way to authenticate. It is not accepted on the
  /// HTTP routes, where a token in the URL would end up in access logs,
  /// proxy logs and browser history for every single request.
  AuthResult check({String? authorizationHeader, String? queryToken}) {
    final expected = _token;
    if (expected == null) return AuthResult.notConfigured;

    final presented = _bearerValue(authorizationHeader) ?? queryToken?.trim();
    if (presented == null || presented.isEmpty) return AuthResult.denied;

    return _constantTimeEquals(presented, expected)
        ? AuthResult.ok
        : AuthResult.denied;
  }

  /// Extracts the credential from `Bearer <token>`, case-insensitively on the
  /// scheme as RFC 7235 requires.
  static String? _bearerValue(String? header) {
    if (header == null) return null;
    final trimmed = header.trim();
    const scheme = 'bearer ';
    if (trimmed.length <= scheme.length) return null;
    if (trimmed.substring(0, scheme.length).toLowerCase() != scheme) {
      return null;
    }
    final value = trimmed.substring(scheme.length).trim();
    return value.isEmpty ? null : value;
  }

  /// Compares in time independent of where the first difference falls.
  ///
  /// A short-circuiting `==` leaks the length of the matching prefix through
  /// response timing, which is enough to recover a token byte by byte over
  /// many requests. Length is compared first and does leak — that is
  /// unavoidable and not useful on its own.
  static bool _constantTimeEquals(String a, String b) {
    final ab = utf8.encode(a);
    final bb = utf8.encode(b);
    if (ab.length != bb.length) return false;
    var diff = 0;
    for (var i = 0; i < ab.length; i++) {
      diff |= ab[i] ^ bb[i];
    }
    return diff == 0;
  }
}
