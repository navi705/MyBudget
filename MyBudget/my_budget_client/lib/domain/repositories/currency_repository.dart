import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';

abstract class CurrencyRepository {
  Future<List<Currency>> getCurrencies();
  Stream<List<Currency>> watchCurrencies();
  Future<Currency?> getCurrencyById(int id);
  Future<void> addCurrency(Currency currency);
  Future<void> updateCurrency(Currency currency);
  Future<void> deleteCurrency(int id);

  Stream<List<CurrencyDesignation>> watchCurrencyDesignationsForCurrency(int currencyId);
  Future<List<CurrencyDesignation>> getCurrencyDesignationsForCurrency(int currencyId);
  Future<CurrencyDesignation?> getCurrencyDesignationById(int id);

  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations();
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations();
}
