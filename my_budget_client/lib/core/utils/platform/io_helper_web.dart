import 'dart:typed_data';

/// Web counterpart of `io_helper_io.dart`.
///
/// A browser gives the app no filesystem: there are no paths to open, no bytes
/// to persist and nothing to enumerate. Earlier this stub simply returned from
/// every write and handed back an empty [Uint8List] for every read, so callers
/// were told their data had been saved when nothing had happened and parsed
/// empty content as if it were a real (empty) file. Both failures were
/// invisible until the data was already gone.
///
/// The contract is therefore split by what an honest answer looks like:
///
///  * [exists] and [listFiles] answer "nothing is there", which is literally
///    true on web and lets probe-then-act callers take their existing "no
///    local file" branch instead of crashing.
///  * Everything that would have to produce or consume real file content
///    throws [UnsupportedError], so a caller that reaches it on web fails
///    loudly at the call site rather than continuing on fabricated data.
///
/// Guard web-reachable call sites with `kIsWeb`. Persisting user data in the
/// browser belongs in a browser-native store (IndexedDB / localStorage); this
/// shim deliberately does not pretend to be one.
class IoHelper {
  static UnsupportedError _noFileSystem(String operation) => UnsupportedError(
    'IoHelper.$operation is not supported on web: the browser has no '
    'filesystem. Guard the call with kIsWeb or use a browser-native store.',
  );

  static Future<String> readAsString(String path) async =>
      throw _noFileSystem('readAsString');

  static Future<void> writeAsString(String path, String content) async =>
      throw _noFileSystem('writeAsString');

  static Future<void> appendAsString(String path, String content) async =>
      throw _noFileSystem('appendAsString');

  /// Always `false`: no file can exist without a filesystem.
  static Future<bool> exists(String path) async => false;

  static Future<void> createParent(String path) async =>
      throw _noFileSystem('createParent');

  static Future<Uint8List> readAsBytes(String path) async =>
      throw _noFileSystem('readAsBytes');

  static Future<void> writeAsBytes(String path, Uint8List bytes) async =>
      throw _noFileSystem('writeAsBytes');

  static Future<void> copyFile(String source, String destination) async =>
      throw _noFileSystem('copyFile');

  static Future<void> createDirectory(String path) async =>
      throw _noFileSystem('createDirectory');

  /// Always empty: there is no directory to enumerate.
  static Future<List<String>> listFiles(String path) async => [];
}
