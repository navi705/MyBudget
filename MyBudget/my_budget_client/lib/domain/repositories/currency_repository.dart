import 'package:my_budget_client/domain/entities/currency.dart';

abstract class CurrencyRepository {
  Future<List<Currency>> getCurrencies();
  Stream<List<Currency>> watchCurrencies();
  Future<Currency?> getCurrencyById(int id);
  Future<void> addCurrency(Currency currency);
  Future<void> updateCurrency(Currency currency);
  Future<void> deleteCurrency(int id);
}
