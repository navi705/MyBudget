import 'package:my_budget_client/domain/entities/account_style.dart';

abstract class AccountStyleRepository {
  Stream<List<AccountStyle>> watchAllStyles();
  Future<void> addStyle(AccountStyle style);
  Future<void> updateStyle(AccountStyle style);
  Future<void> deleteStyle(int id);
}
