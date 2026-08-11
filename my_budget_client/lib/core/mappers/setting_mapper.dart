import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:drift/drift.dart' as drift;
import 'package:my_budget_client/domain/entities/settings.dart';

extension SettingMapper on db.Setting {
  Settings toDomain() {
    return Settings(key: key, value: value, device: device ?? 'unknown');
  }
}

extension SettingsMapper on Settings {
  /// The companion for writing this setting back.
  ///
  /// `modifiedAt` is stamped here because the domain entity does not carry one
  /// and the row it lands on does: left out, the setting is stored as "changed
  /// at epoch 0", which loses last-write-wins against any peer's untouched
  /// default - the user's choice would be the one thrown away.
  db.SettingsCompanion toCompanion() {
    return db.SettingsCompanion.insert(
      key: key,
      value: value,
      device: drift.Value(device),
      modifiedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
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
