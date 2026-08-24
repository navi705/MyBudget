import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/services/steam_inventory_api_service.dart';

/// `steam_inventory_history.json` is a cache the debug fetch reads a day's
/// inventory value out of. It is a plain file on disk that an interrupted
/// write, a hand-edit or an older build can leave in any shape, and reading it
/// used to assume every level of it: the day was indexed and asked for
/// `containsKey` straight off a `dynamic`, and the value was cast to `num`.
void main() {
  double? read(String json, String dateKey, String game) =>
      SteamInventoryApiService.cachedValue(
        jsonDecode(json) as Map<String, dynamic>,
        dateKey,
        game,
      );

  test('reads the value stored for the day and game', () {
    expect(read('{"2026-08-22": {"cs2": 154.25}}', '2026-08-22', 'cs2'), 154.25);
  });

  test('reads an integer value', () {
    expect(read('{"2026-08-22": {"cs2": 154}}', '2026-08-22', 'cs2'), 154.0);
  });

  test('answers null for a day the file does not have', () {
    expect(read('{"2026-08-21": {"cs2": 1.0}}', '2026-08-22', 'cs2'), isNull);
  });

  test('answers null for a game the day does not have', () {
    expect(read('{"2026-08-22": {"cs2": 1.0}}', '2026-08-22', 'dota2'), isNull);
  });

  test('answers null when the day is not a map', () {
    // What a build that stored one number per day leaves behind.
    expect(read('{"2026-08-22": 154.25}', '2026-08-22', 'cs2'), isNull);
    expect(read('{"2026-08-22": null}', '2026-08-22', 'cs2'), isNull);
    expect(read('{"2026-08-22": ["cs2"]}', '2026-08-22', 'cs2'), isNull);
  });

  test('answers null when the value is not a number', () {
    expect(read('{"2026-08-22": {"cs2": "154.25"}}', '2026-08-22', 'cs2'),
        isNull);
    expect(read('{"2026-08-22": {"cs2": null}}', '2026-08-22', 'cs2'), isNull);
  });

  test('refuses a value of zero or less', () {
    // Zero is what a lookup that found nothing returns, and storing it writes
    // that failure into the asset's value.
    expect(read('{"2026-08-22": {"cs2": 0}}', '2026-08-22', 'cs2'), isNull);
    expect(read('{"2026-08-22": {"cs2": -5.5}}', '2026-08-22', 'cs2'), isNull);
  });

  test('refuses a non-finite value', () {
    expect(
      SteamInventoryApiService.cachedValue(
        {
          '2026-08-22': {'cs2': double.nan},
        },
        '2026-08-22',
        'cs2',
      ),
      isNull,
    );
    expect(
      SteamInventoryApiService.cachedValue(
        {
          '2026-08-22': {'cs2': double.infinity},
        },
        '2026-08-22',
        'cs2',
      ),
      isNull,
    );
  });

  test('answers null for the metadata key rather than throwing', () {
    // `_metadata` sits beside the days in the same map.
    expect(
      read('{"_metadata": {"attempts": {}}}', '_metadata', 'cs2'),
      isNull,
    );
  });
}
