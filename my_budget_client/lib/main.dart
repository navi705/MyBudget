import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_driver/driver_extension.dart';
import 'package:my_budget_client/app.dart';
import 'package:my_budget_client/app_wrapper.dart';
import 'package:my_budget_client/core/debug/ui_probe.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as sl;
import 'package:my_budget_client/core/utils/window/window_utils.dart';

void main() async {
  // Before anything else touches the binding: this installs its own
  // WidgetsBinding subclass, and doing it after WidgetsFlutterBinding is up
  // fails with "Binding is already initialized to WidgetsFlutterBinding".
  //
  // Opt-in, because the driver extension takes over text input: while it is on,
  // the real keyboard no longer reaches the app. Off unless the app was started
  // with `--dart-define=ENABLE_FLUTTER_DRIVER=true`, and the const makes the
  // whole branch disappear from every other build.
  if (const bool.fromEnvironment('ENABLE_FLUTTER_DRIVER')) {
    enableFlutterDriverExtension();
  }

  debugPrint('[MAIN_DEBUG] Starting MyBudget app...');
  debugPrint('[MAIN_DEBUG] Platform: ${kIsWeb ? "WEB" : "NATIVE"}');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[MAIN_DEBUG] WidgetsFlutterBinding initialized');

  // Before the first frame: a DateFormat for any locale but en_US throws until
  // intl's symbols are loaded. Keeping the running locale in step with
  // Intl.defaultLocale is IntlLocaleSync's job, in app.dart - the locale can
  // change without a restart, so it cannot be settled here.
  await initializeAppDateFormatting();
  debugPrint('[MAIN_DEBUG] Date formatting initialized');

  await WindowUtils.initialize();
  debugPrint('[MAIN_DEBUG] WindowUtils initialized');

  //await dotenv.load(fileName: ".env");
  await sl.init();
  debugPrint('[MAIN_DEBUG] Dependency injection initialized');

  // Note: IntilizationData.initilizate() is now called inside AppWrapper
  // This allows us to show a loading screen during initialization
  // Debug builds only, and a no-op elsewhere: lets a screen be inspected and
  // driven by widget instead of by guessed pixel coordinates.
  registerUiProbe();

  debugPrint('[MAIN_DEBUG] Launching AppWrapper...');
  runApp(const AppWrapper());
}
