import 'dart:io';
import 'dart:typed_data';

class IoHelper {
  static Future<String> readAsString(String path) => File(path).readAsString();
  static Future<void> writeAsString(String path, String content) =>
      File(path).writeAsString(content);

  static Future<void> appendAsString(String path, String content) =>
      File(path).writeAsString(content, mode: FileMode.append);

  static Future<bool> exists(String path) => File(path).exists();

  static Future<void> createParent(String path) =>
      File(path).parent.create(recursive: true);

  static Future<Uint8List> readAsBytes(String path) => File(path).readAsBytes();

  static Future<void> writeAsBytes(String path, Uint8List bytes) =>
      File(path).writeAsBytes(bytes);

  static Future<void> copyFile(String source, String destination) =>
      File(source).copy(destination);

  static Future<void> createDirectory(String path) =>
      Directory(path).create(recursive: true);

  static Future<List<String>> listFiles(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return [];
    return dir.list().map((entity) => entity.path).toList();
  }
}
