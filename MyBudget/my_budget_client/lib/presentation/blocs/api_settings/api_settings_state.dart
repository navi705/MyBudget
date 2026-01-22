import 'package:equatable/equatable.dart';
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
  final List<ApiSettingDomain> apiSettings;
  final List<CustomDataSourceDomain> customDataSources;
  final String? lastError;
  final bool isOperationInProgress;
  final bool startupSyncEnabled;
  final bool? testResult;

  const ApiSettingsLoadSuccess({
    this.steamId,
    this.apiSettings = const [],
    this.customDataSources = const [],
    this.lastError,
    this.isOperationInProgress = false,
    this.startupSyncEnabled = true,
    this.testResult,
  });

  ApiSettingsLoadSuccess copyWith({
    String? steamId,
    List<ApiSettingDomain>? apiSettings,
    List<CustomDataSourceDomain>? customDataSources,
    String? lastError,
    bool? isOperationInProgress,
    bool? startupSyncEnabled,
    bool? testResult,
  }) {
    return ApiSettingsLoadSuccess(
      steamId: steamId ?? this.steamId,
      apiSettings: apiSettings ?? this.apiSettings,
      customDataSources: customDataSources ?? this.customDataSources,
      lastError: lastError,
      isOperationInProgress:
          isOperationInProgress ?? this.isOperationInProgress,
      startupSyncEnabled: startupSyncEnabled ?? this.startupSyncEnabled,
      testResult: testResult,
    );
  }

  @override
  List<Object?> get props => [
    steamId,
    apiSettings,
    customDataSources,
    lastError,
    isOperationInProgress,
    startupSyncEnabled,
    testResult,
  ];
}

class ApiSettingsFailure extends ApiSettingsState {
  final String message;
  const ApiSettingsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
