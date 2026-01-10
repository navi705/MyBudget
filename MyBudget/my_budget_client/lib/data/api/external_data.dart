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

  static Future<double> getSteamInventoryValue(
    int accountId,
    GameApiSteam game,
  ) async {
    String gameId = gameApiIds[game.name].toString();
    double totalInventoryValue = 0.0;

    Map<String, int> assetQuantities = {};
    Map<String, Description> descriptionMap = {};

    String? startAssetId;
    bool moreItems = true;
    int page = 1;

    // 1. Fetch all pages of inventory
    while (moreItems && page <= 20) {
      bool pageSuccess = false;
      for (int i = 0; i < 10; i++) {
        try {
          final queryParams = {
            'endpoint': 'inventory',
            'steamid64': accountId.toString(),
            'appid': gameId,
            'contextid': '2',
          };
          if (startAssetId != null) {
            queryParams['start_assetid'] = startAssetId!;
          }

          final uriGetItems = Uri.https(
            "wrcurzpfetyvtavbutcp.supabase.co",
            "/functions/v1/steam-proxy",
            queryParams,
          );

          debugPrint(
            'Sending inventory request for acc: $accountId, page: $page, attempt: ${i + 1}',
          );
          final response = await http.get(uriGetItems);

          if (response.statusCode == 200) {
            final json = jsonDecode(response.body);
            final inventoryResponse = SteamInventoryResponse.fromJson(json);

            if (inventoryResponse.success == 1) {
              // Process Assets
              if (inventoryResponse.assets != null) {
                for (var asset in inventoryResponse.assets!) {
                  final key = '${asset.classid}_${asset.instanceid}';
                  // Some assets might have amount > 1? Usually 1 for CS2, but good to parse.
                  final qty = int.tryParse(asset.amount) ?? 1;
                  assetQuantities[key] = (assetQuantities[key] ?? 0) + qty;
                }
              }

              // Process Descriptions
              if (inventoryResponse.descriptions != null) {
                for (var desc in inventoryResponse.descriptions!) {
                  final key = '${desc.classid}_${desc.instanceid}';
                  if (!descriptionMap.containsKey(key)) {
                    descriptionMap[key] = desc;
                  }
                }
              }

              // Pagination Logic
              if (inventoryResponse.moreItems == 1 &&
                  inventoryResponse.lastAssetid != null) {
                startAssetId = inventoryResponse.lastAssetid;
                moreItems = true;
              } else {
                moreItems = false;
              }

              pageSuccess = true;
              break; // Break retry loop
            } else {
              debugPrint("Inventory request success != 1: ${response.body}");
            }
          } else {
            debugPrint("Request failed with status: ${response.statusCode}");
          }
        } catch (e) {
          debugPrint("Attempt ${i + 1} failed: $e");
        }
        await Future.delayed(const Duration(seconds: 5));
      }

      if (!pageSuccess) {
        debugPrint(
          "Failed to fetch page $page after 10 attempts. Aborting inventory fetch.",
        );
        // Return 0.0 to safely indicate incomplete data? or partial?
        // Returning partial data might be misleading.
        // But throwing exception crashes the flow.
        return 0.0;
      }

      page++;
    }

    debugPrint(
      "Total assets counted: ${assetQuantities.length} unique types, "
      "Total items: ${assetQuantities.values.fold(0, (sum, q) => sum + q)}",
    );

    // 2. Identify unique items to price (Marketable only)
    List<Map<String, dynamic>> itemsToPrice = [];
    Set<String> addedMarketNames = {};

    descriptionMap.forEach((key, desc) {
      if (desc.marketable == 1 &&
          !addedMarketNames.contains(desc.marketHashName)) {
        itemsToPrice.add({
          'appid': desc.appid,
          'market_hash_name': desc.marketHashName,
        });
        addedMarketNames.add(desc.marketHashName);
      }
    });

    if (itemsToPrice.isEmpty) return 0.0;

    // 3. Update Status
    debugPrint("Fetching prices for ${itemsToPrice.length} unique items...");

    // 4. Fetch Bulk Prices
    final uriGetPrices = Uri.https(
      "wrcurzpfetyvtavbutcp.supabase.co",
      "/functions/v1/steam-proxy",
      {'endpoint': 'bulkprices'},
    );

    Map<String, double> priceMap = {}; // name -> price

    // Work on a copy of items to retry
    List<Map<String, dynamic>> pendingItems = List.from(itemsToPrice);

    for (int i = 0; i < 10 && pendingItems.isNotEmpty; i++) {
      try {
        debugPrint(
          'Sending bulk price request, attempt: ${i + 1}, items: ${pendingItems.length}',
        );
        final priceResponse = await http.post(
          uriGetPrices,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'items': pendingItems,
            'currency': 3,
          }), // Currency 3 = EUR
        );

        if (priceResponse.statusCode == 200) {
          final bulkPrices = BulkPricesResponse.fromJson(
            jsonDecode(priceResponse.body),
          );

          var nextPendingItems = <Map<String, dynamic>>[];

          if (bulkPrices.items != null) {
            for (var itemRequest in pendingItems) {
              final name = itemRequest['market_hash_name'];
              final appId = itemRequest['appid'];
              // key format from previous logic: appid_name_currency
              final key = '${appId}_${name}_3';

              final priceInfo = bulkPrices.items![key];

              if (priceInfo != null &&
                  priceInfo.success &&
                  priceInfo.lowestPrice != null) {
                // Remove price formatting if needed?
                // The model handles parsing 'x,xx€' to double.
                priceMap[name] = priceInfo.lowestPrice!;
              } else {
                nextPendingItems.add(itemRequest);
              }
            }
            pendingItems = nextPendingItems;
          }
        }
      } catch (e) {
        debugPrint("Bulk price attempt ${i + 1} failed: $e");
      }

      if (pendingItems.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 5));
      }
    }

    // 5. Calculate Grand Total
    assetQuantities.forEach((key, quantity) {
      final desc = descriptionMap[key];
      // Only value marketable items
      if (desc != null && desc.marketable == 1) {
        final price = priceMap[desc.marketHashName];
        if (price != null) {
          totalInventoryValue += (price * quantity);
        }
      }
    });

    debugPrint("Total Inventory Value Calculated: $totalInventoryValue");

    return totalInventoryValue;
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
