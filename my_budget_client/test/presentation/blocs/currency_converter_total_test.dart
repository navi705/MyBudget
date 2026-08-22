import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';

/// The accounts screen totals every account in a handful of currencies. The
/// rates it does that with are a snapshot: ONE row per pair, the newest one
/// stored. Everything here is about what that snapshot has to survive.
void main() {
  Account account({
    required String id,
    required String currencyCode,
    required double balance,
  }) => Account(
    id: id,
    name: id,
    balance: balance,
    currencyCode: currencyCode,
    currencyDesignationId: 'designation',
    accountTypeId: 'type',
    creationDate: DateTime(2024, 1, 1),
  );

  Currency currency(String code) => Currency(
    name: code,
    code: code,
    languageCode: 'en',
    type: TypeCurrency.currency,
  );

  ExchangeRateDomain rate({
    String from = 'EUR',
    required String to,
    required double value,
    required DateTime date,
  }) => ExchangeRateDomain(
    fromCurrencyCode: from,
    toCurrencyCode: to,
    rate: value,
    date: date,
    preset: 1,
  );

  CurrencyConverterLoadSuccess stateWith(List<ExchangeRateDomain> rates) =>
      CurrencyConverterLoadSuccess(
        exchangeRates: rates,
        baseCurrencyCode: 'EUR',
      );

  final accounts = [
    account(id: 'eur', currencyCode: 'EUR', balance: 100),
    account(id: 'rsd', currencyCode: 'RSD', balance: 11700),
  ];

  test('an account is counted even when its only rate was stored later the '
      'same day', () {
    // What the app actually holds after a morning refresh: the rate carries the
    // wall clock of the fetch, while the day being shown starts at midnight.
    // Demanding a row dated at or before the shown day found nothing, so every
    // account in a refreshed currency silently vanished from the total.
    final state = stateWith([
      rate(to: 'RSD', value: 117.0, date: DateTime(2026, 8, 22, 9, 59, 53)),
    ]);

    final total = totalBalanceFor(
      currency: currency('EUR'),
      accounts: accounts,
      converter: state.converter,
      baseCurrencyCode: 'EUR',
      date: DateTime(2026, 8, 22),
    );

    expect(total, closeTo(200.0, 0.000001));
  });

  test('a total asked for in a non-base currency is not zero just because the '
      'rate is newer than the day shown', () {
    final state = stateWith([
      rate(to: 'RSD', value: 117.0, date: DateTime(2026, 8, 22, 9, 59, 53)),
    ]);

    final total = totalBalanceFor(
      currency: currency('RSD'),
      accounts: accounts,
      converter: state.converter,
      baseCurrencyCode: 'EUR',
      date: DateTime(2026, 8, 22),
    );

    // 200 EUR at 117 RSD/EUR. Returning 0.0 here was the visible symptom: the
    // per-currency sections of the summary all read zero.
    expect(total, closeTo(23400.0, 0.000001));
  });

  test('a currency with no rate at all is reported, not silently dropped', () {
    final state = stateWith([
      rate(to: 'RSD', value: 117.0, date: DateTime(2026, 8, 22, 9, 59, 53)),
    ]);
    final unconvertible = <String>{};

    final total = totalBalanceFor(
      currency: currency('EUR'),
      accounts: [
        ...accounts,
        account(id: 'eth', currencyCode: 'ETH', balance: 0.01),
      ],
      converter: state.converter,
      baseCurrencyCode: 'EUR',
      date: DateTime(2026, 8, 22),
      unconvertible: unconvertible,
    );

    expect(total, closeTo(200.0, 0.000001));
    expect(unconvertible, {'ETH'});
  });

  test('a rate dated before the day shown is still the one used', () {
    final state = stateWith([
      rate(to: 'RSD', value: 117.0, date: DateTime(2026, 1, 20)),
    ]);

    final total = totalBalanceFor(
      currency: currency('EUR'),
      accounts: accounts,
      converter: state.converter,
      baseCurrencyCode: 'EUR',
      date: DateTime(2026, 8, 22),
    );

    expect(total, closeTo(200.0, 0.000001));
  });

  test('the nearer of two rates wins', () {
    final state = stateWith([
      rate(to: 'RSD', value: 100.0, date: DateTime(2026, 1, 1)),
      rate(to: 'RSD', value: 117.0, date: DateTime(2026, 8, 20)),
    ]);

    final total = totalBalanceFor(
      currency: currency('EUR'),
      accounts: accounts,
      converter: state.converter,
      baseCurrencyCode: 'EUR',
      date: DateTime(2026, 8, 22),
    );

    expect(total, closeTo(200.0, 0.000001));
  });

  test('balancesOverride is what gets converted, not the live balance', () {
    final state = stateWith([
      rate(to: 'RSD', value: 117.0, date: DateTime(2026, 8, 22, 9, 59, 53)),
    ]);

    final total = totalBalanceFor(
      currency: currency('EUR'),
      accounts: accounts,
      converter: state.converter,
      baseCurrencyCode: 'EUR',
      date: DateTime(2026, 8, 22),
      balancesOverride: {'eur': 50, 'rsd': 5850},
    );

    expect(total, closeTo(100.0, 0.000001));
  });
}
