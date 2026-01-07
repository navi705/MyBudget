import 'package:equatable/equatable.dart';

abstract class ApiSettingsState extends Equatable {
  const ApiSettingsState();

  @override
  List<Object?> get props => [];
}

class ApiSettingsInitial extends ApiSettingsState {}

class ApiSettingsLoadInProgress extends ApiSettingsState {}

class ApiSettingsLoadSuccess extends ApiSettingsState {
  final String? steamId;
  final String? lastError;
  final bool isOperationInProgress;

  const ApiSettingsLoadSuccess({
    this.steamId,
    this.lastError,
    this.isOperationInProgress = false,
  });

  ApiSettingsLoadSuccess copyWith({
    String? steamId,
    String? lastError,
    bool? isOperationInProgress,
  }) {
    return ApiSettingsLoadSuccess(
      steamId: steamId ?? this.steamId,
      lastError: lastError,
      isOperationInProgress:
          isOperationInProgress ?? this.isOperationInProgress,
    );
  }

  @override
  List<Object?> get props => [
        steamId,
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
