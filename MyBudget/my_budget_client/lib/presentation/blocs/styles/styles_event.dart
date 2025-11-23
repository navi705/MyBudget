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
