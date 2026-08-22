import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/currency_designation_mapper.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/repositories/currency_designation_repository.dart';

class LocalCurrencyDesignationRepository
    implements CurrencyDesignationRepository {
  final db.AppDatabase database;

  LocalCurrencyDesignationRepository(this.database);

  @override
  Future<void> addDesignation(CurrencyDesignation designation) async {
    await database.currencyDesignationsDao.insertDesignation(
      designation.toCompanion(),
    );
  }

  @override
  Future<void> addDesignations(List<CurrencyDesignation> designations) async {
    await database.currencyDesignationsDao.insertAllCurrencyDesignations(
      designations.toCompanionList(),
    );
  }

  @override
  Future<void> deleteDesignation(String id) async {
    await database.currencyDesignationsDao.deleteDesignation(
      db.CurrencyDesignationsCompanion(id: Value(id)),
    );
  }

  @override
  Future<CurrencyDesignation?> getDesignationById(String id) async {
    final designation = await database.currencyDesignationsDao
        .getDesignationById(id);
    return designation?.toDomain();
  }

  @override
  Future<List<CurrencyDesignation>> getDesignations() async {
    final designations = await database.currencyDesignationsDao
        .getAllDesignations();
    return designations.toDomainList();
  }

  @override
  Future<void> updateDesignation(CurrencyDesignation designation) async {
    await database.currencyDesignationsDao.updateDesignation(
      designation.toCompanion(),
    );
  }
}
