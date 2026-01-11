import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';

abstract class AccountRepository {
  Future<List<Account>> getAccounts();
  Future<List<Account>> getAccountsPaginated({int limit = 10, int offset = 0});
  Future<List<Account>> getAccountsPaginatedFiltered({
    int limit = 10,
    int offset = 0,
    AccountFilters? accountFilters,
  });
  Stream<List<Account>> watchAccounts();
  Future<Account?> getAccountById(String id);
  Future<void> addAccount(Account account);
  Future<void> addAccounts(List<Account> accounts);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String id);
  Future<void> deleteMultipleAccounts(List<String> accountIds);
  Future<void> deleteAccountWithTransactions(String accountId);
  Future<void> deleteAccountAndReassignTransactions(
    String accountId,
    String newAccountId,
  );
  Future<void> restoreAccount(Account account);
  Future<Map<String, double>> getBalancesAtDate(DateTime date);
  Future<int> getCountWithFilters({List<String>? accountTypeIds});

  Future<List<AccountType>> getAccountTypes();
  Stream<List<AccountType>> watchAccountTypes();
  Future<AccountType?> getAccountTypeById(String id);
  Future<void> addAccountTypes(List<AccountType> accountTypes);
  Future<void> updateAccountTypeForMultipleAccounts(
    List<String> accountIds,
    String accountTypeId,
  );
}

class AccountFilters extends Equatable {
  final String? description;
  final String? name;
  final double? amountFrom;
  final double? amountTo;
  final DateTime? date;
  final List<String>? currenciesIds;
  final List<String>? accountTypeIds;
  final Sort sort;

  const AccountFilters({
    this.description,
    this.name,
    this.amountFrom,
    this.amountTo,
    this.date,
    this.currenciesIds,
    this.accountTypeIds,
    required this.sort,
  });

  AccountFilters copyWith({
    final String? description,
    final String? name,
    final double? amountFrom,
    final double? amountTo,
    final DateTime? date,
    final List<String>? currenciesIds,
    final List<String>? accountTypeIds,
    final Sort? sort,
  }) {
    return AccountFilters(
      description: description ?? this.description,
      name: name ?? this.name,
      amountFrom: amountFrom ?? this.amountFrom,
      amountTo: amountTo ?? this.amountTo,
      date: date ?? this.date,
      currenciesIds: currenciesIds ?? this.currenciesIds,
      accountTypeIds: accountTypeIds ?? this.accountTypeIds,
      sort: sort ?? this.sort,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'description': description,
      'name': name,
      'amountFrom': amountFrom,
      'amountTo': amountTo,
      'date': date?.toIso8601String(),
      'currenciesIds': currenciesIds,
      'accountTypeIds': accountTypeIds,
      'sort': sort.name,
    };
  }

  factory AccountFilters.fromJson(Map<String, dynamic> json) {
    return AccountFilters(
      description: json['description'],
      name: json['name'],
      amountFrom: json['amountFrom'],
      amountTo: json['amountTo'],
      date: json['date'] != null ? DateTime.parse(json['date']) : null,
      currenciesIds: json['currenciesIds'] != null
          ? List<String>.from(json['currenciesIds'])
          : null,
      accountTypeIds: json['accountTypeIds'] != null
          ? List<String>.from(json['accountTypeIds'])
          : null,
      sort: Sort.values.firstWhere(
        (e) => e.name == json['sort'],
        orElse: () => Sort.descending,
      ),
    );
  }

  String toJsonString() => json.encode(toJson());

  factory AccountFilters.fromJsonString(String jsonString) =>
      AccountFilters.fromJson(json.decode(jsonString));

  @override
  List<Object?> get props => [
    description,
    name,
    amountFrom,
    amountTo,
    date,
    currenciesIds,
    accountTypeIds,
    sort,
  ];
}
