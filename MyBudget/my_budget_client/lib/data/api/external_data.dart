import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ExternalData {
  static Future<Map<String, String>>
  getCurrenciesFromFreeExchangeRates() async {
    final uri = Uri.https(
      "cdn.jsdelivr.net",
      "/npm/@fawazahmed0/currency-api@latest/v1/currencies.json",
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        Map<String, String> dictionary = {};
        data.forEach((key, value) {
          dictionary[key] = value.toString();
        });
        return dictionary;
      } else {
        throw Exception(
          'API request failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch currencies: $e');
    }
  }

  static Future<Map<String, double>> getCurrencyRatesFromFreeExchangeRates(
    DateTime date,
  ) async {
    final uri = Uri.https(
      "cdn.jsdelivr.net",
      "/npm/@fawazahmed0/currency-api@${DateFormat('yyyy-MM-dd').format(date)}/v1/currencies/eur.json",
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        Map<dynamic,dynamic> body = jsonDecode(response.body);
        Map<String, dynamic> data = body['eur'];
        Map<String, double> dictionary = {};
        data.forEach((key, value) {
          if (value is num) {
            dictionary[key] = value.toDouble();
          } else if (value is String) {
            try {
              dictionary[key] = double.parse(value);
            } catch (e) {
            throw Exception('Rate is not number: ${e}');
            }
          }
        });
        return dictionary;
      } else {
        throw Exception(
          'API request failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch currency rates: $e');
    }
  }
}
