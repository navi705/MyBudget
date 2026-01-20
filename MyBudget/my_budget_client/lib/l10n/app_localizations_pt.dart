// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get helloWorld => 'Olá Mundo!';

  @override
  String get accountsAppBarTitle => 'Contas';

  @override
  String accountsBalanceLabel(Object balance) {
    return 'Saldo: $balance';
  }

  @override
  String get accountsLoadFailure => 'Falha ao carregar contas';

  @override
  String get accountsEmptyState => 'Nenhuma conta';

  @override
  String get accountsRefreshTooltip => 'Atualizar';

  @override
  String get accountsAddTooltip => 'Adicionar Conta';

  @override
  String get addAccountDialogTitle => 'Adicionar nova conta';

  @override
  String get accountNameHint => 'Nome da conta';

  @override
  String get initialBalanceHint => 'Saldo inicial';

  @override
  String get currencyLabel => 'Moeda';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get saveButton => 'Salvar';

  @override
  String get formValidationPleaseEnterName => 'Por favor, insira um nome';

  @override
  String get formValidationPleaseEnterBalance => 'Por favor, insira um saldo';

  @override
  String get formValidationPleaseEnterValidNumber =>
      'Por favor, insira um número válido';

  @override
  String get formValidationPleaseSelectCurrency =>
      'Por favor, selecione uma moeda';

  @override
  String get currencyLoadError => 'Erro ao carregar moedas';

  @override
  String get noCurrenciesAvailable => 'Nenhuma moeda disponível';

  @override
  String get categoriesAppBarTitle => 'Categorias';

  @override
  String get categoriesScreenBody => 'Tela de Categorias';

  @override
  String get transactionsAppBarTitle => 'Transações';

  @override
  String get transactionsScreenBody => 'Tela de Transações';

  @override
  String get settingsAppBarTitle => 'Configurações';

  @override
  String get settingsScreenBody => 'Tela de Configurações';

  @override
  String get filePickerChooserTitle => 'Select File';

  @override
  String get imagePickerChooserTitle => 'Select Image';
}
