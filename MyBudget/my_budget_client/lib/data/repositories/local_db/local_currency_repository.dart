import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/currency_designation_mapper.dart';
import 'package:my_budget_client/core/mappers/currency_mapper.dart'
    as currency_mapper;
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:rxdart/rxdart.dart';

class LocalCurrencyRepository implements CurrencyRepository {
  final db.AppDatabase database;

  LocalCurrencyRepository(this.database);

  @override
  Stream<List<Currency>> watchCurrencies() {
    return Rx.combineLatest2(
      database.currenciesDao.watchAllCurrencies(),
      database.currencyDesignationsDao.watchAllDesignations(),
      (List<db.Currency> driftCurrencies, List<db.CurrencyDesignation> driftDesignations) {
        final designationMap = {for (var d in driftDesignations) d.id: d.toDomain()};
        final List<Currency> result = [];
        for (var c in driftCurrencies) {
          final designation = designationMap[c.designationId];
          if (designation != null) {
            result.add(currency_mapper.toDomain(c, designation));
          }
        }
        return result;
      },
    );
  }

  @override
  Future<void> addCurrency(Currency currency) async {
    await database.currenciesDao.insertCurrency(currency.toCompanion());
  }

  @override
  Future<void> deleteCurrency(int id) async {
    await database.currenciesDao.deleteCurrency(
      db.CurrenciesCompanion(id: Value(id)),
    );
  }

  @override
  Future<Currency?> getCurrencyById(int id) async {
    final currency = await database.currenciesDao.getCurrencyById(id);
    if (currency == null) {
      return null;
    }

    final designation = await database.currencyDesignationsDao
        .getDesignationById(currency.designationId);
    if (designation == null) {
      // Data integrity issue. A currency must have a designation.
      // For now, returning null as a safe fallback.
      return null;
    }

    return currency_mapper.toDomain(currency, designation.toDomain());
  }

  @override
  Future<List<Currency>> getCurrencies() async {
    final currencies = await database.currenciesDao.getAllCurrencies();
    final designations = await database.currencyDesignationsDao
        .getAllDesignations();

    final designationMap = {for (var d in designations) d.id: d.toDomain()};

    final List<Currency> result = [];
    for (var c in currencies) {
      final designation = designationMap[c.designationId];
      if (designation != null) {
        result.add(currency_mapper.toDomain(c, designation));
      }
      // else: data integrity issue, skip this currency.
    }
    return result;
  }

  @override
  Future<void> updateCurrency(Currency currency) async {
    final companion = db.CurrenciesCompanion(
      id: Value(currency.id),
      name: Value(currency.name),
      code: Value(currency.code),
      designationId: Value(currency.designation.id),
    );
    await database.currenciesDao.updateCurrency(companion);
  }
}
