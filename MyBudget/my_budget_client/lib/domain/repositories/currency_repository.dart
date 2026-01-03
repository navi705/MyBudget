import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

abstract class CurrencyRepository {
  Future<List<Currency>> getCurrencies();
  Stream<List<Currency>> watchCurrencies();
  Future<Currency?> getCurrencyByCode(String code);
  Future<void> addCurrency(Currency currency);
  Future<void> addCurrencies(List<Currency> currencies);
  Future<void> updateCurrency(Currency currency);
  Future<void> deleteCurrency(Currency currency);

  Stream<List<CurrencyDesignation>> watchCurrencyDesignationsForCurrency(
    String currencyCode,
  );
  Future<List<CurrencyDesignation>> getCurrencyDesignationsForCurrency(
    String currencyCode,
  );
  Future<CurrencyDesignation?> getCurrencyDesignationById(String id);
  Future<void> addCurrencyDesignation(CurrencyDesignation designation);

  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations();
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations();

  Future<List<ExchangeRateDomain>> getLatestExchangeRates(DateTime date);
  Future<List<ExchangeRateDomain>> getLatestExchangeRatesAll();
  Future<List<ExchangeRateDomain>> getLatestExchangeRatesByList(
    List<DateTime> date,
  );
  Future<List<ExchangeRateDomain>> getExchangeRatesFiltered({
    int limit = 100,
    int offset = 0,
    DateTime? date,
    String? fromCurrency,
    String? toCurrency,
  });
  Future<int> getExchangeRatesCount({
    DateTime? date,
    String? fromCurrency,
    String? toCurrency,
  });
  Future<void> addExchangeRate(ExchangeRateDomain exchangeRate);
  Future<void> addExchangeRates(List<ExchangeRateDomain> exchangeRates);
  Future<void> updateExchangeRate(ExchangeRateDomain exchangeRate);
}
