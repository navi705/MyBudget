import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/account_style.dart';
import 'package:my_budget_client/domain/repositories/account_style_repository.dart';

part 'account_styles_event.dart';
part 'account_styles_state.dart';

class AccountStylesBloc extends Bloc<AccountStylesEvent, AccountStylesState> {
  final AccountStyleRepository _accountStyleRepository;
  StreamSubscription? _stylesSubscription;

  AccountStylesBloc({required AccountStyleRepository accountStyleRepository})
      : _accountStyleRepository = accountStyleRepository,
        super(AccountStylesInitial()) {
    on<LoadAccountStyles>(_onLoadAccountStyles);
    on<AddAccountStyle>(_onAddAccountStyle);
    on<UpdateAccountStyle>(_onUpdateAccountStyle);
    on<DeleteAccountStyle>(_onDeleteAccountStyle);
    on<_AccountStylesUpdated>(_onStylesUpdated);
  }

  void _onLoadAccountStyles(
    LoadAccountStyles event,
    Emitter<AccountStylesState> emit,
  ) {
    emit(AccountStylesLoadInProgress());
    _stylesSubscription?.cancel();
    _stylesSubscription = _accountStyleRepository.watchAllStyles().listen(
          (styles) => add(_AccountStylesUpdated(styles)),
          onError: (_) => emit(AccountStylesLoadFailure()),
        );
  }

  Future<void> _onAddAccountStyle(
    AddAccountStyle event,
    Emitter<AccountStylesState> emit,
  ) async {
    await _accountStyleRepository.addStyle(event.style);
  }

  Future<void> _onUpdateAccountStyle(
    UpdateAccountStyle event,
    Emitter<AccountStylesState> emit,
  ) async {
    await _accountStyleRepository.updateStyle(event.style);
  }

  Future<void> _onDeleteAccountStyle(
    DeleteAccountStyle event,
    Emitter<AccountStylesState> emit,
  ) async {
    await _accountStyleRepository.deleteStyle(event.id);
  }

  void _onStylesUpdated(
    _AccountStylesUpdated event,
    Emitter<AccountStylesState> emit,
  ) {
    emit(AccountStylesLoadSuccess(event.styles));
  }

  @override
  Future<void> close() {
    _stylesSubscription?.cancel();
    return super.close();
  }
}
