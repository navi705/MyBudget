import 'dart:math';
// import 'package:flutter/foundation.dart'; // Removed to avoid Category collision
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/asset_data.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart'; // For DateStep
import 'package:my_budget_client/domain/services/fee_calculator.dart'; // Added

/// Snapshot of all financial data required for calculations at a specific point in time.
class FinancialSnapshot {
  final List<Account> accounts;
  final List<Transaction> transactions;
  final List<AssetDataDomain> assetData;
  final List<Category> categories; // Added
  final List<ExchangeRateDomain> exchangeRates;
  final List<InflationRateDomain> inflationRates;
  final DateTime date; // The reference date for calculation
  final DateStep dateStep; // Context for period-based calcs (Day, Month, Year)
  final String baseCurrency;

  FinancialSnapshot({
    required this.accounts,
    required this.transactions,
    required this.assetData,
    required this.categories,
    required this.exchangeRates,
    required this.inflationRates,
    required this.date,
    required this.dateStep,
    required this.baseCurrency,
  });

  FinancialSnapshot copyWith({
    List<Account>? accounts,
    List<Transaction>? transactions,
    List<AssetDataDomain>? assetData,
    List<Category>? categories,
    List<ExchangeRateDomain>? exchangeRates,
    List<InflationRateDomain>? inflationRates,
    DateTime? date,
    DateStep? dateStep,
    String? baseCurrency,
  }) {
    return FinancialSnapshot(
      accounts: accounts ?? this.accounts,
      transactions: transactions ?? this.transactions,
      assetData: assetData ?? this.assetData,
      categories: categories ?? this.categories,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      inflationRates: inflationRates ?? this.inflationRates,
      date: date ?? this.date,
      dateStep: dateStep ?? this.dateStep,
      baseCurrency: baseCurrency ?? this.baseCurrency,
    );
  }

  DatePeriod get currentPeriod {
    DateTime start;
    DateTime end;
    switch (dateStep) {
      case DateStep.day:
        start = DateTime(date.year, date.month, date.day);
        end = DateTime(date.year, date.month, date.day, 23, 59, 59);
        break;
      case DateStep.month:
        start = DateTime(date.year, date.month, 1);
        end = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
        break;
      case DateStep.year:
        start = DateTime(date.year, 1, 1);
        end = DateTime(date.year, 12, 31, 23, 59, 59);
        break;
    }
    return DatePeriod(start, end);
  }
}

class DatePeriod {
  final DateTime start;
  final DateTime end;

  DatePeriod(this.start, this.end);
}

class PeriodStats {
  final Map<String, double> income; // Key: AccountId
  final Map<String, double> expense; // Key: AccountId
  final Map<String, double> realIncome; // Key: AccountId
  final Map<String, double> realExpense; // Key: AccountId
  final double totalIncome; // In Base Currency
  final double totalExpense; // In Base Currency

  PeriodStats({
    required this.income,
    required this.expense,
    required this.realIncome,
    required this.realExpense,
    required this.totalIncome,
    required this.totalExpense,
  });
}

