import 'package:flutter/services.dart';

class AndroidFilePickerService {
  static const _channel = MethodChannel(
    'com.example.my_budget_client/file_picker',
  );

  Future<List<String>?> pickFile({
    required String mimeType,
    required String title,
    bool allowMultiple = false,
  }) async {
    try {
      final List<dynamic>? result = await _channel.invokeMethod('pickFile', {
        'mimeType': mimeType,
        'title': title,
        'allowMultiple': allowMultiple,
      });
      return result?.cast<String>();
    } on PlatformException catch (e) {
      print("Failed to pick file: '${e.message}'.");
      return null;
    }
  }
}
