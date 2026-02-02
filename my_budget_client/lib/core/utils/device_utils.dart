import 'dart:developer';
import 'package:my_budget_client/core/utils/platform/platform_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<String> getDeviceName() async {
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  String deviceName = 'Unknown';

  try {
    if (kIsWeb) {
      final WebBrowserInfo webInfo = await deviceInfo.webBrowserInfo;
      deviceName = webInfo.browserName.toString();
    } else {
      if (AppPlatform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model;
      } else if (AppPlatform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      } else if (AppPlatform.isLinux) {
        final LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        deviceName = linuxInfo.name;
      } else if (AppPlatform.isMacOS) {
        final MacOsDeviceInfo macOsInfo = await deviceInfo.macOsInfo;
        deviceName = macOsInfo.computerName;
      } else if (AppPlatform.isWindows) {
        final WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        deviceName = windowsInfo.computerName;
      }
    }
  } catch (e) {
    log('Failed to get device name: $e');
  }

  return deviceName;
}