class FinanceCalculator {
  /// Returns map of AccountId -> Nominal Balance
  ///
  /// For Assset Accounts: Quantity * Price at [data.date]
  /// For Standard Accounts: Initial + Sum(Transactions <= [data.date])
  Map<String, double> calculateBalances(FinancialSnapshot data) {
    final balances = <String, double>{};

    // 1. Group transactions by account
    final transactionsByAccount = <String, List<Transaction>>{};
    for (final tx in data.transactions) {
      // Include ALL transactions.
      // For Standard Accounts (Reverse Calc), we need future transactions to subtract them.
      // For Forward Calc (if used), we would filter later.
      transactionsByAccount.putIfAbsent(tx.accountId, () => []).add(tx);
    }

    // 2. Pre-calculate asset values for the specific date
    // Optimization: Group asset data by assetId -> List<AssetDataDomain>
    final assetDataMap = <String, List<AssetDataDomain>>{};
    for (final entry in data.assetData) {
      assetDataMap.putIfAbsent(entry.assetId, () => []).add(entry);
    }

    for (final account in data.accounts) {
      double balance = 0.0;

      if (account.assetId != null &&
          assetDataMap.containsKey(account.assetId)) {
        // Asset Bound Logic
        final entries = assetDataMap[account.assetId]!;
        final targetDate = DateTime(
          data.date.year,
          data.date.month,
          data.date.day,
        );

        // Sort entries by date ascending
        entries.sort((a, b) => a.date.compareTo(b.date));

        // Find the first entry date (earliestEntry)
        final earliestEntry = entries.isNotEmpty ? entries.first : null;

        // If target date is BEFORE the earliest entry, we don't have data yet
        if (earliestEntry != null) {
          final earliestDate = DateTime(
            earliestEntry.date.year,
            earliestEntry.date.month,
            earliestEntry.date.day,
          );

          if (targetDate.isBefore(earliestDate)) {
            // Asset didn't exist yet at this date
            balance = 0.0;
          } else {
            // Find exact match or closest BEFORE/EQUAL the target date
            AssetDataDomain? bestEntry;
            for (final e in entries) {
              final eDate = DateTime(e.date.year, e.date.month, e.date.day);
              if (eDate.isAtSameMomentAs(targetDate)) {
                // Exact match - use it
                bestEntry = e;
                break;
              } else if (eDate.isBefore(targetDate)) {
                // Closest before target - keep updating until we pass target
                bestEntry = e;
              } else {
                // Passed target date, stop
                break;
              }
            }

            if (bestEntry != null) {
              // Calculate dynamic quantity from transactions
              double currentQuantity = account.assetQuantity;
              final accountTx = transactionsByAccount[account.id] ?? [];
              for (final tx in accountTx) {
                if (!tx.date.isAfter(data.date)) {
                  currentQuantity += tx.amount;
                }
              }

              double assetValue = bestEntry.value;
              if (bestEntry.currency != account.currencyCode) {
                final rate = _getExchangeRate(
                  bestEntry.currency,
                  account.currencyCode,
                  data.exchangeRates,
                  data.date,
                );
                assetValue *= rate;
              }
              balance = assetValue * currentQuantity;
            } else {
              balance = 0.0;
            }
          }
        } else {
          balance = 0.0;
        }
      } else {
        // Standard Logic: Reverse Calculation from Anchor
        // We assume account.balance is the "Latest" state including ALL transactions in history.
        // To get balance at [data.date], we subtract transactions that happened AFTER [data.date].

        double calculatedBalance = account.balance;

        final accountTx = transactionsByAccount[account.id] ?? [];
        for (final tx in accountTx) {
          // If transaction is AFTER the target date, we must "undo" it to get back to the state at date.
          if (tx.date.isAfter(data.date)) {
            calculatedBalance -= tx.amount;
          }
        }
        balance = calculatedBalance;
      }
      balances[account.id!] = balance;
    }

    return balances;
  }

  /// Returns map of AccountId -> Real Balance
  ///
  /// Adjusts Nominal Balance to Present Value using Inflation Rates.
  /// Formula: Real = Nominal * Product(1 + Rate) for all rates between [data.date] and Now.
  Map<String, double> calculateRealBalances(
    FinancialSnapshot data, {
    String? defaultCountry,
  }) {
    final balances = calculateBalances(data);
    final realBalances = <String, double>{};
    // Optimisation: Pre-calculate multipliers per country
    // Group inflation rates by country
    final ratesByCountry = <String, List<InflationRateDomain>>{};
    for (final r in data.inflationRates) {
      if (r.country != null) {
        ratesByCountry.putIfAbsent(r.country!, () => []).add(r);
      }
    }

    for (final accountId in balances.keys) {
      final balance = balances[accountId]!;
      final account = data.accounts.firstWhere((a) => a.id == accountId);

      // Determine country: Account's country > Default > null
      final country = account.country ?? defaultCountry;

      // New Strategy: Deflate to Account Creation Date (Anchor)
      // Real Value = Nominal / (1 + Cumulative Inflation)
      // This shows purchasing power relative to when the account started.
      final anchorDate = account.creationDate;

      double multiplier = 1.0;
      if (country != null) {
        // Multipliers are now specific to (Anchor -> Current Date), not just Country
        // We cannot easily memoize by Country alone unless we assume same creation date.
        // For correctness, we calculate per account.
        // Optimization: We could cache (Country, AnchorDate) -> Multiplier if needed.

        multiplier = _calculateInflationMultiplier(
          anchorDate,
          data.date,
          ratesByCountry[country] ?? [],
        );
      }

      // Avoid division by zero (though multiplier starts at 1.0 and goes up with positive inflation)
      if (multiplier == 0) multiplier = 1.0;

      realBalances[accountId] = balance / multiplier;
    }
    return realBalances;
  }

