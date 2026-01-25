import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;
import 'package:my_budget_client/domain/entities/settings.dart';

extension SettingMapper on db.Setting {
  Settings toDomain() {
    return Settings(key: key, value: value, device: device ?? 'unknown');
  }
}

extension SettingsMapper on Settings {
  db.SettingsCompanion toCompanion() {
    return db.SettingsCompanion.insert(
      key: key,
      value: value,
      device: drift.Value(device),
    );
  }
}

extension SettingsListMapper on List<db.Setting> {
  List<Settings> toDomainList() {
    return map((e) => e.toDomain()).toList();
  }
}

extension SettingListMapper on List<Settings> {
  List<db.SettingsCompanion> toCompanionList() {
    return map((e) => e.toCompanion()).toList();
  }
}
