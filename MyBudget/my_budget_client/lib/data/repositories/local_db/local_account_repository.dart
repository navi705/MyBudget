import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/account_mapper.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';

class LocalAccountRepository implements AccountRepository {
  final db.AppDatabase database;

  LocalAccountRepository(this.database);

  @override
  Stream<List<Account>> watchAccounts() {
    return database.accountsDao
        .watchAllAccounts()
        .map((accounts) => accounts.map((a) => a.toDomain()).toList());
  }

  @override
  Future<void> addAccount(Account account) async {
    await database.accountsDao.insertAccount(account.toCompanion());
  }

  @override
  Future<void> deleteAccount(int id) async {
    await database.accountsDao.deleteAccount(
      db.AccountsCompanion(id: Value(id)),
    );
  }

  @override
  Future<Account?> getAccountById(int id) async {
    final account = await database.accountsDao.getAccountById(id);
    return account?.toDomain();
  }

  @override
  Future<List<Account>> getAccounts() async {
    final accounts = await database.accountsDao.getAllAccounts();
    return accounts.map((a) => a.toDomain()).toList();
  }

  @override
  Future<void> updateAccount(Account account) async {
    await database.accountsDao.updateAccount(account.toCompanion());
  }
}
