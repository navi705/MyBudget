import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../models/steam_inventory_model.dart';
import '../models/world_bank_inflation_model.dart';

enum GameApiSteam { cs2, dota2, steamCommunity }

const Map<String, int> gameApiIds = {
  "cs2": 730,
  "dota2": 570,
  "steamCommunity": 753,
};

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
        Map<dynamic, dynamic> body = jsonDecode(response.body);
        Map<String, dynamic> data = body['eur'];
        Map<String, double> dictionary = {};
        data.forEach((key, value) {
          if (value is num) {
            dictionary[key] = value.toDouble();
          } else if (value is String) {
            try {
              dictionary[key] = double.parse(value);
            } catch (e) {
              throw Exception('Rate is not number: $e');
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

  static Future<Map<String, double>> getSteamInvetoryCost(
    int accountId,
    GameApiSteam game,
  ) async {
    String gameId = gameApiIds[game.name].toString();
    Map<String, double> result = {};
    final uriGetItems = Uri.https(
      "wrcurzpfetyvtavbutcp.supabase.co",
      "/functions/v1/steam-proxy",
      {
        'endpoint': 'inventory',
        'steamid64': accountId.toString(),
        'appid': gameId,
        'contextid': '2',
      },
    );

    List<Map<String, dynamic>> itemsToPrice = [];
    for (int i = 0; i < 10; i++) {
      try {
        debugPrint(
          'Sending inventory request for acc: $accountId, attempt: ${i + 1}',
        );
        final response = await http.get(uriGetItems);
        if (response.statusCode == 200) {
          final inventoryResponse = SteamInventoryResponse.fromJson(
            jsonDecode(response.body),
          );
          if (inventoryResponse.success == 1) {
            itemsToPrice = inventoryResponse.descriptions
                .where((desc) => desc.marketable == 1)
                .map(
                  (desc) => {
                    'appid': desc.appid,
                    'market_hash_name': desc.marketHashName,
                  },
                )
                .toList();
            break;
          }
        }
      } catch (e) {
        debugPrint("Attempt ${i + 1} failed: $e");
      }
      await Future.delayed(const Duration(seconds: 5));
    }

    if (itemsToPrice.isEmpty) return result;

    final uriGetPrices = Uri.https(
      "wrcurzpfetyvtavbutcp.supabase.co",
      "/functions/v1/steam-proxy",
      {'endpoint': 'bulkprices'},
    );

    for (int i = 0; i < 10 && itemsToPrice.isNotEmpty; i++) {
      try {
        debugPrint(
          'Sending bulk price request, attempt: ${i + 1}, items: ${itemsToPrice.length}',
        );
        final priceResponse = await http.post(
          uriGetPrices,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'items': itemsToPrice,
            'currency': 3,
          }), // Assuming currency 3 is EUR
        );

        if (priceResponse.statusCode == 200) {
          final bulkPrices = BulkPricesResponse.fromJson(
            jsonDecode(priceResponse.body),
          );

          var failedItems = <Map<String, dynamic>>[];
          if (bulkPrices.items != null) {
            for (var item in itemsToPrice) {
              final key = '${item['appid']}_${item['market_hash_name']}_3';
              final priceInfo = bulkPrices.items![key];

              if (priceInfo != null &&
                  priceInfo.success &&
                  priceInfo.lowestPrice != null) {
                result[item['market_hash_name'] as String] =
                    priceInfo.lowestPrice!;
              } else {
                failedItems.add(item);
              }
            }
            itemsToPrice = failedItems;
          }
        }
      } catch (e) {
        debugPrint("Bulk price attempt ${i + 1} failed: $e");
      }

      if (itemsToPrice.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    return result;
  }

  static Future<List<InflationDataPoint>> getInflationFromWorldBank(
    String countryCode,
    String dateRange,
  ) async {
    final uri = Uri.https(
      "api.worldbank.org",
      "/v2/country/$countryCode/indicator/FP.CPI.TOTL.ZG",
      {'date': dateRange, 'format': 'json'},
    );
    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return WorldBankInflationResponse.fromJson(decoded).data;
      } else {
        throw Exception(
          'API request failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Failed to fetch inflation data: $e');
    }
  }
}
