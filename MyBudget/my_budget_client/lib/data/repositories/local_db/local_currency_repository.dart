import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/currency_designation_mapper.dart';
import 'package:my_budget_client/core/mappers/currency_mapper.dart';
import 'package:my_budget_client/core/mappers/exchange_rate_mapper.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';

class LocalCurrencyRepository implements CurrencyRepository {
  final db.AppDatabase database;

  LocalCurrencyRepository(this.database);

  @override
  Stream<List<Currency>> watchCurrencies() {
    return database.currenciesDao
        .watchAllCurrencies()
        .map((driftCurrencies) => driftCurrencies.toDomainList());
  }

  @override
  Future<List<Currency>> getCurrencies() async {
    final driftCurrencies = await database.currenciesDao.getAllCurrencies();
    return driftCurrencies.toDomainList();
  }

  @override
  Future<Currency?> getCurrencyByCode(String code) async {
    final driftCurrency = await database.currenciesDao.getCurrencyByCode(code);
    return driftCurrency?.toDomain();
  }

  @override
  Future<void> addCurrency(Currency currency) async {
    await database.currenciesDao.insertCurrency(currency.toCompanion());
  }

  @override
  Future<void> addCurrencies(List<Currency> currencies) async {
    await database.currenciesDao.insertAllCurrencies(currencies.toCompanionList());
  }

  @override
  Future<void> updateCurrency(Currency currency) async {
    final companion = currency.toCompanion();
    await database.currenciesDao.updateCurrency(companion);
  }

  @override
  Future<void> deleteCurrency(Currency currency) async {
    final companion = currency.toCompanion();
    await database.currenciesDao.deleteCurrency(companion);
  }

  @override
  Stream<List<CurrencyDesignation>> watchCurrencyDesignationsForCurrency(
      String currencyCode) {
    return database.currencyDesignationsDao
        .watchAllDesignations()
        .map((driftDesignations) {
      return driftDesignations
          .where((d) => d.currencyCode == currencyCode)
          .map((d) => d.toDomain())
          .toList();
    });
  }

  @override
  Future<List<CurrencyDesignation>> getCurrencyDesignationsForCurrency(
      String currencyCode) async {
    final driftDesignations =
        await database.currencyDesignationsDao.getAllDesignations();
    return driftDesignations
        .where((d) => d.currencyCode == currencyCode)
        .map((d) => d.toDomain())
        .toList();
  }

  @override
  Future<CurrencyDesignation?> getCurrencyDesignationById(String id) async {
    final driftDesignation =
        await database.currencyDesignationsDao.getDesignationById(id);
    return driftDesignation?.toDomain();
  }

  @override
  Future<void> addCurrencyDesignation(CurrencyDesignation designation) async {
    await database.currencyDesignationsDao
        .insertDesignation(designation.toCompanion());
  }

  @override
  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations() {
    return database.currencyDesignationsDao
        .watchAllDesignations()
        .map((driftDesignations) {
      return driftDesignations.toDomainList();
    });
  }

  @override
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations() async {
    final driftDesignations =
        await database.currencyDesignationsDao.getAllDesignations();
    return driftDesignations.toDomainList();
  }

  @override
  Stream<List<ExchangeRate>> watchAllExchangeRates() {
    return database.exchangeRatesDao.watchAllExchangeRates().map((driftExchangeRates) {
      return driftExchangeRates.toDomainList();
    });
  }

  @override
  Future<void> addExchangeRate(ExchangeRate exchangeRate) async {
    await database.exchangeRatesDao
        .addExchangeRate(exchangeRate.toCompanion());
  }
}
