import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/exchange_rate.dart';

abstract class CurrencyRepository {
  Future<List<Currency>> getCurrencies();
  Stream<List<Currency>> watchCurrencies();
  Future<Currency?> getCurrencyByCode(String code);
  Future<void> addCurrency(Currency currency);
  Future<void> addCurrencies(List<Currency> currencies);
  Future<void> updateCurrency(Currency currency);
  Future<void> deleteCurrency(Currency currency);

  Stream<List<CurrencyDesignation>> watchCurrencyDesignationsForCurrency(
    String currencyCode,
  );
  Future<List<CurrencyDesignation>> getCurrencyDesignationsForCurrency(
    String currencyCode,
  );
  Future<CurrencyDesignation?> getCurrencyDesignationById(String id);
  Future<void> addCurrencyDesignation(CurrencyDesignation designation);

  Stream<List<CurrencyDesignation>> watchAllCurrencyDesignations();
  Future<List<CurrencyDesignation>> getAllCurrencyDesignations();

  /// How many accounts and transactions are already recorded in each currency
  /// code. Codes the user has never used are absent rather than zero.
  ///
  /// Ordering hint for the currency picker: the list holds every currency the
  /// app knows, and a person works in a handful of them.
  Future<Map<String, int>> getCurrencyUsageCounts();

  /// The currency codes the user starred, oldest star first.
  Stream<List<String>> watchFavoriteCurrencyCodes();
  Future<List<String>> getFavoriteCurrencyCodes();

  /// Stars or unstars [code]. Starring one that is already starred, or
  /// unstarring one that is not, changes nothing.
  Future<void> setFavoriteCurrency(String code, {required bool favorite});

  /// Fires whenever any exchange rate row is inserted/updated/deleted.
  /// Carries no payload — consumers use it purely as an invalidation signal.
  Stream<void> watchExchangeRateChanges();

  Future<List<ExchangeRateDomain>> getLatestExchangeRates(DateTime date);
  Future<List<ExchangeRateDomain>> getLatestExchangeRatesAll();
  /// Distinct dates that already have preset (seeded) exchange rate data,
  /// without pulling every exchange rate row across the isolate boundary.
  Future<List<DateTime>> getPresetRateDates();
  /// [currencyCodes], when given, limits the result to the pairs that touch
  /// one of those codes on either side.
  Future<List<ExchangeRateDomain>> getLatestExchangeRatesByList(
    List<DateTime> date, {
    Set<String>? currencyCodes,
  });
  Future<List<ExchangeRateDomain>> getExchangeRatesFiltered({
    int limit = 100,
    int offset = 0,
    DateTime? startDate,
    DateTime? endDate,
    String? fromCurrency,
    String? toCurrency,
    List<int>? presets,
    bool sortAscending = false,
  });
  Future<int> getExchangeRatesCount({
    DateTime? startDate,
    DateTime? endDate,
    String? fromCurrency,
    String? toCurrency,
    List<int>? presets,
  });

  Future<void> deleteExchangeRates(List<ExchangeRateDomain> rates);
  Future<void> updateExchangeRatePresets(
    List<ExchangeRateDomain> rates,
    int newPreset,
  );

  Future<List<int>> getAvailablePresets();

  Future<void> addExchangeRate(ExchangeRateDomain exchangeRate);
  Future<void> addExchangeRates(List<ExchangeRateDomain> exchangeRates);
  Future<void> updateExchangeRate(ExchangeRateDomain exchangeRate);

  /// Replaces an existing exchange rate. Deletes the [original] row (located by
  /// its from/to/date/preset key) and inserts [updated] atomically, so editing
  /// key fields does not leave an orphaned duplicate.
  Future<void> replaceExchangeRate(
    ExchangeRateDomain original,
    ExchangeRateDomain updated,
  );
}
