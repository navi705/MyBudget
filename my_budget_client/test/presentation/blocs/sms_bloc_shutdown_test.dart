import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/settings.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/settings_repository.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:my_budget_client/domain/services/currency_converter_service.dart';
import 'package:my_budget_client/presentation/blocs/sms/sms_bloc.dart';

/// Pins the shutdown-race fix in [SmsBloc]'s handlers.
///
/// `Bloc.close()` (bloc 9.1.0) closes its internal `_eventController`
/// SYNCHRONOUSLY as the first thing it does — before any await, and long
/// before `isClosed` flips (that happens only once the whole close() chain,
/// including cancelling every handler's Emitter and every internal
/// subscription, has resolved). So a handler that is mid-`await` when
/// close() is called sees `isClosed == false` for a while longer, yet its
/// next `add()` already throws "Bad state: Cannot add new events after
/// calling close" — a bare `if (isClosed) return;` guard cannot catch this.
/// `BlocShutdownGuard.isShuttingDown` fixes it by flipping synchronously,
/// inside `markClosing()`, as the very first statement of `close()`.
class _FakeSmsRepository extends Fake implements SmsRepository {
  _FakeSmsRepository({required this.togglePresetGate});

  final List<SmsPreset> presets = const [];
  final Completer<void> togglePresetGate;
  final StreamController<SmsMessage> incoming =
      StreamController<SmsMessage>.broadcast();

  @override
  Stream<SmsMessage> listenForSms() => incoming.stream;

  @override
  Future<List<SmsPreset>> getAllPresets() async => presets;

  @override
  Future<List<SmsPreset>> getEnabledPresets() async =>
      presets.where((p) => p.isEnabled).toList();

  @override
  Future<void> togglePreset(String presetId, bool isEnabled) =>
      togglePresetGate.future;
}

class _FakeTransactionRepository extends Fake
    implements TransactionRepository {
  @override
  Stream<void> watchTransactionChanges() => const Stream.empty();
}

class _FakeCurrencyRepository extends Fake implements CurrencyRepository {
  @override
  Future<List<Currency>> getCurrencies() async => const [];
}

class _FakeAccountRepository extends Fake implements AccountRepository {
  @override
  Stream<List<Account>> watchAccounts() => const Stream.empty();
}

class _FakeCategoryRepository extends Fake implements CategoryRepository {
  @override
  Future<List<Category>> getCategories({bool includeSystem = false}) async =>
      const [];
}

class _FakeSettingsRepository extends Fake implements SettingsRepository {
  @override
  Future<Settings?> getSetting(String key) async => null;
}

class _FakeCurrencyConverterService extends Fake
    implements CurrencyConverterService {
  @override
  Future<ExchangeRateDomain?> getExchangeRate({
    required String fromCurrencyCode,
    required String toCurrencyCode,
    required DateTime date,
    required String mainCurrencyCode,
    int preset = 1,
  }) async => null;
}

void main() {
  group('SmsBloc shutdown race', () {
    test(
      'a preset toggle in flight when close() starts does not throw',
      () async {
        final togglePresetGate = Completer<void>();
        final smsRepository = _FakeSmsRepository(
          togglePresetGate: togglePresetGate,
        );
        final bloc = SmsBloc(
          smsRepository: smsRepository,
          transactionRepository: _FakeTransactionRepository(),
          currencyRepository: _FakeCurrencyRepository(),
          accountRepository: _FakeAccountRepository(),
          categoryRepository: _FakeCategoryRepository(),
          currencyConverterService: _FakeCurrencyConverterService(),
          settingsRepository: _FakeSettingsRepository(),
        );

        bloc.add(const ToggleSmsPreset('preset-1', true));
        await pumpEventQueue(); // handler now suspended on togglePresetGate

        final zoneErrors = <Object>[];
        await runZonedGuarded(() async {
          // close() runs markClosing() synchronously as its first statement
          // (see bloc_lifecycle.dart), which is what the guard depends on —
          // long before isClosed itself would flip.
          final closeFuture = bloc.close();
          togglePresetGate.complete();
          await pumpEventQueue();
          await closeFuture;
          await pumpEventQueue();
        }, (error, stack) => zoneErrors.add(error));

        expect(
          zoneErrors,
          isEmpty,
          reason:
              'the resumed handler must bail via isShuttingDown instead of '
              'calling add() on a bloc whose event controller is already '
              'closed',
        );

        await smsRepository.incoming.close();
      },
    );
  });
}
