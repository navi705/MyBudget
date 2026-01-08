import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart' as db;
import 'package:my_budget_client/core/mappers/inflation_rate_mapper.dart';
import 'package:my_budget_client/domain/entities/inflation_rate.dart';
import 'package:my_budget_client/domain/repositories/inflation_repository.dart';

class LocalInflationRepository implements InflationRepository {
  final db.InflationRatesDao _dao;

  LocalInflationRepository(this._dao);

  @override
  Future<List<InflationRateDomain>> getInflationRates() async {
    final driftRates = await _dao.getAllInflationRates();
    return driftRates.toDomainList();
  }

  @override
  Future<List<InflationRateDomain>> getInflationRatesFiltered({
    int limit = 50,
    int offset = 0,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? countries,
    List<int>? presets,
    bool sortAscending = false,
  }) async {
    final driftRates = await _dao.getInflationRatesFiltered(
      limit: limit,
      offset: offset,
      dateFrom: dateFrom,
      dateTo: dateTo,
      countries: countries,
      presets: presets,
      sort: sortAscending ? OrderingMode.asc : OrderingMode.desc,
    );
    return driftRates.toDomainList();
  }

  @override
  Future<void> addInflationRate(InflationRateDomain rate) async {
    await _dao.insertInflationRate(rate.toCompanion());
  }

  @override
  Future<void> updateInflationRate(InflationRateDomain rate) async {
    await _dao.updateInflationRate(rate.toCompanion());
  }

  @override
  Future<void> deleteInflationRate(
    DateTime date,
    String? country,
    int preset,
  ) async {
    await _dao.deleteInflationRate(date, country, preset);
  }

  @override
  Future<List<String>> getAvailableCountries() async {
    final countries = await _dao.getAvailableCountries();
    return countries.where((element) => element.isNotEmpty).toList();
  }

  @override
  Future<List<int>> getAvailablePresets() async {
    return _dao.getAvailablePresets();
  }

  @override
  Future<int> getInflationRatesCount({
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? countries,
    List<int>? presets,
  }) {
    return _dao.getInflationRatesCount(
      dateFrom: dateFrom,
      dateTo: dateTo,
      countries: countries,
      presets: presets,
    );
  }
}
