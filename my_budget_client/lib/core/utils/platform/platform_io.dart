import 'dart:io' as io;

import 'platform_override.dart';

class AppPlatform {
  /// Answers a platform flag, letting [debugAppPlatformOverride] win when a
  /// test has set one. `actual` is passed as a callback so the `dart:io` lookup
  /// is skipped entirely while an override is in force.
  static bool _is(AppPlatformKind kind, bool Function() actual) {
    final override = debugAppPlatformOverride;
    return override == null ? actual() : override == kind;
  }

  static bool get isLinux =>
      _is(AppPlatformKind.linux, () => io.Platform.isLinux);
  static bool get isMacOS =>
      _is(AppPlatformKind.macOS, () => io.Platform.isMacOS);
  static bool get isWindows =>
      _is(AppPlatformKind.windows, () => io.Platform.isWindows);
  static bool get isAndroid =>
      _is(AppPlatformKind.android, () => io.Platform.isAndroid);
  static bool get isIOS => _is(AppPlatformKind.iOS, () => io.Platform.isIOS);
  static bool get isFuchsia =>
      _is(AppPlatformKind.fuchsia, () => io.Platform.isFuchsia);

  static Map<String, String> get environment => io.Platform.environment;
  static String get pathSeparator => io.Platform.pathSeparator;
  static String get operatingSystem => io.Platform.operatingSystem;
  static String get operatingSystemVersion =>
      io.Platform.operatingSystemVersion;
}
