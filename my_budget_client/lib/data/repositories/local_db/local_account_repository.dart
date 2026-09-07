import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/account_mapper.dart';
import 'package:my_budget_client/core/mappers/account_type_mapper.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';

class LocalAccountRepository implements AccountRepository {
  final db.AppDatabase database;

  LocalAccountRepository(this.database);

  @override
  Stream<List<Account>> watchAccounts() {
    return database.accountsDao.watchAllAccounts().map(
      (accounts) => accounts.toDomainList(),
    );
  }

  @override
  Future<void> addAccount(Account account) async {
    await database.accountsDao.insertAccount(account.toCompanion());
  }

  @override
  Future<void> addAccounts(List<Account> account) async {
    await database.accountsDao.insertAllAccounts(account.toCompanionList());
  }

  @override
  Future<void> deleteAccount(String id) async {
    await database.accountsDao.deleteAccount(
      db.AccountsCompanion(id: Value(id)),
    );
  }

  @override
  Future<Account?> getAccountById(String id) async {
    final dbAccount = await database.accountsDao.getAccountById(id);
    return dbAccount?.toDomain();
  }

  // OPTIMIZATION: Bulk fetch accounts by IDs
  @override
  Future<List<Account>> getAccountsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final dbAccounts = await database.accountsDao.getAccountsByIds(ids);
    return dbAccounts.toDomainList();
  }

  @override
  Future<List<Account>> getAccounts() async {
    final accounts = await database.accountsDao.getAllAccounts();
    return accounts.toDomainList();
  }

  @override
  Future<List<Account>> getAccountsPaginated({
    int limit = 10,
    int offset = 0,
  }) async {
    final accounts = await database.accountsDao.getAccounts(
      limit: limit,
      offset: offset,
    );
    return accounts.toDomainList();
  }

  @override
  Future<void> updateAccount(Account account) async {
    await database.accountsDao.updateAccount(account.toCompanion());
  }

  @override
  Future<void> restoreAccount(
    Account account, {
    List<String> tombstonedTransactionIds = const [],
    List<String> movedTransactionIds = const [],
  }) async {
    await database.accountsDao.restoreAccount(
      account.toCompanion(),
      tombstonedTransactionIds: tombstonedTransactionIds,
      movedTransactionIds: movedTransactionIds,
    );
  }

  @override
  Future<List<AccountType>> getAccountTypes() async {
    final accountTypes = await database.accountTypesDao.getAllAccountTypes();
    return accountTypes.toDomainList();
  }

  @override
  Stream<List<AccountType>> watchAccountTypes() {
    return database.accountTypesDao.watchAllAccountTypes().map(
      (accountTypes) => accountTypes.toDomainList(),
    );
  }

  @override
  Future<AccountType?> getAccountTypeById(String id) async {
    final accountType = await database.accountTypesDao.getAccountTypeById(id);
    return accountType?.toDomain();
  }

  @override
  Future<void> addAccountTypes(List<AccountType> accountTypes) async {
    await database.accountTypesDao.insertAllAccountTypes(
      accountTypes.toCompanionList(),
    );
  }

  @override
  Future<Map<String, double>> getBalancesAtDate(DateTime date) {
    return database.accountsDao.getBalancesAtDate(date);
  }

  @override
  Future<int> getCountWithFilters({List<String>? accountTypeIds}) {
    return database.accountsDao.getCountWithFilters(
      accountTypeIds: accountTypeIds,
    );
  }

  @override
  Future<void> deleteMultipleAccounts(List<String> accountIds) {
    return database.accountsDao.deleteMultipleAccounts(accountIds);
  }

  @override
  Future<List<String>> deleteAccountWithTransactions(String accountId) async {
    debugPrint(
      '[LocalRepo] Requesting deleteAccountWithTransactions for $accountId',
    );
    final deletedTxIds = await database.accountsDao
        .deleteAccountWithTransactions(accountId);
    debugPrint(
      '[LocalRepo] Finished deleteAccountWithTransactions for $accountId',
    );
    return deletedTxIds;
  }

  @override
  Future<List<String>> deleteAccountAndReassignTransactions(
    String accountId,
    String newAccountId,
  ) {
    return database.accountsDao.deleteAccountAndReassignTransactions(
      accountId,
      newAccountId,
    );
  }

  @override
  Future<void> updateAccountTypeForMultipleAccounts(
    List<String> accountIds,
    String accountTypeId,
  ) {
    return database.accountsDao.updateAccountTypeForMultipleAccounts(
      accountIds,
      accountTypeId,
    );
  }

  @override
  Future<List<Account>> getAccountsPaginatedFiltered({
    int limit = 10,
    int offset = 0,
    AccountFilters? accountFilters,
  }) async {
    final accounts = await database.accountsDao.getAccountWithFilters(
      limit: limit,
      offset: offset,
      sort: accountFilters?.sort == Sort.ascending
          ? OrderingMode.asc
          : OrderingMode.desc,
      description: accountFilters?.description,
      name: accountFilters?.name,
      amountFrom: accountFilters?.amountFrom,
      amountTo: accountFilters?.amountTo,
      date: accountFilters?.date,
      currenciesIds: accountFilters?.currenciesIds,
      accountTypeIds: accountFilters?.accountTypeIds,
    );

    return accounts.toDomainList();
  }
}
