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
