import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';
import 'package:my_budget_client/core/utils/money_formatter.dart';
import 'package:my_budget_client/core/theme/money_colors.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/presentation/blocs/accounts/accounts_bloc.dart';
import 'package:my_budget_client/presentation/blocs/currency_converter/currency_converter_bloc.dart';
import 'package:my_budget_client/presentation/widgets/currency_selection_dialog.dart';

/// The ten figures one currency card shows, and the currencies it could not
/// price.
///
/// A value rather than ten locals, so the arithmetic can be done once and
/// looked up on later builds instead of re-run. See [_TotalBalanceCache].
class _CurrencyTotals {
  final double nominalBalance;
  final double realBalance;
  final double prevBalance;
  final double prevRealBalance;
  final double nominalIncome;
  final double realIncome;
  final double prevIncome;
  final double prevRealIncome;
  final double nominalExpense;
  final double prevExpense;

  /// Codes no rate could price, collected off the nominal-balance pass — the
  /// same pass that reported them before.
  final Set<String> unconvertible;

  const _CurrencyTotals({
    required this.nominalBalance,
    required this.realBalance,
    required this.prevBalance,
    required this.prevRealBalance,
    required this.nominalIncome,
    required this.realIncome,
    required this.prevIncome,
    required this.prevRealIncome,
    required this.nominalExpense,
    required this.prevExpense,
    required this.unconvertible,
  });
}

/// Everything derived from one pair of bloc states.
///
/// Rebuilt only when one of the two states is replaced, so a rebuild that is
/// not about the data — a theme change, a text-scale change, the parent
/// relaying out — costs a map lookup instead of ten walks of every account.
class _TotalBalanceCache {
  final AccountsLoadSuccess accountsState;
  final CurrencyConverterLoadSuccess converterState;

  /// The whole currency catalogue by code.
  ///
  /// This replaces a `firstWhere` in a try/catch used as control flow: a linear
  /// scan of ~180 currencies per distinct account currency, plus a thrown and
  /// caught exception on every miss, on every build.
  final Map<String, Currency> currencyByCode;

  final Map<String, _CurrencyTotals> totals = {};

  _TotalBalanceCache(this.accountsState, this.converterState)
    : currencyByCode = _indexByCode(converterState.allCurrencies);

  static Map<String, Currency> _indexByCode(List<Currency> currencies) {
    final index = <String, Currency>{};
    // `putIfAbsent`, not a map literal: `firstWhere` returned the first match
    // for a code and a literal would keep the last.
    for (final currency in currencies) {
      index.putIfAbsent(currency.code, () => currency);
    }
    return index;
  }

  bool matches(
    AccountsLoadSuccess accounts,
    CurrencyConverterLoadSuccess converter,
  ) =>
      identical(accountsState, accounts) &&
      identical(converterState, converter);

  /// The figures for [currency] over [accounts], worked out at most once per
  /// [cacheKey] per pair of states.
  ///
  /// The key names the card, not the currency: Total Net Worth prices every
  /// account into a currency while the breakdown prices only the accounts
  /// already in it, so the same code asks two different questions.
  _CurrencyTotals totalsFor(
    String cacheKey,
    Currency currency,
    List<Account> accounts,
  ) {
    return totals[cacheKey] ??= _compute(currency, accounts);
  }

  _CurrencyTotals _compute(Currency currency, List<Account> accounts) {
    final converter = converterState.converter;
    final baseCurrencyCode = converterState.baseCurrencyCode;
    final date = accountsState.activeDate;
    final unconvertible = <String>{};

    double total(Map<String, double>? balancesOverride, {Set<String>? report}) {
      return totalBalanceFor(
        currency: currency,
        accounts: accounts,
        converter: converter,
        baseCurrencyCode: baseCurrencyCode,
        date: date,
        balancesOverride: balancesOverride,
        unconvertible: report,
      );
    }

    return _CurrencyTotals(
      nominalBalance: total(null, report: unconvertible),
      realBalance: total(accountsState.realBalances),
      prevBalance: total(accountsState.previousPeriodBalances),
      prevRealBalance: total(accountsState.previousPeriodRealBalances),
      nominalIncome: total(accountsState.accountIncomes),
      realIncome: total(accountsState.accountRealIncomes),
      prevIncome: total(accountsState.previousAccountIncomes),
      prevRealIncome: total(accountsState.previousAccountRealIncomes),
      nominalExpense: total(accountsState.accountExpenses),
      prevExpense: total(accountsState.previousAccountExpenses),
      unconvertible: unconvertible,
    );
  }
}

