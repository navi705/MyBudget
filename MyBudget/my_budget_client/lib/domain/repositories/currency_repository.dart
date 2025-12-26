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
      String currencyCode);
  Future<List<CurrencyDesignation>> getCurrencyDesignationsForCurrency(
      String currencyCode);
  Future<CurrencyDesignation?> getCurrencyDesignationById(String id);
  Future<void> addCurrencyDesignation(CurrencyDesignation designation);

  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations();
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations();

  Stream<List<ExchangeRate>> watchAllExchangeRates();
  Future<void> addExchangeRate(ExchangeRate exchangeRate);
}
