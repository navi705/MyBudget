import 'package:postgres/postgres.dart';
import 'package:my_budget_server/data/database_client.dart';

class SyncRepository {
  final DatabaseClient _dbClient;

  SyncRepository(this._dbClient);

  /// Arbitrary constant identifying the push lock. Any value works as long as
  /// every push uses the same one and nothing else in the database picks it.
  static const int _pushLockId = 795118301;

  Future<void> upsertBatch(Map<String, dynamic> data) async {
    final tablesList = [
      'settings',
      'api_settings',
      'languages',
      'currencies',
      'styles',
      'custom_themes',
      'account_types',
      'currency_designations',
      'categories',
      'exchange_rates',
      'inflation_rates',
      'custom_data_sources',
      'sms_presets',
      // Dependent tables last
      'accounts',
      'asset_entries',
      'transactions',
    ];

    // Optimization: Use bulk upsert for tables with >50 rows to reduce N+1 queries
    final bulkUpsertTables = {
      'exchange_rates',
      'inflation_rates',
      'categories',
      'transactions',
      'accounts',
    };

    // runTx (not run): a batch must be all-or-nothing. `pool.run` is not a
    // transaction, so a mid-batch failure left rows partially applied and
    // visible to concurrent pulls.
    await _dbClient.pool.runTx((session) async {
      // Serialise pushes against each other so that `server_seq` order and
      // commit order agree.
      //
      // The sequence is read when a row is written, not when the transaction
      // commits. Two overlapping pushes can therefore take seq 100 and 101 and
      // commit in the opposite order; a pull landing in between sees 101, moves
      // its cursor past it, and never sees row 100. That is the same permanent
      // skip the cursor rewrite exists to remove, so the writes are serialised
      // instead. Pulls are read-only and never wait on this.
      await session.execute(Sql.named('SELECT pg_advisory_xact_lock(@lockId)'),
          parameters: {'lockId': _pushLockId});

      for (final table in tablesList) {
        if (data.containsKey(table)) {
          final rows = data[table] as List;

          if (rows.length > 50 && bulkUpsertTables.contains(table)) {
            // Use bulk upsert for large tables to reduce query count
            await _bulkUpsert(
                session, table, rows.cast<Map<String, dynamic>>());
          } else {
            for (final row in rows) {
              await _upsertRow(session, table, row as Map<String, dynamic>);
            }
          }
        }
      }
    });
  }

  Future<void> _upsertRow(
      Session session, String table, Map<String, dynamic> row) async {
    switch (table) {
      case 'categories':
        await _upsertCategory(session, row);
        break;
      case 'transactions':
        await _upsertTransaction(session, row);
        break;
      case 'accounts':
        await _upsertAccount(session, row);
        break;
      case 'styles':
        await _upsertStyle(session, row);
        break;
      case 'asset_entries':
        await _upsertAssetEntry(session, row);
        break;
      case 'account_types':
        await _upsertAccountType(session, row);
        break;
      case 'currency_designations':
        await _upsertCurrencyDesignation(session, row);
        break;
      case 'custom_data_sources':
        await _upsertCustomDataSource(session, row);
        break;
      case 'api_settings':
        await _upsertApiSetting(session, row);
        break;
      case 'sms_presets':
        await _upsertSmsPreset(session, row);
        break;
      case 'settings':
        await _upsertSetting(session, row);
        break;
      case 'exchange_rates':
        await _upsertExchangeRate(session, row);
        break;
      case 'inflation_rates':
        await _upsertInflationRate(session, row);
        break;
      case 'custom_themes':
        await _upsertCustomTheme(session, row);
        break;
      case 'languages':
        await _upsertLanguage(session, row);
        break;
      case 'currencies':
        await _upsertCurrency(session, row);
        break;
    }
  }

  Future<void> _bulkUpsert(
      Session session, String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;

    if (table == 'exchange_rates') {
      await _bulkUpsertExchangeRates(session, rows);
    } else if (table == 'inflation_rates') {
      await _bulkUpsertInflationRates(session, rows);
    } else if (table == 'categories') {
      await _bulkUpsertCategories(session, rows);
    } else if (table == 'transactions') {
      await _bulkUpsertTransactions(session, rows);
    } else if (table == 'accounts') {
      await _bulkUpsertAccounts(session, rows);
    }
  }

