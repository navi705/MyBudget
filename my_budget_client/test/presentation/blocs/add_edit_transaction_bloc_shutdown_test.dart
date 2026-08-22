import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/add_edit_transaction/add_edit_transaction_bloc.dart';

/// Regression coverage for AddEditTransactionBloc's close()/resubscribe
/// await-ordering fix: `close()` now awaits both `_accountsSubscription`
/// and `_categoriesUpdatedSubscription` cancels before `super.close()`, and
/// `_onLoad` awaits the previous cancels before reassigning both
/// subscriptions on a reload (`AddEditTransactionLoad` dispatched twice).
///
/// As with settings_bloc_shutdown_test.dart / dashboard_bloc_shutdown_test.dart,
/// this is a smoke/regression test, not a proof that removing the await
/// reproduces a crash — see settings_bloc_shutdown_test.dart's header for the
/// empirical finding backing that distinction.
class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Stream<List<Account>> watchAccounts() => Stream.value(const []);

  @override
  Future<List<Account>> getAccounts() async => const [];
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      Stream.value(const []);

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      const [];
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<Currency>> getCurrencies() async => const [];
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;
}

class _FakeTransactionRepository extends Fake
    implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeAssetRepository extends Fake implements AssetRepository {}

AddEditTransactionBloc _buildBloc() => AddEditTransactionBloc(
  transactionRepository: _FakeTransactionRepository(),
  accountRepository: _FakeAccountRepository(),
  categoryRepository: _FakeCategoryRepository(),
  currencyRepository: _FakeCurrencyRepository(),
  settingsRepository: _FakeSettingsRepository(),
  assetRepository: _FakeAssetRepository(),
);

void main() {
  group('AddEditTransactionBloc close()/resubscribe', () {
    test('closing mid-load does not throw', () async {
      final bloc = _buildBloc();

      final zoneErrors = <Object>[];
      await runZonedGuarded(() async {
        bloc.add(const AddEditTransactionLoad());
        await pumpEventQueue();
        await bloc.close();
      }, (error, stack) => zoneErrors.add(error));

      expect(zoneErrors, isEmpty);
    });

    test('a second AddEditTransactionLoad resubscribes without leaking the '
        'old streams', () async {
      final bloc = _buildBloc();

      final zoneErrors = <Object>[];
      await runZonedGuarded(() async {
        bloc.add(const AddEditTransactionLoad());
        await pumpEventQueue();
        bloc.add(const AddEditTransactionLoad());
        await pumpEventQueue();
        await bloc.close();
      }, (error, stack) => zoneErrors.add(error));

      expect(zoneErrors, isEmpty);
    });
  });
}
