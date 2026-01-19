import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:my_budget_client/app_wrapper.dart';
import 'package:my_budget_client/core/di/injection_container.dart' as sl;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows) {
    await Window.initialize();
  }
  //await dotenv.load(fileName: ".env");
  await sl.init();
  // Note: IntilizationData.initilizate() is now called inside AppWrapper
  // This allows us to show a loading screen during initialization
  runApp(const AppWrapper());
}