  double _calculateInflationMultiplier(
    DateTime start,
    DateTime end,
    List<InflationRateDomain> rates,
  ) {
    // debugPrint('  Calc Multiplier for $start to $end with ${rates.length} rates');
    double multiplier = 1.0;

    // Sort rates by date (ascending) to process chronologically
    rates.sort((a, b) => a.date.compareTo(b.date));

    for (final rate in rates) {
      // Logic: Treat 'rate' as Annual Inflation for the Calendar Year of rate.date
      // Example: Rate 12% at 2024-06-01 means "2024 has 12% inflation".

      final rateYearStart = DateTime(rate.date.year, 1, 1);
      final rateYearEnd = DateTime(rate.date.year, 12, 31, 23, 59, 59);

      // Calculate Overlap between [start, end] and [rateYearStart, rateYearEnd]
      final overlapStart = start.isAfter(rateYearStart) ? start : rateYearStart;
      final overlapEnd = end.isBefore(rateYearEnd) ? end : rateYearEnd;

      if (overlapEnd.isAfter(overlapStart)) {
        final overlapDuration = overlapEnd.difference(overlapStart);
        final yearDuration = const Duration(days: 365); // Simplified

        // Fraction of the year covered
        final fraction = overlapDuration.inSeconds / yearDuration.inSeconds;

        // Annual Rate = r.
        // Effective Rate for fraction = (1+r)^fraction - 1?
        // OR simply linear scalar if rate is "Annualized"?
        // Most accurately: (1 + r)^fraction

        final partialMultiplier = pow(1 + (rate.percent / 100), fraction);
        multiplier *= partialMultiplier;

        // debugPrint('    Rate ${rate.percent}% in ${rate.date.year}: Fraction $fraction -> Partial $partialMultiplier');
      }
    }
    // debugPrint('  Total Multiplier: $multiplier');
    return multiplier;
  }

  /// Returns Total Net Worth in Base Currency
  ///
  /// Sum of all (Real or Nominal?) balances converted to [data.baseCurrency]
  double calculateTotalNetWorth(FinancialSnapshot data) {
    final balances = calculateBalances(data);
    double total = 0.0;

    for (final accountId in balances.keys) {
      final balance = balances[accountId]!;
      final account = data.accounts.firstWhere((a) => a.id == accountId);

      final rate = _getExchangeRate(
        account.currencyCode,
        data.baseCurrency,
        data.exchangeRates,
        data.date,
      );

      total += balance * rate;
    }
    return total;
  }

  /// Returns breakdown by Currency (Nominal converted to Base?)
  /// Returns Map<CurrencyCode, ValueInBaseCurrency>
  Map<String, double> calculateCurrencyBreakdown(FinancialSnapshot data) {
    final balances = calculateBalances(data);
    final breakdown = <String, double>{};

    for (final accountId in balances.keys) {
      final balance = balances[accountId]!;
      final account = data.accounts.firstWhere((a) => a.id == accountId);

      final rate = _getExchangeRate(
        account.currencyCode,
        data.baseCurrency,
        data.exchangeRates,
        data.date,
      );

      final valueInBase = balance * rate;
      breakdown[account.currencyCode] =
          (breakdown[account.currencyCode] ?? 0.0) + valueInBase;
    }
    return breakdown;
  }

