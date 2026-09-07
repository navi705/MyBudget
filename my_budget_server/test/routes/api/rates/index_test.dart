import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_server/rates/rate_request.dart';
import 'package:my_budget_server/rates/rate_store.dart';
import 'package:test/test.dart';

import '../../../../routes/api/rates/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRateStore extends Mock implements RateStore {}

RateRow _row(String to, {double rate = 1.09}) => (
      fromCurrencyCode: 'EUR',
      toCurrencyCode: to,
      rate: rate,
      preset: kFetchedRatePreset,
      date: DateTime.utc(2026, 3, 14),
      sourceId: 'server:FawazCurrencyApi',
      modifiedAt: 1773446400,
    );

void main() {
  late _MockRequestContext context;
  late _MockRateStore store;

  RequestContext contextFor(Request request) {
    when(() => context.request).thenReturn(request);
    when(() => context.read<RateStore>()).thenReturn(store);
    return context;
  }

  Request get_(String query) =>
      Request.get(Uri.parse('http://localhost/api/rates$query'));

  Future<Map<String, dynamic>> bodyOf(Response response) async =>
      jsonDecode(await response.body()) as Map<String, dynamic>;

  setUp(() {
    context = _MockRequestContext();
    store = _MockRateStore();
    when(
      () => store.query(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
        preset: any(named: 'preset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => [_row('USD')]);
  });

  test('answers a plain request with the store rows', () async {
    final response = await route.onRequest(contextFor(get_('')));

    expect(response.statusCode, HttpStatus.ok);
    final body = await bodyOf(response);
    expect(body['rates'], [
      {
        'fromCurrencyCode': 'EUR',
        'toCurrencyCode': 'USD',
        'rate': 1.09,
        'preset': kFetchedRatePreset,
        'date': '2026-03-14T00:00:00.000Z',
        'sourceId': 'server:FawazCurrencyApi',
        'modifiedAt': 1773446400,
      }
    ]);
    expect(body['has_more'], isFalse);
  });

  test('passes the parsed query straight through to the store', () async {
    await route.onRequest(
      contextFor(get_('?from=usd&to=eur,jpy&date=2026-03-14&limit=10')),
    );

    verify(
      () => store.query(
        fromCurrencyCode: 'USD',
        toCurrencyCodes: ['EUR', 'JPY'],
        dateFrom: DateTime.utc(2026, 3, 14),
        dateTo: DateTime.utc(2026, 3, 14),
        preset: kFetchedRatePreset,
        limit: 10,
      ),
    ).called(1);
  });

  test('reports has_more when the page filled up', () async {
    // The client pages on this flag; without it a truncated first page reads
    // as the whole answer and the rest of the history is never fetched.
    when(
      () => store.query(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
        preset: any(named: 'preset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => [_row('USD'), _row('JPY')]);

    final body = await bodyOf(
      await route.onRequest(contextFor(get_('?limit=2'))),
    );

    expect(body['has_more'], isTrue);
  });

  test('clamps an oversized limit rather than honouring it', () async {
    await route.onRequest(contextFor(get_('?limit=999999')));

    verify(
      () => store.query(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
        preset: any(named: 'preset'),
        limit: maxRateLimit,
      ),
    ).called(1);
  });

  test('rejects a bad query with a 400 and never touches the store', () async {
    final response = await route.onRequest(contextFor(get_('?date=someday')));

    expect(response.statusCode, HttpStatus.badRequest);
    expect((await bodyOf(response))['error'], 'bad_request');
    verifyNever(
      () => store.query(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
        preset: any(named: 'preset'),
        limit: any(named: 'limit'),
      ),
    );
  });

  test('refuses anything but GET', () async {
    final response = await route.onRequest(
      contextFor(Request.post(Uri.parse('http://localhost/api/rates'))),
    );

    expect(response.statusCode, HttpStatus.methodNotAllowed);
  });

  test('a store failure is a 500 that leaks nothing', () async {
    // The exception text from `package:postgres` names the host, port and
    // user it failed to connect as. That belongs in the server log.
    when(
      () => store.query(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        dateFrom: any(named: 'dateFrom'),
        dateTo: any(named: 'dateTo'),
        preset: any(named: 'preset'),
        limit: any(named: 'limit'),
      ),
    ).thenThrow(Exception('connection to db-host:5432 as budget failed'));

    final response = await route.onRequest(contextFor(get_('')));

    expect(response.statusCode, HttpStatus.internalServerError);
    final raw = await response.body();
    expect(raw, isNot(contains('db-host')));
    expect(raw, isNot(contains('5432')));
  });
}
