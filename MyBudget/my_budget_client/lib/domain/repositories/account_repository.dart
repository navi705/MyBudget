import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/account_type.dart';

abstract class AccountRepository {
  Future<List<Account>> getAccounts();
  Future<List<Account>> getAccountsPaginated(
      {int limit = 10, int offset = 0});
  Stream<List<Account>> watchAccounts();
  Future<Account?> getAccountById(String id);
  Future<void> addAccount(Account account);
  Future<void> addAccounts(List<Account> accounts);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(String id);
  Future<void> restoreAccount(Account account);

  Future<List<AccountType>> getAccountTypes();
  Stream<List<AccountType>> watchAccountTypes();
  Future<AccountType?> getAccountTypeById(String id);
  Future<void> addAccountTypes(List<AccountType> accountTypes);
}
