import 'package:my_budget_client/core/utils/import_utils.dart';

class IntilizationData {
  static Future<void> Initilizate() async{
    await ImportDataUtils.getCurrenciesInitial();
  }
}