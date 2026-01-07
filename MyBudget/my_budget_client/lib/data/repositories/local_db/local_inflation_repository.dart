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
    DateTime? date,
    String? country,
  }) async {
    final driftRates = await _dao.getInflationRatesFiltered(
      date: date,
      country: country,
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
}
