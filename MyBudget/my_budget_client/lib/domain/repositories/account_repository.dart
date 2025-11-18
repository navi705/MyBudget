import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';

abstract class AccountRepository {
  Future<List<Account>> getAccounts();
  Stream<List<Account>> watchAccounts();
  Future<Account?> getAccountById(int id);
  Future<void> addAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(int id);
  Future<void> restoreAccount(Account account);

  Future<List<AccountType>> getAccountTypes();
  Stream<List<AccountType>> watchAccountTypes();
  Future<AccountType?> getAccountTypeById(int id);
}
