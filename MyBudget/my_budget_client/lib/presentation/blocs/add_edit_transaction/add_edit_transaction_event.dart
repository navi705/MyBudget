part of 'add_edit_transaction_bloc.dart';

abstract class AddEditTransactionEvent extends Equatable {
  const AddEditTransactionEvent();

  @override
  List<Object?> get props => [];
}
class AddEditTransactionLoad extends AddEditTransactionEvent {
  final Transaction? transaction;

  const AddEditTransactionLoad({this.transaction});

  @override
  List<Object?> get props => [transaction];
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
