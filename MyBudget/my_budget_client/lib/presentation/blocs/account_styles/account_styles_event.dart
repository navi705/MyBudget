part of 'account_styles_bloc.dart';

abstract class AccountStylesEvent extends Equatable {
  const AccountStylesEvent();

  @override
  List<Object> get props => [];
}

class LoadAccountStyles extends AccountStylesEvent {}

class AddAccountStyle extends AccountStylesEvent {
  final AccountStyle style;

  const AddAccountStyle(this.style);

  @override
  List<Object> get props => [style];
}

class UpdateAccountStyle extends AccountStylesEvent {
  final AccountStyle style;

  const UpdateAccountStyle(this.style);

  @override
  List<Object> get props => [style];
}

class DeleteAccountStyle extends AccountStylesEvent {
  final int id;

  const DeleteAccountStyle(this.id);

  @override
  List<Object> get props => [id];
}

class _AccountStylesUpdated extends AccountStylesEvent {
  final List<AccountStyle> styles;

  const _AccountStylesUpdated(this.styles);

  @override
  List<Object> get props => [styles];
}
