// Stub for web: AppPlatform class that mocks dart:io Platform
class AppPlatform {
  static const bool isLinux = false;
  static const bool isMacOS = false;
  static const bool isWindows = false;
  static const bool isAndroid = false;
  static const bool isIOS = false;
  static const bool isFuchsia = false;

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
