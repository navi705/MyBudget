import 'package:my_budget_client/domain/entities/currency_designation.dart';

abstract class CurrencyDesignationRepository {
  Future<List<CurrencyDesignation>> getDesignations();
  Future<CurrencyDesignation?> getDesignationById(String id);
  Future<void> addDesignation(CurrencyDesignation designation);
  Future<void> updateDesignation(CurrencyDesignation designation);
  Future<void> deleteDesignation(String id);
}
