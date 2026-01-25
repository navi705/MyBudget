import 'package:equatable/equatable.dart';
import 'package:my_budget_client/data/api/external_data.dart';
import 'package:my_budget_client/domain/entities/api_setting.dart';
import 'package:my_budget_client/domain/entities/custom_data_source.dart';

abstract class ApiSettingsState extends Equatable {
  const ApiSettingsState();

  @override
  List<Object?> get props => [];
}

class ApiSettingsInitial extends ApiSettingsState {}

class ApiSettingsLoadInProgress extends ApiSettingsState {}

class ApiSettingsLoadSuccess extends ApiSettingsState {
  final String? steamId;
  final GameApiSteam? steamGame;
  final List<ApiSettingDomain> apiSettings;
  final List<CustomDataSourceDomain> customDataSources;
  final String? lastError;
  final bool isOperationInProgress;
  final bool startupSyncEnabled;
  final Map<String, bool> testResults;

  const ApiSettingsLoadSuccess({
    this.steamId,
    this.steamGame,
    this.apiSettings = const [],
    this.customDataSources = const [],
    this.lastError,
    this.isOperationInProgress = false,
    this.startupSyncEnabled = true,
    this.testResults = const {},
  });

  ApiSettingsLoadSuccess copyWith({
    String? steamId,
    GameApiSteam? steamGame,
    List<ApiSettingDomain>? apiSettings,
    List<CustomDataSourceDomain>? customDataSources,
    String? lastError,
    bool? isOperationInProgress,
    bool? startupSyncEnabled,
    Map<String, bool>? testResults,
  }) {
    return ApiSettingsLoadSuccess(
      steamId: steamId ?? this.steamId,
      steamGame: steamGame ?? this.steamGame,
      apiSettings: apiSettings ?? this.apiSettings,
      customDataSources: customDataSources ?? this.customDataSources,
      lastError: lastError,
      isOperationInProgress:
          isOperationInProgress ?? this.isOperationInProgress,
      startupSyncEnabled: startupSyncEnabled ?? this.startupSyncEnabled,
      testResults: testResults ?? this.testResults,
    );
  }

  @override
  List<Object?> get props => [
    steamId,
    steamGame,
    apiSettings,
    customDataSources,
    lastError,
    isOperationInProgress,
    startupSyncEnabled,
    testResults,
  ];
}

class ApiSettingsFailure extends ApiSettingsState {
  final String message;
  const ApiSettingsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