  Future<void> _bulkUpsertExchangeRates(
      Session session, List<Map<String, dynamic>> rows) async {
    // date is part of the primary key: a row without a usable one cannot be
    // stored at all, so skip it instead of inventing a timestamp.
    final validRows = rows.where((row) {
      if (_parseDate(row['date']) != null) return true;
      print(
          '[SYNC] Skipping exchange_rate ${row['fromCurrencyCode']}->${row['toCurrencyCode']}: missing or unparseable date (${row['date']})');
      return false;
    }).toList();
    if (validRows.isEmpty) return;

    const subBatchSize = 1000;
    for (var i = 0; i < validRows.length; i += subBatchSize) {
      final end = (i + subBatchSize < validRows.length)
          ? i + subBatchSize
          : validRows.length;
      final chunk = validRows.sublist(i, end);

      final buffer = StringBuffer();
      buffer.write(
          'INSERT INTO exchange_rates (from_currency_code, to_currency_code, rate, preset, date, modified_at, device_id, source_id) VALUES ');

      final params = <String, dynamic>{};
      for (var j = 0; j < chunk.length; j++) {
        final row = chunk[j];
        if (j > 0) buffer.write(', ');
        final suffix = '_$j';
        buffer.write(
            '(@fcc$suffix, @tcc$suffix, @rate$suffix, @preset$suffix, @date$suffix, @ma$suffix, @did$suffix, @sid$suffix)');
        params['fcc$suffix'] = row['fromCurrencyCode'];
        params['tcc$suffix'] = row['toCurrencyCode'];
        params['rate$suffix'] = _round(row['rate']);
        params['preset$suffix'] = row['preset'];
        params['date$suffix'] = _parseDate(row['date']);
        params['ma$suffix'] = row['modifiedAt'];
        params['did$suffix'] = row['deviceId'];
        params['sid$suffix'] = row['sourceId'];
      }

      buffer.write('''
        ON CONFLICT (from_currency_code, to_currency_code, date, preset) DO UPDATE SET
          rate = EXCLUDED.rate,
          modified_at = EXCLUDED.modified_at,
          device_id = EXCLUDED.device_id,
          source_id = EXCLUDED.source_id
        WHERE EXCLUDED.modified_at > exchange_rates.modified_at
      ''');

      await session.execute(Sql.named(buffer.toString()), parameters: params);
    }
  }

  Future<void> _bulkUpsertInflationRates(
      Session session, List<Map<String, dynamic>> rows) async {
    // date is part of the primary key — skip rows we cannot key.
    final validRows = rows.where((row) {
      if (_parseDate(row['date']) != null) return true;
      print(
          '[SYNC] Skipping inflation_rate for ${row['country']}: missing or unparseable date (${row['date']})');
      return false;
    }).toList();
    if (validRows.isEmpty) return;

    const subBatchSize = 1000;
    for (var i = 0; i < validRows.length; i += subBatchSize) {
      final end = (i + subBatchSize < validRows.length)
          ? i + subBatchSize
          : validRows.length;
      final chunk = validRows.sublist(i, end);

      final buffer = StringBuffer();
      buffer.write(
          'INSERT INTO inflation_rates (date, percent, country, preset, modified_at, device_id, source_id) VALUES ');

      final params = <String, dynamic>{};
      for (var j = 0; j < chunk.length; j++) {
        final row = chunk[j];
        if (j > 0) buffer.write(', ');
        final suffix = '_$j';
        buffer.write(
            '(@date$suffix, @pct$suffix, @cnt$suffix, @pre$suffix, @ma$suffix, @did$suffix, @sid$suffix)');
        params['date$suffix'] = _parseDate(row['date']);
        params['pct$suffix'] = _round(row['percent']);
        params['cnt$suffix'] = row['country'];
        params['pre$suffix'] = row['preset'];
        params['ma$suffix'] = row['modifiedAt'];
        params['did$suffix'] = row['deviceId'];
        params['sid$suffix'] = row['sourceId'];
      }

      buffer.write('''
        ON CONFLICT (date, country, preset) DO UPDATE SET
          percent = EXCLUDED.percent,
          modified_at = EXCLUDED.modified_at,
          device_id = EXCLUDED.device_id,
          source_id = EXCLUDED.source_id
        WHERE EXCLUDED.modified_at > inflation_rates.modified_at
      ''');

      await session.execute(Sql.named(buffer.toString()), parameters: params);
    }
  }

