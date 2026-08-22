import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/style.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/asset_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/style_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/presentation/blocs/dashboard/dashboard_bloc.dart';

/// Regression coverage for DashboardBloc's close()/resubscribe
/// await-ordering fix: `close()` now awaits `_stylesSubscription.cancel()`
/// and `_categoriesSubscription.cancel()` (in that order, before closing
/// `_paramsSubject`), and `_onLoadDashboard` awaits both previous cancels
/// before reassigning the subscriptions on a reload.
///
/// As with settings_bloc_shutdown_test.dart, this is a smoke/regression
/// test, not a proof that removing the await reproduces a crash — see that
/// file's header for the empirical finding (StreamSubscription.cancel()
/// stops delivery synchronously regardless of whether it's awaited, so the
/// existing shipped reference bloc's own test suite does not distinguish
/// awaited vs. unawaited cancel either). The fix is kept because it matches
/// the codebase's established convention and guarantees the old
/// subscriptions are fully torn down before _paramsSubject.close() runs or
/// before the new subscriptions are attached.
class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Stream<List<Account>> watchAccounts() => Stream.value(const []);
}

class _FakeTransactionRepository extends Fake implements TransactionRepository {
  @override
  Stream<List<Transaction>> watchTransactions({DateTime? from}) =>
      Stream.value(const []);

  @override
  Future<List<GroupedTransactionTotal>> getTransactionTotalsGrouped({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async => const [];

  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Stream<List<Category>> watchCategories({bool includeSystem = false}) =>
      Stream.value(const []);

  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      const [];
}

class _FakeStyleRepository extends Fake implements StyleRepository {
  @override
  Stream<List<Style>> watchAllStyles() => Stream.value(const []);
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<Currency>> getCurrencies() async => const [];

  @override
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations() async =>
      const [];

  @override
  Future<List<ExchangeRateDomain>> getLatestExchangeRatesByList(
    List<DateTime> date, {
    Set<String>? currencyCodes,
  }) async => const [];

  @override
  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations() =>
      const Stream.empty();

  @override
  Stream<void> watchExchangeRateChanges() => const Stream.empty();
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Map<String, String>> getAllSettings() async => const {};

  @override
  Stream<List<Settings>> watchAllSettings() => const Stream.empty();
}

class _FakeAssetRepository extends Fake implements AssetRepository {
  @override
  Stream<List<AssetDataDomain>> watchAssetData({
    int limit = 50,
    int offset = 0,
    String? assetId,
    String? accountId,
    DateTime? startDate,
    DateTime? endDate,
    String? name,
    List<String>? assetTypes,
    String? description,
    List<String>? currencyCodes,
    List<String>? sources,
    List<int>? presets,
    double? minValue,
    double? maxValue,
    bool sortAscending = false,
  }) => Stream.value(const []);
}

DashboardBloc _buildBloc() => DashboardBloc(
  accountRepository: _FakeAccountRepository(),
  transactionRepository: _FakeTransactionRepository(),
  categoryRepository: _FakeCategoryRepository(),
  styleRepository: _FakeStyleRepository(),
  currencyRepository: _FakeCurrencyRepository(),
  settingsRepository: _FakeSettingsRepository(),
  assetRepository: _FakeAssetRepository(),
);

void main() {
  group('DashboardBloc close()/resubscribe', () {
    test('closing mid-load does not throw', () async {
      final bloc = _buildBloc();

      final zoneErrors = <Object>[];
      await runZonedGuarded(() async {
        bloc.add(LoadDashboard());
        await pumpEventQueue();
        await bloc.close();
      }, (error, stack) => zoneErrors.add(error));

      expect(zoneErrors, isEmpty);
    });

    test(
      'a second LoadDashboard resubscribes without leaking the old streams',
      () async {
        final bloc = _buildBloc();

        final zoneErrors = <Object>[];
        await runZonedGuarded(() async {
          bloc.add(LoadDashboard());
          await pumpEventQueue();
          bloc.add(LoadDashboard());
          await pumpEventQueue();
          await bloc.close();
        }, (error, stack) => zoneErrors.add(error));

        expect(zoneErrors, isEmpty);
      },
    );
  });
}
