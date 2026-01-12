import 'dart:convert';
import 'dart:io';

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
        print(
          'Bound Account "${accounts[accountIndex].name}" to Asset "$firstAssetId" for testing.',
        );
      } else if (accounts.isNotEmpty) {
        accounts[0] = accounts[0].copyWith(
          assetId: firstAssetId,
          assetQuantity: 1.0,
        );
        print(
          'Bound Account "${accounts[0].name}" to Asset "$firstAssetId" for testing.',
        );
      }
    } else {
      print('WARNING: No asset entries found in backup.');
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

      print('\n--- BALANCE COMPARISON TABLE ---');
      print(
        '${"Account Name".padRight(30)} | ${"Currency".padRight(5)} | ${"Expected (Backup)".padRight(20)} | ${"Calculated (Sum Tx)".padRight(20)} | ${"Diff".padRight(20)}',
      );
      print('-' * 105);

      for (final account in debugSnapshot.accounts) {
        final calculated = calculatedBalances[account.id] ?? 0.0;
        final expected = account.balance;
        final diff = expected - calculated;

        // DEBUG: Drill down into 'cash eur'
        if (account.name.toLowerCase().contains('cash eur')) {
          print(
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
            print(
              '  ${tx.date.toString().substring(0, 10)} | Amount: ${tx.amount.toStringAsFixed(2).padRight(10)} | Sum: ${runningSum.toStringAsFixed(2)} | Desc: ${tx.description}',
            );
          }
          print('[DEBUG] Total Tx Count: ${accountTx.length}');
          print('[DEBUG] Final Sum: $runningSum\n');
        }

        print(
          '${account.name.padRight(30)} | '
          '${account.currencyCode.padRight(5)} | '
          '${expected.toStringAsFixed(2).padRight(20)} | '
          '${calculated.toStringAsFixed(2).padRight(20)} | '
          '${diff.toStringAsFixed(2).padRight(20)}',
        );
      }
      print('-' * 105);
      print('Note: "Expected" is the balance stored in the Account object.');
      print(
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

      print('\n--- TOTAL NET WORTH TABLE ---');
      print(
        '${"Metric".padRight(30)} | ${"Value".padRight(20)} | ${"Currency".padRight(10)}',
      );
      print('-' * 66);
      print(
        '${"Total Net Worth".padRight(30)} | ${netWorth.toStringAsFixed(2).padRight(20)} | ${snapshot.baseCurrency.padRight(10)}',
      );
      print(
        '${"Total Net Worth (RSD)".padRight(30)} | ${netWorthRsd.toStringAsFixed(2).padRight(20)} | ${"RSD".padRight(10)}',
      );
      print('-' * 66 + '\n');
    });

    test('calculateCurrencyBreakdown returns map', () {
      final breakdown = calculator.calculateCurrencyBreakdown(snapshot);
      expect(breakdown, isNotEmpty);
      print('\n--- CURRENCY BREAKDOWN TABLE ---');
      print(
        '${"Currency".padRight(10)} | ${"Value (Base)".padRight(20)} | ${"Share".padRight(10)}',
      );
      print('-' * 46);
      final total = breakdown.values.fold(0.0, (sum, v) => sum + v);
      breakdown.forEach((currency, value) {
        final share = total == 0 ? 0.0 : (value / total) * 100;
        print(
          '${currency.padRight(10)} | ${value.toStringAsFixed(2).padRight(20)} | ${share.toStringAsFixed(1)}%',
        );
      });
      print('-' * 46 + '\n');
    });

    test('calculateRealBalances adjusts for inflation', () {
      final standardParams = snapshot.accounts.firstWhere(
        (a) => a.country == 'Serbia',
      );
      final balances = calculator.calculateBalances(snapshot);
      // Update: Pass 'Serbia' as default
      final realBalances = calculator.calculateRealBalances(
        snapshot,
        defaultCountry: 'Serbia',
      );

      print('\n--- REAL vs NOMINAL BALANCE TABLE (Default: Serbia) ---');
      print(
        '${"Account Name".padRight(30)} | ${"Country".padRight(10)} | ${"Nominal".padRight(15)} | ${"Real (Adj)".padRight(15)} | ${"Multiplier".padRight(10)}',
      );
      print('-' * 89);
      for (final account in snapshot.accounts) {
        final nominal = balances[account.id] ?? 0.0;
        final real = realBalances[account.id] ?? 0.0;
        final multiplier = nominal == 0 ? 0.0 : real / nominal;
        print(
          '${account.name.padRight(30)} | ${account.country?.padRight(10) ?? "N/A".padRight(10)} | ${nominal.toStringAsFixed(2).padRight(15)} | ${real.toStringAsFixed(2).padRight(15)} | ${multiplier.toStringAsFixed(3).padRight(10)}',
        );
      }
      print('-' * 89 + '\n');

      final nominal = balances[standardParams.id]!;
      final real = realBalances[standardParams.id]!;
      if (nominal != 0) {
        expect(real.abs(), greaterThan(nominal.abs()));
      }
    });

    test('calculatePeriodStats correctly sums and deflates', () {
      final period = DatePeriod(
        DateTime.now().subtract(const Duration(days: 365 * 10)),
        DateTime.now(),
      );

      // Update: Pass 'Serbia' as default
      final stats = calculator.calculatePeriodStats(
        snapshot,
        period,
        defaultCountry: 'Serbia',
      );

      print('\n--- PERIOD STATS TABLE (Last 10 Years) ---');
      print(
        '${"Currency".padRight(10)} | ${"Income (Nom)".padRight(15)} | ${"Income (Real)".padRight(15)} | ${"Expense (Nom)".padRight(15)} | ${"Expense (Real)".padRight(15)}',
      );
      print('-' * 80);

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

        print(
          '${currency.padRight(10)} | ${incNom.toStringAsFixed(2).padRight(15)} | ${incReal.toStringAsFixed(2).padRight(15)} | ${expNom.toStringAsFixed(2).padRight(15)} | ${expReal.toStringAsFixed(2).padRight(15)}',
        );
      }
      print('-' * 80);
      print('Total Income (Base): ${stats.totalIncome.toStringAsFixed(2)}');
      print('Total Expense (Base): ${stats.totalExpense.toStringAsFixed(2)}\n');

      expect(stats.income, isNotEmpty);
      expect(stats.expense, isNotEmpty);
      expect(stats.totalIncome, isNot(0.0));

      // Find an account with RSD
      final rsdAccount = snapshot.accounts.firstWhere(
        (a) => a.currencyCode == 'RSD',
        orElse: () => snapshot.accounts.first,
      );
      if (rsdAccount.currencyCode == 'RSD' &&
          stats.income.containsKey(rsdAccount.id)) {
        expect(
          stats.realIncome[rsdAccount.id]!,
          greaterThan(stats.income[rsdAccount.id]!),
        );
      }
    });
    test('calculatePeriodStats partial year inflation check', () {
      // Scenario:
      // Annual Inflation for THIS YEAR: 12%.
      // Transaction was 6 months ago.
      // We check Present Value.
      // Interval: [T-6 months] -> [Now].
      // Duration: ~0.5 years.
      // Expected Inflation Effect: ~6%.

      final now = DateTime.now();
      final sixMonthsAgo = now.subtract(
        const Duration(days: 182),
      ); // ~Half year

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
          date: sixMonthsAgo, // Align Rate with Transaction Year
        ),
      ];

      final mockAccount = Account(
        id: 'acc1',
        name: 'Test',
        balance: 0,
        currencyCode: 'EUR',
        country: 'TestLand',
        creationDate: sixMonthsAgo,
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

      // Expected:
      // Fraction ~0.5.
      // Rate 12%.
      // Effective ~6%.
      // Real ~ 1060.

      print('Partial Year Test (6 months): Nominal=$nominal, Real=$real');

      expect(real, greaterThan(nominal * 1.05)); // > 5%
      expect(real, lessThan(nominal * 1.07)); // < 7%
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
  });
}
