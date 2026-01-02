import 'package:my_budget_client/core/utils/import_utils.dart';

class IntilizationData {
  static Future<void> initilizate() async{
    await ImportDataUtils.getCurrenciesInitial();
  }
  static Future<void> initilizateDebug() async{
    await ImportDataUtils.getCurrenciesInitialDebug();
  }
}