part of 'add_edit_transaction_bloc.dart';

abstract class AddEditTransactionEvent extends Equatable {
  const AddEditTransactionEvent();

  @override
  List<Object?> get props => [];
}

class AddEditTransactionLoad extends AddEditTransactionEvent {
  final Transaction? transaction;
  final String? accountId;
  final bool isTransfer;

  const AddEditTransactionLoad({
    this.transaction,
    this.accountId,
    this.isTransfer = false,
  });

  @override
  List<Object?> get props => [transaction, accountId, isTransfer];
}

class AddEditTransactionDescriptionChanged extends AddEditTransactionEvent {
  final String description;

  const AddEditTransactionDescriptionChanged(this.description);

  @override
  List<Object> get props => [description];
}

class AddEditTransactionAmountChanged extends AddEditTransactionEvent {
  final String amount;

  const AddEditTransactionAmountChanged(this.amount);

  @override
  List<Object> get props => [amount];
}

class AddEditTransactionFeeChanged extends AddEditTransactionEvent {
  final String fee;

  const AddEditTransactionFeeChanged(this.fee);

  @override
  List<Object> get props => [fee];
}

class AddEditTransactionAccountChanged extends AddEditTransactionEvent {
  final Account account;

  const AddEditTransactionAccountChanged(this.account);

  @override
  List<Object> get props => [account];
}

class AddEditTransactionCategoryChanged extends AddEditTransactionEvent {
  final Category category;

  const AddEditTransactionCategoryChanged(this.category);

  @override
  List<Object> get props => [category];
}

class AddEditTransactionDateChanged extends AddEditTransactionEvent {
  final DateTime date;

  const AddEditTransactionDateChanged(this.date);

  @override
  List<Object> get props => [date];
}

class AddEditTransactionSubmitted extends AddEditTransactionEvent {
  // A transfer writes two rows whose descriptions the user never typed, so the
  // app has to word them - and a bloc has no `BuildContext` to reach `l10n`
  // with. The screen does, so it fills the two templates in with the account
  // names and hands over finished strings.
  //
  // Both stay nullable, and the bloc falls back to the English wording it has
  // always written, so the callers with no localizations to offer - the tests,
  // and any future non-UI caller - keep producing exactly what they did.
  final String? transferToDescription;
  final String? transferFromDescription;

  // An asset buy or sell writes two rows the same way and for the same reason:
  // the asset leg ("Buy Bitcoin") when the user typed no description of their
  // own, and the cash leg that pays for it, which they never get to describe.
  final String? assetDescription;
  final String? assetTransferDescription;

  const AddEditTransactionSubmitted({
    this.transferToDescription,
    this.transferFromDescription,
    this.assetDescription,
    this.assetTransferDescription,
  });

  @override
  List<Object?> get props => [
    transferToDescription,
    transferFromDescription,
    assetDescription,
    assetTransferDescription,
  ];
}

class AddEditTransactionCurrencyChanged extends AddEditTransactionEvent {
  final Currency currency;
  const AddEditTransactionCurrencyChanged(this.currency);
  @override
  List<Object> get props => [currency];
}

class AddEditTransactionRatePresetChanged extends AddEditTransactionEvent {
  final ExchangeRateDomain? rate;
  const AddEditTransactionRatePresetChanged(this.rate);
  @override
  List<Object?> get props => [rate];
}

class AddEditTransactionManualRateChanged extends AddEditTransactionEvent {
  final String rate;
  const AddEditTransactionManualRateChanged(this.rate);
  @override
  List<Object> get props => [rate];
}

/// The user typed how much should ARRIVE, rather than the rate it arrives at.
///
/// A cross-currency transfer is nearly always known from both ends - the app
/// that sent it says what left and what landed - and until now the form only
/// accepted the quotient of the two. The rate is derived from this and the
/// sent amount, so the two fields and the rate card stay one number.
class AddEditTransactionReceivedAmountChanged extends AddEditTransactionEvent {
  final String amount;
  const AddEditTransactionReceivedAmountChanged(this.amount);
  @override
  List<Object> get props => [amount];
}

class AddEditTransactionAddNewRate extends AddEditTransactionEvent {
  const AddEditTransactionAddNewRate();
}

class AddEditTransactionSaveRateAsDefault extends AddEditTransactionEvent {
  const AddEditTransactionSaveRateAsDefault();
}

class AddEditTransactionUpdatePreset extends AddEditTransactionEvent {
  final ExchangeRateDomain rate;
  const AddEditTransactionUpdatePreset(this.rate);
  @override
  List<Object> get props => [rate];
}

class AddEditTransactionLinkedAccountChanged extends AddEditTransactionEvent {
  final Account account;

  const AddEditTransactionLinkedAccountChanged(this.account);

  @override
  List<Object> get props => [account];
}

class AddEditTransactionToggleRateDirection extends AddEditTransactionEvent {
  const AddEditTransactionToggleRateDirection();
}

class AddEditTransactionSwapAccounts extends AddEditTransactionEvent {
  const AddEditTransactionSwapAccounts();
}

class AddEditTransactionLinkTransaction extends AddEditTransactionEvent {
  final Transaction linkedTransaction;
  const AddEditTransactionLinkTransaction(this.linkedTransaction);

  @override
  List<Object?> get props => [linkedTransaction];
}

class AddEditTransactionAssetActionChanged extends AddEditTransactionEvent {
  final AssetAction action;

  const AddEditTransactionAssetActionChanged(this.action);

  @override
  List<Object> get props => [action];
}

class AddEditTransactionTotalValueChanged extends AddEditTransactionEvent {
  final String value;

  const AddEditTransactionTotalValueChanged(this.value);

  @override
  List<Object> get props => [value];
}

class AddEditTransactionRecordExchangeLossChanged
    extends AddEditTransactionEvent {
  final bool record;

  const AddEditTransactionRecordExchangeLossChanged(this.record);

  @override
  List<Object> get props => [record];
}

class AddEditTransactionDeletePreset extends AddEditTransactionEvent {
  final ExchangeRateDomain rate;

  const AddEditTransactionDeletePreset(this.rate);

  @override
  List<Object> get props => [rate];
}

class _AddEditTransactionAccountsUpdated extends AddEditTransactionEvent {
  final List<Account> accounts;
  const _AddEditTransactionAccountsUpdated(this.accounts);
  @override
  List<Object> get props => [accounts];
}

class _AddEditTransactionCategoriesUpdated extends AddEditTransactionEvent {
  final List<Category> categories;
  const _AddEditTransactionCategoriesUpdated(this.categories);
  @override
  List<Object> get props => [categories];
}
