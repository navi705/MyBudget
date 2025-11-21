import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';

void main() {
  group('CurrencyConverterLoadSuccess state logic', () {
    // Define currencies
    const usd = Currency(id: 1, name: 'US Dollar', code: 'USD');
    const eur = Currency(id: 2, name: 'Euro', code: 'EUR');
    const rub = Currency(id: 3, name: 'Russian Ruble', code: 'RUB');

    // Define accounts
    final account1 = Account(
        id: 1, name: 'USD Account', balance: 1000, currencyId: usd.id, currencyDesignationId: 1, accountTypeId: 1);
    final account2 = Account(
        id: 2, name: 'EUR Account', balance: 500, currencyId: eur.id, currencyDesignationId: 2, accountTypeId: 1);
    final account3 = Account(
        id: 3, name: 'RUB Account', balance: 10000, currencyId: rub.id, currencyDesignationId: 3, accountTypeId: 1);

    test('totalBalanceFor calculates correctly with no conversion needed', () {
      // Arrange
      final state = CurrencyConverterLoadSuccess(
        accounts: [
          account1,
          account1.copyWith(balance: 250),
        ],
        exchangeRates: [],
        baseCurrencyId: usd.id,
      );

      // Act
      final total = state.totalBalanceFor(usd);

      // Assert
      expect(total, 1250);
    });

    test('totalBalanceFor calculates correctly with a direct exchange rate', () {
      // Arrange
      final state = CurrencyConverterLoadSuccess(
        accounts: [account1, account2], // 1000 USD, 500 EUR
        exchangeRates: [
          ExchangeRate(fromCurrencyId: usd.id, toCurrencyId: eur.id, rate: 0.9, date: DateTime.now()),
        ],
        baseCurrencyId: usd.id,
      );

      // Act
      final totalInEur = state.totalBalanceFor(eur);

      // Assert
      // Expected: 500 EUR + (1000 USD * 0.9) = 1400 EUR
      expect(totalInEur, 1400);
    });

    test('totalBalanceFor calculates correctly with indirect (triangulated) conversion', () {
      // Arrange
      final state = CurrencyConverterLoadSuccess(
        accounts: [account2, account3], // 500 EUR, 10000 RUB
        exchangeRates: [
          ExchangeRate(fromCurrencyId: rub.id, toCurrencyId: usd.id, rate: 0.01, date: DateTime.now()),
          ExchangeRate(fromCurrencyId: usd.id, toCurrencyId: eur.id, rate: 0.9, date: DateTime.now()),
        ],
        baseCurrencyId: usd.id, // Base currency is USD
      );
    
      // Act
      final totalInEur = state.totalBalanceFor(eur);

      // Assert
      // Expected: 500 EUR + (10000 RUB * 0.01 USD/RUB * 0.9 EUR/USD) = 500 + 90 = 590 EUR
      expect(totalInEur, 590);
    });

    test('totalBalanceFor calculates correctly using an inverse exchange rate', () {
      // Arrange
      final state = CurrencyConverterLoadSuccess(
        accounts: [account1, account2], // 1000 USD, 500 EUR
        exchangeRates: [
          // Only the inverse rate is provided
          ExchangeRate(fromCurrencyId: eur.id, toCurrencyId: usd.id, rate: 1.1, date: DateTime.now()),
        ],
        baseCurrencyId: eur.id, 
      );
    
      // Act
      final totalInUsd = state.totalBalanceFor(usd);

      // Assert
      // Expected: 1000 USD + (500 EUR * 1.1 USD/EUR) = 1000 + 550 = 1550 USD
      expect(totalInUsd, 1550);
    });

    test('totalBalanceFor calculates correctly when some conversion rates are missing', () {
      // Arrange
      final state = CurrencyConverterLoadSuccess(
        accounts: [account1, account2, account3], // 1000 USD, 500 EUR, 10000 RUB
        exchangeRates: [
          ExchangeRate(fromCurrencyId: usd.id, toCurrencyId: eur.id, rate: 0.9, date: DateTime.now()),
          // No rate for RUB
        ],
        baseCurrencyId: usd.id,
      );

      // Act
      final totalInEur = state.totalBalanceFor(eur);

      // Assert
      // Expected: 500 EUR + (1000 USD * 0.9) = 1400 EUR. RUB is ignored.
      expect(totalInEur, 1400);
    });

     test('totalBalanceFor returns 0 when there are no accounts', () {
      // Arrange
      final state = CurrencyConverterLoadSuccess(
        accounts: [],
        exchangeRates: [],
        baseCurrencyId: usd.id,
      );

      // Act
      final total = state.totalBalanceFor(usd);

      // Assert
      expect(total, 0);
    });
  });
}
