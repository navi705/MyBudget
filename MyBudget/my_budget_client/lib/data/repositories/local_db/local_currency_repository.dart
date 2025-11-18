import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/currency_designation_mapper.dart';
import 'package:my_budget_client/core/mappers/currency_mapper.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';

class LocalCurrencyRepository implements CurrencyRepository {
  final db.AppDatabase database;

  LocalCurrencyRepository(this.database);

  @override
  Stream<List<Currency>> watchCurrencies() {
    return database.currenciesDao.watchAllCurrencies().map((driftCurrencies) {
      return driftCurrencies.map((c) => c.toDomain()).toList();
    });
  }

  @override
  Future<List<Currency>> getCurrencies() async {
    final driftCurrencies = await database.currenciesDao.getAllCurrencies();
    return driftCurrencies.map((c) => c.toDomain()).toList();
  }

  @override
  Future<Currency?> getCurrencyById(int id) async {
    final driftCurrency = await database.currenciesDao.getCurrencyById(id);
    return driftCurrency?.toDomain();
  }

  @override
  Future<void> addCurrency(Currency currency) async {
    await database.currenciesDao.insertCurrency(currency.toCompanion());
  }

  @override
  Future<void> updateCurrency(Currency currency) async {
    final companion = currency.toCompanion();
    await database.currenciesDao.updateCurrency(companion);
  }

  @override
  Future<void> deleteCurrency(int id) async {
    await database.currenciesDao.deleteCurrency(
      db.CurrenciesCompanion(id: Value(id)),
    );
  }

  @override
  Stream<List<CurrencyDesignation>> watchCurrencyDesignationsForCurrency(int currencyId) {
    return database.currencyDesignationsDao.watchAllDesignations().map((driftDesignations) {
      return driftDesignations
          .where((d) => d.currencyId == currencyId)
          .map((d) => d.toDomain())
          .toList();
    });
  }

  @override
  Future<List<CurrencyDesignation>> getCurrencyDesignationsForCurrency(int currencyId) async {
    final driftDesignations = await database.currencyDesignationsDao.getAllDesignations();
    return driftDesignations
        .where((d) => d.currencyId == currencyId)
        .map((d) => d.toDomain())
        .toList();
  }

  @override
  Future<CurrencyDesignation?> getCurrencyDesignationById(int id) async {
    final driftDesignation = await database.currencyDesignationsDao.getDesignationById(id);
    return driftDesignation?.toDomain();
  }

  @override
  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations() {
    return database.currencyDesignationsDao.watchAllDesignations().map((driftDesignations) {
      return driftDesignations.map((d) => d.toDomain()).toList();
    });
  }

  @override
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations() async {
    final driftDesignations = await database.currencyDesignationsDao.getAllDesignations();
    return driftDesignations.map((d) => d.toDomain()).toList();
  }
}
