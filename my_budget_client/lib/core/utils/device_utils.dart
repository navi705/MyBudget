import 'dart:developer';
import 'dart:io';
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
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceName = androidInfo.model; 
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceName = iosInfo.name;
      } else if (Platform.isLinux) {
        final LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
        deviceName = linuxInfo.name;
      } else if (Platform.isMacOS) {
        final MacOsDeviceInfo macOsInfo = await deviceInfo.macOsInfo;
        deviceName = macOsInfo.computerName;
      } else if (Platform.isWindows) {
        final WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
        deviceName = windowsInfo.computerName;
      }
    }
  } catch (e) {
    log('Failed to get device name: $e');
  }

  return deviceName;
}
