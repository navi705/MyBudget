import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/http/api_responses.dart';
import 'package:my_budget_server/rates/rate_request.dart';
import 'package:my_budget_server/rates/rate_store.dart';

/// `GET /api/rates/latest` — the newest quote per pair, at or before a date.
///
/// The accounts and net-worth screens do not want a window; they want one
/// number per currency as of the date on the app bar, and they want it before
/// the frame is drawn. Asking `/api/rates` for a window and reducing it on the
/// device would move a year of rows across the wire to keep one row per pair.
///
/// A pair with nothing published on the requested day falls back to its last
/// quote before it, so a Sunday reads as Friday's rate rather than as nothing.
/// `date_from` is ignored here — "latest" has only an upper bound.
Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.get) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final parsed = parseRateQuery(context.request.uri.queryParameters);
  final error = parsed.error;
  if (error != null) {
    return Response.json(
      statusCode: HttpStatus.badRequest,
      body: {'error': 'bad_request', 'message': error.message},
    );
  }

  final query = parsed.query!;
  final store = context.read<RateStore>();

  try {
    final rows = await store.latest(
      fromCurrencyCode: query.fromCurrencyCode,
      toCurrencyCodes: query.toCurrencyCodes,
      asOf: query.dateTo,
      preset: query.preset,
      limit: query.limit,
    );

    return Response.json(
      body: {
        'rates': rows.map(rateRowToJson).toList(),
        'has_more': rows.length >= query.limit,
      },
    );
  } catch (e, stackTrace) {
    return internalError('GET /api/rates/latest', e, stackTrace);
  }
}
