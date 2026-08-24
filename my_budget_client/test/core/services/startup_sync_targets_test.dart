import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/services/startup_sync_service.dart';
import 'package:my_budget_client/data/api/external_data.dart';

/// The daily guard in `executeStartupSync` skips a provider whose
/// `lastFetchAt` falls on today, so a stamp written by a branch that fetched
/// nothing is not a cosmetic mistake: it tells every later launch that day
/// that the provider is done. Both of the branches that could fetch nothing
/// are decided by the two pure members below.
void main() {
  group('builtInApiIds', () {
    test('names every id the fetch switch handles', () {
      expect(
        StartupSyncService.builtInApiIds,
        {'exchange_rates', 'inflation', 'steam_inventory', 'assets'},
      );
    });

    test('does not name an id nothing fetches', () {
      // A row in api_settings whose id no branch handles used to be stamped
      // as fetched anyway.
      expect(StartupSyncService.builtInApiIds, isNot(contains('sms')));
      expect(StartupSyncService.builtInApiIds, isNot(contains('')));
    });
  });

  group('steamTargetFor', () {
    test('reads a configured account and game', () {
      final target = StartupSyncService.steamTargetFor(
        '76561198000000000',
        'dota2',
      );

      expect(target, isNotNull);
      expect(target!.accountId, 76561198000000000);
      expect(target.game, GameApiSteam.dota2);
    });

    test('falls back to cs2 when no game is stored', () {
      expect(
        StartupSyncService.steamTargetFor('123', null)?.game,
        GameApiSteam.cs2,
      );
    });

    test('falls back to cs2 when the stored game is not one of ours', () {
      // A game removed from the enum leaves its name behind in settings.
      expect(
        StartupSyncService.steamTargetFor('123', 'tf2')?.game,
        GameApiSteam.cs2,
      );
    });

    test('carries steamCommunity through', () {
      expect(
        StartupSyncService.steamTargetFor('123', 'steamCommunity')?.game,
        GameApiSteam.steamCommunity,
      );
    });

    test('answers null when no account is stored', () {
      expect(StartupSyncService.steamTargetFor(null, 'cs2'), isNull);
    });

    test('answers null for a blank account', () {
      expect(StartupSyncService.steamTargetFor('', 'cs2'), isNull);
      expect(StartupSyncService.steamTargetFor('   ', 'cs2'), isNull);
    });

    test('answers null for an account that is not a number', () {
      expect(StartupSyncService.steamTargetFor('my-profile', 'cs2'), isNull);
    });

    test('accepts an account stored with stray whitespace', () {
      // Pasted out of a browser, which is how the id gets into settings.
      expect(
        StartupSyncService.steamTargetFor(' 123 ', 'cs2')?.accountId,
        123,
      );
    });
  });
}
