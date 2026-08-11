import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/data/repositories/local_sms_repository.dart';
import 'package:my_budget_client/data/seed_data/sms_preset_defaults.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:my_budget_client/domain/repositories/sms_repository.dart'
    show SmsMessage;
import 'package:shared_preferences/shared_preferences.dart';

/// The SMS repository is the odd one out: it stores its presets in
/// SharedPreferences as JSON rather than in the database, behind a memory
/// cache. So what is pinned here is the JSON round-trip, the cache, what
/// survives a restart (a new repository instance) and what silently does not.
///
/// These tests run on the desktop test VM, where `AppPlatform.isAndroid` is
/// false - which is itself part of the contract: the reader has to degrade to
/// empty results instead of throwing on a missing plugin.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  SmsPreset builtIn() => SmsPresetDefaults.getBuiltInPresets().single;

  SmsPreset custom({
    String id = 'custom-1',
    String name = 'My bank',
    bool isEnabled = true,
  }) => SmsPreset(
    id: id,
    name: name,
    senderFilter: 'MYBANK',
    isEnabled: isEnabled,
    rules: const [
      SmsParsingRule(
        id: 'r1',
        type: TransactionType.income,
        matchPattern: 'credited',
        amountPattern: r'([\d.]+)',
        currencyPattern: r'(\w{3})',
        datePattern: 'on (.*)',
        categoryId: 'cat-1',
      ),
    ],
    categoryKeywords: const [
      SmsCategoryKeyword(keyword: 'lidl', categoryId: 'cat-food'),
    ],
  );

  group('presets out of the box', () {
    test('the built-in preset is returned when nothing has been '
        'stored', () async {
      final repo = LocalSmsRepository();

      final presets = await repo.getAllPresets();

      expect(presets.map((p) => p.id).toList(), ['alta_bank']);
      expect(presets.single.isBuiltIn, isTrue);
    });

    test('the built-in preset ships disabled, so no SMS is parsed until the '
        'user opts in', () async {
      // Reading a user's messages without being asked is exactly the surprise
      // this default prevents.
      final repo = LocalSmsRepository();

      expect(await repo.getEnabledPresets(), isEmpty);
    });

    test('unreadable stored JSON falls back to the built-ins instead of '
        'throwing', () async {
      SharedPreferences.setMockInitialValues({'sms_presets': 'not json'});
      final repo = LocalSmsRepository();

      expect(await repo.getAllPresets(), [builtIn()]);
    });
  });

  group('saving presets', () {
    test('a saved custom preset is returned alongside the built-in '
        'ones', () async {
      final repo = LocalSmsRepository();

      await repo.savePreset(custom());

      final ids = (await repo.getAllPresets()).map((p) => p.id);
      expect(ids, containsAll(['alta_bank', 'custom-1']));
    });

    test('a custom preset survives a restart with its rules and keywords '
        'intact', () async {
      // "Restart" is a second repository instance: the cache is per-instance,
      // so this is what the user gets after closing the app.
      await LocalSmsRepository().savePreset(custom());

      final reloaded = (await LocalSmsRepository().getAllPresets())
          .firstWhere((p) => p.id == 'custom-1');

      expect(reloaded.name, 'My bank');
      expect(reloaded.senderFilter, 'MYBANK');
      expect(reloaded.rules.single.id, 'r1');
      expect(reloaded.rules.single.type, TransactionType.income);
      expect(reloaded.rules.single.matchPattern, 'credited');
      expect(reloaded.rules.single.amountPattern, r'([\d.]+)');
      expect(reloaded.rules.single.currencyPattern, r'(\w{3})');
      expect(reloaded.rules.single.datePattern, 'on (.*)');
      expect(reloaded.rules.single.categoryId, 'cat-1');
      expect(reloaded.categoryKeywords.single.keyword, 'lidl');
      expect(reloaded.categoryKeywords.single.categoryId, 'cat-food');
    });

    test('saving the same preset id twice replaces it instead of adding a '
        'second copy', () async {
      final repo = LocalSmsRepository();

      await repo.savePreset(custom(name: 'First'));
      await repo.savePreset(custom(name: 'Second'));

      final matching = (await repo.getAllPresets()).where(
        (p) => p.id == 'custom-1',
      );
      expect(matching, hasLength(1));
      expect(matching.single.name, 'Second');
    });

    test('an unknown rule type in stored JSON reads back as an expense rather '
        'than failing the whole load', () async {
      final stored = [
        {
          'id': 'custom-1',
          'name': 'My bank',
          'senderFilter': 'MYBANK',
          'isBuiltIn': false,
          'isEnabled': true,
          'rules': [
            {
              'id': 'r1',
              'type': 'refund',
              'matchPattern': 'x',
              'amountPattern': 'y',
            },
          ],
        },
      ];
      SharedPreferences.setMockInitialValues({
        'sms_presets': jsonEncode(stored),
      });

      final preset = (await LocalSmsRepository().getAllPresets()).firstWhere(
        (p) => p.id == 'custom-1',
      );

      expect(preset.rules.single.type, TransactionType.expense);
    });

    test('CHARACTERIZATION: an edit to a built-in preset\'s name or rules is '
        'thrown away on the next load', () async {
      // BUG. `LocalSmsRepository.getAllPresets` rebuilds every built-in from
      // `SmsPresetDefaults` and copies only isEnabled, defaultAccountId and
      // defaultCategoryId off the stored copy. Everything else the user edited
      // - name, senderFilter, rules, categoryKeywords - is discarded, silently
      // and only after a restart, so the preset screen shows the edit as saved
      // until the app is reopened. Trigger: edit the Alta_Bank preset's
      // matchPattern because the bank changed its SMS wording, restart, and it
      // is back to the old pattern with the transactions no longer matching.
      // Correct behaviour: merge on top of the stored preset (using the
      // built-in only for fields the stored copy does not have), or mark
      // user-edited built-ins as custom.
      final edited = builtIn().copyWith(
        name: 'Renamed',
        rules: [
          const SmsParsingRule(
            id: 'edited',
            type: TransactionType.expense,
            matchPattern: 'new wording',
            amountPattern: r'([\d.]+)',
          ),
        ],
      );
      await LocalSmsRepository().savePreset(edited);

      final reloaded = (await LocalSmsRepository().getAllPresets()).firstWhere(
        (p) => p.id == 'alta_bank',
      );

      expect(reloaded.name, 'Alta_Bank');
      expect(reloaded.rules.first.id, isNot('edited'));
    });

    test('the default account and category chosen for a built-in preset do '
        'survive a restart', () async {
      // The counterpart to the characterization above: these three fields are
      // the ones getAllPresets carries over, and the import flow depends on
      // them.
      await LocalSmsRepository().savePreset(
        builtIn().copyWith(
          isEnabled: true,
          defaultAccountId: 'acc-1',
          defaultCategoryId: 'cat-1',
        ),
      );

      final reloaded = (await LocalSmsRepository().getAllPresets()).firstWhere(
        (p) => p.id == 'alta_bank',
      );

      expect(reloaded.isEnabled, isTrue);
      expect(reloaded.defaultAccountId, 'acc-1');
      expect(reloaded.defaultCategoryId, 'cat-1');
    });
  });

  group('enabling and deleting', () {
    test('togglePreset enables a preset and the choice survives a '
        'restart', () async {
      await LocalSmsRepository().togglePreset('alta_bank', true);

      final reloaded = await LocalSmsRepository().getEnabledPresets();
      expect(reloaded.map((p) => p.id), ['alta_bank']);
    });

    test('togglePreset can disable a preset again', () async {
      final repo = LocalSmsRepository();
      await repo.togglePreset('alta_bank', true);

      await repo.togglePreset('alta_bank', false);

      expect(await repo.getEnabledPresets(), isEmpty);
    });

    test('toggling an id that does not exist changes nothing', () async {
      final repo = LocalSmsRepository();

      await repo.togglePreset('ghost', true);

      expect(await repo.getEnabledPresets(), isEmpty);
    });

    test('deletePreset removes a custom preset for good', () async {
      final repo = LocalSmsRepository();
      await repo.savePreset(custom());

      await repo.deletePreset('custom-1');

      expect(await repo.getAllPresets(), hasLength(1));
      expect(
        (await LocalSmsRepository().getAllPresets()).map((p) => p.id),
        isNot(contains('custom-1')),
      );
    });

    test('deletePreset refuses to remove a built-in preset', () async {
      // Built-ins are recreated from code on every load, so "deleting" one
      // would only make it come back - the repository keeps it instead.
      final repo = LocalSmsRepository();

      await repo.deletePreset('alta_bank');

      expect((await repo.getAllPresets()).map((p) => p.id), ['alta_bank']);
    });

    test('deleting one custom preset leaves the others alone', () async {
      final repo = LocalSmsRepository();
      await repo.savePreset(custom(id: 'custom-1'));
      await repo.savePreset(custom(id: 'custom-2'));

      await repo.deletePreset('custom-1');

      expect(
        (await repo.getAllPresets()).map((p) => p.id),
        containsAll(['alta_bank', 'custom-2']),
      );
    });
  });

  group('caching', () {
    test('presets are read from storage once and served from memory after '
        'that', () async {
      // Pinned because it is the reason every other test here builds a new
      // repository to check persistence: a write made behind the repository's
      // back is not picked up.
      final repo = LocalSmsRepository();
      await repo.getAllPresets();

      SharedPreferences.setMockInitialValues({
        'sms_presets': jsonEncode([
          {
            'id': 'sneaky',
            'name': 'Sneaky',
            'senderFilter': 'S',
            'isBuiltIn': false,
            'isEnabled': true,
          },
        ]),
      });

      expect((await repo.getAllPresets()).map((p) => p.id), ['alta_bank']);
    });

    test('clearData drops both the stored presets and the cache', () async {
      final repo = LocalSmsRepository();
      await repo.savePreset(custom());

      await repo.clearData();

      expect((await repo.getAllPresets()).map((p) => p.id), ['alta_bank']);
      expect(
        (await LocalSmsRepository().getAllPresets()).map((p) => p.id),
        ['alta_bank'],
      );
    });
  });

  group('last sync timestamp', () {
    test('is null until a sync has happened', () async {
      expect(await LocalSmsRepository().getLastSyncTimestamp(), isNull);
    });

    test('round-trips with millisecond precision', () async {
      // The value is used as an exclusive lower bound when re-reading the
      // inbox, so a rounded timestamp would re-import or skip messages.
      final stamp = DateTime.fromMillisecondsSinceEpoch(1715000000123);
      final repo = LocalSmsRepository();

      await repo.setLastSyncTimestamp(stamp);

      expect(await repo.getLastSyncTimestamp(), stamp);
      expect(await LocalSmsRepository().getLastSyncTimestamp(), stamp);
    });

    test('a later sync overwrites the earlier timestamp', () async {
      final repo = LocalSmsRepository();
      await repo.setLastSyncTimestamp(DateTime(2024, 1, 1));

      await repo.setLastSyncTimestamp(DateTime(2024, 6, 1));

      expect(await repo.getLastSyncTimestamp(), DateTime(2024, 6, 1));
    });

    test('clearData forgets the last sync timestamp, so the next import '
        'starts from scratch', () async {
      final repo = LocalSmsRepository();
      await repo.setLastSyncTimestamp(DateTime(2024, 1, 1));

      await repo.clearData();

      expect(await repo.getLastSyncTimestamp(), isNull);
    });
  });

  group('off Android', () {
    test('reading messages returns an empty list instead of throwing on the '
        'missing platform channel', () async {
      expect(await LocalSmsRepository().getSmsMessages(), isEmpty);
    });

    test('permission is reported as not granted rather than asked '
        'for', () async {
      final repo = LocalSmsRepository();

      expect(await repo.hasSmsPermission(), isFalse);
      expect(await repo.requestSmsPermission(), isFalse);
    });

    test('the incoming-message stream exists but stays silent', () async {
      final repo = LocalSmsRepository();

      expect(repo.listenForSms(), isA<Stream<SmsMessage>>());
      expect(
        await repo.listenForSms().isEmpty.timeout(
          const Duration(milliseconds: 200),
          onTimeout: () => true,
        ),
        isTrue,
      );
    });
  });
}
