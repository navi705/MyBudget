import 'package:equatable/equatable.dart';
import 'package:my_budget_client/data/api/external_data.dart';

abstract class ApiSettingsEvent extends Equatable {
  const ApiSettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadApiSettings extends ApiSettingsEvent {}

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
