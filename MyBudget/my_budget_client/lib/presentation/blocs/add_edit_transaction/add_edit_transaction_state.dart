part of 'add_edit_transaction_bloc.dart';

enum AddEditTransactionStatus { initial, loading, success, failure }

class AddEditTransactionState extends Equatable {
  const AddEditTransactionState({
    this.status = AddEditTransactionStatus.initial,
    this.initialTransaction,
    this.description = '',
    this.amount = '',
    this.selectedAccount,
    this.selectedCategory,
    this.date,
    this.accounts = const [],
    this.categories = const [],
    this.isSaving = false,
    this.isSaveSuccess = false,
  });

  final AddEditTransactionStatus status;
  final Transaction? initialTransaction;
  final String description;
  final String amount;
  final Account? selectedAccount;
  final Category? selectedCategory;
  final DateTime? date;
  final List<Account> accounts;
  final List<Category> categories;
  final bool isSaving;
  final bool isSaveSuccess;

  bool get isEditing =>
      initialTransaction != null &&
      (initialTransaction!.id?.isNotEmpty ?? false);

  AddEditTransactionState copyWith({
    AddEditTransactionStatus? status,
    Transaction? initialTransaction,
    String? description,
    String? amount,
    Account? selectedAccount,
    Category? selectedCategory,
    DateTime? date,
    List<Account>? accounts,
    List<Category>? categories,
    bool? isSaving,
    bool? isSaveSuccess,
  }) {
    return AddEditTransactionState(
      status: status ?? this.status,
      initialTransaction: initialTransaction ?? this.initialTransaction,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      selectedAccount: selectedAccount ?? this.selectedAccount,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      date: date ?? this.date,
      accounts: accounts ?? this.accounts,
      categories: categories ?? this.categories,
      isSaving: isSaving ?? this.isSaving,
      isSaveSuccess: isSaveSuccess ?? this.isSaveSuccess,
    );
  }

  @override
  List<Object?> get props => [
    status,
    initialTransaction,
    description,
    amount,
    selectedAccount,
    selectedCategory,
    date,
    accounts,
    categories,
    isSaving,
    isSaveSuccess,
  ];
}
