import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';

part 'inflation_event.dart';
part 'inflation_state.dart';

class InflationBloc extends Bloc<InflationEvent, InflationState> {
  final InflationRepository _inflationRepository;

  InflationBloc({required InflationRepository inflationRepository})
    : _inflationRepository = inflationRepository,
      super(InflationInitial()) {
    on<LoadInflationRates>(_onLoadInflationRates);
    on<AddInflationRate>(_onAddInflationRate);
    on<UpdateInflationRate>(_onUpdateInflationRate);
    on<DeleteInflationRate>(_onDeleteInflationRate);
  }

  Future<void> _onLoadInflationRates(
    LoadInflationRates event,
    Emitter<InflationState> emit,
  ) async {
    emit(InflationLoadInProgress());
    try {
      final rates = await _inflationRepository.getInflationRates();
      emit(InflationLoadSuccess(rates: rates));
    } catch (e) {
      emit(InflationFailure(e.toString()));
    }
  }

  Future<void> _onAddInflationRate(
    AddInflationRate event,
    Emitter<InflationState> emit,
  ) async {
    try {
      await _inflationRepository.addInflationRate(event.rate);
      add(LoadInflationRates());
    } catch (e) {
      emit(InflationFailure(e.toString()));
    }
  }

  Future<void> _onUpdateInflationRate(
    UpdateInflationRate event,
    Emitter<InflationState> emit,
  ) async {
    try {
      await _inflationRepository.updateInflationRate(event.rate);
      add(LoadInflationRates());
    } catch (e) {
      emit(InflationFailure(e.toString()));
    }
  }

  Future<void> _onDeleteInflationRate(
    DeleteInflationRate event,
    Emitter<InflationState> emit,
  ) async {
    try {
      await _inflationRepository.deleteInflationRate(
        event.date,
        event.country,
        event.preset,
      );
      add(LoadInflationRates());
    } catch (e) {
      emit(InflationFailure(e.toString()));
    }
  }
}
