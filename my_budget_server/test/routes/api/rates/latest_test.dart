import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:mocktail/mocktail.dart';
import 'package:my_budget_server/rates/rate_store.dart';
import 'package:test/test.dart';

import '../../../../routes/api/rates/latest/index.dart' as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRateStore extends Mock implements RateStore {}

RateRow _row(String to) => (
      fromCurrencyCode: 'EUR',
      toCurrencyCode: to,
      rate: 1.09,
      preset: kFetchedRatePreset,
      date: DateTime.utc(2026, 3, 13),
      sourceId: 'server:FawazCurrencyApi',
      modifiedAt: 1773360000,
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
      Request.get(Uri.parse('http://localhost/api/rates/latest$query'));

  Future<Map<String, dynamic>> bodyOf(Response response) async =>
      jsonDecode(await response.body()) as Map<String, dynamic>;

  setUp(() {
    context = _MockRequestContext();
    store = _MockRateStore();
    when(
      () => store.latest(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        asOf: any(named: 'asOf'),
        preset: any(named: 'preset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => [_row('USD')]);
  });

  test('returns one quote per pair', () async {
    final response = await route.onRequest(contextFor(get_('')));

    expect(response.statusCode, HttpStatus.ok);
    final body = await bodyOf(response);
    expect((body['rates'] as List).single, containsPair('rate', 1.09));
    expect(body['has_more'], isFalse);
  });

  test('with no date it asks for the newest the server holds', () async {
    await route.onRequest(contextFor(get_('?to=usd')));

    verify(
      () => store.latest(
        fromCurrencyCode: 'EUR',
        toCurrencyCodes: ['USD'],
        asOf: null,
        preset: kFetchedRatePreset,
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });

  test('`date` becomes the upper bound, not a window', () async {
    // "Latest" has only an upper bound: a pair with nothing published on the
    // requested day has to fall back to its last quote before it, or a Sunday
    // reads as no rate at all.
    await route.onRequest(contextFor(get_('?date=2026-03-14')));

    verify(
      () => store.latest(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        asOf: DateTime.utc(2026, 3, 14),
        preset: any(named: 'preset'),
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });

  test('`preset=all` reaches the store as every preset', () async {
    await route.onRequest(contextFor(get_('?preset=all')));

    verify(
      () => store.latest(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        asOf: any(named: 'asOf'),
        preset: null,
        limit: any(named: 'limit'),
      ),
    ).called(1);
  });

  test('rejects a bad query with a 400', () async {
    final response = await route.onRequest(contextFor(get_('?to=US D')));

    expect(response.statusCode, HttpStatus.badRequest);
    verifyNever(
      () => store.latest(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        asOf: any(named: 'asOf'),
        preset: any(named: 'preset'),
        limit: any(named: 'limit'),
      ),
    );
  });

  test('refuses anything but GET', () async {
    final response = await route.onRequest(
      contextFor(Request.post(Uri.parse('http://localhost/api/rates/latest'))),
    );

    expect(response.statusCode, HttpStatus.methodNotAllowed);
  });

  test('a store failure is a 500 that leaks nothing', () async {
    when(
      () => store.latest(
        fromCurrencyCode: any(named: 'fromCurrencyCode'),
        toCurrencyCodes: any(named: 'toCurrencyCodes'),
        asOf: any(named: 'asOf'),
        preset: any(named: 'preset'),
        limit: any(named: 'limit'),
      ),
    ).thenThrow(Exception('connection to db-host:5432 as budget failed'));

    final response = await route.onRequest(contextFor(get_('')));

    expect(response.statusCode, HttpStatus.internalServerError);
    expect(await response.body(), isNot(contains('db-host')));
  });
}
