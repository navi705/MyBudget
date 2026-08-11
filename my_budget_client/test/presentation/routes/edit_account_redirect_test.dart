import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/presentation/routes/app_router.dart';
import 'package:my_budget_client/presentation/routes/app_routes.dart';

/// Pins the recovery of `/edit-account` when its payload is gone.
///
/// `extra` is in-memory only, and this route sits outside the shell, so
/// arriving without it used to render a bare "Account not found!" Scaffold
/// with no AppBar, no back button and no navigation - nothing on screen could
/// take the user anywhere.
void main() {
  final account = Account(
    id: 'a1',
    name: 'Checking',
    balance: 0,
    currencyCode: 'RSD',
    currencyDesignationId: 'd1',
    accountTypeId: 't1',
    creationDate: DateTime(2025),
  );

  group('editAccountRedirect', () {
    test('lets a real account through', () {
      expect(editAccountRedirect(account), isNull);
    });

    test('sends a missing payload to the accounts list', () {
      expect(editAccountRedirect(null), AppRoutes.accounts);
    });

    test('sends a payload of the wrong type to the accounts list', () {
      // Route restoration hands back whatever it serialised, which is not an
      // Account - the cast in the page builder would throw.
      expect(editAccountRedirect({'id': 'a1'}), AppRoutes.accounts);
    });
  });
}
