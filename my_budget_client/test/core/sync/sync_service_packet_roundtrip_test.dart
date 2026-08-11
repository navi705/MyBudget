import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/core/sync/sync_service.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/icon_type.dart';

/// End-to-end packet round trip: one representative row per table the P2P
/// binary format carries, written on device A, exported to a shared folder,
/// imported into a completely separate in-memory DB for device B, then
/// compared field for field.
///
/// A packet that silently drops a column is the most expensive bug this
/// layer can have (it looks like a successful sync while quietly corrupting
/// data), so every field the sync engine's own `_xToJson`/`_xFromJson`
/// mappers claim to carry (see sync_service_io.dart) is asserted here,
/// including fields deliberately left null.
///
/// The exact minor units (`Transactions.amountMinor`, `Transactions.feeMinor`,
/// `Accounts.balanceMinor`) get particular attention: they are the money the
/// fiat side of the app actually sums, they are nullable with no default, and
/// the peer applies a packet with `InsertMode.insertOrReplace`, so any key the
/// packet does not carry lands on the peer as NULL - a silent downgrade to the
/// legacy double that no other assertion in this file would catch.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory syncFolder;
  late AppDatabase dbA;
  late AppDatabase dbB;
  late SyncService serviceA;
  late SyncService serviceB;

  Future<void> setDeviceId(AppDatabase db, String id) => db.settingsDao
      .setSetting(SettingsCompanion(key: const Value('local_device_id'), value: Value(id)));

  Future<SyncService> configuredService(AppDatabase db, String deviceId) async {
    await setDeviceId(db, deviceId);
    final service = SyncService(db);
    await service.startSync(syncFolder.path);
    await service.stopSync();
    return service;
  }

  // setUpAll, not setUp: the DB seeds hundreds of thousands of exchange rate
  // rows on every AppDatabase.forTesting() call, and exportNow() walks every
  // pending sync_log row (seeded data included) to build a packet - see the
  // REPORT for the production performance bug this exposes. None of the
  // tests below mutate dbA/dbB, so one shared setup for the whole file keeps
  // this suite's runtime sane instead of paying that cost 11 times over.
  setUpAll(() async {
    syncFolder = await Directory.systemTemp.createTemp('mybudget_sync_roundtrip_');
    dbA = AppDatabase.forTesting(NativeDatabase.memory());
    dbB = AppDatabase.forTesting(NativeDatabase.memory());
    serviceA = await configuredService(dbA, 'device-a');
    serviceB = await configuredService(dbB, 'device-b');

    // --- Reference rows on A, needed as FK targets for accounts/transactions.
    // (FK checks are OFF while B applies an imported packet and SQLite does
    // not re-validate existing rows when they are turned back ON, so these
    // ids do not need to exist on B - only on A, where the rows are read from
    // before being serialized.)
    final accountTypeId = (await dbA.select(dbA.accountTypes).get()).first.id;

    await dbA.stylesDao.insertStyle(
      StylesCompanion.insert(
        id: const Value('style1'),
        name: 'Style One',
        iconName: 'heart',
        colorHex: '#FF00FF',
        iconType: Value(IconType.custom),
      ),
    );

    await dbA.categoriesDao.insertCategory(
      CategoriesCompanion.insert(
        id: const Value('cat1'),
        name: 'Cat One',
        type: const Value(CategoryType.income),
      ),
    );

    await dbA.accountTypesDao.insertAccountType(
      AccountTypesCompanion.insert(
        id: const Value('at1'),
        name: 'AT One',
        languageCode: 'en',
      ),
    );

    await dbA.currencyDesignationsDao.insertDesignation(
      CurrencyDesignationsCompanion.insert(
        id: const Value('cd_usd'),
        value: r'$',
        currencyCode: 'USD',
      ),
    );
    await dbA.currencyDesignationsDao.insertDesignation(
      CurrencyDesignationsCompanion.insert(
        id: const Value('cd_btc'),
        value: '₿',
        currencyCode: 'BTC',
      ),
    );

    await dbA.customDataSourcesDao.insertDataSource(
      CustomDataSourcesCompanion.insert(
        id: const Value('cds1'),
        name: 'Src One',
        url: 'https://example.com/api',
        dataType: 2,
        enabled: const Value(false),
        autoFetch: const Value(true),
        lastFetchAt: const Value(1700000000000),
      ),
    );

    await dbA.apiSettingsDao.upsertSetting(
      ApiSettingsTableCompanion.insert(
        id: 'api1',
        enabled: const Value(false),
        autoFetch: const Value(true),
        lastFetchAt: const Value(1600000000000),
      ),
    );

    await dbA.assetEntriesDao.addAssetData(
      AssetEntriesCompanion.insert(
        id: const Value('ae1'),
        assetId: 'BTC-HOLD',
        name: 'My BTC',
        date: DateTime(2024, 2, 2),
        value: 1.2345,
        currencyCode: 'BTC',
        source: 'Manual',
        quantity: const Value(0.5),
        assetType: const Value('crypto'),
        description: const Value('desc here'),
        preset: const Value(2),
      ),
    );

    await dbA.accountsDao.insertAccount(
      AccountsCompanion.insert(
        id: const Value('acc_fiat'),
        name: 'Fiat Acc',
        balance: 100.5,
        currencyCode: 'USD',
        currencyDesignationId: 'cd_usd',
        accountTypeId: accountTypeId,
        description: const Value('desc'),
        balanceMinor: const Value(10050), // $100.50 in exact cents.
        styleId: const Value('style1'),
        creationDate: Value(DateTime(2023, 5, 5)),
        country: const Value('US'),
        assetQuantity: const Value(0.0),
        feeStructure: const Value('{"type":"flat"}'),
      ),
    );

    await dbA.accountsDao.insertAccount(
      AccountsCompanion.insert(
        id: const Value('acc_crypto'),
        name: 'Crypto Acc',
        balance: 0.75,
        currencyCode: 'BTC',
        currencyDesignationId: 'cd_btc',
        accountTypeId: accountTypeId,
        // balanceMinor intentionally absent: crypto accounts have no minor units.
        creationDate: Value(DateTime(2023, 6, 6)),
        assetId: const Value('BTC'),
        assetQuantity: const Value(0.75),
      ),
    );

    await dbA.transactionsDao.insertTransaction(
      TransactionsCompanion.insert(
        id: const Value('tx_fiat'),
        description: 'Coffee',
        amount: 12.34,
        date: DateTime(2024, 3, 3),
        accountId: 'acc_fiat',
        categoryId: 'cat1',
        currencyCode: 'USD',
        amountMinor: const Value(1234), // $12.34 in exact cents.
        fee: const Value(0.5),
        feeMinor: const Value(50), // $0.50 in exact cents.
      ),
    );

    await dbA.transactionsDao.insertTransaction(
      TransactionsCompanion.insert(
        id: const Value('tx_crypto'),
        description: 'Buy BTC',
        amount: 0.001,
        date: DateTime(2024, 3, 4),
        accountId: 'acc_crypto',
        categoryId: 'cat1',
        currencyCode: 'BTC',
        // amountMinor/feeMinor intentionally absent: crypto has no minor units.
        exchangeRate: const Value(45000.12),
        exchangeRatePreset: const Value(3),
        fee: const Value(0.0),
      ),
    );

    await serviceA.exportNow();
    await serviceB.importNow();
  });

  tearDownAll(() async {
    await dbA.close();
    await dbB.close();
    if (await syncFolder.exists()) {
      await syncFolder.delete(recursive: true);
    }
  });

  test('style round trips every field, including enum and null deviceId', () async {
    final onA = await dbA.stylesDao.getStyleById('style1');
    final onB = await dbB.stylesDao.getStyleById('style1');
    expect(onB, isNot(null));
    expect(onB!.name, 'Style One');
    expect(onB.iconName, 'heart');
    expect(onB.colorHex, '#FF00FF');
    expect(onB.iconType, IconType.custom);
    expect(onB.isDeleted, isFalse);
    expect(onB.deviceId, null);
    expect(onB.modifiedAt, onA!.modifiedAt);
  });

  test('category round trips including null parentId/styleId and non-default type', () async {
    final onA = await dbA.categoriesDao.getCategoryById('cat1');
    final onB = await dbB.categoriesDao.getCategoryById('cat1');
    expect(onB, isNot(null));
    expect(onB!.name, 'Cat One');
    expect(onB.parentId, null);
    expect(onB.styleId, null);
    expect(onB.type, CategoryType.income);
    expect(onB.modifiedAt, onA!.modifiedAt);
  });

  test('account type round trips', () async {
    final onB = await dbB.accountTypesDao.getAccountTypeById('at1');
    expect(onB, isNot(null));
    expect(onB!.name, 'AT One');
    expect(onB.languageCode, 'en');
  });

  test('currency designation round trips', () async {
    final onB = await dbB.currencyDesignationsDao.getDesignationById('cd_usd');
    expect(onB, isNot(null));
    expect(onB!.value, r'$');
    expect(onB.currencyCode, 'USD');
  });

  test('custom data source round trips including non-default bools and lastFetchAt', () async {
    final onB = await dbB.customDataSourcesDao.getDataSourceById('cds1');
    expect(onB, isNot(null));
    expect(onB!.name, 'Src One');
    expect(onB.url, 'https://example.com/api');
    expect(onB.dataType, 2);
    expect(onB.enabled, isFalse);
    expect(onB.autoFetch, isTrue);
    expect(onB.lastFetchAt, 1700000000000);
  });

  test('api setting round trips (no isDeleted column on this table)', () async {
    final onB = await dbB.apiSettingsDao.getSettingById('api1');
    expect(onB, isNot(null));
    expect(onB!.enabled, isFalse);
    expect(onB.autoFetch, isTrue);
    expect(onB.lastFetchAt, 1600000000000);
  });

  test('asset entry round trips including optional fields and null accountId', () async {
    final onB = await dbB.assetEntriesDao.getAssetEntryById('ae1');
    expect(onB, isNot(null));
    expect(onB!.assetId, 'BTC-HOLD');
    expect(onB.name, 'My BTC');
    expect(onB.date, DateTime(2024, 2, 2));
    expect(onB.value, 1.2345);
    expect(onB.quantity, 0.5);
    expect(onB.assetType, 'crypto');
    expect(onB.description, 'desc here');
    expect(onB.currencyCode, 'BTC');
    expect(onB.accountId, null);
    expect(onB.source, 'Manual');
    expect(onB.preset, 2);
  });

  test('fiat account round trips all fields including exact balanceMinor', () async {
    final onA = await dbA.accountsDao.getAccountById('acc_fiat');
    final onB = await dbB.accountsDao.getAccountById('acc_fiat');
    expect(onB, isNot(null));
    expect(onB!.name, 'Fiat Acc');
    expect(onB.description, 'desc');
    expect(onB.balance, 100.5);
    expect(onB.currencyCode, 'USD');
    expect(onB.currencyDesignationId, 'cd_usd');
    expect(onB.accountTypeId, onA!.accountTypeId);
    expect(onB.styleId, 'style1');
    expect(onB.creationDate, DateTime(2023, 5, 5));
    expect(onB.country, 'US');
    expect(onB.assetId, null);
    expect(onB.assetQuantity, 0.0);
    expect(onB.feeStructure, '{"type":"flat"}');
    expect(onB.modifiedAt, onA.modifiedAt);
    expect(onA.balanceMinor, 10050);
    expect(
      onB.balanceMinor,
      10050,
      reason: 'exact cents must survive the packet, not decay to NULL',
    );
  });

  test('crypto account round trips with balanceMinor genuinely null on both ends', () async {
    final onA = await dbA.accountsDao.getAccountById('acc_crypto');
    final onB = await dbB.accountsDao.getAccountById('acc_crypto');
    expect(onB, isNot(null));
    expect(onB!.name, 'Crypto Acc');
    expect(onB.balance, 0.75);
    expect(onB.currencyCode, 'BTC');
    expect(onB.currencyDesignationId, 'cd_btc');
    expect(onB.styleId, null);
    expect(onB.assetId, 'BTC');
    expect(onB.assetQuantity, 0.75);
    // A crypto account's minor column is NULL by design: the double is its
    // source of truth, and the packet must not turn that into a number.
    expect(onA!.balanceMinor, null);
    expect(onB.balanceMinor, null);
  });

  test('fiat transaction round trips all fields including exact amountMinor/feeMinor', () async {
    final onA = await dbA.transactionsDao.getTransactionById('tx_fiat');
    final onB = await dbB.transactionsDao.getTransactionById('tx_fiat');
    expect(onB, isNot(null));
    expect(onB!.description, 'Coffee');
    expect(onB.amount, 12.34);
    expect(onB.date, DateTime(2024, 3, 3));
    expect(onB.accountId, 'acc_fiat');
    expect(onB.categoryId, 'cat1');
    expect(onB.currencyCode, 'USD');
    expect(onB.exchangeRate, null);
    expect(onB.exchangeRatePreset, null);
    expect(onB.fee, 0.5);
    expect(onB.linkedTransactionId, null);
    expect(onB.modifiedAt, onA!.modifiedAt);
    expect(onA.amountMinor, 1234);
    expect(onA.feeMinor, 50);
    expect(
      onB.amountMinor,
      1234,
      reason: 'exact cents must survive the packet, not decay to NULL',
    );
    expect(onB.feeMinor, 50);
  });

  test('crypto transaction round trips with amountMinor/feeMinor genuinely null on both ends', () async {
    final onA = await dbA.transactionsDao.getTransactionById('tx_crypto');
    final onB = await dbB.transactionsDao.getTransactionById('tx_crypto');
    expect(onB, isNot(null));
    expect(onB!.amount, 0.001);
    expect(onB.currencyCode, 'BTC');
    expect(onB.exchangeRate, 45000.12);
    expect(onB.exchangeRatePreset, 3);
    expect(onB.fee, 0.0);
    expect(onA!.amountMinor, null);
    expect(onA.feeMinor, null);
    expect(onB.amountMinor, null);
    expect(onB.feeMinor, null);
  });
}
