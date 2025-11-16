import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as drift;
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';

// Этот маппер будет использоваться внутри репозитория для сборки объекта
Currency toDomain(drift.Currency currency, CurrencyDesignation designation) {
  return Currency(
    id: currency.id,
    name: currency.name,
    code: currency.code,
    designation: designation,
  );
}

extension CurrencyCompanionMapper on Currency {
  drift.CurrenciesCompanion toCompanion() {
    return drift.CurrenciesCompanion(
      id: Value(id),
      name: Value(name),
      code: Value(code),
      // Связь с designation будет управляться через ID в репозитории
    );
  }
}
