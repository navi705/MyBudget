part of 'currency_converter_bloc.dart';

abstract class CurrencyConverterState extends Equatable {
  const CurrencyConverterState();

  @override
  List<Object> get props => [];
}

class CurrencyConverterInitial extends CurrencyConverterState {}

class CurrencyConverterLoadInProgress extends CurrencyConverterState {}

// ignore: must_be_immutable
class CurrencyConverterLoadSuccess extends CurrencyConverterState {
  final List<Currency> allCurrencies;
  final List<ExchangeRateDomain> exchangeRates;
  final List<Currency> selectedCurrencies;
  final String baseCurrencyCode;

  CurrencyConverter? _converter;

  CurrencyConverterLoadSuccess({
    this.allCurrencies = const [],
    this.exchangeRates = const [],
    this.selectedCurrencies = const [],
    required this.baseCurrencyCode,
  });

  /// The one converter these rates are worth building.
  ///
  /// Built lazily and kept, because every currency section on the accounts
  /// screen asks for four totals and each total walks every account.
  CurrencyConverter get converter => _converter ??= CurrencyConverter(
    exchangeRates,
    baseCurrency: baseCurrencyCode,
  );

  CurrencyConverterLoadSuccess copyWith({
    List<Currency>? allCurrencies,
    List<ExchangeRateDomain>? exchangeRates,
    List<Currency>? selectedCurrencies,
    String? baseCurrencyCode,
  }) {
    return CurrencyConverterLoadSuccess(
      allCurrencies: allCurrencies ?? this.allCurrencies,
      exchangeRates: exchangeRates ?? this.exchangeRates,
      selectedCurrencies: selectedCurrencies ?? this.selectedCurrencies,
      baseCurrencyCode: baseCurrencyCode ?? this.baseCurrencyCode,
    );
  }

  @override
  List<Object> get props => [
    allCurrencies,
    exchangeRates,
    selectedCurrencies,
    baseCurrencyCode,
  ];
}

class CurrencyConverterLoadFailure extends CurrencyConverterState {}

/// The balance of every account in [accounts], expressed in [currency].
///
/// Anything that cannot be priced in [baseCurrencyCode] is left out of the sum
/// and its currency code is added to [unconvertible], so the caller can say the
/// figure is incomplete instead of quietly presenting a short total.
double totalBalanceFor({
  required Currency currency,
  required List<Account> accounts,
  required CurrencyConverter converter,
  required String baseCurrencyCode,
  required DateTime date,
  Map<String, double>? balancesOverride,
  Set<String>? unconvertible,
}) {
  double totalInBase = 0.0;

  for (final account in accounts) {
    final balance = (balancesOverride != null && account.id != null)
        ? (balancesOverride[account.id!] ?? 0.0)
        : account.balance;

    // Every rate this app stores is dated, and the rate that prices a balance
    // is the one nearest the day being shown - on EITHER side of it. Demanding
    // a row dated at or before [date] used to drop an account whose only rate
    // was fetched later the same morning, which is every account in a currency
    // the user had just refreshed.
    final inBase = converter.tryConvert(
      amount: balance,
      from: account.currencyCode,
      to: baseCurrencyCode,
      date: date,
    );
    if (inBase == null) {
      unconvertible?.add(account.currencyCode);
      continue;
    }
    totalInBase += inBase;
  }

  final total = converter.tryConvert(
    amount: totalInBase,
    from: baseCurrencyCode,
    to: currency.code,
    date: date,
  );

  if (total == null) {
    unconvertible?.add(currency.code);
    return 0.0;
  }
  return total;
}
