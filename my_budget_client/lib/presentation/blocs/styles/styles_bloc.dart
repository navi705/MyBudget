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
    on<_StylesLoadFailed>(_onStylesLoadFailed);
    on<ToggleStyleSelectionMode>(_onToggleStyleSelectionMode);
    on<ToggleStyleSelection>(_onToggleStyleSelection);
    on<SelectAllStyles>(_onSelectAllStyles);
    on<ClearStyleSelection>(_onClearStyleSelection);
    on<DeleteMultipleStyles>(_onDeleteMultipleStyles);
  }

  Future<void> _onLoadStyles(
    LoadStyles event,
    Emitter<StylesState> emit,
  ) async {
    emit(StylesLoadInProgress());
    // Awaited: an un-awaited cancel lets the outgoing stream deliver one last
    // list after the new subscription is already live, so a stale style set can
    // land on top of the fresh one.
    await _stylesSubscription?.cancel();
    _stylesSubscription = _styleRepository.watchAllStyles().listen(
      (styles) => add(_StylesUpdated(styles)),
      // Routed as an event rather than emitted here: a stream error arrives
      // long after this handler has returned, and by then this Emitter is
      // completed — emitting on it threw "Emitter is already completed" and
      // StylesLoadFailure was never reachable. The event handler below owns a
      // live Emitter when the failure actually happens.
      onError: (_) => add(const _StylesLoadFailed()),
    );
  }

  void _onStylesLoadFailed(_StylesLoadFailed event, Emitter<StylesState> emit) {
    emit(StylesLoadFailure());
  }

  Future<void> _onAddStyle(AddStyle event, Emitter<StylesState> emit) async {
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

  Future<void> _onDeleteMultipleStyles(
    DeleteMultipleStyles event,
    Emitter<StylesState> emit,
  ) async {
    // Only delete styles that are NOT "Transfer"
    // Fetch current state to check names would be ideal, but for now we assume ID list is valid
    // Ideally the checking logic is in UI or here.
    // Assuming UI filters out Transfer ID before sending here, or we trust repository.
    // However, to be safe, we could check. But we don't have style map here easily without state access.
    // State access is available via `state`.

    if (state is StylesLoadSuccess) {
      final currentStyles = (state as StylesLoadSuccess).styles;
      final stylesToDelete = currentStyles
          .where((s) => event.ids.contains(s.id) && s.name != 'Transfer')
          .toList();

      for (final style in stylesToDelete) {
        if (style.id != null) {
          await _styleRepository.deleteStyle(style.id!);
        }
      }
      add(const ClearStyleSelection());
      add(const ToggleStyleSelectionMode(false));
    }
  }

  void _onStylesUpdated(_StylesUpdated event, Emitter<StylesState> emit) {
    // Preserve selection if possible, or just reset?
    // Usually reset on new data load is safer to avoid stale IDs,
    // but for updates (like edit) we might want to keep it.
    // For now, let's keep current state params if it was Success.
    if (state is StylesLoadSuccess) {
      final currentState = state as StylesLoadSuccess;
      emit(currentState.copyWith(styles: event.styles));
    } else {
      emit(StylesLoadSuccess(event.styles));
    }
  }

  void _onToggleStyleSelectionMode(
    ToggleStyleSelectionMode event,
    Emitter<StylesState> emit,
  ) {
    if (state is StylesLoadSuccess) {
      final currentState = state as StylesLoadSuccess;
      emit(
        currentState.copyWith(
          isSelectionModeActive: event.isActive,
          selectedStyleIds: event.isActive ? currentState.selectedStyleIds : {},
        ),
      );
    }
  }

  void _onToggleStyleSelection(
    ToggleStyleSelection event,
    Emitter<StylesState> emit,
  ) {
    if (state is StylesLoadSuccess) {
      final currentState = state as StylesLoadSuccess;
      final newSelectedIds = Set<String>.from(currentState.selectedStyleIds);
      if (newSelectedIds.contains(event.styleId)) {
        newSelectedIds.remove(event.styleId);
      } else {
        newSelectedIds.add(event.styleId);
      }
      emit(currentState.copyWith(selectedStyleIds: newSelectedIds));
    }
  }

  void _onSelectAllStyles(SelectAllStyles event, Emitter<StylesState> emit) {
    if (state is StylesLoadSuccess) {
      final currentState = state as StylesLoadSuccess;
      // Exclude 'Transfer' from selection if we want to prevent its mass deletion?
      // Or select it but prevent deletion later?
      // Let's select all that have an ID.
      final allIds = currentState.styles
          .where((s) => s.id != null)
          .map((s) => s.id!)
          .toSet();
      emit(currentState.copyWith(selectedStyleIds: allIds));
    }
  }

  void _onClearStyleSelection(
    ClearStyleSelection event,
    Emitter<StylesState> emit,
  ) {
    if (state is StylesLoadSuccess) {
      emit((state as StylesLoadSuccess).copyWith(selectedStyleIds: {}));
    }
  }

  @override
  Future<void> close() async {
    // Awaited: the listener above calls add(), and adding after the event
    // controller is closed throws. Cancelling without awaiting leaves that race
    // open on every screen dismissal.
    await _stylesSubscription?.cancel();
    return super.close();
  }
}
