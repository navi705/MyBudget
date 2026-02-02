import 'dart:typed_data';

class IoHelper {
  static Future<String> readAsString(String path) async =>
      throw UnsupportedError('File IO not supported on web');
  static Future<void> writeAsString(String path, String content) async {}
  static Future<void> appendAsString(String path, String content) async {}
  static Future<bool> exists(String path) async => false;
  static Future<void> createParent(String path) async {}
  static Future<Uint8List> readAsBytes(String path) async => Uint8List(0);
  static Future<void> writeAsBytes(String path, Uint8List bytes) async {}
  static Future<void> copyFile(String source, String destination) async {}
  static Future<void> createDirectory(String path) async {}
  static Future<List<String>> listFiles(String path) async => [];
}
