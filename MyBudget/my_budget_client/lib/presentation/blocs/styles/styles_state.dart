part of 'styles_bloc.dart';

abstract class StylesState extends Equatable {
  const StylesState();

  @override
  List<Object> get props => [];
}

class StylesInitial extends StylesState {}

class StylesLoadInProgress extends StylesState {}

class StylesLoadSuccess extends StylesState {
  final List<Style> styles;
  final Set<String> selectedStyleIds;
  final bool isSelectionModeActive;

  const StylesLoadSuccess([
    this.styles = const [],
    this.selectedStyleIds = const {},
    this.isSelectionModeActive = false,
  ]);

  StylesLoadSuccess copyWith({
    List<Style>? styles,
    Set<String>? selectedStyleIds,
    bool? isSelectionModeActive,
  }) {
    return StylesLoadSuccess(
      styles ?? this.styles,
      selectedStyleIds ?? this.selectedStyleIds,
      isSelectionModeActive ?? this.isSelectionModeActive,
    );
  }

  @override
  List<Object> get props => [styles, selectedStyleIds, isSelectionModeActive];
}

class StylesLoadFailure extends StylesState {}
