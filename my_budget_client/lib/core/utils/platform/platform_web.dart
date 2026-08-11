// Stub for web: AppPlatform class that mocks dart:io Platform
import 'platform_override.dart';

class AppPlatform {
  /// No OS flag is ever true in a browser, so each one answers `false` unless a
  /// test has pinned a platform through [debugAppPlatformOverride].
  static bool _is(AppPlatformKind kind) => debugAppPlatformOverride == kind;

  static bool get isLinux => _is(AppPlatformKind.linux);
  static bool get isMacOS => _is(AppPlatformKind.macOS);
  static bool get isWindows => _is(AppPlatformKind.windows);
  static bool get isAndroid => _is(AppPlatformKind.android);
  static bool get isIOS => _is(AppPlatformKind.iOS);
  static bool get isFuchsia => _is(AppPlatformKind.fuchsia);

  // Add other properties if needed
  static Map<String, String> get environment => {};
  static String get pathSeparator => '/';
  static String get operatingSystem => 'web';
  static String get operatingSystemVersion => '';
  static String get localHostname => '';
}

class File {
  final String path;
  File(this.path);
  Future<bool> exists() async => false;
  Future<File> copy(String newPath) async => File(newPath);
  Future<void> delete() async {}
  Future<String> readAsString() async => '';
  Future<void> writeAsString(
    String contents, {
    FileMode mode = FileMode.write,
    bool flush = false,
  }) async {}
  Future<void> create({bool recursive = false}) async {}
}

enum FileMode { read, write, append, writeOnly, writeOnlyAppend }

class Directory {
  final String path;
  Directory(this.path);
  Future<bool> exists() async => false;
  Future<void> create({bool recursive = false}) async {}
  Stream<FileSystemEntity> list({
    bool recursive = false,
    bool followLinks = true,
  }) => const Stream.empty();
}

abstract class FileSystemEntity {
  String get path;
}

abstract class FileSystemEvent {
  int get type;
  String get path;
  bool get isDirectory;
}