  double _getExchangeRate(
    String from,
    String to,
    List<ExchangeRateDomain> rates,
    DateTime date,
  ) {
    if (from == to) return 1.0;

    // 1. Direct rate
    // We strictly look for rate at 'date' (or closest before?)
    // Usually we want the Latest Rate applicable to 'date'.
    // Assumption: rates list is history.

    // Sort rates by date desc to find latest before 'date'
    final relevantRates = rates
        .where(
          (r) =>
              r.preset == 1 &&
              (r.date.isBefore(date) || r.date.isAtSameMomentAs(date)),
        )
        .toList();
    relevantRates.sort((a, b) => b.date.compareTo(a.date));

    // Try finding Direct From -> To
    final direct = relevantRates.cast<ExchangeRateDomain?>().firstWhere(
      (r) => r!.fromCurrencyCode == from && r.toCurrencyCode == to,
      orElse: () => null,
    );
    if (direct != null) return direct.rate;

    // Try finding Indirect To -> From (ensure rate is invertible?)
    // Usually stored as 1 From = X To. So 1 To = 1/X From.
    final inverse = relevantRates.cast<ExchangeRateDomain?>().firstWhere(
      (r) => r!.fromCurrencyCode == to && r.toCurrencyCode == from,
      orElse: () => null,
    );
    if (inverse != null && inverse.rate != 0) return 1.0 / inverse.rate;

    // Fallback: Try via Base (EUR) if one of them is EUR and we can't find direct?
    // If we are converting USD -> RSD.
    // We might have USD -> EUR and EUR -> RSD.
    // Value(RSD) = Value(USD) * Rate(USD->EUR) * Rate(EUR->RSD).

    // If 'to' is not EUR, we might need a pivot.
    // But for this project, let's assume rates are provided relative to something common or direct.
    // If not found, return 1.0 (Safe fallback or throw error?)
    // Returning 1.0 might hide errors.

    return 1.0;
  }

  /// Returns Income/Expense for a specific period
  PeriodStats calculatePeriodStats(
    FinancialSnapshot data,
    DatePeriod period, {
    String? defaultCountry,
  }) {
    // 1. Filter Transactions
    // Assumption: Income > 0, Expense < 0.
    final periodTx = data.transactions.where(
      (tx) =>
          (tx.date.isAfter(period.start) ||
              tx.date.isAtSameMomentAs(period.start)) &&
          (tx.date.isBefore(period.end) ||
              tx.date.isAtSameMomentAs(period.end)),
    );

    final incomeMap = <String, double>{};
    final expenseMap = <String, double>{};
    final realIncomeMap = <String, double>{};
    final realExpenseMap = <String, double>{};

    double totalIncome = 0.0;
    double totalExpense = 0.0;

    // Map Category types for quick lookup
    final ratesByCountry = <String, List<InflationRateDomain>>{};
    for (final r in data.inflationRates) {
      if (r.country != null) {
        ratesByCountry.putIfAbsent(r.country!, () => []).add(r);
      }
    }

    // Map Category types for quick lookup
    final categoryTypes = <String, CategoryType>{};
    for (final cat in data.categories) {
      if (cat.id != null) {
        categoryTypes[cat.id!] = cat.type;
      }
    }

    for (final tx in periodTx) {
      // Filter out Transfers
      final type = categoryTypes[tx.categoryId];
      if (type == CategoryType.transfer) {
        continue;
      }

      final amount = tx.amount;
      // Aggregating by AccountId
      final accountId = tx.accountId;

      // Calculate Total in Base Currency
      final toBaseRate = _getExchangeRate(
        tx.currencyCode,
        data.baseCurrency,
        data.exchangeRates,
        tx.date,
      );
      final amountInBase = amount * toBaseRate;

      // Nominal Stats (Per Account, in Account Currency)
      if (amount > 0) {
        incomeMap[accountId] = (incomeMap[accountId] ?? 0.0) + amount;
        totalIncome += amountInBase;
      } else {
        expenseMap[accountId] = (expenseMap[accountId] ?? 0.0) + amount;
        totalExpense += amountInBase;
      }

      // Real Stats (Adjusted to Now)
      // We need to resolve Account -> Country for inflation.
      final account = data.accounts.cast<Account?>().firstWhere(
        (a) => a!.id == tx.accountId,
        orElse: () => null,
      );

      double multiplier = 1.0;
      final country = account?.country ?? defaultCountry;

      if (country != null && account != null) {
        multiplier = _calculateInflationMultiplier(
          account.creationDate,
          tx.date,
          ratesByCountry[country] ?? [],
        );
      }

      if (multiplier == 0) multiplier = 1.0;

      final realAmount = amount / multiplier;
      if (realAmount > 0) {
        realIncomeMap[accountId] =
            (realIncomeMap[accountId] ?? 0.0) + realAmount;
      } else {
        realExpenseMap[accountId] =
            (realExpenseMap[accountId] ?? 0.0) + realAmount;
      }
    }

    return PeriodStats(
      income: incomeMap,
      expense: expenseMap,
      realIncome: realIncomeMap,
      realExpense: realExpenseMap,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );
  }

