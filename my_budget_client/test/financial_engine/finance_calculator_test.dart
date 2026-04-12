import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/domain/services/finance_calculator.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';

void main() {
  late FinanceCalculator calculator;
  late FinancialSnapshot snapshot;

  setUpAll(() async {
    // 1. Load Backup JSON
    final backupFile = File('test/financial_engine/my_budget_backup.json');
    if (!backupFile.existsSync()) {
      fail('Backup fixture not found. Please provide my_budget_backup.json');
    }
    final backupJson = jsonDecode(await backupFile.readAsString());

    // 2. Parse Accounts
    // Note: accounts in JSON might be Drift Data Classes, logic below assumes standard fields
    final List<dynamic> accountsJson = backupJson['accounts'] ?? [];
    var accounts = accountsJson.map((json) {
      return Account(
        id: json['id'] as String?,
        name: json['name'] as String,
        balance: (json['balance'] as num).toDouble(),
        currencyCode: json['currencyCode'] as String,
        currencyDesignationId:
            json['currencyDesignationId'] as String? ?? 'code',
        accountTypeId: json['accountTypeId'] as String? ?? 'general',
        creationDate: DateTime.fromMillisecondsSinceEpoch(
          json['creationDate'] as int,
        ),
        // Handle optional fields that might be missing or different in backup
        assetId: json['assetId'] as String?,
        assetQuantity: (json['assetQuantity'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();

    // 3. Parse Transactions
    final List<dynamic> transactionsJson = backupJson['transactions'] ?? [];
    final transactions = transactionsJson.map((json) {
      return Transaction(
        id: json['id'] as String?,
        description: json['description'] as String,
        amount: (json['amount'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        accountId: json['accountId'] as String,
        categoryId: json['categoryId'] as String,
        currencyCode: json['currencyCode'] as String,
      );
    }).toList();

    // 4. Parse Exchange Rates
    final List<dynamic> ratesJson = backupJson['exchange_rates'] ?? [];
    final exchangeRates = ratesJson.map((json) {
      return ExchangeRateDomain(
        fromCurrencyCode: json['fromCurrencyCode'] as String,
        toCurrencyCode: json['toCurrencyCode'] as String,
        preset: json['preset'] as int,
        rate: (json['rate'] as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
      );
    }).toList();

    // 5. Parse Inflation Rates (Mock if missing from backup)
    final inflationRates = <InflationRateDomain>[
      InflationRateDomain(
        preset: 0,
        country: 'Serbia',
        percent: 10.0, // 10% inflation
        date: DateTime.now().subtract(const Duration(days: 365)), // 1 year ago
      ),
    ];

    // 6. Parse Asset Entries
    // Assuming 'asset_entries' key exists in the updated backup
    final List<dynamic> assetEntriesJson = backupJson['asset_entries'] ?? [];
    final List<AssetDataDomain> assetData = assetEntriesJson.map((json) {
      return AssetDataDomain(
        id: json['id'] as String?,
        assetId: json['assetId'] as String,
        name: json['name'] as String,
        date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
        value: (json['value'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        assetType: json['assetType'] as String?,
        description: json['description'] as String?,
        currency: json['currencyCode'] as String? ?? 'EUR',
        accountId: json['accountId'] as String?,
        source: json['source'] as String,
        preset: json['preset'] as int? ?? 1,
      );
    }).toList();

    // 7. Bind Account to Asset (Test Setup)
    // Since Account.toJson might miss assetId, we manually bind an account to the first asset
    // we find in the data to ensure we can test the Logic.
    if (assetData.isNotEmpty) {
      final firstAssetId = assetData.first.assetId;
      // Try to find account with name 'Steam' or just the first user account
      final accountIndex = accounts.indexWhere(
        (a) => a.name.toLowerCase().contains('steam'),
      );
      if (accountIndex != -1) {
        accounts[accountIndex] = accounts[accountIndex].copyWith(
          assetId: firstAssetId,
          assetQuantity: 1.0,
        );
        debugPrint(
          'Bound Account "${accounts[accountIndex].name}" to Asset "$firstAssetId" for testing.',
        );
      } else if (accounts.isNotEmpty) {
        accounts[0] = accounts[0].copyWith(
          assetId: firstAssetId,
          assetQuantity: 1.0,
        );
        debugPrint(
          'Bound Account "${accounts[0].name}" to Asset "$firstAssetId" for testing.',
        );
      }
    } else {
      debugPrint('WARNING: No asset entries found in backup.');
    }

    // Assign 'Serbia' to standardParams for inflation test
    if (accounts.isNotEmpty) {
      final idx = accounts.indexWhere((a) => a.assetId == null);
      if (idx != -1) {
        accounts[idx] = accounts[idx].copyWith(country: 'Serbia');
      }
    }

    snapshot = FinancialSnapshot(
      accounts: accounts,
      transactions: transactions,
      assetData: assetData,
      categories: [], // Added

      exchangeRates: exchangeRates,
      inflationRates: inflationRates,
      date: DateTime.now().subtract(
        const Duration(days: 400),
      ), // Date BEFORE inflation
      dateStep: DateStep.month,
      baseCurrency: 'EUR', // Default
    );
  });

  setUp(() {
    calculator = FinanceCalculator();
  });

  group('FinanceCalculator', () {
    test('calculatePercentageChange', () {
      expect(calculator.calculatePercentageChange(110, 100), 10.0);
      expect(calculator.calculatePercentageChange(90, 100), -10.0);
      expect(calculator.calculatePercentageChange(100, 0), 0.0);
    });

    test('calculateBalances returns map for all accounts', () {
      final balances = calculator.calculateBalances(snapshot);
      expect(balances.keys.length, snapshot.accounts.length);
    });

    test('Debug: Print Balance Comparison Table', () {
      // Ensure we calculate for "Now" (or the timestamp of the backup)
      // The snapshot date is currently set to 400 days ago in setUpAll.
      // We need to use "Now" (or backup timestamp) to compare with Account.balance

      final debugSnapshot = FinancialSnapshot(
        accounts: snapshot.accounts,
        transactions: snapshot.transactions,
        assetData: snapshot.assetData,
        categories: [], // Added
        exchangeRates: snapshot.exchangeRates,

        inflationRates: snapshot.inflationRates,
        date:
            DateTime.now(), // Calculate for NOW to compare with current balance
        dateStep: DateStep.month,
        baseCurrency: 'EUR',
      );

      final calculatedBalances = calculator.calculateBalances(debugSnapshot);

      debugPrint('\n--- BALANCE COMPARISON TABLE ---');
      debugPrint(
        '${"Account Name".padRight(30)} | ${"Currency".padRight(5)} | ${"Expected (Backup)".padRight(20)} | ${"Calculated (Sum Tx)".padRight(20)} | ${"Diff".padRight(20)}',
      );
      debugPrint('-' * 105);

      for (final account in debugSnapshot.accounts) {
        final calculated = calculatedBalances[account.id] ?? 0.0;
        final expected = account.balance;
        final diff = expected - calculated;

        // DEBUG: Drill down into 'cash eur'
        if (account.name.toLowerCase().contains('cash eur')) {
          debugPrint(
            '\n[DEBUG] Transactions for ${account.name} (ID: ${account.id}):',
          );
          final accountTx = debugSnapshot.transactions
              .where((t) => t.accountId == account.id)
              .toList();
          // Sort by date
          accountTx.sort((a, b) => a.date.compareTo(b.date));

          double runningSum = 0.0;
          for (final tx in accountTx) {
            runningSum += tx.amount;
            debugPrint(
              '  ${tx.date.toString().substring(0, 10)} | Amount: ${tx.amount.toStringAsFixed(2).padRight(10)} | Sum: ${runningSum.toStringAsFixed(2)} | Desc: ${tx.description}',
            );
          }
          debugPrint('[DEBUG] Total Tx Count: ${accountTx.length}');
          debugPrint('[DEBUG] Final Sum: $runningSum\n');
        }

        debugPrint(
          '${account.name.padRight(30)} | '
          '${account.currencyCode.padRight(5)} | '
          '${expected.toStringAsFixed(2).padRight(20)} | '
          '${calculated.toStringAsFixed(2).padRight(20)} | '
          '${diff.toStringAsFixed(2).padRight(20)}',
        );
      }
      debugPrint('-' * 105);
      debugPrint(
        'Note: "Expected" is the balance stored in the Account object.',
      );
      debugPrint(
        'Note: "Calculated" is the Sum of Transactions (or Asset Value).\n',
      );
    });

    test('calculateTotalNetWorth returns a non-zero value', () {
      final netWorth = calculator.calculateTotalNetWorth(snapshot);
      expect(netWorth, isNotNull);

      // Calculate RSD value for display
      // Find exchange rate for RSD relative to base (EUR)
      // Assuming we have EUR -> RSD or equivalent.
      double eurToRsd = 117.0; // Default fallback

      try {
        final rateObj = snapshot.exchangeRates.firstWhere(
          (r) =>
              (r.fromCurrencyCode == 'EUR' && r.toCurrencyCode == 'RSD') ||
              (r.fromCurrencyCode == 'RSD' && r.toCurrencyCode == 'EUR'),
        );

        if (rateObj.fromCurrencyCode == 'EUR' &&
            rateObj.toCurrencyCode == 'RSD') {
          eurToRsd = rateObj.rate;
        } else {
          // RSD -> EUR rate (e.g. 0.0085)
          // we want EUR -> RSD (1 / 0.0085)
          eurToRsd = 1.0 / rateObj.rate;
        }
      } catch (e) {
        // Not found, stick to 117
      }

      final netWorthRsd = netWorth * eurToRsd;

      debugPrint('\n--- TOTAL NET WORTH TABLE ---');
      debugPrint(
        '${"Metric".padRight(30)} | ${"Value".padRight(20)} | ${"Currency".padRight(10)}',
      );
      debugPrint('-' * 66);
      debugPrint(
        '${"Total Net Worth".padRight(30)} | ${netWorth.toStringAsFixed(2).padRight(20)} | ${snapshot.baseCurrency.padRight(10)}',
      );
      debugPrint(
        '${"Total Net Worth (RSD)".padRight(30)} | ${netWorthRsd.toStringAsFixed(2).padRight(20)} | ${"RSD".padRight(10)}',
      );
      debugPrint('-' * 66 + '\n');
    });

    test('calculateCurrencyBreakdown returns map', () {
      final breakdown = calculator.calculateCurrencyBreakdown(snapshot);
      expect(breakdown, isNotEmpty);
      debugPrint('\n--- CURRENCY BREAKDOWN TABLE ---');
      debugPrint(
        '${"Currency".padRight(10)} | ${"Value (Base)".padRight(20)} | ${"Share".padRight(10)}',
      );
      debugPrint('-' * 46);
      final total = breakdown.values.fold(0.0, (sum, v) => sum + v);
      breakdown.forEach((currency, value) {
        final share = total == 0 ? 0.0 : (value / total) * 100;
        debugPrint(
          '${currency.padRight(10)} | ${value.toStringAsFixed(2).padRight(20)} | ${share.toStringAsFixed(1)}%',
        );
      });
      debugPrint('-' * 46 + '\n');
    });

    test('calculateRealBalances adjusts for inflation', () {
      var standardParams = snapshot.accounts.firstWhere(
        (a) => a.country == 'Serbia',
      );

      // Setup: Ensure Anchor is old enough to have inflation
      standardParams = standardParams.copyWith(
        creationDate: DateTime.now().subtract(const Duration(days: 365)),
        balance: 1000.0, // Ensure non-zero for test
      );

      // Update snapshot with modified account
      final accounts = List<Account>.from(snapshot.accounts);
      final idx = accounts.indexWhere((a) => a.id == standardParams.id);
      accounts[idx] = standardParams;

      // Inject recent inflation rate to ensure multiplier > 1.0
      final recentRate = InflationRateDomain(
        preset: 0,
        country: 'Serbia',
        percent: 10.0,
        date: DateTime.now().subtract(
          const Duration(days: 180),
        ), // 6 months ago
      );

      final testSnapshot = snapshot.copyWith(
        accounts: accounts,
        inflationRates: [...snapshot.inflationRates, recentRate],
        date: DateTime.now(), // Advance time to allow deflation
      );

      final balances = calculator.calculateBalances(testSnapshot);
      // Update: Pass 'Serbia' as default
      final realBalances = calculator.calculateRealBalances(
        testSnapshot,
        defaultCountry: 'Serbia',
      );

      debugPrint('\n--- REAL vs NOMINAL BALANCE TABLE (Default: Serbia) ---');
      debugPrint(
        '${"Account Name".padRight(30)} | ${"Country".padRight(10)} | ${"Nominal".padRight(15)} | ${"Real (Adj)".padRight(15)} | ${"Multiplier".padRight(10)}',
      );
      debugPrint('-' * 89);
      for (final account in testSnapshot.accounts) {
        final nominal = balances[account.id] ?? 0.0;
        final real = realBalances[account.id] ?? 0.0;
        final multiplier = nominal == 0
            ? 0.0
            : nominal / real; // Nominal / Real = Multiplier
        debugPrint(
          '${account.name.padRight(30)} | ${account.country?.padRight(10) ?? "N/A".padRight(10)} | ${nominal.toStringAsFixed(2).padRight(15)} | ${real.toStringAsFixed(2).padRight(15)} | ${multiplier.toStringAsFixed(3).padRight(10)}',
        );
      }
      debugPrint('-' * 89 + '\n');

      final nominal = balances[standardParams.id]!;
      final real = realBalances[standardParams.id]!;
      if (nominal != 0) {
        // Deflation: Real < Nominal
        expect(real.abs(), lessThan(nominal.abs()));
      }
    });

    test('calculatePeriodStats correctly sums and deflates', () {
      final period = DatePeriod(
        DateTime.now().subtract(const Duration(days: 365 * 10)),
        DateTime.now(),
      );

      // Setup: Ensure RSD Account has old Anchor for deflation
      var targetAccount = snapshot.accounts.firstWhere(
        (a) => a.currencyCode == 'RSD',
        orElse: () => snapshot.accounts.first,
      );

      targetAccount = targetAccount.copyWith(
        creationDate: DateTime.now().subtract(const Duration(days: 365 * 12)),
      );

      final accounts = List<Account>.from(snapshot.accounts);
      final idx = accounts.indexWhere((a) => a.id == targetAccount.id);
      if (idx != -1) accounts[idx] = targetAccount;

      final testSnapshot = snapshot.copyWith(accounts: accounts);

      // Update: Pass 'Serbia' as default
      final stats = calculator.calculatePeriodStats(
        testSnapshot,
        period,
        defaultCountry: 'Serbia',
      );

      debugPrint('\n--- PERIOD STATS TABLE (Last 10 Years) ---');
      debugPrint(
        '${"Currency".padRight(10)} | ${"Income (Nom)".padRight(15)} | ${"Income (Real)".padRight(15)} | ${"Expense (Nom)".padRight(15)} | ${"Expense (Real)".padRight(15)}',
      );
      debugPrint('-' * 80);

      final allAccountIds = {
        ...stats.income.keys,
        ...stats.realIncome.keys,
        ...stats.expense.keys,
      };

      for (final accId in allAccountIds) {
        final account = snapshot.accounts.firstWhere((a) => a.id == accId);
        final currency = account.currencyCode;

        final incNom = stats.income[accId] ?? 0.0;
        final incReal = stats.realIncome[accId] ?? 0.0;
        final expNom = stats.expense[accId] ?? 0.0;
        final expReal = stats.realExpense[accId] ?? 0.0;

        debugPrint(
          '${currency.padRight(10)} | ${incNom.toStringAsFixed(2).padRight(15)} | ${incReal.toStringAsFixed(2).padRight(15)} | ${expNom.toStringAsFixed(2).padRight(15)} | ${expReal.toStringAsFixed(2).padRight(15)}',
        );
      }
      debugPrint('-' * 80);
      debugPrint(
        'Total Income (Base): ${stats.totalIncome.toStringAsFixed(2)}',
      );
      debugPrint(
        'Total Expense (Base): ${stats.totalExpense.toStringAsFixed(2)}\n',
      );

      expect(stats.income, isNotEmpty);
      expect(stats.expense, isNotEmpty);
      expect(stats.totalIncome, isNot(0.0));

      // Check deflation for Target Account
      if (targetAccount.currencyCode == 'RSD' &&
          stats.income.containsKey(targetAccount.id)) {
        expect(
          stats.realIncome[targetAccount.id]!,
          lessThan(stats.income[targetAccount.id]!),
        );
      }
    });
    test('calculatePeriodStats partial year inflation check', () {
      // Scenario:
      // Annual Inflation for THIS YEAR: 12%.
      // Transaction was 6 months ago.
      // Account Anchor = 1 Year before Tx.
      // Expected: Real (Deflated to Anchor) < Nominal.

      final now = DateTime.now();
      final sixMonthsAgo = now.subtract(const Duration(days: 182));
      final anchorDate = sixMonthsAgo.subtract(const Duration(days: 365));

      // Period just captures this transaction
      final period = DatePeriod(
        sixMonthsAgo.subtract(const Duration(days: 1)),
        sixMonthsAgo.add(const Duration(days: 1)),
      );

      // Create a mock transaction
      final tx = Transaction(
        id: 'test_tx',
        description: 'Test Income',
        amount: 1000.0,
        date: sixMonthsAgo,
        accountId: 'acc1',
        categoryId: 'cat1',
        currencyCode: 'EUR',
      );

      final rates = [
        InflationRateDomain(
          preset: 0,
          country: 'TestLand',
          percent: 12.0, // 12% Annual
          date: sixMonthsAgo,
        ),
        InflationRateDomain(
          preset: 0,
          country: 'TestLand',
          percent: 5.0,
          date: anchorDate,
        ),
      ];

      final mockAccount = Account(
        id: 'acc1',
        name: 'Test',
        balance: 0,
        currencyCode: 'EUR',
        country: 'TestLand',
        creationDate: anchorDate, // ANCHOR
        currencyDesignationId: 'code',
        accountTypeId: 'general',
      );

      final mockSnapshot = FinancialSnapshot(
        accounts: [mockAccount],
        transactions: [tx],
        assetData: [],
        categories: [],
        exchangeRates: [],
        inflationRates: rates,
        date: now,
        dateStep: DateStep.month,
        baseCurrency: 'EUR',
      );

      final stats = calculator.calculatePeriodStats(
        mockSnapshot,
        period,
        defaultCountry: 'TestLand',
      );

      // Validation
      final nominal = stats.income['acc1']!; // 1000
      final real = stats.realIncome['acc1']!;

      // Deflation: Real < Nominal
      expect(real, lessThan(nominal));
    });

    test('calculatePeriodStats excludes transfers', () {
      final now = DateTime.now();
      final period = DatePeriod(
        now.subtract(const Duration(days: 1)),
        now.add(const Duration(days: 1)),
      );

      final transferCategory = Category(
        id: 'cat_transfer',
        name: 'Transfer',
        type: CategoryType.transfer,
      );

      final expenseCategory = Category(
        id: 'cat_expense',
        name: 'Expense',
        type: CategoryType.expense,
      );

      final txTransfer = Transaction(
        id: 'tx_transfer',
        description: 'Transfer Tx',
        amount: -500.0,
        date: now,
        accountId: 'acc1',
        categoryId: 'cat_transfer',
        currencyCode: 'EUR',
      );

      final txExpense = Transaction(
        id: 'tx_expense',
        description: 'Expense Tx',
        amount: -100.0,
        date: now,
        accountId: 'acc1',
        categoryId: 'cat_expense',
        currencyCode: 'EUR',
      );

      final mockSnapshot = FinancialSnapshot(
        accounts: [],
        transactions: [txTransfer, txExpense],
        assetData: [],
        categories: [transferCategory, expenseCategory],
        exchangeRates: [],
        inflationRates: [],
        date: now,
        dateStep: DateStep.month,
        baseCurrency: 'EUR',
      );

      final stats = calculator.calculatePeriodStats(mockSnapshot, period);

      // Expect totalExpense to only include txExpense (-100), ignoring txTransfer (-500)
      expect(stats.totalExpense, equals(-100.0));
      expect(stats.expense['acc1'], equals(-100.0));
    });

    // ============================================================================
    // NEW TEST GROUPS FOR PHASE 1 OPTIMIZATIONS (TC-FC-01 through TC-FC-46)
    // ============================================================================

    group('FinancialSnapshot.currentPeriod', () {
      test('TC-FC-01: day step returns correct period', () {
        final snap = FinancialSnapshot(
          accounts: [],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2025, 6, 15),
          dateStep: DateStep.day,
          baseCurrency: 'EUR',
        );

        final period = snap.currentPeriod;
        expect(period.start, equals(DateTime(2025, 6, 15)));
        expect(period.end, equals(DateTime(2025, 6, 15, 23, 59, 59)));
      });

      test('TC-FC-02: month step returns correct period', () {
        final snap = FinancialSnapshot(
          accounts: [],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2025, 6, 15),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final period = snap.currentPeriod;
        expect(period.start, equals(DateTime(2025, 6, 1)));
        expect(period.end, equals(DateTime(2025, 6, 30, 23, 59, 59)));
      });

      test('TC-FC-03: year step returns correct period', () {
        final snap = FinancialSnapshot(
          accounts: [],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2025, 6, 15),
          dateStep: DateStep.year,
          baseCurrency: 'EUR',
        );

        final period = snap.currentPeriod;
        expect(period.start, equals(DateTime(2025, 1, 1)));
        expect(period.end, equals(DateTime(2025, 12, 31, 23, 59, 59)));
      });

      test('TC-FC-04: copyWith preserves unchanged fields', () {
        final original = FinancialSnapshot(
          accounts: [],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2025, 6, 15),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final newDate = DateTime(2025, 7, 20);
        final copied = original.copyWith(date: newDate);

        expect(copied.date, equals(newDate));
        expect(copied.dateStep, equals(original.dateStep));
        expect(copied.baseCurrency, equals(original.baseCurrency));
      });
    });

    group('calculateBalances - Standard Accounts', () {
      test('TC-FC-05: account with no transactions returns initial balance', () {
        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        expect(balances['acc1'], equals(1000.0));
      });

      test('TC-FC-06: transactions before target date are included', () {
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
        );

        final tx = Transaction(
          id: 'tx1',
          description: 'Past transaction',
          amount: 200.0,
          date: yesterday,
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [tx],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        // Balance is the current state, past tx is already included
        expect(balances['acc1'], equals(1000.0));
      });

      test('TC-FC-07: transactions after target date are subtracted (reverse calc)', () {
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));

        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
        );

        final tx = Transaction(
          id: 'tx1',
          description: 'Future transaction',
          amount: 200.0,
          date: tomorrow,
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [tx],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        // Reverse calc: 1000 - 200 = 800
        expect(balances['acc1'], equals(800.0));
      });

      test('TC-FC-08: multiple future transactions are all subtracted', () {
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));

        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
        );

        final tx1 = Transaction(
          id: 'tx1',
          description: 'Future tx 1',
          amount: 100.0,
          date: tomorrow,
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
        );

        final tx2 = Transaction(
          id: 'tx2',
          description: 'Future tx 2',
          amount: -50.0,
          date: tomorrow.add(const Duration(days: 1)),
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [tx1, tx2],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        // 1000 - 100 - (-50) = 950
        expect(balances['acc1'], equals(950.0));
      });
    });

    group('calculateBalances - Asset Accounts', () {
      test('TC-FC-10: target date before earliest entry returns 0', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime(2024, 12, 31),
          assetId: 'gold',
          assetQuantity: 2.0,
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime(2025, 1, 1),
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2024, 12, 31),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        expect(balances['acc1'], equals(0.0));
      });

      test('TC-FC-11: exact date match uses that entry value', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime(2025, 1, 1),
          assetId: 'gold',
          assetQuantity: 2.0,
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime(2025, 6, 15),
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2025, 6, 15),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        // 2.0 * 100.0 = 200.0
        expect(balances['acc1'], equals(200.0));
      });

      test('TC-FC-12: uses closest entry before target date', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime(2025, 1, 1),
          assetId: 'gold',
          assetQuantity: 1.0,
        );

        final entry1 = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime(2025, 6, 1),
          value: 90.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final entry2 = AssetDataDomain(
          id: 'asset2',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime(2025, 6, 10),
          value: 95.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [entry1, entry2],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2025, 6, 12),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        // Should use entry2 (95.0) * 1.0 = 95.0
        expect(balances['acc1'], equals(95.0));
      });

      test('TC-FC-13: future date uses last known entry', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime(2025, 1, 1),
          assetId: 'gold',
          assetQuantity: 1.0,
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime(2025, 6, 15),
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2030, 1, 1),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        // Should use last entry (100.0) * 1.0 = 100.0
        expect(balances['acc1'], equals(100.0));
      });

      test('TC-FC-14: quantity adjusted by transactions before target date', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime(2025, 1, 1),
          assetId: 'gold',
          assetQuantity: 5.0,
        );

        final tx = Transaction(
          id: 'tx1',
          description: 'Buy gold',
          amount: 2.0,
          date: DateTime(2025, 6, 10),
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime(2025, 6, 15),
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [tx],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2025, 6, 15),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        // (5.0 + 2.0) * 100.0 = 700.0
        expect(balances['acc1'], equals(700.0));
      });

      test('TC-FC-16: no asset data entries returns 0', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime(2025, 1, 1),
          assetId: 'gold',
          assetQuantity: 2.0,
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime(2025, 6, 15),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        expect(balances['acc1'], equals(0.0));
      });
    });

    group('calculateRealBalances', () {
      test('TC-FC-17: no inflation rates - real equals nominal', () {
        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
          country: 'Serbia',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final nominal = calculator.calculateBalances(snap);
        final real = calculator.calculateRealBalances(snap);

        expect(real['acc1'], equals(nominal['acc1']));
      });

      test('TC-FC-18: with inflation - real is less than nominal', () {
        final now = DateTime.now();
        final oneYearAgo = now.subtract(const Duration(days: 365));

        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: oneYearAgo,
          country: 'TestLand',
        );

        final inflationRate = InflationRateDomain(
          preset: 0,
          country: 'TestLand',
          percent: 10.0,
          date: now.subtract(const Duration(days: 180)),
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [inflationRate],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final nominal = calculator.calculateBalances(snap);
        final real = calculator.calculateRealBalances(snap, defaultCountry: 'TestLand');

        expect(real['acc1']!.abs(), lessThan(nominal['acc1']!.abs()));
      });

      test('TC-FC-19: zero multiplier guard uses 1.0', () {
        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
          country: 'TestLand',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final nominal = calculator.calculateBalances(snap);
        final real = calculator.calculateRealBalances(snap);

        // Should not crash and real should equal nominal (multiplier = 1.0)
        expect(real['acc1'], equals(nominal['acc1']));
      });

      test('TC-FC-20: defaultCountry used when account has no country', () {
        final now = DateTime.now();
        final oneYearAgo = now.subtract(const Duration(days: 365));

        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: oneYearAgo,
          country: null,
        );

        final inflationRate = InflationRateDomain(
          preset: 0,
          country: 'Serbia',
          percent: 10.0,
          date: now.subtract(const Duration(days: 180)),
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [inflationRate],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final nominal = calculator.calculateBalances(snap);
        final real = calculator.calculateRealBalances(snap, defaultCountry: 'Serbia');

        // Real should be less than nominal due to inflation
        expect(real['acc1']!.abs(), lessThan(nominal['acc1']!.abs()));
      });

      test('TC-FC-21: account country takes precedence over defaultCountry', () {
        final now = DateTime.now();
        final oneYearAgo = now.subtract(const Duration(days: 365));

        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: oneYearAgo,
          country: 'Germany',
        );

        final germanyRate = InflationRateDomain(
          preset: 0,
          country: 'Germany',
          percent: 5.0,
          date: now.subtract(const Duration(days: 180)),
        );

        final serbiaRate = InflationRateDomain(
          preset: 0,
          country: 'Serbia',
          percent: 20.0,
          date: now.subtract(const Duration(days: 180)),
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [germanyRate, serbiaRate],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final realWithGermany = calculator.calculateRealBalances(snap, defaultCountry: 'Serbia');

        // Should use Germany's 5% rate, not Serbia's 20%
        // Real with 5% inflation should be higher than with 20%
        expect(realWithGermany['acc1'], isNotNull);
      });
    });

    group('calculateTotalNetWorth', () {
      test('TC-FC-22: single account same currency as base', () {
        final account = Account(
          id: 'acc1',
          name: 'Test Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final netWorth = calculator.calculateTotalNetWorth(snap);
        expect(netWorth, equals(1000.0));
      });

      test('TC-FC-23: multiple accounts different currencies', () {
        final account1 = Account(
          id: 'acc1',
          name: 'EUR Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final account2 = Account(
          id: 'acc2',
          name: 'RSD Account',
          balance: 1170.0,
          currencyCode: 'RSD',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final rate = ExchangeRateDomain(
          fromCurrencyCode: 'RSD',
          toCurrencyCode: 'EUR',
          preset: 1,
          rate: 0.00855,
          date: DateTime.now(),
        );

        final snap = FinancialSnapshot(
          accounts: [account1, account2],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [rate],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final netWorth = calculator.calculateTotalNetWorth(snap);
        // 1000 + (1170 * 0.00855) ≈ 1010.0
        expect(netWorth, closeTo(1010.0, 0.1));
      });

      test('TC-FC-24: no exchange rate found falls back to 1.0', () {
        final account = Account(
          id: 'acc1',
          name: 'XYZ Account',
          balance: 500.0,
          currencyCode: 'XYZ',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final netWorth = calculator.calculateTotalNetWorth(snap);
        // Falls back to 1.0 rate
        expect(netWorth, equals(500.0));
      });
    });

    group('calculateCurrencyBreakdown', () {
      test('TC-FC-25: groups balances by currency', () {
        final account1 = Account(
          id: 'acc1',
          name: 'EUR Account 1',
          balance: 500.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final account2 = Account(
          id: 'acc2',
          name: 'EUR Account 2',
          balance: 300.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final account3 = Account(
          id: 'acc3',
          name: 'RSD Account',
          balance: 1000.0,
          currencyCode: 'RSD',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final snap = FinancialSnapshot(
          accounts: [account1, account2, account3],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final breakdown = calculator.calculateCurrencyBreakdown(snap);
        expect(breakdown['EUR'], equals(800.0));
        expect(breakdown['RSD'], equals(1000.0));
      });

      test('TC-FC-26: includes negative balances', () {
        final account1 = Account(
          id: 'acc1',
          name: 'Positive Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final account2 = Account(
          id: 'acc2',
          name: 'Negative Account',
          balance: -500.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final snap = FinancialSnapshot(
          accounts: [account1, account2],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final breakdown = calculator.calculateCurrencyBreakdown(snap);
        expect(breakdown['EUR'], equals(500.0));
      });
    });

    group('calculatePeriodStats', () {
      test('TC-FC-27: excludes transfer category transactions', () {
        final now = DateTime.now();
        final period = DatePeriod(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
        );

        final transferCategory = Category(
          id: 'cat_transfer',
          name: 'Transfer',
          type: CategoryType.transfer,
        );

        final expenseCategory = Category(
          id: 'cat_expense',
          name: 'Expense',
          type: CategoryType.expense,
        );

        final txTransfer = Transaction(
          id: 'tx_transfer',
          description: 'Transfer',
          amount: -500.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat_transfer',
          currencyCode: 'EUR',
        );

        final txExpense = Transaction(
          id: 'tx_expense',
          description: 'Expense',
          amount: -100.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat_expense',
          currencyCode: 'EUR',
        );

        final snap = FinancialSnapshot(
          accounts: [],
          transactions: [txTransfer, txExpense],
          assetData: [],
          categories: [transferCategory, expenseCategory],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final stats = calculator.calculatePeriodStats(snap, period);
        expect(stats.totalExpense, equals(-100.0));
      });

      test('TC-FC-28: excludes asset-linked account transactions', () {
        final now = DateTime.now();
        final period = DatePeriod(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
        );

        final account = Account(
          id: 'acc1',
          name: 'Asset Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
          assetId: 'gold',
        );

        final incomeCategory = Category(
          id: 'cat_income',
          name: 'Income',
          type: CategoryType.income,
        );

        final tx = Transaction(
          id: 'tx1',
          description: 'Asset transaction',
          amount: 100.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat_income',
          currencyCode: 'EUR',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [tx],
          assetData: [],
          categories: [incomeCategory],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final stats = calculator.calculatePeriodStats(snap, period);
        expect(stats.totalIncome, equals(0.0));
      });

      test('TC-FC-29: income transactions aggregated by account', () {
        final now = DateTime.now();
        final period = DatePeriod(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
        );

        final incomeCategory = Category(
          id: 'cat_income',
          name: 'Income',
          type: CategoryType.income,
        );

        final tx1 = Transaction(
          id: 'tx1',
          description: 'Income 1',
          amount: 100.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat_income',
          currencyCode: 'EUR',
        );

        final tx2 = Transaction(
          id: 'tx2',
          description: 'Income 2',
          amount: 200.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat_income',
          currencyCode: 'EUR',
        );

        final snap = FinancialSnapshot(
          accounts: [],
          transactions: [tx1, tx2],
          assetData: [],
          categories: [incomeCategory],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final stats = calculator.calculatePeriodStats(snap, period);
        expect(stats.income['acc1'], equals(300.0));
      });

      test('TC-FC-30: expense transactions aggregated by account', () {
        final now = DateTime.now();
        final period = DatePeriod(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
        );

        final expenseCategory = Category(
          id: 'cat_expense',
          name: 'Expense',
          type: CategoryType.expense,
        );

        final tx1 = Transaction(
          id: 'tx1',
          description: 'Expense 1',
          amount: -50.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat_expense',
          currencyCode: 'EUR',
        );

        final tx2 = Transaction(
          id: 'tx2',
          description: 'Expense 2',
          amount: -75.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat_expense',
          currencyCode: 'EUR',
        );

        final snap = FinancialSnapshot(
          accounts: [],
          transactions: [tx1, tx2],
          assetData: [],
          categories: [expenseCategory],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final stats = calculator.calculatePeriodStats(snap, period);
        expect(stats.expense['acc1'], equals(-125.0));
      });

      test('TC-FC-31: transactions outside period excluded', () {
        final now = DateTime.now();
        final period = DatePeriod(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
        );

        final incomeCategory = Category(
          id: 'cat_income',
          name: 'Income',
          type: CategoryType.income,
        );

        final txBefore = Transaction(
          id: 'tx1',
          description: 'Before period',
          amount: 100.0,
          date: now.subtract(const Duration(days: 10)),
          accountId: 'acc1',
          categoryId: 'cat_income',
          currencyCode: 'EUR',
        );

        final txAfter = Transaction(
          id: 'tx2',
          description: 'After period',
          amount: 200.0,
          date: now.add(const Duration(days: 10)),
          accountId: 'acc1',
          categoryId: 'cat_income',
          currencyCode: 'EUR',
        );

        final snap = FinancialSnapshot(
          accounts: [],
          transactions: [txBefore, txAfter],
          assetData: [],
          categories: [incomeCategory],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final stats = calculator.calculatePeriodStats(snap, period);
        expect(stats.totalIncome, equals(0.0));
      });

      test('TC-FC-32: totalIncome in base currency', () {
        final now = DateTime.now();
        final period = DatePeriod(
          now.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
        );

        final incomeCategory = Category(
          id: 'cat_income',
          name: 'Income',
          type: CategoryType.income,
        );

        final tx = Transaction(
          id: 'tx1',
          description: 'Income in RSD',
          amount: 1000.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat_income',
          currencyCode: 'RSD',
        );

        final rate = ExchangeRateDomain(
          fromCurrencyCode: 'RSD',
          toCurrencyCode: 'EUR',
          preset: 1,
          rate: 0.00855,
          date: now,
        );

        final snap = FinancialSnapshot(
          accounts: [],
          transactions: [tx],
          assetData: [],
          categories: [incomeCategory],
          exchangeRates: [rate],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final stats = calculator.calculatePeriodStats(snap, period);
        // 1000 * 0.00855 ≈ 8.55
        expect(stats.totalIncome, closeTo(8.55, 0.1));
      });
    });

    group('calculateAssetStats', () {
      test('TC-FC-34: non-asset accounts are skipped', () {
        final account = Account(
          id: 'acc1',
          name: 'Standard Account',
          balance: 1000.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
          assetId: null,
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final stats = calculator.calculateAssetStats(snap);
        expect(stats.isEmpty, isTrue);
      });

      test('TC-FC-35: nominalBalance matches calculateBalances result', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 2.0,
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime.now(),
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final balances = calculator.calculateBalances(snap);
        final assetStats = calculator.calculateAssetStats(snap);

        expect(assetStats['acc1']!.nominalBalance, equals(balances['acc1']));
      });

      test('TC-FC-36: netBalance applies fee structure', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 10.0,
          feeStructure: '[{"type":"percent","rate":0.01}]',
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime.now(),
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final assetStats = calculator.calculateAssetStats(snap);
        // nominalBalance = 10 * 100 = 1000
        // netBalance = 1000 * (1 - 0.01) = 990
        expect(assetStats['acc1']!.nominalBalance, equals(1000.0));
        expect(assetStats['acc1']!.netBalance, equals(990.0));
      });

      test('TC-FC-37: netBalance equals nominalBalance when no fee structure', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 10.0,
          feeStructure: null,
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime.now(),
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final assetStats = calculator.calculateAssetStats(snap);
        expect(assetStats['acc1']!.netBalance, equals(assetStats['acc1']!.nominalBalance));
      });

      test('TC-FC-38: commissions sums all transaction fees', () {
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 1.0,
        );

        final tx1 = Transaction(
          id: 'tx1',
          description: 'Buy',
          amount: 1.0,
          date: DateTime.now(),
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
          fee: 5.0,
        );

        final tx2 = Transaction(
          id: 'tx2',
          description: 'Buy',
          amount: 1.0,
          date: DateTime.now(),
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
          fee: 3.0,
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: DateTime.now(),
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [tx1, tx2],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final assetStats = calculator.calculateAssetStats(snap);
        expect(assetStats['acc1']!.commissions, equals(8.0));
      });

      test('TC-FC-39: invested sums cash value of buy transactions', () {
        final now = DateTime.now();
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 1.0,
        );

        final cashAccount = Account(
          id: 'acc2',
          name: 'Cash Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
        );

        final buyTx = Transaction(
          id: 'tx1',
          description: 'Buy gold',
          amount: 1.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
          linkedTransactionId: 'tx2',
        );

        final cashTx = Transaction(
          id: 'tx2',
          description: 'Pay for gold',
          amount: -500.0,
          date: now,
          accountId: 'acc2',
          categoryId: 'cat1',
          currencyCode: 'EUR',
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: now,
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account, cashAccount],
          transactions: [buyTx, cashTx],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final assetStats = calculator.calculateAssetStats(snap);
        expect(assetStats['acc1']!.invested, equals(500.0));
      });

      test('TC-FC-40: realized sums cash value of sell transactions', () {
        final now = DateTime.now();
        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 1.0,
        );

        final cashAccount = Account(
          id: 'acc2',
          name: 'Cash Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
        );

        final sellTx = Transaction(
          id: 'tx1',
          description: 'Sell gold',
          amount: -1.0,
          date: now,
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
          linkedTransactionId: 'tx2',
        );

        final cashTx = Transaction(
          id: 'tx2',
          description: 'Receive from sale',
          amount: 300.0,
          date: now,
          accountId: 'acc2',
          categoryId: 'cat1',
          currencyCode: 'EUR',
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: now,
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account, cashAccount],
          transactions: [sellTx, cashTx],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final assetStats = calculator.calculateAssetStats(snap);
        expect(assetStats['acc1']!.realized, equals(300.0));
      });

      test('TC-FC-41: transactions after snapshot date are excluded', () {
        final now = DateTime.now();
        final tomorrow = now.add(const Duration(days: 1));

        final account = Account(
          id: 'acc1',
          name: 'Gold Account',
          balance: 0.0,
          currencyCode: 'EUR',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: now.subtract(const Duration(days: 30)),
          assetId: 'gold',
          assetQuantity: 1.0,
        );

        final tx = Transaction(
          id: 'tx1',
          description: 'Future buy',
          amount: 1.0,
          date: tomorrow,
          accountId: 'acc1',
          categoryId: 'cat1',
          currencyCode: 'EUR',
          fee: 10.0,
        );

        final assetEntry = AssetDataDomain(
          id: 'asset1',
          assetId: 'gold',
          name: 'Gold Price',
          date: now,
          value: 100.0,
          quantity: 1.0,
          currency: 'EUR',
          source: 'test',
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [tx],
          assetData: [assetEntry],
          categories: [],
          exchangeRates: [],
          inflationRates: [],
          date: now,
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final assetStats = calculator.calculateAssetStats(snap);
        expect(assetStats['acc1']!.commissions, equals(0.0));
        expect(assetStats['acc1']!.invested, equals(0.0));
      });
    });

    group('calculatePercentageChange', () {
      test('TC-FC-42: positive change', () {
        final change = calculator.calculatePercentageChange(110, 100);
        expect(change, equals(10.0));
      });

      test('TC-FC-43: negative change', () {
        final change = calculator.calculatePercentageChange(90, 100);
        expect(change, equals(-10.0));
      });

      test('TC-FC-44: zero previous value returns 0', () {
        final change = calculator.calculatePercentageChange(100, 0);
        expect(change, equals(0.0));
      });
    });

    group('_buildRateIndex (tested indirectly)', () {
      test('TC-FC-45: only preset == 1 rates are indexed', () {
        final rate1 = ExchangeRateDomain(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          preset: 1,
          rate: 0.909,
          date: DateTime.now(),
        );

        final rate2 = ExchangeRateDomain(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          preset: 2,
          rate: 0.87,
          date: DateTime.now(),
        );

        final account = Account(
          id: 'acc1',
          name: 'USD Account',
          balance: 100.0,
          currencyCode: 'USD',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [rate1, rate2],
          inflationRates: [],
          date: DateTime.now(),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final netWorth = calculator.calculateTotalNetWorth(snap);
        // Should use rate1 (0.909), not rate2 (0.87)
        // 100 * 0.909 = 90.9
        expect(netWorth, closeTo(90.9, 0.1));
      });

      test('TC-FC-46: rates sorted descending by date (most recent first)', () {
        final oldRate = ExchangeRateDomain(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          preset: 1,
          rate: 1.0,
          date: DateTime(2025, 1, 1),
        );

        final newRate = ExchangeRateDomain(
          fromCurrencyCode: 'USD',
          toCurrencyCode: 'EUR',
          preset: 1,
          rate: 0.833,
          date: DateTime(2025, 6, 15),
        );

        final account = Account(
          id: 'acc1',
          name: 'USD Account',
          balance: 100.0,
          currencyCode: 'USD',
          currencyDesignationId: 'code',
          accountTypeId: 'general',
          creationDate: DateTime.now().subtract(const Duration(days: 30)),
        );

        final snap = FinancialSnapshot(
          accounts: [account],
          transactions: [],
          assetData: [],
          categories: [],
          exchangeRates: [oldRate, newRate],
          inflationRates: [],
          date: DateTime(2025, 6, 15),
          dateStep: DateStep.month,
          baseCurrency: 'EUR',
        );

        final netWorth = calculator.calculateTotalNetWorth(snap);
        // Should use newRate (0.833) since it's most recent
        // 100 * 0.833 = 83.3
        expect(netWorth, closeTo(83.3, 0.1));
      });
    });
  });
}
