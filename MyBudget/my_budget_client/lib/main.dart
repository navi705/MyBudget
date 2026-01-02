import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as sl;
import 'package:my_budget_client/intilization_data.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await sl.init();
  if(kDebugMode){
    //IntilizationData.InitilizateDebug();
  }
  else{
    IntilizationData.Initilizate();
  }
  
  runApp(const App());
}