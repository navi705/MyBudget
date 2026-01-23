import 'package:equatable/equatable.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/domain/entities/custom_data_source.dart';

abstract class ApiSettingsEvent extends Equatable {
  const ApiSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadApiSettings extends ApiSettingsEvent {
  final bool silent;
  const LoadApiSettings({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

class ManualFetchRange extends ApiSettingsEvent {
  final DateTime start;
  final DateTime end;
  const ManualFetchRange(this.start, this.end);

  @override
  List<Object?> get props => [start, end];
}

class FetchSteamInventory extends ApiSettingsEvent {
  final int accountId;
  final GameApiSteam game;

  const FetchSteamInventory(this.accountId, this.game);

  @override
  List<Object?> get props => [accountId, game];
}

class SaveSteamId extends ApiSettingsEvent {
  final String steamId;

  const SaveSteamId(this.steamId);

  @override
  List<Object?> get props => [steamId];
}

class FetchInflationData extends ApiSettingsEvent {
  final String countryCode;
  final String dateRange;

  const FetchInflationData(this.countryCode, this.dateRange);

  @override
  List<Object?> get props => [countryCode, dateRange];
}

class UpdateApiSetting extends ApiSettingsEvent {
  final String id;
  final bool? enabled;
  final bool? autoFetch;

  const UpdateApiSetting({required this.id, this.enabled, this.autoFetch});

  @override
  List<Object?> get props => [id, enabled, autoFetch];
}

class AddCustomDataSource extends ApiSettingsEvent {
  final String name;
  final String url;
  final int dataType;

  const AddCustomDataSource({
    required this.name,
    required this.url,
    required this.dataType,
  });

  @override
  List<Object?> get props => [name, url, dataType];
}

class DeleteCustomDataSource extends ApiSettingsEvent {
  final String id;
  const DeleteCustomDataSource(this.id);

  @override
  List<Object?> get props => [id];
}

class UpdateCustomDataSource extends ApiSettingsEvent {
  final String id;
  final bool? enabled;
  final bool? autoFetch;

  const UpdateCustomDataSource({
    required this.id,
    this.enabled,
    this.autoFetch,
  });

  @override
  List<Object?> get props => [id, enabled, autoFetch];
}

class ToggleStartupSync extends ApiSettingsEvent {
  final bool enabled;
  const ToggleStartupSync(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class TestCustomDataSource extends ApiSettingsEvent {
  final String url;
  const TestCustomDataSource(this.url);

  @override
  List<Object?> get props => [url];
}

class ToggleAllCustomSources extends ApiSettingsEvent {
  final ApiDataType dataType;
  final bool enabled;

  const ToggleAllCustomSources({required this.dataType, required this.enabled});

  @override
  List<Object?> get props => [dataType, enabled];
}

class SaveSteamGame extends ApiSettingsEvent {
  final GameApiSteam game;

  const SaveSteamGame(this.game);

  @override
  List<Object?> get props => [game];
}
