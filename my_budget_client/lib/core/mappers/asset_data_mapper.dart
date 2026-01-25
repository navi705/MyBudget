import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';

extension AssetDataMapper on AssetEntry {
  AssetDataDomain toDomain() {
    return AssetDataDomain(
      id: id,
      assetId: assetId,
      name: name,
      date: date,
      value: value,
      quantity: quantity,
      assetType: assetType,
      description: description,
      preset: preset,
      source: source,
      currency: currencyCode,
      accountId: accountId, // Added
    );
  }
}

extension AssetDataDomainMapper on AssetDataDomain {
  AssetEntriesCompanion toCompanion() {
    return AssetEntriesCompanion(
      id: id != null ? Value(id!) : const Value.absent(),
      assetId: Value(assetId),
      name: Value(name),
      date: Value(date),
      value: Value(value),
      quantity: Value(quantity),
      assetType: Value(assetType),
      description: Value(description),
      preset: Value(preset),
      source: Value(source),
      currencyCode: Value(currency),
      accountId: accountId != null
          ? Value(accountId)
          : const Value.absent(), // Added
    );
  }
}
