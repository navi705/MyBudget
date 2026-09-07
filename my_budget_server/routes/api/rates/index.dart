import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:my_budget_server/http/api_responses.dart';
import 'package:my_budget_server/rates/rate_request.dart';
import 'package:my_budget_server/rates/rate_store.dart';

/// `GET /api/rates` — published quotes for a pair filter and a date window.
///
/// This is the route that replaces the app's own trips to the currency CDN and
/// the 2 MB of history it used to ship in the bundle. A device keeps whatever
/// it has already been given and comes here only for what it is missing, so
/// the useful shape of a request is narrow: a few currency codes and a short
/// window, not the table.
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
    final rows = await store.query(
      fromCurrencyCode: query.fromCurrencyCode,
      toCurrencyCodes: query.toCurrencyCodes,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      preset: query.preset,
      limit: query.limit,
    );

    return Response.json(
      body: {
        'rates': rows.map(rateRowToJson).toList(),
        // The page was cut short if it came back exactly full. The caller
        // narrows its window or its pair list rather than paging by offset:
        // an offset page over a table this server is actively writing to can
        // skip a row that moved between requests.
        'has_more': rows.length >= query.limit,
      },
    );
  } catch (e, stackTrace) {
    return internalError('GET /api/rates', e, stackTrace);
  }
}
