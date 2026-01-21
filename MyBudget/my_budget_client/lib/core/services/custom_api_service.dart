import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CustomApiService {
  Future<void> fetchCustomData(String url) async {
    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        debugPrint('[CustomApiService] Successfully fetched data from $url');
        // TODO: Implement parsing logic when schema is defined.
        // For now, we just verify connectivity and response.
      } else {
        debugPrint(
          '[CustomApiService] Failed to fetch data from $url. Status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('[CustomApiService] Error fetching data from $url: $e');
    }
  }
}
