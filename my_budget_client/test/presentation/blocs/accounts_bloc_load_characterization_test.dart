import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:my_budget_client/data/repositories/local_db/local_account_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_asset_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_category_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_currency_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_inflation_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_settings_repository.dart';
import 'package:my_budget_client/data/repositories/local_db/local_transaction_repository.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';

/// Golden-value characterization of AccountsBloc._onLoadAccounts against a real
/// in-memory database, wired through the real Local* repositories.
///
/// Pins the balances / period stats the bloc emits today so the upcoming
/// SQL-aggregate swap (standard balances via getFutureSumsGrouped instead of a
/// full-history FinanceCalculator pass) can be proven to preserve them.
///
/// Dataset is seeded RELATIVE to DateTime.now() so it is deterministic
/// regardless of the machine clock, and — crucially — chosen so no transaction
/// lands after activeDate on the same calendar day. That keeps the values
/// identical under both the current (exact-timestamp) engine and the
/// end-of-day SQL cutoff the swap introduces.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());

    final currencies = await db.select(db.currencies).get();
    final currencyCode = currencies
        .firstWhere((c) => c.code == 'EUR', orElse: () => currencies.first)
        .code;
    final designationId =
        (await db.select(db.currencyDesignations).get()).first.id;
    final accountTypeId = (await db.select(db.accountTypes).get()).first.id;
    final categoryId = (await db.select(db.categories).get()).first.id;

    final creation = DateTime.now().subtract(const Duration(days: 2000));

    Future<void> account(String id, double balance) {
      return db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: Value(id),
              name: id,
              balance: balance,
              currencyCode: currencyCode,
              currencyDesignationId: designationId,
              accountTypeId: accountTypeId,
              creationDate: Value(creation),
            ),
          );
    }

    Future<void> tx(String id, String acc, double amount, DateTime date) {
      return db
          .into(db.transactions)
          .insert(
            TransactionsCompanion.insert(
              id: Value(id),
              description: id,
              amount: amount,
              date: date,
              accountId: acc,
              categoryId: categoryId,
              currencyCode: currencyCode,
            ),
          );
    }

    final now = DateTime.now();
    await account('S1', 1000.0);
    await account('S2', 500.0);

    // Future transaction: always undone by reverse-calc -> nominal 1000 - 30.
    await tx('future', 'S1', 30.0, now.add(const Duration(days: 400)));
    // "Today" income, strictly before the bloc's activeDate (captured later),
    // so it is already baked into the stored balance and sits in the current
    // month's period.
    await tx('today', 'S1', 200.0, now);

    // Populate the exact minor-unit columns so the bloc exercises the
    // integer-minor balance path (goldens are integer-clean, so values match).
    await db.backfillMinorUnits();
  });

  tearDown(() async {
    await db.close();
  });

  AccountsBloc buildBloc() => AccountsBloc(
    accountRepository: LocalAccountRepository(db),
    settingsRepository: LocalSettingsRepository(db),
    currencyRepository: LocalCurrencyRepository(db),
    inflationRepository: LocalInflationRepository(db.inflationRatesDao),
    transactionRepository: LocalTransactionRepository(db),
    assetRepository: LocalAssetRepository(db.assetEntriesDao),
    categoryRepository: LocalCategoryRepository(db),
    financeCalculator: FinanceCalculator(),
  );

  Future<AccountsLoadSuccess> load(AccountsBloc bloc) async {
    bloc.add(LoadAccounts());
    return await bloc.stream.firstWhere((s) => s is AccountsLoadSuccess)
        as AccountsLoadSuccess;
  }

  test('emits reverse-calc nominal balances (future tx undone)', () async {
    final bloc = buildBloc();
    final s = await load(bloc);

    double bal(String id) => s.accounts.firstWhere((a) => a.id == id).balance;
    expect(bal('S1'), 970.0); // 1000 - future(30)
    expect(bal('S2'), 500.0);

    await bloc.close();
  });

  test('real balances equal nominal when no inflation seeded', () async {
    final bloc = buildBloc();
    final s = await load(bloc);

    expect(s.realBalances['S1'], 970.0);
    expect(s.realBalances['S2'], 500.0);

    await bloc.close();
  });

  test(
    'previous-period balances undo everything after prev period end',
    () async {
      final bloc = buildBloc();
      final s = await load(bloc);

      // Prev period = previous month. Everything after its end (today +200,
      // future +30) is undone: 1000 - 230 = 770.
      expect(s.previousPeriodBalances['S1'], 770.0);
      expect(s.previousPeriodBalances['S2'], 500.0);

      await bloc.close();
    },
  );

  test('current-period income captures the today transaction', () async {
    final bloc = buildBloc();
    final s = await load(bloc);

    expect(s.accountIncomes['S1'], 200.0);
    // No expenses seeded.
    expect(s.accountExpenses['S1'] ?? 0.0, 0.0);

    await bloc.close();
  });
}
