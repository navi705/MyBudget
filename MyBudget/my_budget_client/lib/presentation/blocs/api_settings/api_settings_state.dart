import 'package:equatable/equatable.dart';

abstract class ApiSettingsState extends Equatable {
  const ApiSettingsState();

  @override
  List<Object?> get props => [];
}

class ApiSettingsInitial extends ApiSettingsState {}

class ApiSettingsLoadInProgress extends ApiSettingsState {}

class ApiSettingsLoadSuccess extends ApiSettingsState {
  final bool isFetchingEnabled;
  final String fetchMode;
  final String? lastError;
  final bool isOperationInProgress;

  const ApiSettingsLoadSuccess({
    required this.isFetchingEnabled,
    required this.fetchMode,
    this.lastError,
    this.isOperationInProgress = false,
  });

  ApiSettingsLoadSuccess copyWith({
    bool? isFetchingEnabled,
    String? fetchMode,
    String? lastError,
    bool? isOperationInProgress,
  }) {
    return ApiSettingsLoadSuccess(
      isFetchingEnabled: isFetchingEnabled ?? this.isFetchingEnabled,
      fetchMode: fetchMode ?? this.fetchMode,
      lastError: lastError,
      isOperationInProgress:
          isOperationInProgress ?? this.isOperationInProgress,
    );
  }

  @override
  List<Object?> get props => [
    isFetchingEnabled,
    fetchMode,
    lastError,
    isOperationInProgress,
  ];
}

class ApiSettingsFailure extends ApiSettingsState {
  final String message;
  const ApiSettingsFailure(this.message);

  @override
  List<Object?> get props => [message];
}
