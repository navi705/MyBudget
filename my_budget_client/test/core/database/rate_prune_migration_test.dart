import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/database/app_database.dart'
    hide Transaction;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

/// The v22 -> v23 step: rates for currencies nobody holds are dropped.
///
/// The bundled history used to be every currency the data set publishes, for
/// every day since 2024-04-01 - ~283 000 rows carried by a device that
/// converts between two of them. The asset now ships the last 30 days and the
/// server answers for the rest, so the rows for currencies nothing references
/// are dead weight in every query that scans the table.
///
/// The fixture is a real file, because the migration has to be observed by a
/// second connection opening a database whose `user_version` is behind.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File file;

  /// Days a bulk write covers. The seed is recognised by its shape - one
  /// `modified_at` shared by a thousand rows or more - so the fixture has to
  /// be that big to be recognised as one.
  const seededRowCount = 1200;

  const serverStamp = 1770000000;
  const seedStamp = 1760000000;
  const manualStamp = 1750000000;

  /// Builds a device at v23, seeds it, then winds `user_version` back so the
  /// next open runs the step under test against real data.
  Future<void> buildFixture(void Function(sqlite3.Database raw) seed) async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    await db.customSelect('SELECT 1').get();
    await db.delete(db.exchangeRates).go();
    await db.close();

    final raw = sqlite3.sqlite3.open(file.path);
    seed(raw);
    raw.execute('PRAGMA user_version = 22;');
    raw.dispose();
  }

  /// `to` codes still in the table after the upgrade.
  Future<Set<String>> survivorsAfterUpgrade() async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final rows = await db.exchangeRatesDao.getAllExchangesRatesAll();
    final version = await db.customSelect('PRAGMA user_version').getSingle();
    expect(version.data['user_version'], db.schemaVersion);
    await db.close();
    return rows.map((r) => r.toCurrencyCode).toSet();
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mybudget_rate_prune_test');
    file = File('${tempDir.path}/v22.sqlite');
  });

  tearDown(() {
    // Windows keeps a handle on a database file a failed test left open; the
    // fixture is a temp directory either way and losing it is not a failure.
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } on FileSystemException {
      // Nothing to do about it here.
    }
  });

  /// A device whose owner holds RUB, whose main currency is USD, and which
  /// carries published rates for two currencies it has no use for.
  void seedTypicalDevice(sqlite3.Database raw) {
    raw.execute('''
      UPDATE settings SET value = 'USD' WHERE key = 'main_currency_code';
      INSERT OR REPLACE INTO settings (key, value) VALUES ('main_currency_code', 'USD');
      INSERT INTO accounts (id, name, balance, opening_balance, currency_code,
                            currency_designation_id, account_type_id, creation_date)
        SELECT 'acc-rub', 'Rub Wallet', 0, 0, 'RUB',
               (SELECT id FROM currency_designations LIMIT 1),
               (SELECT id FROM account_types LIMIT 1),
               0;
    ''');

    // Published rows, the kind the server hands over and the kind the fetch
    // stores. Two of them are for currencies this device references.
    for (final code in ['USD', 'RUB', 'JPY', 'CHF']) {
      raw.execute(
        "INSERT INTO exchange_rates (from_currency_code, to_currency_code, "
        "rate, preset, date, modified_at, device_id) "
        "VALUES ('EUR', ?, 1.1, 1, 1773446400000, $serverStamp, "
        "'$kServerRateDeviceId')",
        [code],
      );
    }
  }

  test('keeps what the device references and drops the rest', () async {
    await buildFixture(seedTypicalDevice);

    // EUR survives as the base every rate is quoted against, USD as the main
    // currency, RUB because an account holds it.
    expect(await survivorsAfterUpgrade(), {'USD', 'RUB'});
  });

  test('a rate the user typed is never touched', () async {
    // A hand-entered or hand-corrected rate is the one row here that cannot
    // be fetched again, so it is not enough for its currency to be unused -
    // it has to carry the mark of a bulk write or a server fetch as well.
    await buildFixture((raw) {
      seedTypicalDevice(raw);
      raw.execute(
        "INSERT INTO exchange_rates (from_currency_code, to_currency_code, "
        "rate, preset, date, modified_at, device_id) "
        "VALUES ('EUR', 'JPY', 99.0, 1, 1773360000000, $manualStamp, "
        "'this-device')",
      );
    });

    final db = AppDatabase.forTesting(NativeDatabase(file));
    final kept = await db.exchangeRatesDao.getAllExchangesRatesAll();
    await db.close();

    final jpy = kept.where((r) => r.toCurrencyCode == 'JPY');
    expect(jpy.single.rate, 99.0);
  });

  test('the bundled seed is recognised by its shape and pruned', () async {
    // The seed writes a whole day at once, so every row of it shares one
    // `modified_at`. That is what separates it from anything a person did.
    await buildFixture((raw) {
      seedTypicalDevice(raw);
      final statement = raw.prepare(
        'INSERT INTO exchange_rates (from_currency_code, to_currency_code, '
        'rate, preset, date, modified_at) VALUES (?, ?, ?, 1, ?, $seedStamp)',
      );
      for (var i = 0; i < seededRowCount; i++) {
        statement.execute([
          'EUR',
          'CHF',
          0.95,
          // Past the day seedTypicalDevice already wrote CHF on.
          1773532800000 + i * 86400000,
        ]);
      }
      statement.dispose();
    });

    expect(await survivorsAfterUpgrade(), {'USD', 'RUB'});
  });

  test('leaves nothing queued for a row it deleted', () async {
    // A queue entry is a note saying "the server has not been told about this
    // row". Deleting the row without the note leaves the push looking for a
    // row that is not there.
    await buildFixture((raw) {
      seedTypicalDevice(raw);
      raw.execute(
        "INSERT INTO sync_push_queue (changed_table_name, record_key) "
        "SELECT 'exchange_rates', "
        "from_currency_code || '|' || to_currency_code || '|' || date || '|' "
        "|| preset FROM exchange_rates",
      );
    });

    final db = AppDatabase.forTesting(NativeDatabase(file));
    final queued = await db
        .customSelect(
          "SELECT record_key FROM sync_push_queue "
          "WHERE changed_table_name = 'exchange_rates'",
        )
        .get();
    await db.close();

    final keys = queued.map((r) => r.data['record_key'] as String);
    expect(keys.where((k) => k.contains('JPY')), isEmpty);
    expect(keys.where((k) => k.contains('CHF')), isEmpty);
  });

  test('a device that holds nothing keeps its base and main currency',
      () async {
    // A bare install: no accounts, no transactions. It still has to be able to
    // show its own main currency.
    await buildFixture((raw) {
      raw.execute(
        "INSERT OR REPLACE INTO settings (key, value) "
        "VALUES ('main_currency_code', 'GBP')",
      );
      for (final code in ['GBP', 'JPY']) {
        raw.execute(
          "INSERT INTO exchange_rates (from_currency_code, to_currency_code, "
          "rate, preset, date, modified_at, device_id) "
          "VALUES ('EUR', ?, 1.1, 1, 1773446400000, $serverStamp, "
          "'$kServerRateDeviceId')",
          [code],
        );
      }
    });

    expect(await survivorsAfterUpgrade(), {'GBP'});
  });
}
