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

  const StylesLoadSuccess([this.styles = const []]);

  @override
  List<Object> get props => [styles];
}

class StylesLoadFailure extends StylesState {}
