import 'dart:io' as io;

class AppPlatform {
  static bool get isLinux => io.Platform.isLinux;
  static bool get isMacOS => io.Platform.isMacOS;
  static bool get isWindows => io.Platform.isWindows;
  static bool get isAndroid => io.Platform.isAndroid;
  static bool get isIOS => io.Platform.isIOS;
  static bool get isFuchsia => io.Platform.isFuchsia;

  static Map<String, String> get environment => io.Platform.environment;
  static String get pathSeparator => io.Platform.pathSeparator;
  static String get operatingSystem => io.Platform.operatingSystem;
  static String get operatingSystemVersion =>
      io.Platform.operatingSystemVersion;
}
