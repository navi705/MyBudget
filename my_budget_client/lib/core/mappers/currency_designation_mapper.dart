import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/currency_designation.dart';

extension CurrencyDesignationMapper on drift.CurrencyDesignation {
  CurrencyDesignation toDomain() {
    return CurrencyDesignation(
      id: id,
      value: value,
      currencyCode: currencyCode,
    );
  }
}

extension CurrencyDesignationCompanionMapper on CurrencyDesignation {
  drift.CurrencyDesignationsCompanion toCompanion() {
    return drift.CurrencyDesignationsCompanion(
      id: Value(id),
      value: Value(value),
      currencyCode: Value(currencyCode),
    );
  }
}

extension CurrencyDesignationListMapper on List<drift.CurrencyDesignation> {
  List<CurrencyDesignation> toDomainList() {
    return map((designation) => designation.toDomain()).toList();
  }
}

extension CurrencyDesignationCompanionListMapper on List<CurrencyDesignation> {
  List<drift.CurrencyDesignationsCompanion> toCompanionList() {
    return map((designation) => designation.toCompanion()).toList();
  }
}