  /// Returns percentage change vs previous period
  /// ((Current - Previous) / |Previous|) * 100
  /// Returns 0.0 if Previous is 0.
  double calculatePercentageChange(double currentValue, double previousValue) {
    if (previousValue == 0) return 0.0;
    return ((currentValue - previousValue) / previousValue.abs()) * 100;
  }

  /// Returns map of AccountId -> AssetStats
  /// Calculates Net Balance (Post-Exit), Invested, Realized, and Commissions.
  Map<String, AssetStats> calculateAssetStats(FinancialSnapshot data) {
    final stats = <String, AssetStats>{};
    final balances = calculateBalances(data);

    // Group transactions by account
    final transactionsByAccount = <String, List<Transaction>>{};
    for (final tx in data.transactions) {
      transactionsByAccount.putIfAbsent(tx.accountId, () => []).add(tx);
    }

    for (final account in data.accounts) {
      if (account.assetId == null) continue;

      final nominalBalance = balances[account.id] ?? 0.0;
      final feeStructure = account.feeStructure;

      // 1. Net Balance (Exit Strategy)
      // Apply the fee structure to the CURRENT Market Value
      final netBalance = FeeCalculator.calculateNetValue(
        nominalValue: nominalBalance,
        feeStructureJson: feeStructure,
      );

      // 2. Historical Stats
      double invested = 0.0;
      double realized = 0.0;
      double commissions = 0.0;

      final accountTx = transactionsByAccount[account.id] ?? [];

      for (final tx in accountTx) {
        // Filter out transactions after the snapshot date (to show stats AT that point in time)
        if (tx.date.isAfter(data.date)) {
          continue;
        }

        // Filter out transfers if needed?
        // User requirements say "Invested = Total Inflow + Fees".
        // Assuming all positive TX in Asset Account are "Investments".

        // Fee is always positive value stored in DB
        commissions += tx.fee;

        if (tx.amount > 0) {
          // Buy / Inflow
          invested += tx.amount + tx.fee;
        } else {
          // Sell / Outflow (tx.amount is negative)
          // Realized = Gross Sell Amount - Fee
          // Example: Sell for 100, Fee 5. Net Cash = 95.
          // tx.amount = -100 (or +100 depending on convention, usually negative if it leaves account, but here we are talking about Asset Account... wait).
          // If Asset Account tracks "Value of Asset":
          //   Usually we don't track "Cash" in Asset Account. We track "Holdings".
          //   But `Account` has `balance`.
          //   The user binding logic overlays `assetQuantity * price` on `balance`.
          //   So `tx.amount` in Asset Account might represent "Cash Flow" or "Correction"?
          //   Or maybe the user tracks "Cash Balance" in a separate Broker Account, and "Asset Account" is just for the Asset?
          //   If "Asset Account" is just the Asset, then transactions there might represent "Adjustments" or nothing?
          //   User said: "in income how much I received transferred to another account by transaction".
          //   This suggests Transactions EXISTING in the Asset Account.
          //   Let's assume:
          //     Positive Tx = Adding money/value (Investing).
          //     Negative Tx = Removing money/value (Realizing).

          realized += tx.amount.abs() - tx.fee;
        }
      }

      stats[account.id!] = AssetStats(
        accountId: account.id!,
        nominalBalance: nominalBalance,
        netBalance: netBalance,
        invested: invested,
        realized: realized,
        commissions: commissions,
      );
    }

    return stats;
  }
}

class AssetStats {
  final String accountId;
  final double nominalBalance; // Market Value
  final double netBalance; // Exit Value (After Fees)
  final double invested; // Total Inflow + Fees
  final double realized; // Total Outflow - Fees
  final double commissions; // Total Fees Paid

  AssetStats({
    required this.accountId,
    required this.nominalBalance,
    required this.netBalance,
    required this.invested,
    required this.realized,
    required this.commissions,
  });
}
