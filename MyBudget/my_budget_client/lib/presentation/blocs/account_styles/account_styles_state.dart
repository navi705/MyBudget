part of 'account_styles_bloc.dart';

abstract class AccountStylesState extends Equatable {
  const AccountStylesState();

  @override
  List<Object> get props => [];
}

class AccountStylesInitial extends AccountStylesState {}

class AccountStylesLoadInProgress extends AccountStylesState {}

class AccountStylesLoadSuccess extends AccountStylesState {
  final List<AccountStyle> styles;

  const AccountStylesLoadSuccess([this.styles = const []]);

  @override
  List<Object> get props => [styles];
}

class AccountStylesLoadFailure extends AccountStylesState {}
