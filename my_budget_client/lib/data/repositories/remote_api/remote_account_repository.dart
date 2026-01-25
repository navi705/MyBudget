import 'package:my_budget_client/domain/entities/account.dart';

abstract class RemoteAccountRepository {
  Future<List<Account>> getAccounts();
  Future<Account?> getAccountById(int id);
  Future<void> addAccount(Account account);
  Future<void> updateAccount(Account account);
  Future<void> deleteAccount(int id);
}
