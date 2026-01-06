import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/core/services/exchange_rate_api_service.dart';
import 'api_settings_event.dart';
import 'api_settings_state.dart';

class ApiSettingsBloc extends Bloc<ApiSettingsEvent, ApiSettingsState> {
  final SettingsRepository _settingsRepository;
  final ExchangeRateApiService _apiService;

  ApiSettingsBloc(this._settingsRepository, this._apiService)
    : super(ApiSettingsInitial()) {
    on<LoadApiSettings>(_onLoadApiSettings);
    on<ToggleApiFetching>(_onToggleApiFetching);
    on<SetApiFetchMode>(_onSetApiFetchMode);
    on<ManualFetchRange>(_onManualFetchRange);
  }

  Future<void> _onLoadApiSettings(
    LoadApiSettings event,
    Emitter<ApiSettingsState> emit,
  ) async {
    emit(ApiSettingsLoadInProgress());
    try {
      final settings = await _settingsRepository.getAllSettings();
      final enabled = settings['api_fetching_enabled'] == 'true';
      final mode = settings['api_fetch_mode'] ?? 'debug';
      emit(ApiSettingsLoadSuccess(isFetchingEnabled: enabled, fetchMode: mode));
    } catch (e) {
      emit(ApiSettingsFailure(e.toString()));
    }
  }

  Future<void> _onToggleApiFetching(
    ToggleApiFetching event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        await _settingsRepository.saveSetting(
          'api_fetching_enabled',
          event.enabled.toString(),
        );
        emit(currentState.copyWith(isFetchingEnabled: event.enabled));
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
    }
  }

  Future<void> _onSetApiFetchMode(
    SetApiFetchMode event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      try {
        await _settingsRepository.saveSetting('api_fetch_mode', event.mode);
        emit(currentState.copyWith(fetchMode: event.mode));
      } catch (e) {
        emit(currentState.copyWith(lastError: e.toString()));
      }
    }
  }

  Future<void> _onManualFetchRange(
    ManualFetchRange event,
    Emitter<ApiSettingsState> emit,
  ) async {
    if (state is ApiSettingsLoadSuccess) {
      final currentState = state as ApiSettingsLoadSuccess;
      emit(currentState.copyWith(isOperationInProgress: true));
      try {
        await _apiService.fetchRatesForRange(event.start, event.end);
        emit(currentState.copyWith(isOperationInProgress: false));
      } catch (e) {
        emit(
          currentState.copyWith(
            isOperationInProgress: false,
            lastError: e.toString(),
          ),
        );
      }
    }
  }


  Future<void> _onGellAllMissedDate() async{

  }
  
}