class TotalBalanceSummaryWidget extends StatefulWidget {
  final AccountsLoadSuccess accountsState;
  final CurrencyConverterLoadSuccess converterState;

  const TotalBalanceSummaryWidget({
    super.key,
    required this.accountsState,
    required this.converterState,
  });

  @override
  State<TotalBalanceSummaryWidget> createState() =>
      _TotalBalanceSummaryWidgetState();
}

class _TotalBalanceSummaryWidgetState extends State<TotalBalanceSummaryWidget> {
  _TotalBalanceCache? _cache;

  // Whether each card's figures have ever been asked for.
  //
  // Both tiles open collapsed, and an `ExpansionTile` builds the `children`
  // list its caller passes whether or not it is going to show it — so a screen
  // nobody expanded still ran ten `totalBalanceFor` walks of every account per
  // selected currency, and again per distinct account currency, on every
  // build. These latch on first expansion instead.
  //
  // A latch rather than the live expansion flag: `ExpansionTile` keeps its
  // children mounted while it animates shut, and emptying the list the moment
  // the tile closes would make the card vanish instead of sliding up. The cost
  // of latching is that a card opened once keeps recomputing when its data
  // changes; the cache above means that is once per data change, not once per
  // build.
  bool _netWorthOpened = false;
  bool _breakdownOpened = false;

