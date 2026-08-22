import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/currency.dart';

// Create an extension on drift.Currency directly
extension CurrencyMapper on drift.Currency {
  Currency toDomain() {
    return Currency(
      name: name,
      code: code,
      languageCode: languageCode,
      type: type,
    );
  }
}

extension CurrencyCompanionMapper on Currency {
  drift.CurrenciesCompanion toCompanion() {
    return drift.CurrenciesCompanion(
      name: Value(name),
      code: Value(code),
      languageCode: Value(languageCode),
      type: Value(type),
    );
  }
}

extension CurrencyListMapper on List<drift.Currency> {
  List<Currency> toDomainList() {
    return map((currency) => currency.toDomain()).toList();
  }
}

extension CurrencyCompanionListMapper on List<Currency> {
  List<drift.CurrenciesCompanion> toCompanionList() {
    return map((currency) => currency.toCompanion()).toList();
  }
}
