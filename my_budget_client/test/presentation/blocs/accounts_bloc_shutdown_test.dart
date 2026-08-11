import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';

/// Pins the shutdown-race fix in [AccountsBloc]'s handlers.
///
/// `Bloc.close()` closes its internal event controller synchronously, before
/// `isClosed` ever flips (see sms_bloc_shutdown_test.dart for the full
/// mechanism). A handler resuming from an `await` after close() has started
/// therefore still sees `isClosed == false`, so its `add(LoadAccounts())`
/// throws "Bad state: Cannot add new events after calling close" unless it
/// is guarded by `isShuttingDown` instead.
class _FakeAccountRepository extends Fake implements AccountRepository {
  _FakeAccountRepository({required this.addAccountGate});

  final Completer<void> addAccountGate;

  @override
  Future<void> addAccount(Account account) => addAccountGate.future;
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {}

class _FakeInflationRepository extends Fake implements InflationRepository {}

class _FakeAssetRepository extends Fake implements AssetRepository {}

class _FakeCategoryRepository extends Fake implements CategoryRepository {}

void main() {
  group('AccountsBloc shutdown race', () {
    test('an add-account in flight when close() starts does not throw',
        () async {
      final addAccountGate = Completer<void>();
      final bloc = AccountsBloc(
        accountRepository: _FakeAccountRepository(
          addAccountGate: addAccountGate,
        ),
        settingsRepository: _FakeSettingsRepository(),
        currencyRepository: _FakeCurrencyRepository(),
        inflationRepository: _FakeInflationRepository(),
        transactionRepository: _FakeTransactionRepository(),
        assetRepository: _FakeAssetRepository(),
        categoryRepository: _FakeCategoryRepository(),
        financeCalculator: FinanceCalculator(),
      );

      final account = Account(
        id: 'acc-1',
        name: 'Wallet',
        balance: 0,
        currencyCode: 'EUR',
        currencyDesignationId: 'des-1',
        accountTypeId: 'type-1',
        creationDate: DateTime(2024),
      );

      bloc.add(AddAccount(account));
      await pumpEventQueue(); // handler suspended on addAccountGate

      final zoneErrors = <Object>[];
      await runZonedGuarded(() async {
        final closeFuture = bloc.close();
        addAccountGate.complete();
        await pumpEventQueue();
        await closeFuture;
        await pumpEventQueue();
      }, (error, stack) => zoneErrors.add(error));

      expect(
        zoneErrors,
        isEmpty,
        reason:
            'the resumed handler must bail via isShuttingDown instead of '
            'calling add(LoadAccounts()) on a bloc whose event controller '
            'is already closed',
      );
    });
  });
}
