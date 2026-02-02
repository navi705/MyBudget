import 'dart:typed_data';

class ImportFileData {
  final String name;
  final String? path;
  final Uint8List? bytes;

  ImportFileData({required this.name, this.path, this.bytes});
}
