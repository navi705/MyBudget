import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';

part 'styles_event.dart';
part 'styles_state.dart';

class StylesBloc extends Bloc<StylesEvent, StylesState> {
  final StyleRepository _styleRepository;
  StreamSubscription? _stylesSubscription;

  StylesBloc({required StyleRepository styleRepository})
      : _styleRepository = styleRepository,
        super(StylesInitial()) {
    on<LoadStyles>(_onLoadStyles);
    on<AddStyle>(_onAddStyle);
    on<UpdateStyle>(_onUpdateStyle);
    on<DeleteStyle>(_onDeleteStyle);
    on<_StylesUpdated>(_onStylesUpdated);
  }

  void _onLoadStyles(
    LoadStyles event,
    Emitter<StylesState> emit,
  ) {
    emit(StylesLoadInProgress());
    _stylesSubscription?.cancel();
    _stylesSubscription = _styleRepository.watchAllStyles().listen(
          (styles) => add(_StylesUpdated(styles)),
          onError: (_) => emit(StylesLoadFailure()),
        );
  }

  Future<void> _onAddStyle(
    AddStyle event,
    Emitter<StylesState> emit,
  ) async {
    await _styleRepository.addStyle(event.style);
  }

  Future<void> _onUpdateStyle(
    UpdateStyle event,
    Emitter<StylesState> emit,
  ) async {
    await _styleRepository.updateStyle(event.style);
  }

  Future<void> _onDeleteStyle(
    DeleteStyle event,
    Emitter<StylesState> emit,
  ) async {
    await _styleRepository.deleteStyle(event.id);
  }

  void _onStylesUpdated(
    _StylesUpdated event,
    Emitter<StylesState> emit,
  ) {
    emit(StylesLoadSuccess(event.styles));
  }

  @override
  Future<void> close() {
    _stylesSubscription?.cancel();
    return super.close();
  }
}