  Future<void> _bulkUpsertCategories(
      Session session, List<Map<String, dynamic>> rows) async {
    const subBatchSize = 1000;
    for (var i = 0; i < rows.length; i += subBatchSize) {
      final end =
          (i + subBatchSize < rows.length) ? i + subBatchSize : rows.length;
      final chunk = rows.sublist(i, end);

      final buffer = StringBuffer();
      buffer.write(
          'INSERT INTO categories (id, name, parent_id, style_id, type, modified_at, device_id, is_deleted) VALUES ');

      final params = <String, dynamic>{};
      for (var j = 0; j < chunk.length; j++) {
        final row = chunk[j];
        if (j > 0) buffer.write(', ');
        final suffix = '_$j';
        buffer.write(
            '(@id$suffix, @name$suffix, @pid$suffix, @sid$suffix, @type$suffix, @ma$suffix, @did$suffix, @del$suffix)');
        params['id$suffix'] = row['id'];
        params['name$suffix'] = row['name'];
        params['pid$suffix'] = row['parentId'];
        params['sid$suffix'] = row['styleId'];
        params['type$suffix'] = row['type'];
        params['ma$suffix'] = row['modifiedAt'];
        params['did$suffix'] = row['deviceId'];
        params['del$suffix'] = row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1);
      }

      buffer.write('''
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          parent_id = EXCLUDED.parent_id,
          style_id = EXCLUDED.style_id,
          type = EXCLUDED.type,
          modified_at = EXCLUDED.modified_at,
          device_id = EXCLUDED.device_id,
          is_deleted = EXCLUDED.is_deleted
        WHERE EXCLUDED.modified_at > categories.modified_at
      ''');

      await session.execute(Sql.named(buffer.toString()), parameters: params);
    }
  }

  Future<void> _bulkUpsertTransactions(
      Session session, List<Map<String, dynamic>> rows) async {
    // A transaction with no usable date cannot be placed on any timeline —
    // skip it rather than stamping it with DateTime.now().
    final validRows = rows.where((row) {
      if (_parseDate(row['date']) != null) return true;
      print(
          '[SYNC] Skipping transaction ${row['id']}: missing or unparseable date (${row['date']})');
      return false;
    }).toList();
    if (validRows.isEmpty) return;

    const subBatchSize = 500;
    for (var i = 0; i < validRows.length; i += subBatchSize) {
      final end = (i + subBatchSize < validRows.length)
          ? i + subBatchSize
          : validRows.length;
      final chunk = validRows.sublist(i, end);

      final buffer = StringBuffer();
      buffer.write(
          'INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code, exchange_rate, exchange_rate_preset, fee, fee_minor, linked_transaction_id, modified_at, device_id, is_deleted) VALUES ');

      final params = <String, dynamic>{};
      for (var j = 0; j < chunk.length; j++) {
        final row = chunk[j];
        if (j > 0) buffer.write(', ');
        final suffix = '_$j';
        buffer.write(
            '(@id$suffix, @desc$suffix, @amt$suffix, @amtm$suffix, @date$suffix, @aid$suffix, @cid$suffix, @cc$suffix, @er$suffix, @erp$suffix, @fee$suffix, @feem$suffix, @lti$suffix, @ma$suffix, @did$suffix, @del$suffix)');
        params['id$suffix'] = row['id'];
        params['desc$suffix'] = row['description'];
        params['amt$suffix'] = _round(row['amount']);
        params['amtm$suffix'] = _minorUnits(row['amountMinor']);
        params['date$suffix'] = _parseDate(row['date']);
        params['aid$suffix'] = row['accountId'];
        params['cid$suffix'] = row['categoryId'];
        params['cc$suffix'] = row['currencyCode'];
        params['er$suffix'] = _round(row['exchangeRate']);
        params['erp$suffix'] = row['exchangeRatePreset'];
        params['fee$suffix'] = _round(row['fee']);
        params['feem$suffix'] = _minorUnits(row['feeMinor']);
        params['lti$suffix'] = row['linkedTransactionId'];
        params['ma$suffix'] = row['modifiedAt'];
        params['did$suffix'] = row['deviceId'];
        params['del$suffix'] = row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1);
      }

      buffer.write('''
        ON CONFLICT (id) DO UPDATE SET
          description = EXCLUDED.description,
          amount = EXCLUDED.amount,
          amount_minor = EXCLUDED.amount_minor,
          date = EXCLUDED.date,
          account_id = EXCLUDED.account_id,
          category_id = EXCLUDED.category_id,
          currency_code = EXCLUDED.currency_code,
          exchange_rate = EXCLUDED.exchange_rate,
          exchange_rate_preset = EXCLUDED.exchange_rate_preset,
          fee = EXCLUDED.fee,
          fee_minor = EXCLUDED.fee_minor,
          linked_transaction_id = EXCLUDED.linked_transaction_id,
          modified_at = EXCLUDED.modified_at,
          device_id = EXCLUDED.device_id,
          is_deleted = EXCLUDED.is_deleted
        WHERE EXCLUDED.modified_at > transactions.modified_at
      ''');

      await session.execute(Sql.named(buffer.toString()), parameters: params);
    }
  }

  Future<void> _bulkUpsertAccounts(
      Session session, List<Map<String, dynamic>> rows) async {
    const subBatchSize = 500;
    for (var i = 0; i < rows.length; i += subBatchSize) {
      final end =
          (i + subBatchSize < rows.length) ? i + subBatchSize : rows.length;
      final chunk = rows.sublist(i, end);

      final buffer = StringBuffer();
      buffer.write(
          'INSERT INTO accounts (id, name, description, balance, balance_minor, currency_code, currency_designation_id, style_id, account_type_id, creation_date, country, asset_id, asset_quantity, fee_structure, modified_at, device_id, is_deleted) VALUES ');

      final params = <String, dynamic>{};
      for (var j = 0; j < chunk.length; j++) {
        final row = chunk[j];
        if (j > 0) buffer.write(', ');
        final suffix = '_$j';
        buffer.write(
            '(@id$suffix, @name$suffix, @desc$suffix, @bal$suffix, @balm$suffix, @cc$suffix, @cdi$suffix, @sid$suffix, @ati$suffix, @cd$suffix, @cnt$suffix, @aid$suffix, @aq$suffix, @fs$suffix, @ma$suffix, @did$suffix, @del$suffix)');
        params['id$suffix'] = row['id'];
        params['name$suffix'] = row['name'];
        params['desc$suffix'] = row['description'];
        params['bal$suffix'] = _round(row['balance']);
        params['balm$suffix'] = _minorUnits(row['balanceMinor']);
        params['cc$suffix'] = row['currencyCode'];
        params['cdi$suffix'] = row['currencyDesignationId'];
        params['sid$suffix'] = row['styleId'];
        params['ati$suffix'] = row['accountTypeId'];
        params['cd$suffix'] = _accountCreationDate(row);
        params['cnt$suffix'] = row['country'];
        params['aid$suffix'] = row['assetId'];
        params['aq$suffix'] = _round(row['assetQuantity']);
        params['fs$suffix'] = row['feeStructure'];
        params['ma$suffix'] = row['modifiedAt'];
        params['did$suffix'] = row['deviceId'];
        params['del$suffix'] = row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1);
      }

      buffer.write('''
        ON CONFLICT (id) DO UPDATE SET
          name = EXCLUDED.name,
          description = EXCLUDED.description,
          balance = EXCLUDED.balance,
          balance_minor = EXCLUDED.balance_minor,
          currency_code = EXCLUDED.currency_code,
          currency_designation_id = EXCLUDED.currency_designation_id,
          style_id = EXCLUDED.style_id,
          account_type_id = EXCLUDED.account_type_id,
          creation_date = EXCLUDED.creation_date,
          country = EXCLUDED.country,
          asset_id = EXCLUDED.asset_id,
          asset_quantity = EXCLUDED.asset_quantity,
          fee_structure = EXCLUDED.fee_structure,
          modified_at = EXCLUDED.modified_at,
          device_id = EXCLUDED.device_id,
          is_deleted = EXCLUDED.is_deleted
        WHERE EXCLUDED.modified_at > accounts.modified_at
      ''');

      await session.execute(Sql.named(buffer.toString()), parameters: params);
    }
  }

  Future<void> _upsertCategory(
      Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO categories (id, name, parent_id, style_id, type, modified_at, device_id, is_deleted)
      VALUES (@id, @name, @parentId, @styleId, @type, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        parent_id = EXCLUDED.parent_id,
        style_id = EXCLUDED.style_id,
        type = EXCLUDED.type,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > categories.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'name': row['name'],
      'parentId': row['parentId'],
      'styleId': row['styleId'],
      'type': row['type'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertLanguage(
      Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO languages (language_code, language, modified_at, device_id)
      VALUES (@languageCode, @language, @modifiedAt, @deviceId)
      ON CONFLICT (language_code) DO UPDATE SET
        language = EXCLUDED.language,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id
      WHERE EXCLUDED.modified_at > languages.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'languageCode': row['languageCode'],
      'language': row['language'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
    });
  }

  Future<void> _upsertCurrency(
      Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO currencies (code, name, language_code, type, modified_at, device_id)
      VALUES (@code, @name, @languageCode, @type, @modifiedAt, @deviceId)
      ON CONFLICT (code) DO UPDATE SET
        name = EXCLUDED.name,
        language_code = EXCLUDED.language_code,
        type = EXCLUDED.type,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id
      WHERE EXCLUDED.modified_at > currencies.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'code': row['code'],
      'name': row['name'],
      'languageCode': row['languageCode'],
      'type': row['type'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
    });
  }

  Future<void> _upsertTransaction(
      Session session, Map<String, dynamic> row) async {
    final date = _parseDate(row['date']);
    if (date == null) {
      // No usable date: skip rather than stamping it with DateTime.now().
      print(
          '[SYNC] Skipping transaction ${row['id']}: missing or unparseable date (${row['date']})');
      return;
    }

    final sql = '''
      INSERT INTO transactions (id, description, amount, amount_minor, date, account_id, category_id, currency_code, exchange_rate, exchange_rate_preset, fee, fee_minor, linked_transaction_id, modified_at, device_id, is_deleted)
      VALUES (@id, @description, @amount, @amountMinor, @date, @accountId, @categoryId, @currencyCode, @exchangeRate, @exchangeRatePreset, @fee, @feeMinor, @linkedTransactionId, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        description = EXCLUDED.description,
        amount = EXCLUDED.amount,
        amount_minor = EXCLUDED.amount_minor,
        date = EXCLUDED.date,
        account_id = EXCLUDED.account_id,
        category_id = EXCLUDED.category_id,
        currency_code = EXCLUDED.currency_code,
        exchange_rate = EXCLUDED.exchange_rate,
        exchange_rate_preset = EXCLUDED.exchange_rate_preset,
        fee = EXCLUDED.fee,
        fee_minor = EXCLUDED.fee_minor,
        linked_transaction_id = EXCLUDED.linked_transaction_id,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > transactions.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'description': row['description'],
      'amount': _round(row['amount']),
      'amountMinor': _minorUnits(row['amountMinor']),
      'date': date,
      'accountId': row['accountId'],
      'categoryId': row['categoryId'],
      'currencyCode': row['currencyCode'],
      'exchangeRate': _round(row['exchangeRate']),
      'exchangeRatePreset': row['exchangeRatePreset'],
      'fee': _round(row['fee']),
      'feeMinor': _minorUnits(row['feeMinor']),
      'linkedTransactionId': row['linkedTransactionId'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertAccount(Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO accounts (id, name, description, balance, balance_minor, currency_code, currency_designation_id, style_id, account_type_id, creation_date, country, asset_id, asset_quantity, fee_structure, modified_at, device_id, is_deleted)
      VALUES (@id, @name, @description, @balance, @balanceMinor, @currencyCode, @currencyDesignationId, @styleId, @accountTypeId, @creationDate, @country, @assetId, @assetQuantity, @feeStructure, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        balance = EXCLUDED.balance,
        balance_minor = EXCLUDED.balance_minor,
        currency_code = EXCLUDED.currency_code,
        currency_designation_id = EXCLUDED.currency_designation_id,
        style_id = EXCLUDED.style_id,
        account_type_id = EXCLUDED.account_type_id,
        creation_date = EXCLUDED.creation_date,
        country = EXCLUDED.country,
        asset_id = EXCLUDED.asset_id,
        asset_quantity = EXCLUDED.asset_quantity,
        fee_structure = EXCLUDED.fee_structure,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > accounts.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'name': row['name'],
      'description': row['description'],
      'balance': _round(row['balance']),
      'balanceMinor': _minorUnits(row['balanceMinor']),
      'currencyCode': row['currencyCode'],
      'currencyDesignationId': row['currencyDesignationId'],
      'styleId': row['styleId'],
      'accountTypeId': row['accountTypeId'],
      'creationDate': _accountCreationDate(row),
      'country': row['country'],
      'assetId': row['assetId'],
      'assetQuantity': _round(row['assetQuantity']),
      'feeStructure': row['feeStructure'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertStyle(Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO styles (id, name, color_hex, icon_name, icon_type, modified_at, device_id, is_deleted)
      VALUES (@id, @name, @colorHex, @iconName, @iconType, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        color_hex = EXCLUDED.color_hex,
        icon_name = EXCLUDED.icon_name,
        icon_type = EXCLUDED.icon_type,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > styles.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'name': row['name'],
      'colorHex': row['colorHex'],
      'iconName': row['iconName'],
      'iconType': row['iconType'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertAssetEntry(
      Session session, Map<String, dynamic> row) async {
    final date = _parseDate(row['date']);
    if (date == null) {
      // An asset entry is a point on a value timeline — without a date it is
      // meaningless, so skip it rather than inventing one.
      print(
          '[SYNC] Skipping asset_entry ${row['id']}: missing or unparseable date (${row['date']})');
      return;
    }

    final sql = '''
      INSERT INTO asset_entries (id, asset_id, name, date, value, quantity, asset_type, description, currency_code, account_id, source, preset, modified_at, device_id, source_id, is_deleted)
      VALUES (@id, @assetId, @name, @date, @value, @quantity, @assetType, @description, @currencyCode, @accountId, @source, @preset, @modifiedAt, @deviceId, @sourceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        asset_id = EXCLUDED.asset_id,
        name = EXCLUDED.name,
        date = EXCLUDED.date,
        value = EXCLUDED.value,
        quantity = EXCLUDED.quantity,
        asset_type = EXCLUDED.asset_type,
        description = EXCLUDED.description,
        currency_code = EXCLUDED.currency_code,
        account_id = EXCLUDED.account_id,
        source = EXCLUDED.source,
        preset = EXCLUDED.preset,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        source_id = EXCLUDED.source_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > asset_entries.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'assetId': row['assetId'],
      'name': row['name'],
      'date': date,
      'value': _round(row['value']),
      'quantity': _round(row['quantity']),
      'assetType': row['assetType'],
      'description': row['description'],
      'currencyCode': row['currencyCode'],
      'accountId': row['accountId'],
      'source': row['source'],
      'preset': row['preset'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'sourceId': row['sourceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertAccountType(
      Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO account_types (id, name, language_code, modified_at, device_id, is_deleted)
      VALUES (@id, @name, @languageCode, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        language_code = EXCLUDED.language_code,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > account_types.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'name': row['name'],
      'languageCode': row['languageCode'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertCurrencyDesignation(
      Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO currency_designations (id, value, currency_code, modified_at, device_id, is_deleted)
      VALUES (@id, @value, @currencyCode, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        value = EXCLUDED.value,
        currency_code = EXCLUDED.currency_code,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > currency_designations.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'value': row['value'],
      'currencyCode': row['currencyCode'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertCustomDataSource(
      Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO custom_data_sources (id, name, url, data_type, enabled, auto_fetch, last_fetch_at, modified_at, device_id, is_deleted)
      VALUES (@id, @name, @url, @dataType, @enabled, @autoFetch, @lastFetchAt, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        url = EXCLUDED.url,
        data_type = EXCLUDED.data_type,
        enabled = EXCLUDED.enabled,
        auto_fetch = EXCLUDED.auto_fetch,
        last_fetch_at = EXCLUDED.last_fetch_at,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > custom_data_sources.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'name': row['name'],
      'url': row['url'],
      'dataType': row['dataType'],
      'enabled':
          row['enabled'] is bool ? row['enabled'] : (row['enabled'] == 1),
      'autoFetch':
          row['autoFetch'] is bool ? row['autoFetch'] : (row['autoFetch'] == 1),
      'lastFetchAt': row['lastFetchAt'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertApiSetting(
      Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO api_settings (id, enabled, auto_fetch, last_fetch_at, modified_at, device_id)
      VALUES (@id, @enabled, @autoFetch, @lastFetchAt, @modifiedAt, @deviceId)
      ON CONFLICT (id) DO UPDATE SET
        enabled = EXCLUDED.enabled,
        auto_fetch = EXCLUDED.auto_fetch,
        last_fetch_at = EXCLUDED.last_fetch_at,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id
      WHERE EXCLUDED.modified_at > api_settings.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'enabled':
          row['enabled'] is bool ? row['enabled'] : (row['enabled'] == 1),
      'autoFetch':
          row['autoFetch'] is bool ? row['autoFetch'] : (row['autoFetch'] == 1),
      'lastFetchAt': row['lastFetchAt'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
    });
  }

  Future<void> _upsertSmsPreset(
      Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO sms_presets (id, name, sender_filter, is_built_in, is_enabled, default_account_id, default_category_id, rules_json, modified_at, device_id, is_deleted)
      VALUES (@id, @name, @senderFilter, @isBuiltIn, @isEnabled, @defaultAccountId, @defaultCategoryId, @rulesJson, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        sender_filter = EXCLUDED.sender_filter,
        is_built_in = EXCLUDED.is_built_in,
        is_enabled = EXCLUDED.is_enabled,
        default_account_id = EXCLUDED.default_account_id,
        default_category_id = EXCLUDED.default_category_id,
        rules_json = EXCLUDED.rules_json,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > sms_presets.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'name': row['name'],
      'senderFilter': row['senderFilter'],
      'isBuiltIn':
          row['isBuiltIn'] is bool ? row['isBuiltIn'] : (row['isBuiltIn'] == 1),
      'isEnabled':
          row['isEnabled'] is bool ? row['isEnabled'] : (row['isEnabled'] == 1),
      'defaultAccountId': row['defaultAccountId'],
      'defaultCategoryId': row['defaultCategoryId'],
      'rulesJson': row['rulesJson'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  Future<void> _upsertSetting(Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO settings (key, value, device, modified_at, device_id)
      VALUES (@key, @value, @device, @modifiedAt, @deviceId)
      ON CONFLICT (key) DO UPDATE SET
        value = EXCLUDED.value,
        device = EXCLUDED.device,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id
      WHERE EXCLUDED.modified_at > settings.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'key': row['key'],
      'value': row['value'],
      'device': row['device'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
    });
  }

  Future<void> _upsertExchangeRate(
      Session session, Map<String, dynamic> row) async {
    final date = _parseDate(row['date']);
    if (date == null) {
      // date is part of the primary key — the row cannot be stored at all.
      print(
          '[SYNC] Skipping exchange_rate ${row['fromCurrencyCode']}->${row['toCurrencyCode']}: missing or unparseable date (${row['date']})');
      return;
    }

    final sql = '''
      INSERT INTO exchange_rates (from_currency_code, to_currency_code, rate, preset, date, modified_at, device_id, source_id)
      VALUES (@fromCurrencyCode, @toCurrencyCode, @rate, @preset, @date, @modifiedAt, @deviceId, @sourceId)
      ON CONFLICT (from_currency_code, to_currency_code, date, preset) DO UPDATE SET
        rate = EXCLUDED.rate,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        source_id = EXCLUDED.source_id
      WHERE EXCLUDED.modified_at > exchange_rates.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'fromCurrencyCode': row['fromCurrencyCode'],
      'toCurrencyCode': row['toCurrencyCode'],
      'rate': _round(row['rate']),
      'preset': row['preset'],
      'date': date,
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'sourceId': row['sourceId'],
    });
  }

  Future<void> _upsertInflationRate(
      Session session, Map<String, dynamic> row) async {
    final date = _parseDate(row['date']);
    if (date == null) {
      // date is part of the primary key — the row cannot be stored at all.
      print(
          '[SYNC] Skipping inflation_rate for ${row['country']}: missing or unparseable date (${row['date']})');
      return;
    }

    final sql = '''
      INSERT INTO inflation_rates (date, percent, country, preset, modified_at, device_id, source_id)
      VALUES (@date, @percent, @country, @preset, @modifiedAt, @deviceId, @sourceId)
      ON CONFLICT (date, country, preset) DO UPDATE SET
        percent = EXCLUDED.percent,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        source_id = EXCLUDED.source_id
      WHERE EXCLUDED.modified_at > inflation_rates.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'date': date,
      'percent': _round(row['percent']),
      'country': row['country'],
      'preset': row['preset'],
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'sourceId': row['sourceId'],
    });
  }

  Future<void> _upsertCustomTheme(
      Session session, Map<String, dynamic> row) async {
    final sql = '''
      INSERT INTO custom_themes (id, name, primary_color_hex, secondary_color_hex, surface_color_hex, background_color_hex, background_image_path, background_image_opacity, background_image_blur, window_effect_type, effect_opacity, surface_opacity, theme_mode, is_preset, is_active, modified_at, device_id, is_deleted)
      VALUES (@id, @name, @primaryColorHex, @secondaryColorHex, @surfaceColorHex, @backgroundColorHex, @backgroundImagePath, @backgroundImageOpacity, @backgroundImageBlur, @windowEffectType, @effectOpacity, @surfaceOpacity, @themeMode, @isPreset, @isActive, @modifiedAt, @deviceId, @isDeleted)
      ON CONFLICT (id) DO UPDATE SET
        name = EXCLUDED.name,
        primary_color_hex = EXCLUDED.primary_color_hex,
        secondary_color_hex = EXCLUDED.secondary_color_hex,
        surface_color_hex = EXCLUDED.surface_color_hex,
        background_color_hex = EXCLUDED.background_color_hex,
        background_image_path = EXCLUDED.background_image_path,
        background_image_opacity = EXCLUDED.background_image_opacity,
        background_image_blur = EXCLUDED.background_image_blur,
        window_effect_type = EXCLUDED.window_effect_type,
        effect_opacity = EXCLUDED.effect_opacity,
        surface_opacity = EXCLUDED.surface_opacity,
        theme_mode = EXCLUDED.theme_mode,
        is_preset = EXCLUDED.is_preset,
        is_active = EXCLUDED.is_active,
        modified_at = EXCLUDED.modified_at,
        device_id = EXCLUDED.device_id,
        is_deleted = EXCLUDED.is_deleted
      WHERE EXCLUDED.modified_at > custom_themes.modified_at
    ''';

    await session.execute(Sql.named(sql), parameters: {
      'id': row['id'],
      'name': row['name'],
      'primaryColorHex': row['primaryColorHex'],
      'secondaryColorHex': row['secondaryColorHex'],
      'surfaceColorHex': row['surfaceColorHex'],
      'backgroundColorHex': row['backgroundColorHex'],
      'backgroundImagePath': row['backgroundImagePath'],
      'backgroundImageOpacity': row['backgroundImageOpacity'],
      'backgroundImageBlur': row['backgroundImageBlur'],
      'windowEffectType': row['windowEffectType'],
      'effectOpacity': row['effectOpacity'],
      'surfaceOpacity': row['surfaceOpacity'],
      'themeMode': row['themeMode'],
      'isPreset':
          row['isPreset'] is bool ? row['isPreset'] : (row['isPreset'] == 1),
      'isActive':
          row['isActive'] is bool ? row['isActive'] : (row['isActive'] == 1),
      'modifiedAt': row['modifiedAt'],
      'deviceId': row['deviceId'],
      'isDeleted':
          row['isDeleted'] is bool ? row['isDeleted'] : (row['isDeleted'] == 1),
    });
  }

  /// Returns null when the value is missing or unparseable.
  ///
  /// Never substitute DateTime.now() here: a fabricated timestamp is
  /// indistinguishable from a real one once it is stored, and it silently wins
  /// against the client's real date on the next comparison.
  DateTime? _parseDate(dynamic val) {
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val);
    } else if (val is String) {
      return DateTime.tryParse(val);
    }
    return null;
  }

  /// creation_date is nullable and nothing is keyed on it, so an account with a
  /// bad one is stored with NULL instead of being dropped — dropping it would
  /// break the accounts(id) foreign key for every transaction it owns.
  DateTime? _accountCreationDate(Map<String, dynamic> row) {
    final parsed = _parseDate(row['creationDate']);
    if (parsed == null && row['creationDate'] != null) {
      print(
          '[SYNC] Account ${row['id']}: unparseable creationDate (${row['creationDate']}), storing NULL');
    }
    return parsed;
  }

  /// Null in, null out — a NULL amount/rate/fee must stay NULL rather than
  /// becoming 0.0, which would silently rewrite the value on every device.
  double? _round(dynamic value) {
    if (value == null) return null;
    final numVal = value is num ? value : num.tryParse(value.toString());
    if (numVal == null) return null;
    return double.parse(numVal.toStringAsFixed(8));
  }

  /// Exact integer minor units (cents) for fiat money.
  ///
  /// Nullable end to end: NULL marks a row whose value is not expressible in
  /// minor units (crypto/commodity), where the double column is authoritative.
  /// Never coerce to 0 and never route these through [_round].
  int? _minorUnits(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    final numVal = value is num ? value : num.tryParse(value.toString());
    return numVal?.round();
  }

  /// Everything written after cursor [lastSync], in server-write order.
  ///
  /// [lastSync] is a `server_seq` value, not a timestamp: paging on
  /// `modified_at` skipped any row a client pushed with a clock below a cursor
  /// its peers had already passed, permanently and silently. `lastTimestamp` in
  /// the returned record is likewise the cursor to send back next time - the
  /// name is kept only because it is the wire field clients already read.
  Future<({Map<String, List<Map<String, dynamic>>> changes, int lastTimestamp, bool hasMore})>
      getChanges(int lastSync, {int limit = 5000}) async {
    final changes = <String, List<Map<String, dynamic>>>{};
    int maxSeq = lastSync;

    final tableConfigsMap = {
      'categories': {
        'parent_id': 'parentId',
        'style_id': 'styleId',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'transactions': {
        'account_id': 'accountId',
        'category_id': 'categoryId',
        'currency_code': 'currencyCode',
        'exchange_rate': 'exchangeRate',
        'exchange_rate_preset': 'exchangeRatePreset',
        'linked_transaction_id': 'linkedTransactionId',
        'amount_minor': 'amountMinor',
        'fee_minor': 'feeMinor',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'accounts': {
        'balance_minor': 'balanceMinor',
        'currency_code': 'currencyCode',
        'currency_designation_id': 'currencyDesignationId',
        'account_type_id': 'accountTypeId',
        'style_id': 'styleId',
        'creation_date': 'creationDate',
        'asset_id': 'assetId',
        'asset_quantity': 'assetQuantity',
        'fee_structure': 'feeStructure',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'styles': {
        'color_hex': 'colorHex',
        'icon_name': 'iconName',
        'icon_type': 'iconType',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'asset_entries': {
        'asset_id': 'assetId',
        'asset_type': 'assetType',
        'currency_code': 'currencyCode',
        'account_id': 'accountId',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'source_id': 'sourceId',
        'is_deleted': 'isDeleted'
      },
      'account_types': {
        'language_code': 'languageCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'currency_designations': {
        'currency_code': 'currencyCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'custom_data_sources': {
        'data_type': 'dataType',
        'auto_fetch': 'autoFetch',
        'last_fetch_at': 'lastFetchAt',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'api_settings': {
        'auto_fetch': 'autoFetch',
        'last_fetch_at': 'lastFetchAt',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId'
      },
      'sms_presets': {
        'sender_filter': 'senderFilter',
        'is_built_in': 'isBuiltIn',
        'is_enabled': 'isEnabled',
        'default_account_id': 'defaultAccountId',
        'default_category_id': 'defaultCategoryId',
        'rules_json': 'rulesJson',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
      'settings': {
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
      },
      'exchange_rates': {
        'from_currency_code': 'fromCurrencyCode',
        'to_currency_code': 'toCurrencyCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'source_id': 'sourceId'
      },
      'inflation_rates': {
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'source_id': 'sourceId'
      },
      'languages': {
        'language_code': 'languageCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId'
      },
      'currencies': {
        'language_code': 'languageCode',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId'
      },
      'custom_themes': {
        'primary_color_hex': 'primaryColorHex',
        'secondary_color_hex': 'secondaryColorHex',
        'surface_color_hex': 'surfaceColorHex',
        'background_color_hex': 'backgroundColorHex',
        'background_image_path': 'backgroundImagePath',
        'background_image_opacity': 'backgroundImageOpacity',
        'background_image_blur': 'backgroundImageBlur',
        'window_effect_type': 'windowEffectType',
        'effect_opacity': 'effectOpacity',
        'surface_opacity': 'surfaceOpacity',
        'theme_mode': 'themeMode',
        'is_preset': 'isPreset',
        'is_active': 'isActive',
        'modified_at': 'modifiedAt',
        'device_id': 'deviceId',
        'is_deleted': 'isDeleted'
      },
    };

    final tableConfigs = tableConfigsMap.entries.toList();

    // Optimization: Parallelize independent DB queries using Future.wait
    final queryFutures = tableConfigs.map((entry) async {
      final tableName = entry.key;
      // Carried through the mapping so the cursor can be read off the rows;
      // stripped again before they are handed to the client.
      final columnMap = {...entry.value, 'server_seq': 'serverSeq'};

      // `server_seq` is unique across every table, so it is already a total
      // order - no primary-key tiebreaker is needed to keep paging stable, and
      // no page can end mid-way through a group of rows sharing a value.
      final result = await _dbClient.pool.execute(
        Sql.named(
          'SELECT * FROM $tableName WHERE server_seq > @lastSync '
          'ORDER BY server_seq ASC LIMIT @limit',
        ),
        parameters: {'lastSync': lastSync, 'limit': limit},
      );

      final rows = _mapResult(result, columnMap);
      final hitLimit = rows.isNotEmpty && rows.length >= limit;

      // Cursor for THIS table alone. It is never advanced past a row this table
      // has not returned yet; the caller then takes the minimum over the
      // truncated tables so no table can be skipped by another table's data.
      var cursor = lastSync;
      if (rows.isNotEmpty) {
        cursor = rows.last['serverSeq'] as int;
      }

      return (
        tableName: tableName,
        rows: rows,
        cursor: cursor,
        hitLimit: hitLimit
      );
    }).toList();

    final results = await Future.wait(queryFutures);

    // Aggregate results and compute the next cursor.
    // NOTE: No early break — all tables must be included regardless of count.
    // Breaking early causes tables with lower sequence numbers to be
    // permanently skipped once a high-volume table (e.g. exchange_rates)
    // consumes the entire limit.
    bool hasMore = false;
    int? truncatedCursor;
    for (final result in results) {
      final rows = result.rows;
      if (rows.isNotEmpty) {
        for (final row in rows) {
          final seq = row['serverSeq'] as int;
          if (seq > maxSeq) maxSeq = seq;
          // Internal bookkeeping: the client stores whatever it is handed, and
          // this column is not one of its own.
          row.remove('serverSeq');
        }
        changes[result.tableName] = rows;
      }

      // A table that filled its limit still has rows to give
      if (result.hitLimit) {
        hasMore = true;
        if (truncatedCursor == null || result.cursor < truncatedCursor) {
          truncatedCursor = result.cursor;
        }
      }
    }

    // A single global max would skip everything a truncated table has not
    // returned yet, so any truncated table pins the cursor for all tables. The
    // untruncated ones simply re-send a few rows on the next page (upserts are
    // idempotent) instead of losing rows forever.
    final nextCursor = truncatedCursor ?? maxSeq;

    return (changes: changes, lastTimestamp: nextCursor, hasMore: hasMore);
  }

  // Helper to map DB row (snake_case) to JSON (camelCase or whatever client expects)
  List<Map<String, dynamic>> _mapResult(
      Result result, Map<String, String> columnMap) {
    return result.map((row) {
      final map = <String, dynamic>{};
      final colMap = row.toColumnMap();
      colMap.forEach((key, value) {
        final newKey = columnMap[key] ?? key;
        if (value is DateTime) {
          map[newKey] = value.toIso8601String();
        } else {
          map[newKey] = value;
        }
      });
      return map;
    }).toList();
  }
}