  _TotalBalanceCache get _data {
    final cache = _cache;
    if (cache != null &&
        cache.matches(widget.accountsState, widget.converterState)) {
      return cache;
    }
    return _cache = _TotalBalanceCache(
      widget.accountsState,
      widget.converterState,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final converterState = widget.converterState;
    final accountsState = widget.accountsState;

    if (converterState.selectedCurrencies.isEmpty &&
        accountsState.accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    final data = _data;

    final accountCurrencies = accountsState.accounts
        .map((a) => a.currencyCode)
        .toSet()
        .map((code) => data.currencyByCode[code])
        .whereType<Currency>()
        .toList();

    // Determine which currencies to show for Total Net Worth
    // If none selected, fallback to Base Currency
    List<Currency> currenciesToShow = converterState.selectedCurrencies;
    if (currenciesToShow.isEmpty) {
      final base = data.currencyByCode[converterState.baseCurrencyCode];
      if (base != null) {
        currenciesToShow = [base];
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Block 1: Total Net Worth (Selected Currencies or Base)
          if (currenciesToShow.isNotEmpty) ...[
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                initiallyExpanded: false, // Auto-expand if showing Total
                onExpansionChanged: (expanded) {
                  if (expanded && !_netWorthOpened) {
                    setState(() => _netWorthOpened = true);
                  }
                },
                title: Text(
                  l10n.totalNetWorth,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 18),
                  onPressed: () async {
                    final results = await showDialog<List<Currency>>(
                      context: context,
                      builder: (context) => CurrencySelectionDialog(
                        allCurrencies: converterState.allCurrencies,
                        selectedCurrencies: converterState.selectedCurrencies,
                      ),
                    );

                    if (results != null && context.mounted) {
                      final bloc = context.read<CurrencyConverterBloc>();
                      final current = converterState.selectedCurrencies;
                      for (final c in results) {
                        if (!current.any((curr) => curr.code == c.code)) {
                          bloc.add(AddSelectedCurrency(c));
                        }
                      }
                      for (final c in current) {
                        if (!results.any((curr) => curr.code == c.code)) {
                          bloc.add(RemoveSelectedCurrency(c));
                        }
                      }
                    }
                  },
                ),
                children: _netWorthOpened
                    ? [
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          alignment: WrapAlignment.start,
                          children: currenciesToShow.map((currency) {
                            return _buildCurrencySection(
                              context,
                              'net:${currency.code}',
                              currency,
                              accountsState.accounts, // Use ALL accounts
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                      ]
                    : const [],
              ),
            ),
          ],

          // Block 2: Currency Breakdown (Account Currencies)
          if (accountCurrencies.isNotEmpty) ...[
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                onExpansionChanged: (expanded) {
                  if (expanded && !_breakdownOpened) {
                    setState(() => _breakdownOpened = true);
                  }
                },
                title: Text(
                  l10n.currencyBreakdown,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                initiallyExpanded: false,
                children: _breakdownOpened
                    ? [
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          alignment: WrapAlignment.start,
                          children: accountCurrencies.map((currency) {
                            // Filter accounts matching this currency
                            final filteredAccounts = accountsState.accounts
                                .where((a) => a.currencyCode == currency.code)
                                .toList();

                            return _buildCurrencySection(
                              context,
                              'breakdown:${currency.code}',
                              currency,
                              filteredAccounts,
                            );
                          }).toList(),
                        ),
                      ]
                    : const [],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrencySection(
    BuildContext context,
    String cacheKey,
    Currency currency,
    List<Account> accounts,
  ) {
    final l10n = context.l10n;
    final totals = _data.totalsFor(cacheKey, currency, accounts);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ensure card fits content
          children: [
            Text(
              currency.code,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min, // Wrap width
                children: [
                  _buildMetricColumn(
                    context,
                    l10n.metricBalance,
                    totals.nominalBalance,
                    totals.prevBalance,
                    totals.realBalance,
                    totals.prevRealBalance,
                    Colors.blue,
                    currency.code,
                  ),
                  const SizedBox(width: 24),
                  _buildMetricColumn(
                    context,
                    l10n.metricIncome,
                    totals.nominalIncome,
                    totals.prevIncome,
                    totals.realIncome, // Restore Real Income
                    totals.prevRealIncome,
                    MoneyColors.of(context).inflow,
                    currency.code,
                  ),
                  const SizedBox(width: 24),
                  _buildMetricColumn(
                    context,
                    l10n.metricExpense,
                    totals.nominalExpense,
                    totals.prevExpense,
                    null, // Hide Real Expense
                    null,
                    MoneyColors.of(context).outflow,
                    currency.code, // Pass symbol/code
                  ),
                ],
              ),
            ),
            // A total that quietly leaves out an account is a wrong number
            // presented as a right one. Say which currencies had no rate.
            if (totals.unconvertible.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  l10n.dashboardUnconvertibleCurrencies(
                    (totals.unconvertible.toList()..sort()).join(', '),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: MoneyColors.of(context).unconvertible,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricColumn(
    BuildContext context,
    String label,
    double nominal,
    double prevNominal,
    double? real,
    double? prevReal,
    Color color,
    String symbol,
  ) {
    final l10n = context.l10n;

    // Relaxed hiding: allow small non-zero values
    const epsilon = 0.000001;
    if (nominal.abs() < epsilon &&
        (real == null || real.abs() < epsilon) &&
        prevNominal.abs() < epsilon) {
      if (label != "Balance") return const SizedBox.shrink();
    }

    final nominalDiff = nominal - prevNominal;
    final realDiff = (real != null && prevReal != null) ? real - prevReal : 0.0;

    // Percentages
    final nominalPct = prevNominal != 0
        ? (nominal - prevNominal) / prevNominal.abs() * 100
        : 0.0;
    final realPct = (real != null && prevReal != null && prevReal != 0)
        ? (real - prevReal) / prevReal.abs() * 100
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        // Nominal
        SelectableText.rich(
          TextSpan(
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 18,
            ),
            children: [
              TextSpan(
                text: '${MoneyFormatter.format(nominal, symbol)} $symbol',
                style: TextStyle(fontWeight: FontWeight.bold, color: color),
              ),
              if (nominalDiff.abs() >= 0.01) ...[
                TextSpan(
                  text: '  ${l10n.metricChange}: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
                TextSpan(
                  text:
                      '${MoneyFormatter.format(nominalDiff, symbol, signed: true)} $symbol (${nominalPct > 0 ? '+' : ''}${nominalPct.toStringAsFixed(2)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: MoneyColors.of(context).forAmount(nominalDiff),
                  ),
                ),
              ],
            ],
          ),
        ),
        // Real
        if (real != null) ...[
          const SizedBox(height: 2),
          SelectableText.rich(
            TextSpan(
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
              ),
              children: [
                TextSpan(text: '${l10n.metricReal}: '),
                TextSpan(
                  text: '${MoneyFormatter.format(real, symbol)} $symbol',
                ),
                if (realDiff.abs() >= 0.01) ...[
                  const TextSpan(text: ' '),
                  TextSpan(
                    text:
                        '${MoneyFormatter.format(realDiff, symbol, signed: true)} $symbol (${realPct > 0 ? '+' : ''}${realPct.toStringAsFixed(2)}%)',
                    style: TextStyle(
                      fontSize: 12,
                      color: MoneyColors.of(context).forAmount(realDiff),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
