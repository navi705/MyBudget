part of 'styles_bloc.dart';

abstract class StylesEvent extends Equatable {
  const StylesEvent();

  @override
  List<Object> get props => [];
}

class LoadStyles extends StylesEvent {}

class AddStyle extends StylesEvent {
  final Style style;

  const AddStyle(this.style);

  @override
  List<Object> get props => [style];
}

class UpdateStyle extends StylesEvent {
  final Style style;

  const UpdateStyle(this.style);

  @override
  List<Object> get props => [style];
}

class DeleteStyle extends StylesEvent {
  final String id;

  const DeleteStyle(this.id);

  @override
  List<Object> get props => [id];
}

class _StylesUpdated extends StylesEvent {
  final List<Style> styles;

  const _StylesUpdated(this.styles);

  @override
  List<Object> get props => [styles];
}

class ToggleStyleSelectionMode extends StylesEvent {
  final bool isActive;

  const ToggleStyleSelectionMode(this.isActive);

  @override
  List<Object> get props => [isActive];
}

class ToggleStyleSelection extends StylesEvent {
  final String styleId;

  const ToggleStyleSelection(this.styleId);

  @override
  List<Object> get props => [styleId];
}

class SelectAllStyles extends StylesEvent {
  const SelectAllStyles();
}

class ClearStyleSelection extends StylesEvent {
  const ClearStyleSelection();
}

class DeleteMultipleStyles extends StylesEvent {
  final List<String> ids;

  const DeleteMultipleStyles(this.ids);

  @override
  List<Object> get props => [ids];
}
