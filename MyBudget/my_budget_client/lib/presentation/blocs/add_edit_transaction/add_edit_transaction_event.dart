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
  const AddEditTransactionSubmitted();
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

class AddEditTransactionAddNewRate extends AddEditTransactionEvent {
  const AddEditTransactionAddNewRate();
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
