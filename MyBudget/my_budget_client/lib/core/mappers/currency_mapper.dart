import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/currency.dart';

// Create an extension on drift.Currency directly
extension CurrencyMapper on drift.Currency {
  Currency toDomain() {
    return Currency(
      id: id,
      name: name,
      code: code,
    );
  }
}

extension CurrencyCompanionMapper on Currency {
  drift.CurrenciesCompanion toCompanion() {
    return drift.CurrenciesCompanion(
      id: Value(id),
      name: Value(name),
      code: Value(code),
    );
  }
}
