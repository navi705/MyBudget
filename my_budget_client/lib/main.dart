import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:my_budget_client/app_wrapper.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as sl;
import 'package:my_budget_client/core/utils/window/window_utils.dart';

void main() async {
  debugPrint('[MAIN_DEBUG] Starting MyBudget app...');
  debugPrint('[MAIN_DEBUG] Platform: ${kIsWeb ? "WEB" : "NATIVE"}');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[MAIN_DEBUG] WidgetsFlutterBinding initialized');

  await WindowUtils.initialize();
  debugPrint('[MAIN_DEBUG] WindowUtils initialized');

  //await dotenv.load(fileName: ".env");
  await sl.init();
  debugPrint('[MAIN_DEBUG] Dependency injection initialized');

  // Note: IntilizationData.initilizate() is now called inside AppWrapper
  // This allows us to show a loading screen during initialization
  debugPrint('[MAIN_DEBUG] Launching AppWrapper...');
  runApp(const AppWrapper());
}
