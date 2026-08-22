// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
mixin _$LanguageDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagesTable get languages => attachedDatabase.languages;
}
mixin _$CurrencyDesignationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagesTable get languages => attachedDatabase.languages;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $CurrencyDesignationsTable get currencyDesignations =>
      attachedDatabase.currencyDesignations;
}
mixin _$CurrenciesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagesTable get languages => attachedDatabase.languages;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
}
mixin _$CategoriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $StylesTable get styles => attachedDatabase.styles;
  $CategoriesTable get categories => attachedDatabase.categories;
  $LanguagesTable get languages => attachedDatabase.languages;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $CurrencyDesignationsTable get currencyDesignations =>
      attachedDatabase.currencyDesignations;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}
mixin _$StylesDaoMixin on DatabaseAccessor<AppDatabase> {
  $StylesTable get styles => attachedDatabase.styles;
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}
mixin _$AccountTypesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagesTable get languages => attachedDatabase.languages;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
}
mixin _$AccountsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagesTable get languages => attachedDatabase.languages;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $CurrencyDesignationsTable get currencyDesignations =>
      attachedDatabase.currencyDesignations;
  $StylesTable get styles => attachedDatabase.styles;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}
mixin _$TransactionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagesTable get languages => attachedDatabase.languages;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $CurrencyDesignationsTable get currencyDesignations =>
      attachedDatabase.currencyDesignations;
  $StylesTable get styles => attachedDatabase.styles;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $TransactionsTable get transactions => attachedDatabase.transactions;
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}
mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsTable get settings => attachedDatabase.settings;
}
mixin _$ExchangeRatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagesTable get languages => attachedDatabase.languages;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $ExchangeRatesTable get exchangeRates => attachedDatabase.exchangeRates;
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}
mixin _$CustomThemesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomThemesTable get customThemes => attachedDatabase.customThemes;
}
mixin _$InflationRatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $InflationRatesTable get inflationRates => attachedDatabase.inflationRates;
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}
mixin _$AssetEntriesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagesTable get languages => attachedDatabase.languages;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $CurrencyDesignationsTable get currencyDesignations =>
      attachedDatabase.currencyDesignations;
  $StylesTable get styles => attachedDatabase.styles;
  $AccountTypesTable get accountTypes => attachedDatabase.accountTypes;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $AssetEntriesTable get assetEntries => attachedDatabase.assetEntries;
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}

class $LanguagesTable extends Languages
    with TableInfo<$LanguagesTable, Language> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LanguagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _languageMeta = const VerificationMeta(
    'language',
  );
  @override
  late final GeneratedColumn<String> language = GeneratedColumn<String>(
    'language',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    language,
    languageCode,
    modifiedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'languages';
  @override
  VerificationContext validateIntegrity(
    Insertable<Language> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('language')) {
      context.handle(
        _languageMeta,
        language.isAcceptableOrUnknown(data['language']!, _languageMeta),
      );
    } else if (isInserting) {
      context.missing(_languageMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {languageCode};
  @override
  Language map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Language(
      language: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
    );
  }

  @override
  $LanguagesTable createAlias(String alias) {
    return $LanguagesTable(attachedDatabase, alias);
  }
}

class Language extends DataClass implements Insertable<Language> {
  final String language;
  final String languageCode;
  final int modifiedAt;
  final String? deviceId;
  const Language({
    required this.language,
    required this.languageCode,
    required this.modifiedAt,
    this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['language'] = Variable<String>(language);
    map['language_code'] = Variable<String>(languageCode);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  LanguagesCompanion toCompanion(bool nullToAbsent) {
    return LanguagesCompanion(
      language: Value(language),
      languageCode: Value(languageCode),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory Language.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Language(
      language: serializer.fromJson<String>(json['language']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'language': serializer.toJson<String>(language),
      'languageCode': serializer.toJson<String>(languageCode),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  Language copyWith({
    String? language,
    String? languageCode,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
  }) => Language(
    language: language ?? this.language,
    languageCode: languageCode ?? this.languageCode,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
  );
  Language copyWithCompanion(LanguagesCompanion data) {
    return Language(
      language: data.language.present ? data.language.value : this.language,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Language(')
          ..write('language: $language, ')
          ..write('languageCode: $languageCode, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(language, languageCode, modifiedAt, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Language &&
          other.language == this.language &&
          other.languageCode == this.languageCode &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId);
}

class LanguagesCompanion extends UpdateCompanion<Language> {
  final Value<String> language;
  final Value<String> languageCode;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const LanguagesCompanion({
    this.language = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LanguagesCompanion.insert({
    required String language,
    required String languageCode,
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : language = Value(language),
       languageCode = Value(languageCode);
  static Insertable<Language> custom({
    Expression<String>? language,
    Expression<String>? languageCode,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (language != null) 'language': language,
      if (languageCode != null) 'language_code': languageCode,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LanguagesCompanion copyWith({
    Value<String>? language,
    Value<String>? languageCode,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<int>? rowid,
  }) {
    return LanguagesCompanion(
      language: language ?? this.language,
      languageCode: languageCode ?? this.languageCode,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (language.present) {
      map['language'] = Variable<String>(language.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LanguagesCompanion(')
          ..write('language: $language, ')
          ..write('languageCode: $languageCode, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CurrenciesTable extends Currencies
    with TableInfo<$CurrenciesTable, Currency> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrenciesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
    'code',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 5,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES languages (language_code)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<TypeCurrency, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(6),
      ).withConverter<TypeCurrency>($CurrenciesTable.$convertertype);
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    name,
    code,
    languageCode,
    type,
    modifiedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currencies';
  @override
  VerificationContext validateIntegrity(
    Insertable<Currency> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
        _codeMeta,
        code.isAcceptableOrUnknown(data['code']!, _codeMeta),
      );
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {code};
  @override
  Currency map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Currency(
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      code: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      type: $CurrenciesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
    );
  }

  @override
  $CurrenciesTable createAlias(String alias) {
    return $CurrenciesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<TypeCurrency, int, int> $convertertype =
      const EnumIndexConverter(TypeCurrency.values);
}

class Currency extends DataClass implements Insertable<Currency> {
  /// Deliberately not unique.
  ///
  /// The key is [code]; this is the label shown next to it, and two devices on
  /// different app versions do not agree on labels. The bundled seed renamed
  /// `BYR` to "Belarusian Ruble (2000-2016)" when `BYN` took over the plain
  /// name, and did the same for `SLL`/`SLE`. A device still on the older seed
  /// pushes `BYR = "Belarusian Ruble"`, which on the newer device is the name
  /// `BYN` already holds - and a UNIQUE here turned that into
  /// `SqliteException(2067)` inside the pull transaction. The pull applies all
  /// sixteen tables in one transaction and advances its cursor only after it
  /// commits, so the whole page rolled back and the next sync asked for the
  /// same page and failed the same way. Forever, including the WebSocket
  /// doorbell. Nothing reads a currency by name, so the constraint bought
  /// nothing and cost every pair of devices that were not on the same version.
  final String name;
  final String code;
  final String languageCode;
  final TypeCurrency type;
  final int modifiedAt;
  final String? deviceId;
  const Currency({
    required this.name,
    required this.code,
    required this.languageCode,
    required this.type,
    required this.modifiedAt,
    this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['language_code'] = Variable<String>(languageCode);
    {
      map['type'] = Variable<int>($CurrenciesTable.$convertertype.toSql(type));
    }
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  CurrenciesCompanion toCompanion(bool nullToAbsent) {
    return CurrenciesCompanion(
      name: Value(name),
      code: Value(code),
      languageCode: Value(languageCode),
      type: Value(type),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory Currency.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Currency(
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      type: $CurrenciesTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'languageCode': serializer.toJson<String>(languageCode),
      'type': serializer.toJson<int>(
        $CurrenciesTable.$convertertype.toJson(type),
      ),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  Currency copyWith({
    String? name,
    String? code,
    String? languageCode,
    TypeCurrency? type,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
  }) => Currency(
    name: name ?? this.name,
    code: code ?? this.code,
    languageCode: languageCode ?? this.languageCode,
    type: type ?? this.type,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
  );
  Currency copyWithCompanion(CurrenciesCompanion data) {
    return Currency(
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      type: data.type.present ? data.type.value : this.type,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Currency(')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('languageCode: $languageCode, ')
          ..write('type: $type, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(name, code, languageCode, type, modifiedAt, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Currency &&
          other.name == this.name &&
          other.code == this.code &&
          other.languageCode == this.languageCode &&
          other.type == this.type &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId);
}

class CurrenciesCompanion extends UpdateCompanion<Currency> {
  final Value<String> name;
  final Value<String> code;
  final Value<String> languageCode;
  final Value<TypeCurrency> type;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const CurrenciesCompanion({
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.type = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurrenciesCompanion.insert({
    required String name,
    required String code,
    required String languageCode,
    this.type = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       code = Value(code),
       languageCode = Value(languageCode);
  static Insertable<Currency> custom({
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? languageCode,
    Expression<int>? type,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (languageCode != null) 'language_code': languageCode,
      if (type != null) 'type': type,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurrenciesCompanion copyWith({
    Value<String>? name,
    Value<String>? code,
    Value<String>? languageCode,
    Value<TypeCurrency>? type,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<int>? rowid,
  }) {
    return CurrenciesCompanion(
      name: name ?? this.name,
      code: code ?? this.code,
      languageCode: languageCode ?? this.languageCode,
      type: type ?? this.type,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $CurrenciesTable.$convertertype.toSql(type.value),
      );
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrenciesCompanion(')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('languageCode: $languageCode, ')
          ..write('type: $type, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CurrencyDesignationsTable extends CurrencyDesignations
    with TableInfo<$CurrencyDesignationsTable, CurrencyDesignation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CurrencyDesignationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 5,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    value,
    currencyCode,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'currency_designations';
  @override
  VerificationContext validateIntegrity(
    Insertable<CurrencyDesignation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CurrencyDesignation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CurrencyDesignation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CurrencyDesignationsTable createAlias(String alias) {
    return $CurrencyDesignationsTable(attachedDatabase, alias);
  }
}

class CurrencyDesignation extends DataClass
    implements Insertable<CurrencyDesignation> {
  final String id;
  final String value;
  final String currencyCode;
  final int modifiedAt;
  final String? deviceId;
  final bool isDeleted;
  const CurrencyDesignation({
    required this.id,
    required this.value,
    required this.currencyCode,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['value'] = Variable<String>(value);
    map['currency_code'] = Variable<String>(currencyCode);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CurrencyDesignationsCompanion toCompanion(bool nullToAbsent) {
    return CurrencyDesignationsCompanion(
      id: Value(id),
      value: Value(value),
      currencyCode: Value(currencyCode),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory CurrencyDesignation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CurrencyDesignation(
      id: serializer.fromJson<String>(json['id']),
      value: serializer.fromJson<String>(json['value']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'value': serializer.toJson<String>(value),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  CurrencyDesignation copyWith({
    String? id,
    String? value,
    String? currencyCode,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => CurrencyDesignation(
    id: id ?? this.id,
    value: value ?? this.value,
    currencyCode: currencyCode ?? this.currencyCode,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CurrencyDesignation copyWithCompanion(CurrencyDesignationsCompanion data) {
    return CurrencyDesignation(
      id: data.id.present ? data.id.value : this.id,
      value: data.value.present ? data.value.value : this.value,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyDesignation(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, value, currencyCode, modifiedAt, deviceId, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrencyDesignation &&
          other.id == this.id &&
          other.value == this.value &&
          other.currencyCode == this.currencyCode &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class CurrencyDesignationsCompanion
    extends UpdateCompanion<CurrencyDesignation> {
  final Value<String> id;
  final Value<String> value;
  final Value<String> currencyCode;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const CurrencyDesignationsCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurrencyDesignationsCompanion.insert({
    this.id = const Value.absent(),
    required String value,
    required String currencyCode,
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : value = Value(value),
       currencyCode = Value(currencyCode);
  static Insertable<CurrencyDesignation> custom({
    Expression<String>? id,
    Expression<String>? value,
    Expression<String>? currencyCode,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'value': value,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurrencyDesignationsCompanion copyWith({
    Value<String>? id,
    Value<String>? value,
    Value<String>? currencyCode,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return CurrencyDesignationsCompanion(
      id: id ?? this.id,
      value: value ?? this.value,
      currencyCode: currencyCode ?? this.currencyCode,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyDesignationsCompanion(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StylesTable extends Styles with TableInfo<$StylesTable, Style> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StylesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconNameMeta = const VerificationMeta(
    'iconName',
  );
  @override
  late final GeneratedColumn<String> iconName = GeneratedColumn<String>(
    'icon_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<IconType, int> iconType =
      GeneratedColumn<int>(
        'icon_type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<IconType>($StylesTable.$convertericonType);
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconName,
    colorHex,
    iconType,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'styles';
  @override
  VerificationContext validateIntegrity(
    Insertable<Style> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_name')) {
      context.handle(
        _iconNameMeta,
        iconName.isAcceptableOrUnknown(data['icon_name']!, _iconNameMeta),
      );
    } else if (isInserting) {
      context.missing(_iconNameMeta);
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    } else if (isInserting) {
      context.missing(_colorHexMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Style map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Style(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      iconName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_name'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      iconType: $StylesTable.$convertericonType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}icon_type'],
        )!,
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $StylesTable createAlias(String alias) {
    return $StylesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<IconType, int, int> $convertericonType =
      const EnumIndexConverter(IconType.values);
}

class Style extends DataClass implements Insertable<Style> {
  final String id;
  final String name;
  final String iconName;
  final String colorHex;
  final IconType iconType;
  final int modifiedAt;
  final String? deviceId;
  final bool isDeleted;
  const Style({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.iconType,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['icon_name'] = Variable<String>(iconName);
    map['color_hex'] = Variable<String>(colorHex);
    {
      map['icon_type'] = Variable<int>(
        $StylesTable.$convertericonType.toSql(iconType),
      );
    }
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  StylesCompanion toCompanion(bool nullToAbsent) {
    return StylesCompanion(
      id: Value(id),
      name: Value(name),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
      iconType: Value(iconType),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory Style.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Style(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconName: serializer.fromJson<String>(json['iconName']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      iconType: $StylesTable.$convertericonType.fromJson(
        serializer.fromJson<int>(json['iconType']),
      ),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'iconName': serializer.toJson<String>(iconName),
      'colorHex': serializer.toJson<String>(colorHex),
      'iconType': serializer.toJson<int>(
        $StylesTable.$convertericonType.toJson(iconType),
      ),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Style copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    IconType? iconType,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => Style(
    id: id ?? this.id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorHex: colorHex ?? this.colorHex,
    iconType: iconType ?? this.iconType,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Style copyWithCompanion(StylesCompanion data) {
    return Style(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      iconType: data.iconType.present ? data.iconType.value : this.iconType,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Style(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconType: $iconType, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    iconName,
    colorHex,
    iconType,
    modifiedAt,
    deviceId,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Style &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconName == this.iconName &&
          other.colorHex == this.colorHex &&
          other.iconType == this.iconType &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class StylesCompanion extends UpdateCompanion<Style> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> iconName;
  final Value<String> colorHex;
  final Value<IconType> iconType;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const StylesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconType = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StylesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String iconName,
    required String colorHex,
    this.iconType = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       iconName = Value(iconName),
       colorHex = Value(colorHex);
  static Insertable<Style> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? iconName,
    Expression<String>? colorHex,
    Expression<int>? iconType,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconName != null) 'icon_name': iconName,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconType != null) 'icon_type': iconType,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StylesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? iconName,
    Value<String>? colorHex,
    Value<IconType>? iconType,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return StylesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      iconType: iconType ?? this.iconType,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconName.present) {
      map['icon_name'] = Variable<String>(iconName.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (iconType.present) {
      map['icon_type'] = Variable<int>(
        $StylesTable.$convertericonType.toSql(iconType.value),
      );
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StylesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconType: $iconType, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _styleIdMeta = const VerificationMeta(
    'styleId',
  );
  @override
  late final GeneratedColumn<String> styleId = GeneratedColumn<String>(
    'style_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES styles (id)',
    ),
  );
  @override
  late final GeneratedColumnWithTypeConverter<CategoryType, int> type =
      GeneratedColumn<int>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      ).withConverter<CategoryType>($CategoriesTable.$convertertype);
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    parentId,
    styleId,
    type,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('style_id')) {
      context.handle(
        _styleIdMeta,
        styleId.isAcceptableOrUnknown(data['style_id']!, _styleIdMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      styleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style_id'],
      ),
      type: $CategoriesTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}type'],
        )!,
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<CategoryType, int, int> $convertertype =
      const EnumIndexConverter(CategoryType.values);
}

class Category extends DataClass implements Insertable<Category> {
  final String id;
  final String name;
  final String? parentId;
  final String? styleId;
  final CategoryType type;
  final int modifiedAt;
  final String? deviceId;
  final bool isDeleted;
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.styleId,
    required this.type,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || styleId != null) {
      map['style_id'] = Variable<String>(styleId);
    }
    {
      map['type'] = Variable<int>($CategoriesTable.$convertertype.toSql(type));
    }
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      styleId: styleId == null && nullToAbsent
          ? const Value.absent()
          : Value(styleId),
      type: Value(type),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      styleId: serializer.fromJson<String?>(json['styleId']),
      type: $CategoriesTable.$convertertype.fromJson(
        serializer.fromJson<int>(json['type']),
      ),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'parentId': serializer.toJson<String?>(parentId),
      'styleId': serializer.toJson<String?>(styleId),
      'type': serializer.toJson<int>(
        $CategoriesTable.$convertertype.toJson(type),
      ),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Category copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    Value<String?> styleId = const Value.absent(),
    CategoryType? type,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    styleId: styleId.present ? styleId.value : this.styleId,
    type: type ?? this.type,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      styleId: data.styleId.present ? data.styleId.value : this.styleId,
      type: data.type.present ? data.type.value : this.type,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('styleId: $styleId, ')
          ..write('type: $type, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    parentId,
    styleId,
    type,
    modifiedAt,
    deviceId,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.styleId == this.styleId &&
          other.type == this.type &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<String?> styleId;
  final Value<CategoryType> type;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.styleId = const Value.absent(),
    this.type = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.parentId = const Value.absent(),
    this.styleId = const Value.absent(),
    this.type = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? styleId,
    Expression<int>? type,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (styleId != null) 'style_id': styleId,
      if (type != null) 'type': type,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<String?>? styleId,
    Value<CategoryType>? type,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      styleId: styleId ?? this.styleId,
      type: type ?? this.type,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (styleId.present) {
      map['style_id'] = Variable<String>(styleId.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(
        $CategoriesTable.$convertertype.toSql(type.value),
      );
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('styleId: $styleId, ')
          ..write('type: $type, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountTypesTable extends AccountTypes
    with TableInfo<$AccountTypesTable, AccountType> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountTypesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _languageCodeMeta = const VerificationMeta(
    'languageCode',
  );
  @override
  late final GeneratedColumn<String> languageCode = GeneratedColumn<String>(
    'language_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES languages (language_code)',
    ),
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    languageCode,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_types';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountType> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('language_code')) {
      context.handle(
        _languageCodeMeta,
        languageCode.isAcceptableOrUnknown(
          data['language_code']!,
          _languageCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_languageCodeMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountType map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountType(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      languageCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}language_code'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $AccountTypesTable createAlias(String alias) {
    return $AccountTypesTable(attachedDatabase, alias);
  }
}

class AccountType extends DataClass implements Insertable<AccountType> {
  final String id;

  /// Deliberately not unique - see [Currencies.name] for what a UNIQUE on a
  /// synced label does.
  ///
  /// Same failure, one step further from the seed: the bundled types have
  /// stable ids, so a plain install cannot collide, but the name is the user's
  /// to edit. Rename "Savings" to "Cash" on the phone while the desktop still
  /// has the seeded "Cash", and the row that arrives carries a name another id
  /// holds. That threw inside the pull transaction, rolled the whole page back
  /// and left the cursor where it was, so every later sync retried the same
  /// page and failed the same way. Nothing looks an account type up by name.
  final String name;
  final String languageCode;
  final int modifiedAt;
  final String? deviceId;
  final bool isDeleted;
  const AccountType({
    required this.id,
    required this.name,
    required this.languageCode,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['language_code'] = Variable<String>(languageCode);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  AccountTypesCompanion toCompanion(bool nullToAbsent) {
    return AccountTypesCompanion(
      id: Value(id),
      name: Value(name),
      languageCode: Value(languageCode),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory AccountType.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountType(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      languageCode: serializer.fromJson<String>(json['languageCode']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'languageCode': serializer.toJson<String>(languageCode),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  AccountType copyWith({
    String? id,
    String? name,
    String? languageCode,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => AccountType(
    id: id ?? this.id,
    name: name ?? this.name,
    languageCode: languageCode ?? this.languageCode,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  AccountType copyWithCompanion(AccountTypesCompanion data) {
    return AccountType(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountType(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('languageCode: $languageCode, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, languageCode, modifiedAt, deviceId, isDeleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountType &&
          other.id == this.id &&
          other.name == this.name &&
          other.languageCode == this.languageCode &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class AccountTypesCompanion extends UpdateCompanion<AccountType> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> languageCode;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const AccountTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountTypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String languageCode,
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       languageCode = Value(languageCode);
  static Insertable<AccountType> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? languageCode,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (languageCode != null) 'language_code': languageCode,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? languageCode,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return AccountTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      languageCode: languageCode ?? this.languageCode,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (languageCode.present) {
      map['language_code'] = Variable<String>(languageCode.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountTypesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('languageCode: $languageCode, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, DbAccount> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<double> balance = GeneratedColumn<double>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _balanceMinorMeta = const VerificationMeta(
    'balanceMinor',
  );
  @override
  late final GeneratedColumn<int> balanceMinor = GeneratedColumn<int>(
    'balance_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openingBalanceMeta = const VerificationMeta(
    'openingBalance',
  );
  @override
  late final GeneratedColumn<double> openingBalance = GeneratedColumn<double>(
    'opening_balance',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _openingBalanceMinorMeta =
      const VerificationMeta('openingBalanceMinor');
  @override
  late final GeneratedColumn<int> openingBalanceMinor = GeneratedColumn<int>(
    'opening_balance_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _currencyDesignationIdMeta =
      const VerificationMeta('currencyDesignationId');
  @override
  late final GeneratedColumn<String> currencyDesignationId =
      GeneratedColumn<String>(
        'currency_designation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES currency_designations (id)',
        ),
      );
  static const VerificationMeta _styleIdMeta = const VerificationMeta(
    'styleId',
  );
  @override
  late final GeneratedColumn<String> styleId = GeneratedColumn<String>(
    'style_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES styles (id)',
    ),
  );
  static const VerificationMeta _accountTypeIdMeta = const VerificationMeta(
    'accountTypeId',
  );
  @override
  late final GeneratedColumn<String> accountTypeId = GeneratedColumn<String>(
    'account_type_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES account_types (id)',
    ),
  );
  static const VerificationMeta _creationDateMeta = const VerificationMeta(
    'creationDate',
  );
  @override
  late final GeneratedColumn<DateTime> creationDate = GeneratedColumn<DateTime>(
    'creation_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    clientDefault: () => DateTime.now(),
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _assetQuantityMeta = const VerificationMeta(
    'assetQuantity',
  );
  @override
  late final GeneratedColumn<double> assetQuantity = GeneratedColumn<double>(
    'asset_quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _feeStructureMeta = const VerificationMeta(
    'feeStructure',
  );
  @override
  late final GeneratedColumn<String> feeStructure = GeneratedColumn<String>(
    'fee_structure',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    balance,
    balanceMinor,
    openingBalance,
    openingBalanceMinor,
    currencyCode,
    currencyDesignationId,
    styleId,
    accountTypeId,
    creationDate,
    country,
    assetId,
    assetQuantity,
    feeStructure,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbAccount> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    } else if (isInserting) {
      context.missing(_balanceMeta);
    }
    if (data.containsKey('balance_minor')) {
      context.handle(
        _balanceMinorMeta,
        balanceMinor.isAcceptableOrUnknown(
          data['balance_minor']!,
          _balanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance')) {
      context.handle(
        _openingBalanceMeta,
        openingBalance.isAcceptableOrUnknown(
          data['opening_balance']!,
          _openingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('opening_balance_minor')) {
      context.handle(
        _openingBalanceMinorMeta,
        openingBalanceMinor.isAcceptableOrUnknown(
          data['opening_balance_minor']!,
          _openingBalanceMinorMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('currency_designation_id')) {
      context.handle(
        _currencyDesignationIdMeta,
        currencyDesignationId.isAcceptableOrUnknown(
          data['currency_designation_id']!,
          _currencyDesignationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyDesignationIdMeta);
    }
    if (data.containsKey('style_id')) {
      context.handle(
        _styleIdMeta,
        styleId.isAcceptableOrUnknown(data['style_id']!, _styleIdMeta),
      );
    }
    if (data.containsKey('account_type_id')) {
      context.handle(
        _accountTypeIdMeta,
        accountTypeId.isAcceptableOrUnknown(
          data['account_type_id']!,
          _accountTypeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountTypeIdMeta);
    }
    if (data.containsKey('creation_date')) {
      context.handle(
        _creationDateMeta,
        creationDate.isAcceptableOrUnknown(
          data['creation_date']!,
          _creationDateMeta,
        ),
      );
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    }
    if (data.containsKey('asset_quantity')) {
      context.handle(
        _assetQuantityMeta,
        assetQuantity.isAcceptableOrUnknown(
          data['asset_quantity']!,
          _assetQuantityMeta,
        ),
      );
    }
    if (data.containsKey('fee_structure')) {
      context.handle(
        _feeStructureMeta,
        feeStructure.isAcceptableOrUnknown(
          data['fee_structure']!,
          _feeStructureMeta,
        ),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbAccount map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbAccount(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}balance'],
      )!,
      balanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance_minor'],
      ),
      openingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opening_balance'],
      )!,
      openingBalanceMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening_balance_minor'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      currencyDesignationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_designation_id'],
      )!,
      styleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style_id'],
      ),
      accountTypeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_type_id'],
      )!,
      creationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}creation_date'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      ),
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      ),
      assetQuantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}asset_quantity'],
      )!,
      feeStructure: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fee_structure'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class DbAccount extends DataClass implements Insertable<DbAccount> {
  final String id;
  final String name;
  final String? description;
  final double balance;
  final int? balanceMinor;
  final double openingBalance;
  final int? openingBalanceMinor;
  final String currencyCode;
  final String currencyDesignationId;
  final String? styleId;
  final String accountTypeId;
  final DateTime creationDate;
  final String? country;
  final String? assetId;
  final double assetQuantity;
  final String? feeStructure;
  final int modifiedAt;
  final String? deviceId;
  final bool isDeleted;
  const DbAccount({
    required this.id,
    required this.name,
    this.description,
    required this.balance,
    this.balanceMinor,
    required this.openingBalance,
    this.openingBalanceMinor,
    required this.currencyCode,
    required this.currencyDesignationId,
    this.styleId,
    required this.accountTypeId,
    required this.creationDate,
    this.country,
    this.assetId,
    required this.assetQuantity,
    this.feeStructure,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['balance'] = Variable<double>(balance);
    if (!nullToAbsent || balanceMinor != null) {
      map['balance_minor'] = Variable<int>(balanceMinor);
    }
    map['opening_balance'] = Variable<double>(openingBalance);
    if (!nullToAbsent || openingBalanceMinor != null) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    map['currency_designation_id'] = Variable<String>(currencyDesignationId);
    if (!nullToAbsent || styleId != null) {
      map['style_id'] = Variable<String>(styleId);
    }
    map['account_type_id'] = Variable<String>(accountTypeId);
    map['creation_date'] = Variable<DateTime>(creationDate);
    if (!nullToAbsent || country != null) {
      map['country'] = Variable<String>(country);
    }
    if (!nullToAbsent || assetId != null) {
      map['asset_id'] = Variable<String>(assetId);
    }
    map['asset_quantity'] = Variable<double>(assetQuantity);
    if (!nullToAbsent || feeStructure != null) {
      map['fee_structure'] = Variable<String>(feeStructure);
    }
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      balance: Value(balance),
      balanceMinor: balanceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(balanceMinor),
      openingBalance: Value(openingBalance),
      openingBalanceMinor: openingBalanceMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(openingBalanceMinor),
      currencyCode: Value(currencyCode),
      currencyDesignationId: Value(currencyDesignationId),
      styleId: styleId == null && nullToAbsent
          ? const Value.absent()
          : Value(styleId),
      accountTypeId: Value(accountTypeId),
      creationDate: Value(creationDate),
      country: country == null && nullToAbsent
          ? const Value.absent()
          : Value(country),
      assetId: assetId == null && nullToAbsent
          ? const Value.absent()
          : Value(assetId),
      assetQuantity: Value(assetQuantity),
      feeStructure: feeStructure == null && nullToAbsent
          ? const Value.absent()
          : Value(feeStructure),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory DbAccount.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbAccount(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      balance: serializer.fromJson<double>(json['balance']),
      balanceMinor: serializer.fromJson<int?>(json['balanceMinor']),
      openingBalance: serializer.fromJson<double>(json['openingBalance']),
      openingBalanceMinor: serializer.fromJson<int?>(
        json['openingBalanceMinor'],
      ),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      currencyDesignationId: serializer.fromJson<String>(
        json['currencyDesignationId'],
      ),
      styleId: serializer.fromJson<String?>(json['styleId']),
      accountTypeId: serializer.fromJson<String>(json['accountTypeId']),
      creationDate: serializer.fromJson<DateTime>(json['creationDate']),
      country: serializer.fromJson<String?>(json['country']),
      assetId: serializer.fromJson<String?>(json['assetId']),
      assetQuantity: serializer.fromJson<double>(json['assetQuantity']),
      feeStructure: serializer.fromJson<String?>(json['feeStructure']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'balance': serializer.toJson<double>(balance),
      'balanceMinor': serializer.toJson<int?>(balanceMinor),
      'openingBalance': serializer.toJson<double>(openingBalance),
      'openingBalanceMinor': serializer.toJson<int?>(openingBalanceMinor),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'currencyDesignationId': serializer.toJson<String>(currencyDesignationId),
      'styleId': serializer.toJson<String?>(styleId),
      'accountTypeId': serializer.toJson<String>(accountTypeId),
      'creationDate': serializer.toJson<DateTime>(creationDate),
      'country': serializer.toJson<String?>(country),
      'assetId': serializer.toJson<String?>(assetId),
      'assetQuantity': serializer.toJson<double>(assetQuantity),
      'feeStructure': serializer.toJson<String?>(feeStructure),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  DbAccount copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    double? balance,
    Value<int?> balanceMinor = const Value.absent(),
    double? openingBalance,
    Value<int?> openingBalanceMinor = const Value.absent(),
    String? currencyCode,
    String? currencyDesignationId,
    Value<String?> styleId = const Value.absent(),
    String? accountTypeId,
    DateTime? creationDate,
    Value<String?> country = const Value.absent(),
    Value<String?> assetId = const Value.absent(),
    double? assetQuantity,
    Value<String?> feeStructure = const Value.absent(),
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => DbAccount(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    balance: balance ?? this.balance,
    balanceMinor: balanceMinor.present ? balanceMinor.value : this.balanceMinor,
    openingBalance: openingBalance ?? this.openingBalance,
    openingBalanceMinor: openingBalanceMinor.present
        ? openingBalanceMinor.value
        : this.openingBalanceMinor,
    currencyCode: currencyCode ?? this.currencyCode,
    currencyDesignationId: currencyDesignationId ?? this.currencyDesignationId,
    styleId: styleId.present ? styleId.value : this.styleId,
    accountTypeId: accountTypeId ?? this.accountTypeId,
    creationDate: creationDate ?? this.creationDate,
    country: country.present ? country.value : this.country,
    assetId: assetId.present ? assetId.value : this.assetId,
    assetQuantity: assetQuantity ?? this.assetQuantity,
    feeStructure: feeStructure.present ? feeStructure.value : this.feeStructure,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  DbAccount copyWithCompanion(AccountsCompanion data) {
    return DbAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      balance: data.balance.present ? data.balance.value : this.balance,
      balanceMinor: data.balanceMinor.present
          ? data.balanceMinor.value
          : this.balanceMinor,
      openingBalance: data.openingBalance.present
          ? data.openingBalance.value
          : this.openingBalance,
      openingBalanceMinor: data.openingBalanceMinor.present
          ? data.openingBalanceMinor.value
          : this.openingBalanceMinor,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      currencyDesignationId: data.currencyDesignationId.present
          ? data.currencyDesignationId.value
          : this.currencyDesignationId,
      styleId: data.styleId.present ? data.styleId.value : this.styleId,
      accountTypeId: data.accountTypeId.present
          ? data.accountTypeId.value
          : this.accountTypeId,
      creationDate: data.creationDate.present
          ? data.creationDate.value
          : this.creationDate,
      country: data.country.present ? data.country.value : this.country,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      assetQuantity: data.assetQuantity.present
          ? data.assetQuantity.value
          : this.assetQuantity,
      feeStructure: data.feeStructure.present
          ? data.feeStructure.value
          : this.feeStructure,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('balance: $balance, ')
          ..write('balanceMinor: $balanceMinor, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencyDesignationId: $currencyDesignationId, ')
          ..write('styleId: $styleId, ')
          ..write('accountTypeId: $accountTypeId, ')
          ..write('creationDate: $creationDate, ')
          ..write('country: $country, ')
          ..write('assetId: $assetId, ')
          ..write('assetQuantity: $assetQuantity, ')
          ..write('feeStructure: $feeStructure, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    balance,
    balanceMinor,
    openingBalance,
    openingBalanceMinor,
    currencyCode,
    currencyDesignationId,
    styleId,
    accountTypeId,
    creationDate,
    country,
    assetId,
    assetQuantity,
    feeStructure,
    modifiedAt,
    deviceId,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.balance == this.balance &&
          other.balanceMinor == this.balanceMinor &&
          other.openingBalance == this.openingBalance &&
          other.openingBalanceMinor == this.openingBalanceMinor &&
          other.currencyCode == this.currencyCode &&
          other.currencyDesignationId == this.currencyDesignationId &&
          other.styleId == this.styleId &&
          other.accountTypeId == this.accountTypeId &&
          other.creationDate == this.creationDate &&
          other.country == this.country &&
          other.assetId == this.assetId &&
          other.assetQuantity == this.assetQuantity &&
          other.feeStructure == this.feeStructure &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class AccountsCompanion extends UpdateCompanion<DbAccount> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> balance;
  final Value<int?> balanceMinor;
  final Value<double> openingBalance;
  final Value<int?> openingBalanceMinor;
  final Value<String> currencyCode;
  final Value<String> currencyDesignationId;
  final Value<String?> styleId;
  final Value<String> accountTypeId;
  final Value<DateTime> creationDate;
  final Value<String?> country;
  final Value<String?> assetId;
  final Value<double> assetQuantity;
  final Value<String?> feeStructure;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.balance = const Value.absent(),
    this.balanceMinor = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.currencyDesignationId = const Value.absent(),
    this.styleId = const Value.absent(),
    this.accountTypeId = const Value.absent(),
    this.creationDate = const Value.absent(),
    this.country = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetQuantity = const Value.absent(),
    this.feeStructure = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required double balance,
    this.balanceMinor = const Value.absent(),
    this.openingBalance = const Value.absent(),
    this.openingBalanceMinor = const Value.absent(),
    required String currencyCode,
    required String currencyDesignationId,
    this.styleId = const Value.absent(),
    required String accountTypeId,
    this.creationDate = const Value.absent(),
    this.country = const Value.absent(),
    this.assetId = const Value.absent(),
    this.assetQuantity = const Value.absent(),
    this.feeStructure = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       balance = Value(balance),
       currencyCode = Value(currencyCode),
       currencyDesignationId = Value(currencyDesignationId),
       accountTypeId = Value(accountTypeId);
  static Insertable<DbAccount> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<double>? balance,
    Expression<int>? balanceMinor,
    Expression<double>? openingBalance,
    Expression<int>? openingBalanceMinor,
    Expression<String>? currencyCode,
    Expression<String>? currencyDesignationId,
    Expression<String>? styleId,
    Expression<String>? accountTypeId,
    Expression<DateTime>? creationDate,
    Expression<String>? country,
    Expression<String>? assetId,
    Expression<double>? assetQuantity,
    Expression<String>? feeStructure,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (balance != null) 'balance': balance,
      if (balanceMinor != null) 'balance_minor': balanceMinor,
      if (openingBalance != null) 'opening_balance': openingBalance,
      if (openingBalanceMinor != null)
        'opening_balance_minor': openingBalanceMinor,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (currencyDesignationId != null)
        'currency_designation_id': currencyDesignationId,
      if (styleId != null) 'style_id': styleId,
      if (accountTypeId != null) 'account_type_id': accountTypeId,
      if (creationDate != null) 'creation_date': creationDate,
      if (country != null) 'country': country,
      if (assetId != null) 'asset_id': assetId,
      if (assetQuantity != null) 'asset_quantity': assetQuantity,
      if (feeStructure != null) 'fee_structure': feeStructure,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<double>? balance,
    Value<int?>? balanceMinor,
    Value<double>? openingBalance,
    Value<int?>? openingBalanceMinor,
    Value<String>? currencyCode,
    Value<String>? currencyDesignationId,
    Value<String?>? styleId,
    Value<String>? accountTypeId,
    Value<DateTime>? creationDate,
    Value<String?>? country,
    Value<String?>? assetId,
    Value<double>? assetQuantity,
    Value<String?>? feeStructure,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      balance: balance ?? this.balance,
      balanceMinor: balanceMinor ?? this.balanceMinor,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceMinor: openingBalanceMinor ?? this.openingBalanceMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyDesignationId:
          currencyDesignationId ?? this.currencyDesignationId,
      styleId: styleId ?? this.styleId,
      accountTypeId: accountTypeId ?? this.accountTypeId,
      creationDate: creationDate ?? this.creationDate,
      country: country ?? this.country,
      assetId: assetId ?? this.assetId,
      assetQuantity: assetQuantity ?? this.assetQuantity,
      feeStructure: feeStructure ?? this.feeStructure,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (balance.present) {
      map['balance'] = Variable<double>(balance.value);
    }
    if (balanceMinor.present) {
      map['balance_minor'] = Variable<int>(balanceMinor.value);
    }
    if (openingBalance.present) {
      map['opening_balance'] = Variable<double>(openingBalance.value);
    }
    if (openingBalanceMinor.present) {
      map['opening_balance_minor'] = Variable<int>(openingBalanceMinor.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (currencyDesignationId.present) {
      map['currency_designation_id'] = Variable<String>(
        currencyDesignationId.value,
      );
    }
    if (styleId.present) {
      map['style_id'] = Variable<String>(styleId.value);
    }
    if (accountTypeId.present) {
      map['account_type_id'] = Variable<String>(accountTypeId.value);
    }
    if (creationDate.present) {
      map['creation_date'] = Variable<DateTime>(creationDate.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (assetQuantity.present) {
      map['asset_quantity'] = Variable<double>(assetQuantity.value);
    }
    if (feeStructure.present) {
      map['fee_structure'] = Variable<String>(feeStructure.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('balance: $balance, ')
          ..write('balanceMinor: $balanceMinor, ')
          ..write('openingBalance: $openingBalance, ')
          ..write('openingBalanceMinor: $openingBalanceMinor, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencyDesignationId: $currencyDesignationId, ')
          ..write('styleId: $styleId, ')
          ..write('accountTypeId: $accountTypeId, ')
          ..write('creationDate: $creationDate, ')
          ..write('country: $country, ')
          ..write('assetId: $assetId, ')
          ..write('assetQuantity: $assetQuantity, ')
          ..write('feeStructure: $feeStructure, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, Transaction> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMinorMeta = const VerificationMeta(
    'amountMinor',
  );
  @override
  late final GeneratedColumn<int> amountMinor = GeneratedColumn<int>(
    'amount_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<String> categoryId = GeneratedColumn<String>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _exchangeRateMeta = const VerificationMeta(
    'exchangeRate',
  );
  @override
  late final GeneratedColumn<double> exchangeRate = GeneratedColumn<double>(
    'exchange_rate',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exchangeRatePresetMeta =
      const VerificationMeta('exchangeRatePreset');
  @override
  late final GeneratedColumn<int> exchangeRatePreset = GeneratedColumn<int>(
    'exchange_rate_preset',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _feeMeta = const VerificationMeta('fee');
  @override
  late final GeneratedColumn<double> fee = GeneratedColumn<double>(
    'fee',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _feeMinorMeta = const VerificationMeta(
    'feeMinor',
  );
  @override
  late final GeneratedColumn<int> feeMinor = GeneratedColumn<int>(
    'fee_minor',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _linkedTransactionIdMeta =
      const VerificationMeta('linkedTransactionId');
  @override
  late final GeneratedColumn<String> linkedTransactionId =
      GeneratedColumn<String>(
        'linked_transaction_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    description,
    amount,
    amountMinor,
    date,
    accountId,
    categoryId,
    currencyCode,
    exchangeRate,
    exchangeRatePreset,
    fee,
    feeMinor,
    linkedTransactionId,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transaction> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('amount_minor')) {
      context.handle(
        _amountMinorMeta,
        amountMinor.isAcceptableOrUnknown(
          data['amount_minor']!,
          _amountMinorMeta,
        ),
      );
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('exchange_rate')) {
      context.handle(
        _exchangeRateMeta,
        exchangeRate.isAcceptableOrUnknown(
          data['exchange_rate']!,
          _exchangeRateMeta,
        ),
      );
    }
    if (data.containsKey('exchange_rate_preset')) {
      context.handle(
        _exchangeRatePresetMeta,
        exchangeRatePreset.isAcceptableOrUnknown(
          data['exchange_rate_preset']!,
          _exchangeRatePresetMeta,
        ),
      );
    }
    if (data.containsKey('fee')) {
      context.handle(
        _feeMeta,
        fee.isAcceptableOrUnknown(data['fee']!, _feeMeta),
      );
    }
    if (data.containsKey('fee_minor')) {
      context.handle(
        _feeMinorMeta,
        feeMinor.isAcceptableOrUnknown(data['fee_minor']!, _feeMinorMeta),
      );
    }
    if (data.containsKey('linked_transaction_id')) {
      context.handle(
        _linkedTransactionIdMeta,
        linkedTransactionId.isAcceptableOrUnknown(
          data['linked_transaction_id']!,
          _linkedTransactionIdMeta,
        ),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transaction map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transaction(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
      amountMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_minor'],
      ),
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_id'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      exchangeRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}exchange_rate'],
      ),
      exchangeRatePreset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exchange_rate_preset'],
      ),
      fee: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fee'],
      )!,
      feeMinor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fee_minor'],
      ),
      linkedTransactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}linked_transaction_id'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class Transaction extends DataClass implements Insertable<Transaction> {
  final String id;
  final String description;
  final double amount;
  final int? amountMinor;
  final DateTime date;
  final String accountId;
  final String categoryId;
  final String currencyCode;
  final double? exchangeRate;
  final int? exchangeRatePreset;
  final double fee;
  final int? feeMinor;
  final String? linkedTransactionId;
  final int modifiedAt;
  final String? deviceId;
  final bool isDeleted;
  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    this.amountMinor,
    required this.date,
    required this.accountId,
    required this.categoryId,
    required this.currencyCode,
    this.exchangeRate,
    this.exchangeRatePreset,
    required this.fee,
    this.feeMinor,
    this.linkedTransactionId,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<double>(amount);
    if (!nullToAbsent || amountMinor != null) {
      map['amount_minor'] = Variable<int>(amountMinor);
    }
    map['date'] = Variable<DateTime>(date);
    map['account_id'] = Variable<String>(accountId);
    map['category_id'] = Variable<String>(categoryId);
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || exchangeRate != null) {
      map['exchange_rate'] = Variable<double>(exchangeRate);
    }
    if (!nullToAbsent || exchangeRatePreset != null) {
      map['exchange_rate_preset'] = Variable<int>(exchangeRatePreset);
    }
    map['fee'] = Variable<double>(fee);
    if (!nullToAbsent || feeMinor != null) {
      map['fee_minor'] = Variable<int>(feeMinor);
    }
    if (!nullToAbsent || linkedTransactionId != null) {
      map['linked_transaction_id'] = Variable<String>(linkedTransactionId);
    }
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      description: Value(description),
      amount: Value(amount),
      amountMinor: amountMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(amountMinor),
      date: Value(date),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      currencyCode: Value(currencyCode),
      exchangeRate: exchangeRate == null && nullToAbsent
          ? const Value.absent()
          : Value(exchangeRate),
      exchangeRatePreset: exchangeRatePreset == null && nullToAbsent
          ? const Value.absent()
          : Value(exchangeRatePreset),
      fee: Value(fee),
      feeMinor: feeMinor == null && nullToAbsent
          ? const Value.absent()
          : Value(feeMinor),
      linkedTransactionId: linkedTransactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedTransactionId),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory Transaction.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transaction(
      id: serializer.fromJson<String>(json['id']),
      description: serializer.fromJson<String>(json['description']),
      amount: serializer.fromJson<double>(json['amount']),
      amountMinor: serializer.fromJson<int?>(json['amountMinor']),
      date: serializer.fromJson<DateTime>(json['date']),
      accountId: serializer.fromJson<String>(json['accountId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      exchangeRate: serializer.fromJson<double?>(json['exchangeRate']),
      exchangeRatePreset: serializer.fromJson<int?>(json['exchangeRatePreset']),
      fee: serializer.fromJson<double>(json['fee']),
      feeMinor: serializer.fromJson<int?>(json['feeMinor']),
      linkedTransactionId: serializer.fromJson<String?>(
        json['linkedTransactionId'],
      ),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<double>(amount),
      'amountMinor': serializer.toJson<int?>(amountMinor),
      'date': serializer.toJson<DateTime>(date),
      'accountId': serializer.toJson<String>(accountId),
      'categoryId': serializer.toJson<String>(categoryId),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'exchangeRate': serializer.toJson<double?>(exchangeRate),
      'exchangeRatePreset': serializer.toJson<int?>(exchangeRatePreset),
      'fee': serializer.toJson<double>(fee),
      'feeMinor': serializer.toJson<int?>(feeMinor),
      'linkedTransactionId': serializer.toJson<String?>(linkedTransactionId),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    Value<int?> amountMinor = const Value.absent(),
    DateTime? date,
    String? accountId,
    String? categoryId,
    String? currencyCode,
    Value<double?> exchangeRate = const Value.absent(),
    Value<int?> exchangeRatePreset = const Value.absent(),
    double? fee,
    Value<int?> feeMinor = const Value.absent(),
    Value<String?> linkedTransactionId = const Value.absent(),
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => Transaction(
    id: id ?? this.id,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    amountMinor: amountMinor.present ? amountMinor.value : this.amountMinor,
    date: date ?? this.date,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    currencyCode: currencyCode ?? this.currencyCode,
    exchangeRate: exchangeRate.present ? exchangeRate.value : this.exchangeRate,
    exchangeRatePreset: exchangeRatePreset.present
        ? exchangeRatePreset.value
        : this.exchangeRatePreset,
    fee: fee ?? this.fee,
    feeMinor: feeMinor.present ? feeMinor.value : this.feeMinor,
    linkedTransactionId: linkedTransactionId.present
        ? linkedTransactionId.value
        : this.linkedTransactionId,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      description: data.description.present
          ? data.description.value
          : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      amountMinor: data.amountMinor.present
          ? data.amountMinor.value
          : this.amountMinor,
      date: data.date.present ? data.date.value : this.date,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      exchangeRate: data.exchangeRate.present
          ? data.exchangeRate.value
          : this.exchangeRate,
      exchangeRatePreset: data.exchangeRatePreset.present
          ? data.exchangeRatePreset.value
          : this.exchangeRatePreset,
      fee: data.fee.present ? data.fee.value : this.fee,
      feeMinor: data.feeMinor.present ? data.feeMinor.value : this.feeMinor,
      linkedTransactionId: data.linkedTransactionId.present
          ? data.linkedTransactionId.value
          : this.linkedTransactionId,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('exchangeRatePreset: $exchangeRatePreset, ')
          ..write('fee: $fee, ')
          ..write('feeMinor: $feeMinor, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    description,
    amount,
    amountMinor,
    date,
    accountId,
    categoryId,
    currencyCode,
    exchangeRate,
    exchangeRatePreset,
    fee,
    feeMinor,
    linkedTransactionId,
    modifiedAt,
    deviceId,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.amountMinor == this.amountMinor &&
          other.date == this.date &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.currencyCode == this.currencyCode &&
          other.exchangeRate == this.exchangeRate &&
          other.exchangeRatePreset == this.exchangeRatePreset &&
          other.fee == this.fee &&
          other.feeMinor == this.feeMinor &&
          other.linkedTransactionId == this.linkedTransactionId &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> description;
  final Value<double> amount;
  final Value<int?> amountMinor;
  final Value<DateTime> date;
  final Value<String> accountId;
  final Value<String> categoryId;
  final Value<String> currencyCode;
  final Value<double?> exchangeRate;
  final Value<int?> exchangeRatePreset;
  final Value<double> fee;
  final Value<int?> feeMinor;
  final Value<String?> linkedTransactionId;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.amountMinor = const Value.absent(),
    this.date = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.exchangeRate = const Value.absent(),
    this.exchangeRatePreset = const Value.absent(),
    this.fee = const Value.absent(),
    this.feeMinor = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String description,
    required double amount,
    this.amountMinor = const Value.absent(),
    required DateTime date,
    required String accountId,
    required String categoryId,
    required String currencyCode,
    this.exchangeRate = const Value.absent(),
    this.exchangeRatePreset = const Value.absent(),
    this.fee = const Value.absent(),
    this.feeMinor = const Value.absent(),
    this.linkedTransactionId = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : description = Value(description),
       amount = Value(amount),
       date = Value(date),
       accountId = Value(accountId),
       categoryId = Value(categoryId),
       currencyCode = Value(currencyCode);
  static Insertable<Transaction> custom({
    Expression<String>? id,
    Expression<String>? description,
    Expression<double>? amount,
    Expression<int>? amountMinor,
    Expression<DateTime>? date,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<String>? currencyCode,
    Expression<double>? exchangeRate,
    Expression<int>? exchangeRatePreset,
    Expression<double>? fee,
    Expression<int>? feeMinor,
    Expression<String>? linkedTransactionId,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (amountMinor != null) 'amount_minor': amountMinor,
      if (date != null) 'date': date,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (exchangeRate != null) 'exchange_rate': exchangeRate,
      if (exchangeRatePreset != null)
        'exchange_rate_preset': exchangeRatePreset,
      if (fee != null) 'fee': fee,
      if (feeMinor != null) 'fee_minor': feeMinor,
      if (linkedTransactionId != null)
        'linked_transaction_id': linkedTransactionId,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? description,
    Value<double>? amount,
    Value<int?>? amountMinor,
    Value<DateTime>? date,
    Value<String>? accountId,
    Value<String>? categoryId,
    Value<String>? currencyCode,
    Value<double?>? exchangeRate,
    Value<int?>? exchangeRatePreset,
    Value<double>? fee,
    Value<int?>? feeMinor,
    Value<String?>? linkedTransactionId,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      amountMinor: amountMinor ?? this.amountMinor,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      currencyCode: currencyCode ?? this.currencyCode,
      exchangeRate: exchangeRate ?? this.exchangeRate,
      exchangeRatePreset: exchangeRatePreset ?? this.exchangeRatePreset,
      fee: fee ?? this.fee,
      feeMinor: feeMinor ?? this.feeMinor,
      linkedTransactionId: linkedTransactionId ?? this.linkedTransactionId,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (amountMinor.present) {
      map['amount_minor'] = Variable<int>(amountMinor.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<String>(categoryId.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (exchangeRate.present) {
      map['exchange_rate'] = Variable<double>(exchangeRate.value);
    }
    if (exchangeRatePreset.present) {
      map['exchange_rate_preset'] = Variable<int>(exchangeRatePreset.value);
    }
    if (fee.present) {
      map['fee'] = Variable<double>(fee.value);
    }
    if (feeMinor.present) {
      map['fee_minor'] = Variable<int>(feeMinor.value);
    }
    if (linkedTransactionId.present) {
      map['linked_transaction_id'] = Variable<String>(
        linkedTransactionId.value,
      );
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('amountMinor: $amountMinor, ')
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('exchangeRate: $exchangeRate, ')
          ..write('exchangeRatePreset: $exchangeRatePreset, ')
          ..write('fee: $fee, ')
          ..write('feeMinor: $feeMinor, ')
          ..write('linkedTransactionId: $linkedTransactionId, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ExchangeRatesTable extends ExchangeRates
    with TableInfo<$ExchangeRatesTable, ExchangeRate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExchangeRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromCurrencyCodeMeta = const VerificationMeta(
    'fromCurrencyCode',
  );
  @override
  late final GeneratedColumn<String> fromCurrencyCode = GeneratedColumn<String>(
    'from_currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _toCurrencyCodeMeta = const VerificationMeta(
    'toCurrencyCode',
  );
  @override
  late final GeneratedColumn<String> toCurrencyCode = GeneratedColumn<String>(
    'to_currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _rateMeta = const VerificationMeta('rate');
  @override
  late final GeneratedColumn<double> rate = GeneratedColumn<double>(
    'rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presetMeta = const VerificationMeta('preset');
  @override
  late final GeneratedColumn<int> preset = GeneratedColumn<int>(
    'preset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    fromCurrencyCode,
    toCurrencyCode,
    rate,
    preset,
    date,
    modifiedAt,
    deviceId,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exchange_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<ExchangeRate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_currency_code')) {
      context.handle(
        _fromCurrencyCodeMeta,
        fromCurrencyCode.isAcceptableOrUnknown(
          data['from_currency_code']!,
          _fromCurrencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromCurrencyCodeMeta);
    }
    if (data.containsKey('to_currency_code')) {
      context.handle(
        _toCurrencyCodeMeta,
        toCurrencyCode.isAcceptableOrUnknown(
          data['to_currency_code']!,
          _toCurrencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toCurrencyCodeMeta);
    }
    if (data.containsKey('rate')) {
      context.handle(
        _rateMeta,
        rate.isAcceptableOrUnknown(data['rate']!, _rateMeta),
      );
    } else if (isInserting) {
      context.missing(_rateMeta);
    }
    if (data.containsKey('preset')) {
      context.handle(
        _presetMeta,
        preset.isAcceptableOrUnknown(data['preset']!, _presetMeta),
      );
    } else if (isInserting) {
      context.missing(_presetMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    fromCurrencyCode,
    toCurrencyCode,
    date,
    preset,
  };
  @override
  ExchangeRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExchangeRate(
      fromCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_currency_code'],
      )!,
      toCurrencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_currency_code'],
      )!,
      rate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}rate'],
      )!,
      preset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preset'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
    );
  }

  @override
  $ExchangeRatesTable createAlias(String alias) {
    return $ExchangeRatesTable(attachedDatabase, alias);
  }
}

class ExchangeRate extends DataClass implements Insertable<ExchangeRate> {
  final String fromCurrencyCode;
  final String toCurrencyCode;
  final double rate;
  final int preset;
  final DateTime date;
  final int modifiedAt;
  final String? deviceId;
  final String? sourceId;
  const ExchangeRate({
    required this.fromCurrencyCode,
    required this.toCurrencyCode,
    required this.rate,
    required this.preset,
    required this.date,
    required this.modifiedAt,
    this.deviceId,
    this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_currency_code'] = Variable<String>(fromCurrencyCode);
    map['to_currency_code'] = Variable<String>(toCurrencyCode);
    map['rate'] = Variable<double>(rate);
    map['preset'] = Variable<int>(preset);
    map['date'] = Variable<DateTime>(date);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      fromCurrencyCode: Value(fromCurrencyCode),
      toCurrencyCode: Value(toCurrencyCode),
      rate: Value(rate),
      preset: Value(preset),
      date: Value(date),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
    );
  }

  factory ExchangeRate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExchangeRate(
      fromCurrencyCode: serializer.fromJson<String>(json['fromCurrencyCode']),
      toCurrencyCode: serializer.fromJson<String>(json['toCurrencyCode']),
      rate: serializer.fromJson<double>(json['rate']),
      preset: serializer.fromJson<int>(json['preset']),
      date: serializer.fromJson<DateTime>(json['date']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromCurrencyCode': serializer.toJson<String>(fromCurrencyCode),
      'toCurrencyCode': serializer.toJson<String>(toCurrencyCode),
      'rate': serializer.toJson<double>(rate),
      'preset': serializer.toJson<int>(preset),
      'date': serializer.toJson<DateTime>(date),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'sourceId': serializer.toJson<String?>(sourceId),
    };
  }

  ExchangeRate copyWith({
    String? fromCurrencyCode,
    String? toCurrencyCode,
    double? rate,
    int? preset,
    DateTime? date,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
  }) => ExchangeRate(
    fromCurrencyCode: fromCurrencyCode ?? this.fromCurrencyCode,
    toCurrencyCode: toCurrencyCode ?? this.toCurrencyCode,
    rate: rate ?? this.rate,
    preset: preset ?? this.preset,
    date: date ?? this.date,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
  );
  ExchangeRate copyWithCompanion(ExchangeRatesCompanion data) {
    return ExchangeRate(
      fromCurrencyCode: data.fromCurrencyCode.present
          ? data.fromCurrencyCode.value
          : this.fromCurrencyCode,
      toCurrencyCode: data.toCurrencyCode.present
          ? data.toCurrencyCode.value
          : this.toCurrencyCode,
      rate: data.rate.present ? data.rate.value : this.rate,
      preset: data.preset.present ? data.preset.value : this.preset,
      date: data.date.present ? data.date.value : this.date,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRate(')
          ..write('fromCurrencyCode: $fromCurrencyCode, ')
          ..write('toCurrencyCode: $toCurrencyCode, ')
          ..write('rate: $rate, ')
          ..write('preset: $preset, ')
          ..write('date: $date, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    fromCurrencyCode,
    toCurrencyCode,
    rate,
    preset,
    date,
    modifiedAt,
    deviceId,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRate &&
          other.fromCurrencyCode == this.fromCurrencyCode &&
          other.toCurrencyCode == this.toCurrencyCode &&
          other.rate == this.rate &&
          other.preset == this.preset &&
          other.date == this.date &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.sourceId == this.sourceId);
}

class ExchangeRatesCompanion extends UpdateCompanion<ExchangeRate> {
  final Value<String> fromCurrencyCode;
  final Value<String> toCurrencyCode;
  final Value<double> rate;
  final Value<int> preset;
  final Value<DateTime> date;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<String?> sourceId;
  final Value<int> rowid;
  const ExchangeRatesCompanion({
    this.fromCurrencyCode = const Value.absent(),
    this.toCurrencyCode = const Value.absent(),
    this.rate = const Value.absent(),
    this.preset = const Value.absent(),
    this.date = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    required String fromCurrencyCode,
    required String toCurrencyCode,
    required double rate,
    required int preset,
    required DateTime date,
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fromCurrencyCode = Value(fromCurrencyCode),
       toCurrencyCode = Value(toCurrencyCode),
       rate = Value(rate),
       preset = Value(preset),
       date = Value(date);
  static Insertable<ExchangeRate> custom({
    Expression<String>? fromCurrencyCode,
    Expression<String>? toCurrencyCode,
    Expression<double>? rate,
    Expression<int>? preset,
    Expression<DateTime>? date,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromCurrencyCode != null) 'from_currency_code': fromCurrencyCode,
      if (toCurrencyCode != null) 'to_currency_code': toCurrencyCode,
      if (rate != null) 'rate': rate,
      if (preset != null) 'preset': preset,
      if (date != null) 'date': date,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeRatesCompanion copyWith({
    Value<String>? fromCurrencyCode,
    Value<String>? toCurrencyCode,
    Value<double>? rate,
    Value<int>? preset,
    Value<DateTime>? date,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<String?>? sourceId,
    Value<int>? rowid,
  }) {
    return ExchangeRatesCompanion(
      fromCurrencyCode: fromCurrencyCode ?? this.fromCurrencyCode,
      toCurrencyCode: toCurrencyCode ?? this.toCurrencyCode,
      rate: rate ?? this.rate,
      preset: preset ?? this.preset,
      date: date ?? this.date,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromCurrencyCode.present) {
      map['from_currency_code'] = Variable<String>(fromCurrencyCode.value);
    }
    if (toCurrencyCode.present) {
      map['to_currency_code'] = Variable<String>(toCurrencyCode.value);
    }
    if (rate.present) {
      map['rate'] = Variable<double>(rate.value);
    }
    if (preset.present) {
      map['preset'] = Variable<int>(preset.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRatesCompanion(')
          ..write('fromCurrencyCode: $fromCurrencyCode, ')
          ..write('toCurrencyCode: $toCurrencyCode, ')
          ..write('rate: $rate, ')
          ..write('preset: $preset, ')
          ..write('date: $date, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InflationRatesTable extends InflationRates
    with TableInfo<$InflationRatesTable, InflationRate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InflationRatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _percentMeta = const VerificationMeta(
    'percent',
  );
  @override
  late final GeneratedColumn<double> percent = GeneratedColumn<double>(
    'percent',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryMeta = const VerificationMeta(
    'country',
  );
  @override
  late final GeneratedColumn<String> country = GeneratedColumn<String>(
    'country',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(globalInflationCountry),
  );
  static const VerificationMeta _presetMeta = const VerificationMeta('preset');
  @override
  late final GeneratedColumn<int> preset = GeneratedColumn<int>(
    'preset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    percent,
    country,
    preset,
    modifiedAt,
    deviceId,
    sourceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'inflation_rates';
  @override
  VerificationContext validateIntegrity(
    Insertable<InflationRate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('percent')) {
      context.handle(
        _percentMeta,
        percent.isAcceptableOrUnknown(data['percent']!, _percentMeta),
      );
    } else if (isInserting) {
      context.missing(_percentMeta);
    }
    if (data.containsKey('country')) {
      context.handle(
        _countryMeta,
        country.isAcceptableOrUnknown(data['country']!, _countryMeta),
      );
    }
    if (data.containsKey('preset')) {
      context.handle(
        _presetMeta,
        preset.isAcceptableOrUnknown(data['preset']!, _presetMeta),
      );
    } else if (isInserting) {
      context.missing(_presetMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, country, preset};
  @override
  InflationRate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InflationRate(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      percent: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}percent'],
      )!,
      country: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country'],
      )!,
      preset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preset'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
    );
  }

  @override
  $InflationRatesTable createAlias(String alias) {
    return $InflationRatesTable(attachedDatabase, alias);
  }
}

class InflationRate extends DataClass implements Insertable<InflationRate> {
  final DateTime date;
  final double percent;
  final String country;
  final int preset;
  final int modifiedAt;
  final String? deviceId;
  final String? sourceId;
  const InflationRate({
    required this.date,
    required this.percent,
    required this.country,
    required this.preset,
    required this.modifiedAt,
    this.deviceId,
    this.sourceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<DateTime>(date);
    map['percent'] = Variable<double>(percent);
    map['country'] = Variable<String>(country);
    map['preset'] = Variable<int>(preset);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    return map;
  }

  InflationRatesCompanion toCompanion(bool nullToAbsent) {
    return InflationRatesCompanion(
      date: Value(date),
      percent: Value(percent),
      country: Value(country),
      preset: Value(preset),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
    );
  }

  factory InflationRate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InflationRate(
      date: serializer.fromJson<DateTime>(json['date']),
      percent: serializer.fromJson<double>(json['percent']),
      country: serializer.fromJson<String>(json['country']),
      preset: serializer.fromJson<int>(json['preset']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<DateTime>(date),
      'percent': serializer.toJson<double>(percent),
      'country': serializer.toJson<String>(country),
      'preset': serializer.toJson<int>(preset),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'sourceId': serializer.toJson<String?>(sourceId),
    };
  }

  InflationRate copyWith({
    DateTime? date,
    double? percent,
    String? country,
    int? preset,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
  }) => InflationRate(
    date: date ?? this.date,
    percent: percent ?? this.percent,
    country: country ?? this.country,
    preset: preset ?? this.preset,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
  );
  InflationRate copyWithCompanion(InflationRatesCompanion data) {
    return InflationRate(
      date: data.date.present ? data.date.value : this.date,
      percent: data.percent.present ? data.percent.value : this.percent,
      country: data.country.present ? data.country.value : this.country,
      preset: data.preset.present ? data.preset.value : this.preset,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InflationRate(')
          ..write('date: $date, ')
          ..write('percent: $percent, ')
          ..write('country: $country, ')
          ..write('preset: $preset, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('sourceId: $sourceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    date,
    percent,
    country,
    preset,
    modifiedAt,
    deviceId,
    sourceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InflationRate &&
          other.date == this.date &&
          other.percent == this.percent &&
          other.country == this.country &&
          other.preset == this.preset &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.sourceId == this.sourceId);
}

class InflationRatesCompanion extends UpdateCompanion<InflationRate> {
  final Value<DateTime> date;
  final Value<double> percent;
  final Value<String> country;
  final Value<int> preset;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<String?> sourceId;
  final Value<int> rowid;
  const InflationRatesCompanion({
    this.date = const Value.absent(),
    this.percent = const Value.absent(),
    this.country = const Value.absent(),
    this.preset = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InflationRatesCompanion.insert({
    required DateTime date,
    required double percent,
    this.country = const Value.absent(),
    required int preset,
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       percent = Value(percent),
       preset = Value(preset);
  static Insertable<InflationRate> custom({
    Expression<DateTime>? date,
    Expression<double>? percent,
    Expression<String>? country,
    Expression<int>? preset,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<String>? sourceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (percent != null) 'percent': percent,
      if (country != null) 'country': country,
      if (preset != null) 'preset': preset,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (sourceId != null) 'source_id': sourceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InflationRatesCompanion copyWith({
    Value<DateTime>? date,
    Value<double>? percent,
    Value<String>? country,
    Value<int>? preset,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<String?>? sourceId,
    Value<int>? rowid,
  }) {
    return InflationRatesCompanion(
      date: date ?? this.date,
      percent: percent ?? this.percent,
      country: country ?? this.country,
      preset: preset ?? this.preset,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      sourceId: sourceId ?? this.sourceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (percent.present) {
      map['percent'] = Variable<double>(percent.value);
    }
    if (country.present) {
      map['country'] = Variable<String>(country.value);
    }
    if (preset.present) {
      map['preset'] = Variable<int>(preset.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InflationRatesCompanion(')
          ..write('date: $date, ')
          ..write('percent: $percent, ')
          ..write('country: $country, ')
          ..write('preset: $preset, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('sourceId: $sourceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetEntriesTable extends AssetEntries
    with TableInfo<$AssetEntriesTable, AssetEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _assetIdMeta = const VerificationMeta(
    'assetId',
  );
  @override
  late final GeneratedColumn<String> assetId = GeneratedColumn<String>(
    'asset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _assetTypeMeta = const VerificationMeta(
    'assetType',
  );
  @override
  late final GeneratedColumn<String> assetType = GeneratedColumn<String>(
    'asset_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  @override
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES currencies (code)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _presetMeta = const VerificationMeta('preset');
  @override
  late final GeneratedColumn<int> preset = GeneratedColumn<int>(
    'preset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  @override
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    assetId,
    name,
    date,
    value,
    quantity,
    assetType,
    description,
    currencyCode,
    accountId,
    source,
    preset,
    modifiedAt,
    deviceId,
    sourceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('asset_id')) {
      context.handle(
        _assetIdMeta,
        assetId.isAcceptableOrUnknown(data['asset_id']!, _assetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_assetIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    }
    if (data.containsKey('asset_type')) {
      context.handle(
        _assetTypeMeta,
        assetType.isAcceptableOrUnknown(data['asset_type']!, _assetTypeMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('preset')) {
      context.handle(
        _presetMeta,
        preset.isAcceptableOrUnknown(data['preset']!, _presetMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      assetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      assetType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}asset_type'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      preset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}preset'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $AssetEntriesTable createAlias(String alias) {
    return $AssetEntriesTable(attachedDatabase, alias);
  }
}

class AssetEntry extends DataClass implements Insertable<AssetEntry> {
  final String id;
  final String assetId;
  final String name;
  final DateTime date;
  final double value;
  final double quantity;
  final String? assetType;
  final String? description;
  final String currencyCode;
  final String? accountId;
  final String source;
  final int preset;
  final int modifiedAt;
  final String? deviceId;
  final String? sourceId;
  final bool isDeleted;
  const AssetEntry({
    required this.id,
    required this.assetId,
    required this.name,
    required this.date,
    required this.value,
    required this.quantity,
    this.assetType,
    this.description,
    required this.currencyCode,
    this.accountId,
    required this.source,
    required this.preset,
    required this.modifiedAt,
    this.deviceId,
    this.sourceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['asset_id'] = Variable<String>(assetId);
    map['name'] = Variable<String>(name);
    map['date'] = Variable<DateTime>(date);
    map['value'] = Variable<double>(value);
    map['quantity'] = Variable<double>(quantity);
    if (!nullToAbsent || assetType != null) {
      map['asset_type'] = Variable<String>(assetType);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['currency_code'] = Variable<String>(currencyCode);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['source'] = Variable<String>(source);
    map['preset'] = Variable<int>(preset);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    if (!nullToAbsent || sourceId != null) {
      map['source_id'] = Variable<String>(sourceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  AssetEntriesCompanion toCompanion(bool nullToAbsent) {
    return AssetEntriesCompanion(
      id: Value(id),
      assetId: Value(assetId),
      name: Value(name),
      date: Value(date),
      value: Value(value),
      quantity: Value(quantity),
      assetType: assetType == null && nullToAbsent
          ? const Value.absent()
          : Value(assetType),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      currencyCode: Value(currencyCode),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      source: Value(source),
      preset: Value(preset),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      sourceId: sourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory AssetEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetEntry(
      id: serializer.fromJson<String>(json['id']),
      assetId: serializer.fromJson<String>(json['assetId']),
      name: serializer.fromJson<String>(json['name']),
      date: serializer.fromJson<DateTime>(json['date']),
      value: serializer.fromJson<double>(json['value']),
      quantity: serializer.fromJson<double>(json['quantity']),
      assetType: serializer.fromJson<String?>(json['assetType']),
      description: serializer.fromJson<String?>(json['description']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      source: serializer.fromJson<String>(json['source']),
      preset: serializer.fromJson<int>(json['preset']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      sourceId: serializer.fromJson<String?>(json['sourceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'assetId': serializer.toJson<String>(assetId),
      'name': serializer.toJson<String>(name),
      'date': serializer.toJson<DateTime>(date),
      'value': serializer.toJson<double>(value),
      'quantity': serializer.toJson<double>(quantity),
      'assetType': serializer.toJson<String?>(assetType),
      'description': serializer.toJson<String?>(description),
      'currencyCode': serializer.toJson<String>(currencyCode),
      'accountId': serializer.toJson<String?>(accountId),
      'source': serializer.toJson<String>(source),
      'preset': serializer.toJson<int>(preset),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'sourceId': serializer.toJson<String?>(sourceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  AssetEntry copyWith({
    String? id,
    String? assetId,
    String? name,
    DateTime? date,
    double? value,
    double? quantity,
    Value<String?> assetType = const Value.absent(),
    Value<String?> description = const Value.absent(),
    String? currencyCode,
    Value<String?> accountId = const Value.absent(),
    String? source,
    int? preset,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    Value<String?> sourceId = const Value.absent(),
    bool? isDeleted,
  }) => AssetEntry(
    id: id ?? this.id,
    assetId: assetId ?? this.assetId,
    name: name ?? this.name,
    date: date ?? this.date,
    value: value ?? this.value,
    quantity: quantity ?? this.quantity,
    assetType: assetType.present ? assetType.value : this.assetType,
    description: description.present ? description.value : this.description,
    currencyCode: currencyCode ?? this.currencyCode,
    accountId: accountId.present ? accountId.value : this.accountId,
    source: source ?? this.source,
    preset: preset ?? this.preset,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    sourceId: sourceId.present ? sourceId.value : this.sourceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  AssetEntry copyWithCompanion(AssetEntriesCompanion data) {
    return AssetEntry(
      id: data.id.present ? data.id.value : this.id,
      assetId: data.assetId.present ? data.assetId.value : this.assetId,
      name: data.name.present ? data.name.value : this.name,
      date: data.date.present ? data.date.value : this.date,
      value: data.value.present ? data.value.value : this.value,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      assetType: data.assetType.present ? data.assetType.value : this.assetType,
      description: data.description.present
          ? data.description.value
          : this.description,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      source: data.source.present ? data.source.value : this.source,
      preset: data.preset.present ? data.preset.value : this.preset,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetEntry(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('quantity: $quantity, ')
          ..write('assetType: $assetType, ')
          ..write('description: $description, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('accountId: $accountId, ')
          ..write('source: $source, ')
          ..write('preset: $preset, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('sourceId: $sourceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    assetId,
    name,
    date,
    value,
    quantity,
    assetType,
    description,
    currencyCode,
    accountId,
    source,
    preset,
    modifiedAt,
    deviceId,
    sourceId,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetEntry &&
          other.id == this.id &&
          other.assetId == this.assetId &&
          other.name == this.name &&
          other.date == this.date &&
          other.value == this.value &&
          other.quantity == this.quantity &&
          other.assetType == this.assetType &&
          other.description == this.description &&
          other.currencyCode == this.currencyCode &&
          other.accountId == this.accountId &&
          other.source == this.source &&
          other.preset == this.preset &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.sourceId == this.sourceId &&
          other.isDeleted == this.isDeleted);
}

class AssetEntriesCompanion extends UpdateCompanion<AssetEntry> {
  final Value<String> id;
  final Value<String> assetId;
  final Value<String> name;
  final Value<DateTime> date;
  final Value<double> value;
  final Value<double> quantity;
  final Value<String?> assetType;
  final Value<String?> description;
  final Value<String> currencyCode;
  final Value<String?> accountId;
  final Value<String> source;
  final Value<int> preset;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<String?> sourceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const AssetEntriesCompanion({
    this.id = const Value.absent(),
    this.assetId = const Value.absent(),
    this.name = const Value.absent(),
    this.date = const Value.absent(),
    this.value = const Value.absent(),
    this.quantity = const Value.absent(),
    this.assetType = const Value.absent(),
    this.description = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.accountId = const Value.absent(),
    this.source = const Value.absent(),
    this.preset = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String assetId,
    required String name,
    required DateTime date,
    required double value,
    this.quantity = const Value.absent(),
    this.assetType = const Value.absent(),
    this.description = const Value.absent(),
    required String currencyCode,
    this.accountId = const Value.absent(),
    required String source,
    this.preset = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : assetId = Value(assetId),
       name = Value(name),
       date = Value(date),
       value = Value(value),
       currencyCode = Value(currencyCode),
       source = Value(source);
  static Insertable<AssetEntry> custom({
    Expression<String>? id,
    Expression<String>? assetId,
    Expression<String>? name,
    Expression<DateTime>? date,
    Expression<double>? value,
    Expression<double>? quantity,
    Expression<String>? assetType,
    Expression<String>? description,
    Expression<String>? currencyCode,
    Expression<String>? accountId,
    Expression<String>? source,
    Expression<int>? preset,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<String>? sourceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (assetId != null) 'asset_id': assetId,
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (value != null) 'value': value,
      if (quantity != null) 'quantity': quantity,
      if (assetType != null) 'asset_type': assetType,
      if (description != null) 'description': description,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (accountId != null) 'account_id': accountId,
      if (source != null) 'source': source,
      if (preset != null) 'preset': preset,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (sourceId != null) 'source_id': sourceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? assetId,
    Value<String>? name,
    Value<DateTime>? date,
    Value<double>? value,
    Value<double>? quantity,
    Value<String?>? assetType,
    Value<String?>? description,
    Value<String>? currencyCode,
    Value<String?>? accountId,
    Value<String>? source,
    Value<int>? preset,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<String?>? sourceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return AssetEntriesCompanion(
      id: id ?? this.id,
      assetId: assetId ?? this.assetId,
      name: name ?? this.name,
      date: date ?? this.date,
      value: value ?? this.value,
      quantity: quantity ?? this.quantity,
      assetType: assetType ?? this.assetType,
      description: description ?? this.description,
      currencyCode: currencyCode ?? this.currencyCode,
      accountId: accountId ?? this.accountId,
      source: source ?? this.source,
      preset: preset ?? this.preset,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      sourceId: sourceId ?? this.sourceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (assetId.present) {
      map['asset_id'] = Variable<String>(assetId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (assetType.present) {
      map['asset_type'] = Variable<String>(assetType.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (preset.present) {
      map['preset'] = Variable<int>(preset.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetEntriesCompanion(')
          ..write('id: $id, ')
          ..write('assetId: $assetId, ')
          ..write('name: $name, ')
          ..write('date: $date, ')
          ..write('value: $value, ')
          ..write('quantity: $quantity, ')
          ..write('assetType: $assetType, ')
          ..write('description: $description, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('accountId: $accountId, ')
          ..write('source: $source, ')
          ..write('preset: $preset, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('sourceId: $sourceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceMeta = const VerificationMeta('device');
  @override
  late final GeneratedColumn<String> device = GeneratedColumn<String>(
    'device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    key,
    value,
    device,
    modifiedAt,
    deviceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('device')) {
      context.handle(
        _deviceMeta,
        device.isAcceptableOrUnknown(data['device']!, _deviceMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      device: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  final String? device;
  final int modifiedAt;
  final String? deviceId;
  const Setting({
    required this.key,
    required this.value,
    this.device,
    required this.modifiedAt,
    this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    if (!nullToAbsent || device != null) {
      map['device'] = Variable<String>(device);
    }
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      device: device == null && nullToAbsent
          ? const Value.absent()
          : Value(device),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      device: serializer.fromJson<String?>(json['device']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'device': serializer.toJson<String?>(device),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
    };
  }

  Setting copyWith({
    String? key,
    String? value,
    Value<String?> device = const Value.absent(),
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
  }) => Setting(
    key: key ?? this.key,
    value: value ?? this.value,
    device: device.present ? device.value : this.device,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      device: data.device.present ? data.device.value : this.device,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('device: $device, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, device, modifiedAt, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.device == this.device &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<String?> device;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.device = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.device = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? device,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (device != null) 'device': device,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<String?>? device,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      device: device ?? this.device,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (device.present) {
      map['device'] = Variable<String>(device.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('device: $device, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomThemesTable extends CustomThemes
    with TableInfo<$CustomThemesTable, DbCustomTheme> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomThemesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 50,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _primaryColorHexMeta = const VerificationMeta(
    'primaryColorHex',
  );
  @override
  late final GeneratedColumn<String> primaryColorHex = GeneratedColumn<String>(
    'primary_color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secondaryColorHexMeta = const VerificationMeta(
    'secondaryColorHex',
  );
  @override
  late final GeneratedColumn<String> secondaryColorHex =
      GeneratedColumn<String>(
        'secondary_color_hex',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _surfaceColorHexMeta = const VerificationMeta(
    'surfaceColorHex',
  );
  @override
  late final GeneratedColumn<String> surfaceColorHex = GeneratedColumn<String>(
    'surface_color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _backgroundColorHexMeta =
      const VerificationMeta('backgroundColorHex');
  @override
  late final GeneratedColumn<String> backgroundColorHex =
      GeneratedColumn<String>(
        'background_color_hex',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _backgroundImagePathMeta =
      const VerificationMeta('backgroundImagePath');
  @override
  late final GeneratedColumn<String> backgroundImagePath =
      GeneratedColumn<String>(
        'background_image_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _backgroundImageOpacityMeta =
      const VerificationMeta('backgroundImageOpacity');
  @override
  late final GeneratedColumn<double> backgroundImageOpacity =
      GeneratedColumn<double>(
        'background_image_opacity',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(1.0),
      );
  static const VerificationMeta _backgroundImageBlurMeta =
      const VerificationMeta('backgroundImageBlur');
  @override
  late final GeneratedColumn<double> backgroundImageBlur =
      GeneratedColumn<double>(
        'background_image_blur',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(0.0),
      );
  static const VerificationMeta _windowEffectTypeMeta = const VerificationMeta(
    'windowEffectType',
  );
  @override
  late final GeneratedColumn<int> windowEffectType = GeneratedColumn<int>(
    'window_effect_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _effectOpacityMeta = const VerificationMeta(
    'effectOpacity',
  );
  @override
  late final GeneratedColumn<double> effectOpacity = GeneratedColumn<double>(
    'effect_opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _surfaceOpacityMeta = const VerificationMeta(
    'surfaceOpacity',
  );
  @override
  late final GeneratedColumn<double> surfaceOpacity = GeneratedColumn<double>(
    'surface_opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1.0),
  );
  static const VerificationMeta _themeModeMeta = const VerificationMeta(
    'themeMode',
  );
  @override
  late final GeneratedColumn<int> themeMode = GeneratedColumn<int>(
    'theme_mode',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isPresetMeta = const VerificationMeta(
    'isPreset',
  );
  @override
  late final GeneratedColumn<bool> isPreset = GeneratedColumn<bool>(
    'is_preset',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_preset" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    primaryColorHex,
    secondaryColorHex,
    surfaceColorHex,
    backgroundColorHex,
    backgroundImagePath,
    backgroundImageOpacity,
    backgroundImageBlur,
    windowEffectType,
    effectOpacity,
    surfaceOpacity,
    themeMode,
    isPreset,
    isActive,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_themes';
  @override
  VerificationContext validateIntegrity(
    Insertable<DbCustomTheme> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('primary_color_hex')) {
      context.handle(
        _primaryColorHexMeta,
        primaryColorHex.isAcceptableOrUnknown(
          data['primary_color_hex']!,
          _primaryColorHexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_primaryColorHexMeta);
    }
    if (data.containsKey('secondary_color_hex')) {
      context.handle(
        _secondaryColorHexMeta,
        secondaryColorHex.isAcceptableOrUnknown(
          data['secondary_color_hex']!,
          _secondaryColorHexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_secondaryColorHexMeta);
    }
    if (data.containsKey('surface_color_hex')) {
      context.handle(
        _surfaceColorHexMeta,
        surfaceColorHex.isAcceptableOrUnknown(
          data['surface_color_hex']!,
          _surfaceColorHexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_surfaceColorHexMeta);
    }
    if (data.containsKey('background_color_hex')) {
      context.handle(
        _backgroundColorHexMeta,
        backgroundColorHex.isAcceptableOrUnknown(
          data['background_color_hex']!,
          _backgroundColorHexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_backgroundColorHexMeta);
    }
    if (data.containsKey('background_image_path')) {
      context.handle(
        _backgroundImagePathMeta,
        backgroundImagePath.isAcceptableOrUnknown(
          data['background_image_path']!,
          _backgroundImagePathMeta,
        ),
      );
    }
    if (data.containsKey('background_image_opacity')) {
      context.handle(
        _backgroundImageOpacityMeta,
        backgroundImageOpacity.isAcceptableOrUnknown(
          data['background_image_opacity']!,
          _backgroundImageOpacityMeta,
        ),
      );
    }
    if (data.containsKey('background_image_blur')) {
      context.handle(
        _backgroundImageBlurMeta,
        backgroundImageBlur.isAcceptableOrUnknown(
          data['background_image_blur']!,
          _backgroundImageBlurMeta,
        ),
      );
    }
    if (data.containsKey('window_effect_type')) {
      context.handle(
        _windowEffectTypeMeta,
        windowEffectType.isAcceptableOrUnknown(
          data['window_effect_type']!,
          _windowEffectTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_windowEffectTypeMeta);
    }
    if (data.containsKey('effect_opacity')) {
      context.handle(
        _effectOpacityMeta,
        effectOpacity.isAcceptableOrUnknown(
          data['effect_opacity']!,
          _effectOpacityMeta,
        ),
      );
    }
    if (data.containsKey('surface_opacity')) {
      context.handle(
        _surfaceOpacityMeta,
        surfaceOpacity.isAcceptableOrUnknown(
          data['surface_opacity']!,
          _surfaceOpacityMeta,
        ),
      );
    }
    if (data.containsKey('theme_mode')) {
      context.handle(
        _themeModeMeta,
        themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeModeMeta);
    }
    if (data.containsKey('is_preset')) {
      context.handle(
        _isPresetMeta,
        isPreset.isAcceptableOrUnknown(data['is_preset']!, _isPresetMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DbCustomTheme map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DbCustomTheme(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      primaryColorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}primary_color_hex'],
      )!,
      secondaryColorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secondary_color_hex'],
      )!,
      surfaceColorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}surface_color_hex'],
      )!,
      backgroundColorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_color_hex'],
      )!,
      backgroundImagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background_image_path'],
      ),
      backgroundImageOpacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}background_image_opacity'],
      )!,
      backgroundImageBlur: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}background_image_blur'],
      )!,
      windowEffectType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}window_effect_type'],
      )!,
      effectOpacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}effect_opacity'],
      )!,
      surfaceOpacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}surface_opacity'],
      )!,
      themeMode: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}theme_mode'],
      )!,
      isPreset: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_preset'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CustomThemesTable createAlias(String alias) {
    return $CustomThemesTable(attachedDatabase, alias);
  }
}

class DbCustomTheme extends DataClass implements Insertable<DbCustomTheme> {
  final String id;
  final String name;
  final String primaryColorHex;
  final String secondaryColorHex;
  final String surfaceColorHex;
  final String backgroundColorHex;
  final String? backgroundImagePath;
  final double backgroundImageOpacity;
  final double backgroundImageBlur;
  final int windowEffectType;
  final double effectOpacity;
  final double surfaceOpacity;
  final int themeMode;
  final bool isPreset;
  final bool isActive;
  final int modifiedAt;
  final String? deviceId;
  final bool isDeleted;
  const DbCustomTheme({
    required this.id,
    required this.name,
    required this.primaryColorHex,
    required this.secondaryColorHex,
    required this.surfaceColorHex,
    required this.backgroundColorHex,
    this.backgroundImagePath,
    required this.backgroundImageOpacity,
    required this.backgroundImageBlur,
    required this.windowEffectType,
    required this.effectOpacity,
    required this.surfaceOpacity,
    required this.themeMode,
    required this.isPreset,
    required this.isActive,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['primary_color_hex'] = Variable<String>(primaryColorHex);
    map['secondary_color_hex'] = Variable<String>(secondaryColorHex);
    map['surface_color_hex'] = Variable<String>(surfaceColorHex);
    map['background_color_hex'] = Variable<String>(backgroundColorHex);
    if (!nullToAbsent || backgroundImagePath != null) {
      map['background_image_path'] = Variable<String>(backgroundImagePath);
    }
    map['background_image_opacity'] = Variable<double>(backgroundImageOpacity);
    map['background_image_blur'] = Variable<double>(backgroundImageBlur);
    map['window_effect_type'] = Variable<int>(windowEffectType);
    map['effect_opacity'] = Variable<double>(effectOpacity);
    map['surface_opacity'] = Variable<double>(surfaceOpacity);
    map['theme_mode'] = Variable<int>(themeMode);
    map['is_preset'] = Variable<bool>(isPreset);
    map['is_active'] = Variable<bool>(isActive);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CustomThemesCompanion toCompanion(bool nullToAbsent) {
    return CustomThemesCompanion(
      id: Value(id),
      name: Value(name),
      primaryColorHex: Value(primaryColorHex),
      secondaryColorHex: Value(secondaryColorHex),
      surfaceColorHex: Value(surfaceColorHex),
      backgroundColorHex: Value(backgroundColorHex),
      backgroundImagePath: backgroundImagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(backgroundImagePath),
      backgroundImageOpacity: Value(backgroundImageOpacity),
      backgroundImageBlur: Value(backgroundImageBlur),
      windowEffectType: Value(windowEffectType),
      effectOpacity: Value(effectOpacity),
      surfaceOpacity: Value(surfaceOpacity),
      themeMode: Value(themeMode),
      isPreset: Value(isPreset),
      isActive: Value(isActive),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory DbCustomTheme.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DbCustomTheme(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      primaryColorHex: serializer.fromJson<String>(json['primaryColorHex']),
      secondaryColorHex: serializer.fromJson<String>(json['secondaryColorHex']),
      surfaceColorHex: serializer.fromJson<String>(json['surfaceColorHex']),
      backgroundColorHex: serializer.fromJson<String>(
        json['backgroundColorHex'],
      ),
      backgroundImagePath: serializer.fromJson<String?>(
        json['backgroundImagePath'],
      ),
      backgroundImageOpacity: serializer.fromJson<double>(
        json['backgroundImageOpacity'],
      ),
      backgroundImageBlur: serializer.fromJson<double>(
        json['backgroundImageBlur'],
      ),
      windowEffectType: serializer.fromJson<int>(json['windowEffectType']),
      effectOpacity: serializer.fromJson<double>(json['effectOpacity']),
      surfaceOpacity: serializer.fromJson<double>(json['surfaceOpacity']),
      themeMode: serializer.fromJson<int>(json['themeMode']),
      isPreset: serializer.fromJson<bool>(json['isPreset']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'primaryColorHex': serializer.toJson<String>(primaryColorHex),
      'secondaryColorHex': serializer.toJson<String>(secondaryColorHex),
      'surfaceColorHex': serializer.toJson<String>(surfaceColorHex),
      'backgroundColorHex': serializer.toJson<String>(backgroundColorHex),
      'backgroundImagePath': serializer.toJson<String?>(backgroundImagePath),
      'backgroundImageOpacity': serializer.toJson<double>(
        backgroundImageOpacity,
      ),
      'backgroundImageBlur': serializer.toJson<double>(backgroundImageBlur),
      'windowEffectType': serializer.toJson<int>(windowEffectType),
      'effectOpacity': serializer.toJson<double>(effectOpacity),
      'surfaceOpacity': serializer.toJson<double>(surfaceOpacity),
      'themeMode': serializer.toJson<int>(themeMode),
      'isPreset': serializer.toJson<bool>(isPreset),
      'isActive': serializer.toJson<bool>(isActive),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  DbCustomTheme copyWith({
    String? id,
    String? name,
    String? primaryColorHex,
    String? secondaryColorHex,
    String? surfaceColorHex,
    String? backgroundColorHex,
    Value<String?> backgroundImagePath = const Value.absent(),
    double? backgroundImageOpacity,
    double? backgroundImageBlur,
    int? windowEffectType,
    double? effectOpacity,
    double? surfaceOpacity,
    int? themeMode,
    bool? isPreset,
    bool? isActive,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => DbCustomTheme(
    id: id ?? this.id,
    name: name ?? this.name,
    primaryColorHex: primaryColorHex ?? this.primaryColorHex,
    secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
    surfaceColorHex: surfaceColorHex ?? this.surfaceColorHex,
    backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
    backgroundImagePath: backgroundImagePath.present
        ? backgroundImagePath.value
        : this.backgroundImagePath,
    backgroundImageOpacity:
        backgroundImageOpacity ?? this.backgroundImageOpacity,
    backgroundImageBlur: backgroundImageBlur ?? this.backgroundImageBlur,
    windowEffectType: windowEffectType ?? this.windowEffectType,
    effectOpacity: effectOpacity ?? this.effectOpacity,
    surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
    themeMode: themeMode ?? this.themeMode,
    isPreset: isPreset ?? this.isPreset,
    isActive: isActive ?? this.isActive,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  DbCustomTheme copyWithCompanion(CustomThemesCompanion data) {
    return DbCustomTheme(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      primaryColorHex: data.primaryColorHex.present
          ? data.primaryColorHex.value
          : this.primaryColorHex,
      secondaryColorHex: data.secondaryColorHex.present
          ? data.secondaryColorHex.value
          : this.secondaryColorHex,
      surfaceColorHex: data.surfaceColorHex.present
          ? data.surfaceColorHex.value
          : this.surfaceColorHex,
      backgroundColorHex: data.backgroundColorHex.present
          ? data.backgroundColorHex.value
          : this.backgroundColorHex,
      backgroundImagePath: data.backgroundImagePath.present
          ? data.backgroundImagePath.value
          : this.backgroundImagePath,
      backgroundImageOpacity: data.backgroundImageOpacity.present
          ? data.backgroundImageOpacity.value
          : this.backgroundImageOpacity,
      backgroundImageBlur: data.backgroundImageBlur.present
          ? data.backgroundImageBlur.value
          : this.backgroundImageBlur,
      windowEffectType: data.windowEffectType.present
          ? data.windowEffectType.value
          : this.windowEffectType,
      effectOpacity: data.effectOpacity.present
          ? data.effectOpacity.value
          : this.effectOpacity,
      surfaceOpacity: data.surfaceOpacity.present
          ? data.surfaceOpacity.value
          : this.surfaceOpacity,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      isPreset: data.isPreset.present ? data.isPreset.value : this.isPreset,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbCustomTheme(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('primaryColorHex: $primaryColorHex, ')
          ..write('secondaryColorHex: $secondaryColorHex, ')
          ..write('surfaceColorHex: $surfaceColorHex, ')
          ..write('backgroundColorHex: $backgroundColorHex, ')
          ..write('backgroundImagePath: $backgroundImagePath, ')
          ..write('backgroundImageOpacity: $backgroundImageOpacity, ')
          ..write('backgroundImageBlur: $backgroundImageBlur, ')
          ..write('windowEffectType: $windowEffectType, ')
          ..write('effectOpacity: $effectOpacity, ')
          ..write('surfaceOpacity: $surfaceOpacity, ')
          ..write('themeMode: $themeMode, ')
          ..write('isPreset: $isPreset, ')
          ..write('isActive: $isActive, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    primaryColorHex,
    secondaryColorHex,
    surfaceColorHex,
    backgroundColorHex,
    backgroundImagePath,
    backgroundImageOpacity,
    backgroundImageBlur,
    windowEffectType,
    effectOpacity,
    surfaceOpacity,
    themeMode,
    isPreset,
    isActive,
    modifiedAt,
    deviceId,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbCustomTheme &&
          other.id == this.id &&
          other.name == this.name &&
          other.primaryColorHex == this.primaryColorHex &&
          other.secondaryColorHex == this.secondaryColorHex &&
          other.surfaceColorHex == this.surfaceColorHex &&
          other.backgroundColorHex == this.backgroundColorHex &&
          other.backgroundImagePath == this.backgroundImagePath &&
          other.backgroundImageOpacity == this.backgroundImageOpacity &&
          other.backgroundImageBlur == this.backgroundImageBlur &&
          other.windowEffectType == this.windowEffectType &&
          other.effectOpacity == this.effectOpacity &&
          other.surfaceOpacity == this.surfaceOpacity &&
          other.themeMode == this.themeMode &&
          other.isPreset == this.isPreset &&
          other.isActive == this.isActive &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class CustomThemesCompanion extends UpdateCompanion<DbCustomTheme> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> primaryColorHex;
  final Value<String> secondaryColorHex;
  final Value<String> surfaceColorHex;
  final Value<String> backgroundColorHex;
  final Value<String?> backgroundImagePath;
  final Value<double> backgroundImageOpacity;
  final Value<double> backgroundImageBlur;
  final Value<int> windowEffectType;
  final Value<double> effectOpacity;
  final Value<double> surfaceOpacity;
  final Value<int> themeMode;
  final Value<bool> isPreset;
  final Value<bool> isActive;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const CustomThemesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.primaryColorHex = const Value.absent(),
    this.secondaryColorHex = const Value.absent(),
    this.surfaceColorHex = const Value.absent(),
    this.backgroundColorHex = const Value.absent(),
    this.backgroundImagePath = const Value.absent(),
    this.backgroundImageOpacity = const Value.absent(),
    this.backgroundImageBlur = const Value.absent(),
    this.windowEffectType = const Value.absent(),
    this.effectOpacity = const Value.absent(),
    this.surfaceOpacity = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.isPreset = const Value.absent(),
    this.isActive = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomThemesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String primaryColorHex,
    required String secondaryColorHex,
    required String surfaceColorHex,
    required String backgroundColorHex,
    this.backgroundImagePath = const Value.absent(),
    this.backgroundImageOpacity = const Value.absent(),
    this.backgroundImageBlur = const Value.absent(),
    required int windowEffectType,
    this.effectOpacity = const Value.absent(),
    this.surfaceOpacity = const Value.absent(),
    required int themeMode,
    this.isPreset = const Value.absent(),
    this.isActive = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       primaryColorHex = Value(primaryColorHex),
       secondaryColorHex = Value(secondaryColorHex),
       surfaceColorHex = Value(surfaceColorHex),
       backgroundColorHex = Value(backgroundColorHex),
       windowEffectType = Value(windowEffectType),
       themeMode = Value(themeMode);
  static Insertable<DbCustomTheme> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? primaryColorHex,
    Expression<String>? secondaryColorHex,
    Expression<String>? surfaceColorHex,
    Expression<String>? backgroundColorHex,
    Expression<String>? backgroundImagePath,
    Expression<double>? backgroundImageOpacity,
    Expression<double>? backgroundImageBlur,
    Expression<int>? windowEffectType,
    Expression<double>? effectOpacity,
    Expression<double>? surfaceOpacity,
    Expression<int>? themeMode,
    Expression<bool>? isPreset,
    Expression<bool>? isActive,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (primaryColorHex != null) 'primary_color_hex': primaryColorHex,
      if (secondaryColorHex != null) 'secondary_color_hex': secondaryColorHex,
      if (surfaceColorHex != null) 'surface_color_hex': surfaceColorHex,
      if (backgroundColorHex != null)
        'background_color_hex': backgroundColorHex,
      if (backgroundImagePath != null)
        'background_image_path': backgroundImagePath,
      if (backgroundImageOpacity != null)
        'background_image_opacity': backgroundImageOpacity,
      if (backgroundImageBlur != null)
        'background_image_blur': backgroundImageBlur,
      if (windowEffectType != null) 'window_effect_type': windowEffectType,
      if (effectOpacity != null) 'effect_opacity': effectOpacity,
      if (surfaceOpacity != null) 'surface_opacity': surfaceOpacity,
      if (themeMode != null) 'theme_mode': themeMode,
      if (isPreset != null) 'is_preset': isPreset,
      if (isActive != null) 'is_active': isActive,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomThemesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? primaryColorHex,
    Value<String>? secondaryColorHex,
    Value<String>? surfaceColorHex,
    Value<String>? backgroundColorHex,
    Value<String?>? backgroundImagePath,
    Value<double>? backgroundImageOpacity,
    Value<double>? backgroundImageBlur,
    Value<int>? windowEffectType,
    Value<double>? effectOpacity,
    Value<double>? surfaceOpacity,
    Value<int>? themeMode,
    Value<bool>? isPreset,
    Value<bool>? isActive,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return CustomThemesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      secondaryColorHex: secondaryColorHex ?? this.secondaryColorHex,
      surfaceColorHex: surfaceColorHex ?? this.surfaceColorHex,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      backgroundImageOpacity:
          backgroundImageOpacity ?? this.backgroundImageOpacity,
      backgroundImageBlur: backgroundImageBlur ?? this.backgroundImageBlur,
      windowEffectType: windowEffectType ?? this.windowEffectType,
      effectOpacity: effectOpacity ?? this.effectOpacity,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      themeMode: themeMode ?? this.themeMode,
      isPreset: isPreset ?? this.isPreset,
      isActive: isActive ?? this.isActive,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (primaryColorHex.present) {
      map['primary_color_hex'] = Variable<String>(primaryColorHex.value);
    }
    if (secondaryColorHex.present) {
      map['secondary_color_hex'] = Variable<String>(secondaryColorHex.value);
    }
    if (surfaceColorHex.present) {
      map['surface_color_hex'] = Variable<String>(surfaceColorHex.value);
    }
    if (backgroundColorHex.present) {
      map['background_color_hex'] = Variable<String>(backgroundColorHex.value);
    }
    if (backgroundImagePath.present) {
      map['background_image_path'] = Variable<String>(
        backgroundImagePath.value,
      );
    }
    if (backgroundImageOpacity.present) {
      map['background_image_opacity'] = Variable<double>(
        backgroundImageOpacity.value,
      );
    }
    if (backgroundImageBlur.present) {
      map['background_image_blur'] = Variable<double>(
        backgroundImageBlur.value,
      );
    }
    if (windowEffectType.present) {
      map['window_effect_type'] = Variable<int>(windowEffectType.value);
    }
    if (effectOpacity.present) {
      map['effect_opacity'] = Variable<double>(effectOpacity.value);
    }
    if (surfaceOpacity.present) {
      map['surface_opacity'] = Variable<double>(surfaceOpacity.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<int>(themeMode.value);
    }
    if (isPreset.present) {
      map['is_preset'] = Variable<bool>(isPreset.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomThemesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('primaryColorHex: $primaryColorHex, ')
          ..write('secondaryColorHex: $secondaryColorHex, ')
          ..write('surfaceColorHex: $surfaceColorHex, ')
          ..write('backgroundColorHex: $backgroundColorHex, ')
          ..write('backgroundImagePath: $backgroundImagePath, ')
          ..write('backgroundImageOpacity: $backgroundImageOpacity, ')
          ..write('backgroundImageBlur: $backgroundImageBlur, ')
          ..write('windowEffectType: $windowEffectType, ')
          ..write('effectOpacity: $effectOpacity, ')
          ..write('surfaceOpacity: $surfaceOpacity, ')
          ..write('themeMode: $themeMode, ')
          ..write('isPreset: $isPreset, ')
          ..write('isActive: $isActive, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiFetchStatusesTable extends ApiFetchStatuses
    with TableInfo<$ApiFetchStatusesTable, ApiFetchStatus> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiFetchStatusesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastAttemptMeta = const VerificationMeta(
    'lastAttempt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAttempt = GeneratedColumn<DateTime>(
    'last_attempt',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, attempts, lastAttempt, status];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_fetch_statuses';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiFetchStatus> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('last_attempt')) {
      context.handle(
        _lastAttemptMeta,
        lastAttempt.isAcceptableOrUnknown(
          data['last_attempt']!,
          _lastAttemptMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApiFetchStatus map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiFetchStatus(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      lastAttempt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_attempt'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
    );
  }

  @override
  $ApiFetchStatusesTable createAlias(String alias) {
    return $ApiFetchStatusesTable(attachedDatabase, alias);
  }
}

class ApiFetchStatus extends DataClass implements Insertable<ApiFetchStatus> {
  final String id;
  final int attempts;
  final DateTime? lastAttempt;
  final String status;
  const ApiFetchStatus({
    required this.id,
    required this.attempts,
    this.lastAttempt,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['attempts'] = Variable<int>(attempts);
    if (!nullToAbsent || lastAttempt != null) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt);
    }
    map['status'] = Variable<String>(status);
    return map;
  }

  ApiFetchStatusesCompanion toCompanion(bool nullToAbsent) {
    return ApiFetchStatusesCompanion(
      id: Value(id),
      attempts: Value(attempts),
      lastAttempt: lastAttempt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttempt),
      status: Value(status),
    );
  }

  factory ApiFetchStatus.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiFetchStatus(
      id: serializer.fromJson<String>(json['id']),
      attempts: serializer.fromJson<int>(json['attempts']),
      lastAttempt: serializer.fromJson<DateTime?>(json['lastAttempt']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'attempts': serializer.toJson<int>(attempts),
      'lastAttempt': serializer.toJson<DateTime?>(lastAttempt),
      'status': serializer.toJson<String>(status),
    };
  }

  ApiFetchStatus copyWith({
    String? id,
    int? attempts,
    Value<DateTime?> lastAttempt = const Value.absent(),
    String? status,
  }) => ApiFetchStatus(
    id: id ?? this.id,
    attempts: attempts ?? this.attempts,
    lastAttempt: lastAttempt.present ? lastAttempt.value : this.lastAttempt,
    status: status ?? this.status,
  );
  ApiFetchStatus copyWithCompanion(ApiFetchStatusesCompanion data) {
    return ApiFetchStatus(
      id: data.id.present ? data.id.value : this.id,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      lastAttempt: data.lastAttempt.present
          ? data.lastAttempt.value
          : this.lastAttempt,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiFetchStatus(')
          ..write('id: $id, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, attempts, lastAttempt, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiFetchStatus &&
          other.id == this.id &&
          other.attempts == this.attempts &&
          other.lastAttempt == this.lastAttempt &&
          other.status == this.status);
}

class ApiFetchStatusesCompanion extends UpdateCompanion<ApiFetchStatus> {
  final Value<String> id;
  final Value<int> attempts;
  final Value<DateTime?> lastAttempt;
  final Value<String> status;
  final Value<int> rowid;
  const ApiFetchStatusesCompanion({
    this.id = const Value.absent(),
    this.attempts = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiFetchStatusesCompanion.insert({
    required String id,
    this.attempts = const Value.absent(),
    this.lastAttempt = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ApiFetchStatus> custom({
    Expression<String>? id,
    Expression<int>? attempts,
    Expression<DateTime>? lastAttempt,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (attempts != null) 'attempts': attempts,
      if (lastAttempt != null) 'last_attempt': lastAttempt,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiFetchStatusesCompanion copyWith({
    Value<String>? id,
    Value<int>? attempts,
    Value<DateTime?>? lastAttempt,
    Value<String>? status,
    Value<int>? rowid,
  }) {
    return ApiFetchStatusesCompanion(
      id: id ?? this.id,
      attempts: attempts ?? this.attempts,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (lastAttempt.present) {
      map['last_attempt'] = Variable<DateTime>(lastAttempt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiFetchStatusesCompanion(')
          ..write('id: $id, ')
          ..write('attempts: $attempts, ')
          ..write('lastAttempt: $lastAttempt, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ApiSettingsTableTable extends ApiSettingsTable
    with TableInfo<$ApiSettingsTableTable, ApiSettingsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoFetchMeta = const VerificationMeta(
    'autoFetch',
  );
  @override
  late final GeneratedColumn<bool> autoFetch = GeneratedColumn<bool>(
    'auto_fetch',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_fetch" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastFetchAtMeta = const VerificationMeta(
    'lastFetchAt',
  );
  @override
  late final GeneratedColumn<int> lastFetchAt = GeneratedColumn<int>(
    'last_fetch_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    enabled,
    autoFetch,
    lastFetchAt,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_settings_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiSettingsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('auto_fetch')) {
      context.handle(
        _autoFetchMeta,
        autoFetch.isAcceptableOrUnknown(data['auto_fetch']!, _autoFetchMeta),
      );
    }
    if (data.containsKey('last_fetch_at')) {
      context.handle(
        _lastFetchAtMeta,
        lastFetchAt.isAcceptableOrUnknown(
          data['last_fetch_at']!,
          _lastFetchAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ApiSettingsTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiSettingsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      autoFetch: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_fetch'],
      )!,
      lastFetchAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_fetch_at'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $ApiSettingsTableTable createAlias(String alias) {
    return $ApiSettingsTableTable(attachedDatabase, alias);
  }
}

class ApiSettingsTableData extends DataClass
    implements Insertable<ApiSettingsTableData> {
  final String id;
  final bool enabled;
  final bool autoFetch;
  final int? lastFetchAt;
  final int modifiedAt;
  final String? deviceId;

  /// Tombstone flag, like every other synced table.
  ///
  /// Without it a delete for a provider row the peer had never seen was a
  /// no-op there, and the upsert that had been sitting in an earlier file
  /// simply recreated the row - a provider the user removed came back, and
  /// started fetching again.
  final bool isDeleted;
  const ApiSettingsTableData({
    required this.id,
    required this.enabled,
    required this.autoFetch,
    this.lastFetchAt,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['auto_fetch'] = Variable<bool>(autoFetch);
    if (!nullToAbsent || lastFetchAt != null) {
      map['last_fetch_at'] = Variable<int>(lastFetchAt);
    }
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  ApiSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return ApiSettingsTableCompanion(
      id: Value(id),
      enabled: Value(enabled),
      autoFetch: Value(autoFetch),
      lastFetchAt: lastFetchAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchAt),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory ApiSettingsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiSettingsTableData(
      id: serializer.fromJson<String>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      autoFetch: serializer.fromJson<bool>(json['autoFetch']),
      lastFetchAt: serializer.fromJson<int?>(json['lastFetchAt']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'autoFetch': serializer.toJson<bool>(autoFetch),
      'lastFetchAt': serializer.toJson<int?>(lastFetchAt),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  ApiSettingsTableData copyWith({
    String? id,
    bool? enabled,
    bool? autoFetch,
    Value<int?> lastFetchAt = const Value.absent(),
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => ApiSettingsTableData(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    autoFetch: autoFetch ?? this.autoFetch,
    lastFetchAt: lastFetchAt.present ? lastFetchAt.value : this.lastFetchAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  ApiSettingsTableData copyWithCompanion(ApiSettingsTableCompanion data) {
    return ApiSettingsTableData(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      autoFetch: data.autoFetch.present ? data.autoFetch.value : this.autoFetch,
      lastFetchAt: data.lastFetchAt.present
          ? data.lastFetchAt.value
          : this.lastFetchAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiSettingsTableData(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('autoFetch: $autoFetch, ')
          ..write('lastFetchAt: $lastFetchAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    enabled,
    autoFetch,
    lastFetchAt,
    modifiedAt,
    deviceId,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiSettingsTableData &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.autoFetch == this.autoFetch &&
          other.lastFetchAt == this.lastFetchAt &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class ApiSettingsTableCompanion extends UpdateCompanion<ApiSettingsTableData> {
  final Value<String> id;
  final Value<bool> enabled;
  final Value<bool> autoFetch;
  final Value<int?> lastFetchAt;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const ApiSettingsTableCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.autoFetch = const Value.absent(),
    this.lastFetchAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiSettingsTableCompanion.insert({
    required String id,
    this.enabled = const Value.absent(),
    this.autoFetch = const Value.absent(),
    this.lastFetchAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id);
  static Insertable<ApiSettingsTableData> custom({
    Expression<String>? id,
    Expression<bool>? enabled,
    Expression<bool>? autoFetch,
    Expression<int>? lastFetchAt,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (autoFetch != null) 'auto_fetch': autoFetch,
      if (lastFetchAt != null) 'last_fetch_at': lastFetchAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiSettingsTableCompanion copyWith({
    Value<String>? id,
    Value<bool>? enabled,
    Value<bool>? autoFetch,
    Value<int?>? lastFetchAt,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return ApiSettingsTableCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      autoFetch: autoFetch ?? this.autoFetch,
      lastFetchAt: lastFetchAt ?? this.lastFetchAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (autoFetch.present) {
      map['auto_fetch'] = Variable<bool>(autoFetch.value);
    }
    if (lastFetchAt.present) {
      map['last_fetch_at'] = Variable<int>(lastFetchAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('autoFetch: $autoFetch, ')
          ..write('lastFetchAt: $lastFetchAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SmsPresetsTable extends SmsPresets
    with TableInfo<$SmsPresetsTable, SmsPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SmsPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderFilterMeta = const VerificationMeta(
    'senderFilter',
  );
  @override
  late final GeneratedColumn<String> senderFilter = GeneratedColumn<String>(
    'sender_filter',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isBuiltInMeta = const VerificationMeta(
    'isBuiltIn',
  );
  @override
  late final GeneratedColumn<bool> isBuiltIn = GeneratedColumn<bool>(
    'is_built_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_built_in" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isEnabledMeta = const VerificationMeta(
    'isEnabled',
  );
  @override
  late final GeneratedColumn<bool> isEnabled = GeneratedColumn<bool>(
    'is_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _defaultAccountIdMeta = const VerificationMeta(
    'defaultAccountId',
  );
  @override
  late final GeneratedColumn<String> defaultAccountId = GeneratedColumn<String>(
    'default_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultCategoryIdMeta = const VerificationMeta(
    'defaultCategoryId',
  );
  @override
  late final GeneratedColumn<String> defaultCategoryId =
      GeneratedColumn<String>(
        'default_category_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rulesJsonMeta = const VerificationMeta(
    'rulesJson',
  );
  @override
  late final GeneratedColumn<String> rulesJson = GeneratedColumn<String>(
    'rules_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    senderFilter,
    isBuiltIn,
    isEnabled,
    defaultAccountId,
    defaultCategoryId,
    rulesJson,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sms_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SmsPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sender_filter')) {
      context.handle(
        _senderFilterMeta,
        senderFilter.isAcceptableOrUnknown(
          data['sender_filter']!,
          _senderFilterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_senderFilterMeta);
    }
    if (data.containsKey('is_built_in')) {
      context.handle(
        _isBuiltInMeta,
        isBuiltIn.isAcceptableOrUnknown(data['is_built_in']!, _isBuiltInMeta),
      );
    }
    if (data.containsKey('is_enabled')) {
      context.handle(
        _isEnabledMeta,
        isEnabled.isAcceptableOrUnknown(data['is_enabled']!, _isEnabledMeta),
      );
    }
    if (data.containsKey('default_account_id')) {
      context.handle(
        _defaultAccountIdMeta,
        defaultAccountId.isAcceptableOrUnknown(
          data['default_account_id']!,
          _defaultAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('default_category_id')) {
      context.handle(
        _defaultCategoryIdMeta,
        defaultCategoryId.isAcceptableOrUnknown(
          data['default_category_id']!,
          _defaultCategoryIdMeta,
        ),
      );
    }
    if (data.containsKey('rules_json')) {
      context.handle(
        _rulesJsonMeta,
        rulesJson.isAcceptableOrUnknown(data['rules_json']!, _rulesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_rulesJsonMeta);
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SmsPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SmsPreset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      senderFilter: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_filter'],
      )!,
      isBuiltIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_built_in'],
      )!,
      isEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_enabled'],
      )!,
      defaultAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_account_id'],
      ),
      defaultCategoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_category_id'],
      ),
      rulesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rules_json'],
      )!,
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $SmsPresetsTable createAlias(String alias) {
    return $SmsPresetsTable(attachedDatabase, alias);
  }
}

class SmsPreset extends DataClass implements Insertable<SmsPreset> {
  final String id;
  final String name;
  final String senderFilter;
  final bool isBuiltIn;
  final bool isEnabled;
  final String? defaultAccountId;
  final String? defaultCategoryId;
  final String rulesJson;
  final int modifiedAt;
  final String? deviceId;
  final bool isDeleted;
  const SmsPreset({
    required this.id,
    required this.name,
    required this.senderFilter,
    required this.isBuiltIn,
    required this.isEnabled,
    this.defaultAccountId,
    this.defaultCategoryId,
    required this.rulesJson,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['sender_filter'] = Variable<String>(senderFilter);
    map['is_built_in'] = Variable<bool>(isBuiltIn);
    map['is_enabled'] = Variable<bool>(isEnabled);
    if (!nullToAbsent || defaultAccountId != null) {
      map['default_account_id'] = Variable<String>(defaultAccountId);
    }
    if (!nullToAbsent || defaultCategoryId != null) {
      map['default_category_id'] = Variable<String>(defaultCategoryId);
    }
    map['rules_json'] = Variable<String>(rulesJson);
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  SmsPresetsCompanion toCompanion(bool nullToAbsent) {
    return SmsPresetsCompanion(
      id: Value(id),
      name: Value(name),
      senderFilter: Value(senderFilter),
      isBuiltIn: Value(isBuiltIn),
      isEnabled: Value(isEnabled),
      defaultAccountId: defaultAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultAccountId),
      defaultCategoryId: defaultCategoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultCategoryId),
      rulesJson: Value(rulesJson),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory SmsPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SmsPreset(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      senderFilter: serializer.fromJson<String>(json['senderFilter']),
      isBuiltIn: serializer.fromJson<bool>(json['isBuiltIn']),
      isEnabled: serializer.fromJson<bool>(json['isEnabled']),
      defaultAccountId: serializer.fromJson<String?>(json['defaultAccountId']),
      defaultCategoryId: serializer.fromJson<String?>(
        json['defaultCategoryId'],
      ),
      rulesJson: serializer.fromJson<String>(json['rulesJson']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'senderFilter': serializer.toJson<String>(senderFilter),
      'isBuiltIn': serializer.toJson<bool>(isBuiltIn),
      'isEnabled': serializer.toJson<bool>(isEnabled),
      'defaultAccountId': serializer.toJson<String?>(defaultAccountId),
      'defaultCategoryId': serializer.toJson<String?>(defaultCategoryId),
      'rulesJson': serializer.toJson<String>(rulesJson),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  SmsPreset copyWith({
    String? id,
    String? name,
    String? senderFilter,
    bool? isBuiltIn,
    bool? isEnabled,
    Value<String?> defaultAccountId = const Value.absent(),
    Value<String?> defaultCategoryId = const Value.absent(),
    String? rulesJson,
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => SmsPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    senderFilter: senderFilter ?? this.senderFilter,
    isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    isEnabled: isEnabled ?? this.isEnabled,
    defaultAccountId: defaultAccountId.present
        ? defaultAccountId.value
        : this.defaultAccountId,
    defaultCategoryId: defaultCategoryId.present
        ? defaultCategoryId.value
        : this.defaultCategoryId,
    rulesJson: rulesJson ?? this.rulesJson,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  SmsPreset copyWithCompanion(SmsPresetsCompanion data) {
    return SmsPreset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      senderFilter: data.senderFilter.present
          ? data.senderFilter.value
          : this.senderFilter,
      isBuiltIn: data.isBuiltIn.present ? data.isBuiltIn.value : this.isBuiltIn,
      isEnabled: data.isEnabled.present ? data.isEnabled.value : this.isEnabled,
      defaultAccountId: data.defaultAccountId.present
          ? data.defaultAccountId.value
          : this.defaultAccountId,
      defaultCategoryId: data.defaultCategoryId.present
          ? data.defaultCategoryId.value
          : this.defaultCategoryId,
      rulesJson: data.rulesJson.present ? data.rulesJson.value : this.rulesJson,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SmsPreset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('senderFilter: $senderFilter, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('defaultAccountId: $defaultAccountId, ')
          ..write('defaultCategoryId: $defaultCategoryId, ')
          ..write('rulesJson: $rulesJson, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    senderFilter,
    isBuiltIn,
    isEnabled,
    defaultAccountId,
    defaultCategoryId,
    rulesJson,
    modifiedAt,
    deviceId,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SmsPreset &&
          other.id == this.id &&
          other.name == this.name &&
          other.senderFilter == this.senderFilter &&
          other.isBuiltIn == this.isBuiltIn &&
          other.isEnabled == this.isEnabled &&
          other.defaultAccountId == this.defaultAccountId &&
          other.defaultCategoryId == this.defaultCategoryId &&
          other.rulesJson == this.rulesJson &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class SmsPresetsCompanion extends UpdateCompanion<SmsPreset> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> senderFilter;
  final Value<bool> isBuiltIn;
  final Value<bool> isEnabled;
  final Value<String?> defaultAccountId;
  final Value<String?> defaultCategoryId;
  final Value<String> rulesJson;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const SmsPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.senderFilter = const Value.absent(),
    this.isBuiltIn = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.defaultAccountId = const Value.absent(),
    this.defaultCategoryId = const Value.absent(),
    this.rulesJson = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SmsPresetsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String senderFilter,
    this.isBuiltIn = const Value.absent(),
    this.isEnabled = const Value.absent(),
    this.defaultAccountId = const Value.absent(),
    this.defaultCategoryId = const Value.absent(),
    required String rulesJson,
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       senderFilter = Value(senderFilter),
       rulesJson = Value(rulesJson);
  static Insertable<SmsPreset> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? senderFilter,
    Expression<bool>? isBuiltIn,
    Expression<bool>? isEnabled,
    Expression<String>? defaultAccountId,
    Expression<String>? defaultCategoryId,
    Expression<String>? rulesJson,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (senderFilter != null) 'sender_filter': senderFilter,
      if (isBuiltIn != null) 'is_built_in': isBuiltIn,
      if (isEnabled != null) 'is_enabled': isEnabled,
      if (defaultAccountId != null) 'default_account_id': defaultAccountId,
      if (defaultCategoryId != null) 'default_category_id': defaultCategoryId,
      if (rulesJson != null) 'rules_json': rulesJson,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SmsPresetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? senderFilter,
    Value<bool>? isBuiltIn,
    Value<bool>? isEnabled,
    Value<String?>? defaultAccountId,
    Value<String?>? defaultCategoryId,
    Value<String>? rulesJson,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return SmsPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      senderFilter: senderFilter ?? this.senderFilter,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isEnabled: isEnabled ?? this.isEnabled,
      defaultAccountId: defaultAccountId ?? this.defaultAccountId,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      rulesJson: rulesJson ?? this.rulesJson,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (senderFilter.present) {
      map['sender_filter'] = Variable<String>(senderFilter.value);
    }
    if (isBuiltIn.present) {
      map['is_built_in'] = Variable<bool>(isBuiltIn.value);
    }
    if (isEnabled.present) {
      map['is_enabled'] = Variable<bool>(isEnabled.value);
    }
    if (defaultAccountId.present) {
      map['default_account_id'] = Variable<String>(defaultAccountId.value);
    }
    if (defaultCategoryId.present) {
      map['default_category_id'] = Variable<String>(defaultCategoryId.value);
    }
    if (rulesJson.present) {
      map['rules_json'] = Variable<String>(rulesJson.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SmsPresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('senderFilter: $senderFilter, ')
          ..write('isBuiltIn: $isBuiltIn, ')
          ..write('isEnabled: $isEnabled, ')
          ..write('defaultAccountId: $defaultAccountId, ')
          ..write('defaultCategoryId: $defaultCategoryId, ')
          ..write('rulesJson: $rulesJson, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncProcessedFilesTable extends SyncProcessedFiles
    with TableInfo<$SyncProcessedFilesTable, SyncProcessedFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncProcessedFilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _processedAtMeta = const VerificationMeta(
    'processedAt',
  );
  @override
  late final GeneratedColumn<int> processedAt = GeneratedColumn<int>(
    'processed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fileName, processedAt, deviceId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_processed_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncProcessedFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('processed_at')) {
      context.handle(
        _processedAtMeta,
        processedAt.isAcceptableOrUnknown(
          data['processed_at']!,
          _processedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_processedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fileName};
  @override
  SyncProcessedFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncProcessedFile(
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      processedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}processed_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
    );
  }

  @override
  $SyncProcessedFilesTable createAlias(String alias) {
    return $SyncProcessedFilesTable(attachedDatabase, alias);
  }
}

class SyncProcessedFile extends DataClass
    implements Insertable<SyncProcessedFile> {
  final String fileName;
  final int processedAt;
  final String deviceId;
  const SyncProcessedFile({
    required this.fileName,
    required this.processedAt,
    required this.deviceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['file_name'] = Variable<String>(fileName);
    map['processed_at'] = Variable<int>(processedAt);
    map['device_id'] = Variable<String>(deviceId);
    return map;
  }

  SyncProcessedFilesCompanion toCompanion(bool nullToAbsent) {
    return SyncProcessedFilesCompanion(
      fileName: Value(fileName),
      processedAt: Value(processedAt),
      deviceId: Value(deviceId),
    );
  }

  factory SyncProcessedFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncProcessedFile(
      fileName: serializer.fromJson<String>(json['fileName']),
      processedAt: serializer.fromJson<int>(json['processedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fileName': serializer.toJson<String>(fileName),
      'processedAt': serializer.toJson<int>(processedAt),
      'deviceId': serializer.toJson<String>(deviceId),
    };
  }

  SyncProcessedFile copyWith({
    String? fileName,
    int? processedAt,
    String? deviceId,
  }) => SyncProcessedFile(
    fileName: fileName ?? this.fileName,
    processedAt: processedAt ?? this.processedAt,
    deviceId: deviceId ?? this.deviceId,
  );
  SyncProcessedFile copyWithCompanion(SyncProcessedFilesCompanion data) {
    return SyncProcessedFile(
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      processedAt: data.processedAt.present
          ? data.processedAt.value
          : this.processedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncProcessedFile(')
          ..write('fileName: $fileName, ')
          ..write('processedAt: $processedAt, ')
          ..write('deviceId: $deviceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fileName, processedAt, deviceId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncProcessedFile &&
          other.fileName == this.fileName &&
          other.processedAt == this.processedAt &&
          other.deviceId == this.deviceId);
}

class SyncProcessedFilesCompanion extends UpdateCompanion<SyncProcessedFile> {
  final Value<String> fileName;
  final Value<int> processedAt;
  final Value<String> deviceId;
  final Value<int> rowid;
  const SyncProcessedFilesCompanion({
    this.fileName = const Value.absent(),
    this.processedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncProcessedFilesCompanion.insert({
    required String fileName,
    required int processedAt,
    required String deviceId,
    this.rowid = const Value.absent(),
  }) : fileName = Value(fileName),
       processedAt = Value(processedAt),
       deviceId = Value(deviceId);
  static Insertable<SyncProcessedFile> custom({
    Expression<String>? fileName,
    Expression<int>? processedAt,
    Expression<String>? deviceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fileName != null) 'file_name': fileName,
      if (processedAt != null) 'processed_at': processedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncProcessedFilesCompanion copyWith({
    Value<String>? fileName,
    Value<int>? processedAt,
    Value<String>? deviceId,
    Value<int>? rowid,
  }) {
    return SyncProcessedFilesCompanion(
      fileName: fileName ?? this.fileName,
      processedAt: processedAt ?? this.processedAt,
      deviceId: deviceId ?? this.deviceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (processedAt.present) {
      map['processed_at'] = Variable<int>(processedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncProcessedFilesCompanion(')
          ..write('fileName: $fileName, ')
          ..write('processedAt: $processedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncLogTable extends SyncLog with TableInfo<$SyncLogTable, SyncLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _changedTableNameMeta = const VerificationMeta(
    'changedTableName',
  );
  @override
  late final GeneratedColumn<String> changedTableName = GeneratedColumn<String>(
    'changed_table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<int> timestamp = GeneratedColumn<int>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _exportedMeta = const VerificationMeta(
    'exported',
  );
  @override
  late final GeneratedColumn<bool> exported = GeneratedColumn<bool>(
    'exported',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("exported" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    changedTableName,
    recordId,
    action,
    timestamp,
    exported,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('changed_table_name')) {
      context.handle(
        _changedTableNameMeta,
        changedTableName.isAcceptableOrUnknown(
          data['changed_table_name']!,
          _changedTableNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changedTableNameMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('exported')) {
      context.handle(
        _exportedMeta,
        exported.isAcceptableOrUnknown(data['exported']!, _exportedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      changedTableName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_table_name'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}timestamp'],
      )!,
      exported: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exported'],
      )!,
    );
  }

  @override
  $SyncLogTable createAlias(String alias) {
    return $SyncLogTable(attachedDatabase, alias);
  }
}

class SyncLogData extends DataClass implements Insertable<SyncLogData> {
  final int id;
  final String changedTableName;
  final String recordId;
  final String action;
  final int timestamp;
  final bool exported;
  const SyncLogData({
    required this.id,
    required this.changedTableName,
    required this.recordId,
    required this.action,
    required this.timestamp,
    required this.exported,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['changed_table_name'] = Variable<String>(changedTableName);
    map['record_id'] = Variable<String>(recordId);
    map['action'] = Variable<String>(action);
    map['timestamp'] = Variable<int>(timestamp);
    map['exported'] = Variable<bool>(exported);
    return map;
  }

  SyncLogCompanion toCompanion(bool nullToAbsent) {
    return SyncLogCompanion(
      id: Value(id),
      changedTableName: Value(changedTableName),
      recordId: Value(recordId),
      action: Value(action),
      timestamp: Value(timestamp),
      exported: Value(exported),
    );
  }

  factory SyncLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogData(
      id: serializer.fromJson<int>(json['id']),
      changedTableName: serializer.fromJson<String>(json['changedTableName']),
      recordId: serializer.fromJson<String>(json['recordId']),
      action: serializer.fromJson<String>(json['action']),
      timestamp: serializer.fromJson<int>(json['timestamp']),
      exported: serializer.fromJson<bool>(json['exported']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'changedTableName': serializer.toJson<String>(changedTableName),
      'recordId': serializer.toJson<String>(recordId),
      'action': serializer.toJson<String>(action),
      'timestamp': serializer.toJson<int>(timestamp),
      'exported': serializer.toJson<bool>(exported),
    };
  }

  SyncLogData copyWith({
    int? id,
    String? changedTableName,
    String? recordId,
    String? action,
    int? timestamp,
    bool? exported,
  }) => SyncLogData(
    id: id ?? this.id,
    changedTableName: changedTableName ?? this.changedTableName,
    recordId: recordId ?? this.recordId,
    action: action ?? this.action,
    timestamp: timestamp ?? this.timestamp,
    exported: exported ?? this.exported,
  );
  SyncLogData copyWithCompanion(SyncLogCompanion data) {
    return SyncLogData(
      id: data.id.present ? data.id.value : this.id,
      changedTableName: data.changedTableName.present
          ? data.changedTableName.value
          : this.changedTableName,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      action: data.action.present ? data.action.value : this.action,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      exported: data.exported.present ? data.exported.value : this.exported,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogData(')
          ..write('id: $id, ')
          ..write('changedTableName: $changedTableName, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('timestamp: $timestamp, ')
          ..write('exported: $exported')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, changedTableName, recordId, action, timestamp, exported);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogData &&
          other.id == this.id &&
          other.changedTableName == this.changedTableName &&
          other.recordId == this.recordId &&
          other.action == this.action &&
          other.timestamp == this.timestamp &&
          other.exported == this.exported);
}

class SyncLogCompanion extends UpdateCompanion<SyncLogData> {
  final Value<int> id;
  final Value<String> changedTableName;
  final Value<String> recordId;
  final Value<String> action;
  final Value<int> timestamp;
  final Value<bool> exported;
  const SyncLogCompanion({
    this.id = const Value.absent(),
    this.changedTableName = const Value.absent(),
    this.recordId = const Value.absent(),
    this.action = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.exported = const Value.absent(),
  });
  SyncLogCompanion.insert({
    this.id = const Value.absent(),
    required String changedTableName,
    required String recordId,
    required String action,
    required int timestamp,
    this.exported = const Value.absent(),
  }) : changedTableName = Value(changedTableName),
       recordId = Value(recordId),
       action = Value(action),
       timestamp = Value(timestamp);
  static Insertable<SyncLogData> custom({
    Expression<int>? id,
    Expression<String>? changedTableName,
    Expression<String>? recordId,
    Expression<String>? action,
    Expression<int>? timestamp,
    Expression<bool>? exported,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (changedTableName != null) 'changed_table_name': changedTableName,
      if (recordId != null) 'record_id': recordId,
      if (action != null) 'action': action,
      if (timestamp != null) 'timestamp': timestamp,
      if (exported != null) 'exported': exported,
    });
  }

  SyncLogCompanion copyWith({
    Value<int>? id,
    Value<String>? changedTableName,
    Value<String>? recordId,
    Value<String>? action,
    Value<int>? timestamp,
    Value<bool>? exported,
  }) {
    return SyncLogCompanion(
      id: id ?? this.id,
      changedTableName: changedTableName ?? this.changedTableName,
      recordId: recordId ?? this.recordId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      exported: exported ?? this.exported,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (changedTableName.present) {
      map['changed_table_name'] = Variable<String>(changedTableName.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<int>(timestamp.value);
    }
    if (exported.present) {
      map['exported'] = Variable<bool>(exported.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogCompanion(')
          ..write('id: $id, ')
          ..write('changedTableName: $changedTableName, ')
          ..write('recordId: $recordId, ')
          ..write('action: $action, ')
          ..write('timestamp: $timestamp, ')
          ..write('exported: $exported')
          ..write(')'))
        .toString();
  }
}

class $SyncPushQueueTable extends SyncPushQueue
    with TableInfo<$SyncPushQueueTable, SyncPushQueueData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPushQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _changedTableNameMeta = const VerificationMeta(
    'changedTableName',
  );
  @override
  late final GeneratedColumn<String> changedTableName = GeneratedColumn<String>(
    'changed_table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordKeyMeta = const VerificationMeta(
    'recordKey',
  );
  @override
  late final GeneratedColumn<String> recordKey = GeneratedColumn<String>(
    'record_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, changedTableName, recordKey];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_push_queue';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPushQueueData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('changed_table_name')) {
      context.handle(
        _changedTableNameMeta,
        changedTableName.isAcceptableOrUnknown(
          data['changed_table_name']!,
          _changedTableNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changedTableNameMeta);
    }
    if (data.containsKey('record_key')) {
      context.handle(
        _recordKeyMeta,
        recordKey.isAcceptableOrUnknown(data['record_key']!, _recordKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_recordKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncPushQueueData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPushQueueData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      changedTableName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_table_name'],
      )!,
      recordKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_key'],
      )!,
    );
  }

  @override
  $SyncPushQueueTable createAlias(String alias) {
    return $SyncPushQueueTable(attachedDatabase, alias);
  }
}

class SyncPushQueueData extends DataClass
    implements Insertable<SyncPushQueueData> {
  /// AUTOINCREMENT (what drift emits for [autoIncrement]), so an id is never
  /// handed out twice. A push deletes the exact ids it read; with reused ids
  /// that delete could land on an entry queued for a later edit of the same row
  /// while the push was in flight, and that edit would never be sent again.
  final int id;
  final String changedTableName;

  /// The row's primary key, built by [syncPushQueueKeyExpression] so the push
  /// can find the row again — composite keys joined with `|`.
  final String recordKey;
  const SyncPushQueueData({
    required this.id,
    required this.changedTableName,
    required this.recordKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['changed_table_name'] = Variable<String>(changedTableName);
    map['record_key'] = Variable<String>(recordKey);
    return map;
  }

  SyncPushQueueCompanion toCompanion(bool nullToAbsent) {
    return SyncPushQueueCompanion(
      id: Value(id),
      changedTableName: Value(changedTableName),
      recordKey: Value(recordKey),
    );
  }

  factory SyncPushQueueData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPushQueueData(
      id: serializer.fromJson<int>(json['id']),
      changedTableName: serializer.fromJson<String>(json['changedTableName']),
      recordKey: serializer.fromJson<String>(json['recordKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'changedTableName': serializer.toJson<String>(changedTableName),
      'recordKey': serializer.toJson<String>(recordKey),
    };
  }

  SyncPushQueueData copyWith({
    int? id,
    String? changedTableName,
    String? recordKey,
  }) => SyncPushQueueData(
    id: id ?? this.id,
    changedTableName: changedTableName ?? this.changedTableName,
    recordKey: recordKey ?? this.recordKey,
  );
  SyncPushQueueData copyWithCompanion(SyncPushQueueCompanion data) {
    return SyncPushQueueData(
      id: data.id.present ? data.id.value : this.id,
      changedTableName: data.changedTableName.present
          ? data.changedTableName.value
          : this.changedTableName,
      recordKey: data.recordKey.present ? data.recordKey.value : this.recordKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPushQueueData(')
          ..write('id: $id, ')
          ..write('changedTableName: $changedTableName, ')
          ..write('recordKey: $recordKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, changedTableName, recordKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPushQueueData &&
          other.id == this.id &&
          other.changedTableName == this.changedTableName &&
          other.recordKey == this.recordKey);
}

class SyncPushQueueCompanion extends UpdateCompanion<SyncPushQueueData> {
  final Value<int> id;
  final Value<String> changedTableName;
  final Value<String> recordKey;
  const SyncPushQueueCompanion({
    this.id = const Value.absent(),
    this.changedTableName = const Value.absent(),
    this.recordKey = const Value.absent(),
  });
  SyncPushQueueCompanion.insert({
    this.id = const Value.absent(),
    required String changedTableName,
    required String recordKey,
  }) : changedTableName = Value(changedTableName),
       recordKey = Value(recordKey);
  static Insertable<SyncPushQueueData> custom({
    Expression<int>? id,
    Expression<String>? changedTableName,
    Expression<String>? recordKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (changedTableName != null) 'changed_table_name': changedTableName,
      if (recordKey != null) 'record_key': recordKey,
    });
  }

  SyncPushQueueCompanion copyWith({
    Value<int>? id,
    Value<String>? changedTableName,
    Value<String>? recordKey,
  }) {
    return SyncPushQueueCompanion(
      id: id ?? this.id,
      changedTableName: changedTableName ?? this.changedTableName,
      recordKey: recordKey ?? this.recordKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (changedTableName.present) {
      map['changed_table_name'] = Variable<String>(changedTableName.value);
    }
    if (recordKey.present) {
      map['record_key'] = Variable<String>(recordKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPushQueueCompanion(')
          ..write('id: $id, ')
          ..write('changedTableName: $changedTableName, ')
          ..write('recordKey: $recordKey')
          ..write(')'))
        .toString();
  }
}

class $ConflictHistoryTable extends ConflictHistory
    with TableInfo<$ConflictHistoryTable, ConflictHistoryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConflictHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _changedTableNameMeta = const VerificationMeta(
    'changedTableName',
  );
  @override
  late final GeneratedColumn<String> changedTableName = GeneratedColumn<String>(
    'changed_table_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectedDataMeta = const VerificationMeta(
    'rejectedData',
  );
  @override
  late final GeneratedColumn<String> rejectedData = GeneratedColumn<String>(
    'rejected_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectedAtMeta = const VerificationMeta(
    'rejectedAt',
  );
  @override
  late final GeneratedColumn<int> rejectedAt = GeneratedColumn<int>(
    'rejected_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rejectedDeviceMeta = const VerificationMeta(
    'rejectedDevice',
  );
  @override
  late final GeneratedColumn<String> rejectedDevice = GeneratedColumn<String>(
    'rejected_device',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    changedTableName,
    recordId,
    rejectedData,
    rejectedAt,
    rejectedDevice,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflict_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConflictHistoryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('changed_table_name')) {
      context.handle(
        _changedTableNameMeta,
        changedTableName.isAcceptableOrUnknown(
          data['changed_table_name']!,
          _changedTableNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_changedTableNameMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('rejected_data')) {
      context.handle(
        _rejectedDataMeta,
        rejectedData.isAcceptableOrUnknown(
          data['rejected_data']!,
          _rejectedDataMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rejectedDataMeta);
    }
    if (data.containsKey('rejected_at')) {
      context.handle(
        _rejectedAtMeta,
        rejectedAt.isAcceptableOrUnknown(data['rejected_at']!, _rejectedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_rejectedAtMeta);
    }
    if (data.containsKey('rejected_device')) {
      context.handle(
        _rejectedDeviceMeta,
        rejectedDevice.isAcceptableOrUnknown(
          data['rejected_device']!,
          _rejectedDeviceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConflictHistoryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConflictHistoryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      changedTableName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}changed_table_name'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      rejectedData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejected_data'],
      )!,
      rejectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rejected_at'],
      )!,
      rejectedDevice: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rejected_device'],
      ),
    );
  }

  @override
  $ConflictHistoryTable createAlias(String alias) {
    return $ConflictHistoryTable(attachedDatabase, alias);
  }
}

class ConflictHistoryData extends DataClass
    implements Insertable<ConflictHistoryData> {
  final String id;
  final String changedTableName;
  final String recordId;
  final String rejectedData;
  final int rejectedAt;
  final String? rejectedDevice;
  const ConflictHistoryData({
    required this.id,
    required this.changedTableName,
    required this.recordId,
    required this.rejectedData,
    required this.rejectedAt,
    this.rejectedDevice,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['changed_table_name'] = Variable<String>(changedTableName);
    map['record_id'] = Variable<String>(recordId);
    map['rejected_data'] = Variable<String>(rejectedData);
    map['rejected_at'] = Variable<int>(rejectedAt);
    if (!nullToAbsent || rejectedDevice != null) {
      map['rejected_device'] = Variable<String>(rejectedDevice);
    }
    return map;
  }

  ConflictHistoryCompanion toCompanion(bool nullToAbsent) {
    return ConflictHistoryCompanion(
      id: Value(id),
      changedTableName: Value(changedTableName),
      recordId: Value(recordId),
      rejectedData: Value(rejectedData),
      rejectedAt: Value(rejectedAt),
      rejectedDevice: rejectedDevice == null && nullToAbsent
          ? const Value.absent()
          : Value(rejectedDevice),
    );
  }

  factory ConflictHistoryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConflictHistoryData(
      id: serializer.fromJson<String>(json['id']),
      changedTableName: serializer.fromJson<String>(json['changedTableName']),
      recordId: serializer.fromJson<String>(json['recordId']),
      rejectedData: serializer.fromJson<String>(json['rejectedData']),
      rejectedAt: serializer.fromJson<int>(json['rejectedAt']),
      rejectedDevice: serializer.fromJson<String?>(json['rejectedDevice']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'changedTableName': serializer.toJson<String>(changedTableName),
      'recordId': serializer.toJson<String>(recordId),
      'rejectedData': serializer.toJson<String>(rejectedData),
      'rejectedAt': serializer.toJson<int>(rejectedAt),
      'rejectedDevice': serializer.toJson<String?>(rejectedDevice),
    };
  }

  ConflictHistoryData copyWith({
    String? id,
    String? changedTableName,
    String? recordId,
    String? rejectedData,
    int? rejectedAt,
    Value<String?> rejectedDevice = const Value.absent(),
  }) => ConflictHistoryData(
    id: id ?? this.id,
    changedTableName: changedTableName ?? this.changedTableName,
    recordId: recordId ?? this.recordId,
    rejectedData: rejectedData ?? this.rejectedData,
    rejectedAt: rejectedAt ?? this.rejectedAt,
    rejectedDevice: rejectedDevice.present
        ? rejectedDevice.value
        : this.rejectedDevice,
  );
  ConflictHistoryData copyWithCompanion(ConflictHistoryCompanion data) {
    return ConflictHistoryData(
      id: data.id.present ? data.id.value : this.id,
      changedTableName: data.changedTableName.present
          ? data.changedTableName.value
          : this.changedTableName,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      rejectedData: data.rejectedData.present
          ? data.rejectedData.value
          : this.rejectedData,
      rejectedAt: data.rejectedAt.present
          ? data.rejectedAt.value
          : this.rejectedAt,
      rejectedDevice: data.rejectedDevice.present
          ? data.rejectedDevice.value
          : this.rejectedDevice,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConflictHistoryData(')
          ..write('id: $id, ')
          ..write('changedTableName: $changedTableName, ')
          ..write('recordId: $recordId, ')
          ..write('rejectedData: $rejectedData, ')
          ..write('rejectedAt: $rejectedAt, ')
          ..write('rejectedDevice: $rejectedDevice')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    changedTableName,
    recordId,
    rejectedData,
    rejectedAt,
    rejectedDevice,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConflictHistoryData &&
          other.id == this.id &&
          other.changedTableName == this.changedTableName &&
          other.recordId == this.recordId &&
          other.rejectedData == this.rejectedData &&
          other.rejectedAt == this.rejectedAt &&
          other.rejectedDevice == this.rejectedDevice);
}

class ConflictHistoryCompanion extends UpdateCompanion<ConflictHistoryData> {
  final Value<String> id;
  final Value<String> changedTableName;
  final Value<String> recordId;
  final Value<String> rejectedData;
  final Value<int> rejectedAt;
  final Value<String?> rejectedDevice;
  final Value<int> rowid;
  const ConflictHistoryCompanion({
    this.id = const Value.absent(),
    this.changedTableName = const Value.absent(),
    this.recordId = const Value.absent(),
    this.rejectedData = const Value.absent(),
    this.rejectedAt = const Value.absent(),
    this.rejectedDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictHistoryCompanion.insert({
    this.id = const Value.absent(),
    required String changedTableName,
    required String recordId,
    required String rejectedData,
    required int rejectedAt,
    this.rejectedDevice = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : changedTableName = Value(changedTableName),
       recordId = Value(recordId),
       rejectedData = Value(rejectedData),
       rejectedAt = Value(rejectedAt);
  static Insertable<ConflictHistoryData> custom({
    Expression<String>? id,
    Expression<String>? changedTableName,
    Expression<String>? recordId,
    Expression<String>? rejectedData,
    Expression<int>? rejectedAt,
    Expression<String>? rejectedDevice,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (changedTableName != null) 'changed_table_name': changedTableName,
      if (recordId != null) 'record_id': recordId,
      if (rejectedData != null) 'rejected_data': rejectedData,
      if (rejectedAt != null) 'rejected_at': rejectedAt,
      if (rejectedDevice != null) 'rejected_device': rejectedDevice,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictHistoryCompanion copyWith({
    Value<String>? id,
    Value<String>? changedTableName,
    Value<String>? recordId,
    Value<String>? rejectedData,
    Value<int>? rejectedAt,
    Value<String?>? rejectedDevice,
    Value<int>? rowid,
  }) {
    return ConflictHistoryCompanion(
      id: id ?? this.id,
      changedTableName: changedTableName ?? this.changedTableName,
      recordId: recordId ?? this.recordId,
      rejectedData: rejectedData ?? this.rejectedData,
      rejectedAt: rejectedAt ?? this.rejectedAt,
      rejectedDevice: rejectedDevice ?? this.rejectedDevice,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (changedTableName.present) {
      map['changed_table_name'] = Variable<String>(changedTableName.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (rejectedData.present) {
      map['rejected_data'] = Variable<String>(rejectedData.value);
    }
    if (rejectedAt.present) {
      map['rejected_at'] = Variable<int>(rejectedAt.value);
    }
    if (rejectedDevice.present) {
      map['rejected_device'] = Variable<String>(rejectedDevice.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictHistoryCompanion(')
          ..write('id: $id, ')
          ..write('changedTableName: $changedTableName, ')
          ..write('recordId: $recordId, ')
          ..write('rejectedData: $rejectedData, ')
          ..write('rejectedAt: $rejectedAt, ')
          ..write('rejectedDevice: $rejectedDevice, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CustomDataSourcesTable extends CustomDataSources
    with TableInfo<$CustomDataSourcesTable, CustomDataSource> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CustomDataSourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => _uuid.v4(),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataTypeMeta = const VerificationMeta(
    'dataType',
  );
  @override
  late final GeneratedColumn<int> dataType = GeneratedColumn<int>(
    'data_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _autoFetchMeta = const VerificationMeta(
    'autoFetch',
  );
  @override
  late final GeneratedColumn<bool> autoFetch = GeneratedColumn<bool>(
    'auto_fetch',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_fetch" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastFetchAtMeta = const VerificationMeta(
    'lastFetchAt',
  );
  @override
  late final GeneratedColumn<int> lastFetchAt = GeneratedColumn<int>(
    'last_fetch_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _modifiedAtMeta = const VerificationMeta(
    'modifiedAt',
  );
  @override
  late final GeneratedColumn<int> modifiedAt = GeneratedColumn<int>(
    'modified_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    url,
    dataType,
    enabled,
    autoFetch,
    lastFetchAt,
    modifiedAt,
    deviceId,
    isDeleted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_data_sources';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomDataSource> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('data_type')) {
      context.handle(
        _dataTypeMeta,
        dataType.isAcceptableOrUnknown(data['data_type']!, _dataTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_dataTypeMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('auto_fetch')) {
      context.handle(
        _autoFetchMeta,
        autoFetch.isAcceptableOrUnknown(data['auto_fetch']!, _autoFetchMeta),
      );
    }
    if (data.containsKey('last_fetch_at')) {
      context.handle(
        _lastFetchAtMeta,
        lastFetchAt.isAcceptableOrUnknown(
          data['last_fetch_at']!,
          _lastFetchAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_at')) {
      context.handle(
        _modifiedAtMeta,
        modifiedAt.isAcceptableOrUnknown(data['modified_at']!, _modifiedAtMeta),
      );
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomDataSource map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomDataSource(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      dataType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}data_type'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      autoFetch: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_fetch'],
      )!,
      lastFetchAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_fetch_at'],
      ),
      modifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}modified_at'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
    );
  }

  @override
  $CustomDataSourcesTable createAlias(String alias) {
    return $CustomDataSourcesTable(attachedDatabase, alias);
  }
}

class CustomDataSource extends DataClass
    implements Insertable<CustomDataSource> {
  final String id;
  final String name;
  final String url;
  final int dataType;
  final bool enabled;
  final bool autoFetch;
  final int? lastFetchAt;
  final int modifiedAt;
  final String? deviceId;
  final bool isDeleted;
  const CustomDataSource({
    required this.id,
    required this.name,
    required this.url,
    required this.dataType,
    required this.enabled,
    required this.autoFetch,
    this.lastFetchAt,
    required this.modifiedAt,
    this.deviceId,
    required this.isDeleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['url'] = Variable<String>(url);
    map['data_type'] = Variable<int>(dataType);
    map['enabled'] = Variable<bool>(enabled);
    map['auto_fetch'] = Variable<bool>(autoFetch);
    if (!nullToAbsent || lastFetchAt != null) {
      map['last_fetch_at'] = Variable<int>(lastFetchAt);
    }
    map['modified_at'] = Variable<int>(modifiedAt);
    if (!nullToAbsent || deviceId != null) {
      map['device_id'] = Variable<String>(deviceId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    return map;
  }

  CustomDataSourcesCompanion toCompanion(bool nullToAbsent) {
    return CustomDataSourcesCompanion(
      id: Value(id),
      name: Value(name),
      url: Value(url),
      dataType: Value(dataType),
      enabled: Value(enabled),
      autoFetch: Value(autoFetch),
      lastFetchAt: lastFetchAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastFetchAt),
      modifiedAt: Value(modifiedAt),
      deviceId: deviceId == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceId),
      isDeleted: Value(isDeleted),
    );
  }

  factory CustomDataSource.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomDataSource(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      url: serializer.fromJson<String>(json['url']),
      dataType: serializer.fromJson<int>(json['dataType']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      autoFetch: serializer.fromJson<bool>(json['autoFetch']),
      lastFetchAt: serializer.fromJson<int?>(json['lastFetchAt']),
      modifiedAt: serializer.fromJson<int>(json['modifiedAt']),
      deviceId: serializer.fromJson<String?>(json['deviceId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'url': serializer.toJson<String>(url),
      'dataType': serializer.toJson<int>(dataType),
      'enabled': serializer.toJson<bool>(enabled),
      'autoFetch': serializer.toJson<bool>(autoFetch),
      'lastFetchAt': serializer.toJson<int?>(lastFetchAt),
      'modifiedAt': serializer.toJson<int>(modifiedAt),
      'deviceId': serializer.toJson<String?>(deviceId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
    };
  }

  CustomDataSource copyWith({
    String? id,
    String? name,
    String? url,
    int? dataType,
    bool? enabled,
    bool? autoFetch,
    Value<int?> lastFetchAt = const Value.absent(),
    int? modifiedAt,
    Value<String?> deviceId = const Value.absent(),
    bool? isDeleted,
  }) => CustomDataSource(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    dataType: dataType ?? this.dataType,
    enabled: enabled ?? this.enabled,
    autoFetch: autoFetch ?? this.autoFetch,
    lastFetchAt: lastFetchAt.present ? lastFetchAt.value : this.lastFetchAt,
    modifiedAt: modifiedAt ?? this.modifiedAt,
    deviceId: deviceId.present ? deviceId.value : this.deviceId,
    isDeleted: isDeleted ?? this.isDeleted,
  );
  CustomDataSource copyWithCompanion(CustomDataSourcesCompanion data) {
    return CustomDataSource(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      url: data.url.present ? data.url.value : this.url,
      dataType: data.dataType.present ? data.dataType.value : this.dataType,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      autoFetch: data.autoFetch.present ? data.autoFetch.value : this.autoFetch,
      lastFetchAt: data.lastFetchAt.present
          ? data.lastFetchAt.value
          : this.lastFetchAt,
      modifiedAt: data.modifiedAt.present
          ? data.modifiedAt.value
          : this.modifiedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomDataSource(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('dataType: $dataType, ')
          ..write('enabled: $enabled, ')
          ..write('autoFetch: $autoFetch, ')
          ..write('lastFetchAt: $lastFetchAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    url,
    dataType,
    enabled,
    autoFetch,
    lastFetchAt,
    modifiedAt,
    deviceId,
    isDeleted,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomDataSource &&
          other.id == this.id &&
          other.name == this.name &&
          other.url == this.url &&
          other.dataType == this.dataType &&
          other.enabled == this.enabled &&
          other.autoFetch == this.autoFetch &&
          other.lastFetchAt == this.lastFetchAt &&
          other.modifiedAt == this.modifiedAt &&
          other.deviceId == this.deviceId &&
          other.isDeleted == this.isDeleted);
}

class CustomDataSourcesCompanion extends UpdateCompanion<CustomDataSource> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> url;
  final Value<int> dataType;
  final Value<bool> enabled;
  final Value<bool> autoFetch;
  final Value<int?> lastFetchAt;
  final Value<int> modifiedAt;
  final Value<String?> deviceId;
  final Value<bool> isDeleted;
  final Value<int> rowid;
  const CustomDataSourcesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.url = const Value.absent(),
    this.dataType = const Value.absent(),
    this.enabled = const Value.absent(),
    this.autoFetch = const Value.absent(),
    this.lastFetchAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomDataSourcesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String url,
    required int dataType,
    this.enabled = const Value.absent(),
    this.autoFetch = const Value.absent(),
    this.lastFetchAt = const Value.absent(),
    this.modifiedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       url = Value(url),
       dataType = Value(dataType);
  static Insertable<CustomDataSource> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? url,
    Expression<int>? dataType,
    Expression<bool>? enabled,
    Expression<bool>? autoFetch,
    Expression<int>? lastFetchAt,
    Expression<int>? modifiedAt,
    Expression<String>? deviceId,
    Expression<bool>? isDeleted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (url != null) 'url': url,
      if (dataType != null) 'data_type': dataType,
      if (enabled != null) 'enabled': enabled,
      if (autoFetch != null) 'auto_fetch': autoFetch,
      if (lastFetchAt != null) 'last_fetch_at': lastFetchAt,
      if (modifiedAt != null) 'modified_at': modifiedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomDataSourcesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? url,
    Value<int>? dataType,
    Value<bool>? enabled,
    Value<bool>? autoFetch,
    Value<int?>? lastFetchAt,
    Value<int>? modifiedAt,
    Value<String?>? deviceId,
    Value<bool>? isDeleted,
    Value<int>? rowid,
  }) {
    return CustomDataSourcesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      dataType: dataType ?? this.dataType,
      enabled: enabled ?? this.enabled,
      autoFetch: autoFetch ?? this.autoFetch,
      lastFetchAt: lastFetchAt ?? this.lastFetchAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      deviceId: deviceId ?? this.deviceId,
      isDeleted: isDeleted ?? this.isDeleted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (dataType.present) {
      map['data_type'] = Variable<int>(dataType.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (autoFetch.present) {
      map['auto_fetch'] = Variable<bool>(autoFetch.value);
    }
    if (lastFetchAt.present) {
      map['last_fetch_at'] = Variable<int>(lastFetchAt.value);
    }
    if (modifiedAt.present) {
      map['modified_at'] = Variable<int>(modifiedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomDataSourcesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('url: $url, ')
          ..write('dataType: $dataType, ')
          ..write('enabled: $enabled, ')
          ..write('autoFetch: $autoFetch, ')
          ..write('lastFetchAt: $lastFetchAt, ')
          ..write('modifiedAt: $modifiedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LanguagesTable languages = $LanguagesTable(this);
  late final $CurrenciesTable currencies = $CurrenciesTable(this);
  late final $CurrencyDesignationsTable currencyDesignations =
      $CurrencyDesignationsTable(this);
  late final $StylesTable styles = $StylesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $AccountTypesTable accountTypes = $AccountTypesTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $ExchangeRatesTable exchangeRates = $ExchangeRatesTable(this);
  late final $InflationRatesTable inflationRates = $InflationRatesTable(this);
  late final $AssetEntriesTable assetEntries = $AssetEntriesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $CustomThemesTable customThemes = $CustomThemesTable(this);
  late final $ApiFetchStatusesTable apiFetchStatuses = $ApiFetchStatusesTable(
    this,
  );
  late final $ApiSettingsTableTable apiSettingsTable = $ApiSettingsTableTable(
    this,
  );
  late final $SmsPresetsTable smsPresets = $SmsPresetsTable(this);
  late final $SyncProcessedFilesTable syncProcessedFiles =
      $SyncProcessedFilesTable(this);
  late final $SyncLogTable syncLog = $SyncLogTable(this);
  late final $SyncPushQueueTable syncPushQueue = $SyncPushQueueTable(this);
  late final $ConflictHistoryTable conflictHistory = $ConflictHistoryTable(
    this,
  );
  late final $CustomDataSourcesTable customDataSources =
      $CustomDataSourcesTable(this);
  late final Index idxTransactionsDate = Index(
    'idx_transactions_date',
    'CREATE INDEX idx_transactions_date ON transactions (date)',
  );
  late final Index idxTransactionsAccount = Index(
    'idx_transactions_account',
    'CREATE INDEX idx_transactions_account ON transactions (account_id)',
  );
  late final Index idxTransactionsCategory = Index(
    'idx_transactions_category',
    'CREATE INDEX idx_transactions_category ON transactions (category_id)',
  );
  late final Index idxTransactionsDateCategory = Index(
    'idx_transactions_date_category',
    'CREATE INDEX idx_transactions_date_category ON transactions (date, category_id)',
  );
  late final Index idxTransactionsAccountDate = Index(
    'idx_transactions_account_date',
    'CREATE INDEX idx_transactions_account_date ON transactions (account_id, date)',
  );
  late final Index idxExchangeRatesDate = Index(
    'idx_exchange_rates_date',
    'CREATE INDEX idx_exchange_rates_date ON exchange_rates (date)',
  );
  late final Index idxExchangeRatesComposite = Index(
    'idx_exchange_rates_composite',
    'CREATE INDEX idx_exchange_rates_composite ON exchange_rates (from_currency_code, to_currency_code, date)',
  );
  late final Index idxSyncPushQueueTable = Index(
    'idx_sync_push_queue_table',
    'CREATE INDEX idx_sync_push_queue_table ON sync_push_queue (changed_table_name, id)',
  );
  late final LanguageDao languageDao = LanguageDao(this as AppDatabase);
  late final CurrencyDesignationsDao currencyDesignationsDao =
      CurrencyDesignationsDao(this as AppDatabase);
  late final CurrenciesDao currenciesDao = CurrenciesDao(this as AppDatabase);
  late final CategoriesDao categoriesDao = CategoriesDao(this as AppDatabase);
  late final StylesDao stylesDao = StylesDao(this as AppDatabase);
  late final AccountTypesDao accountTypesDao = AccountTypesDao(
    this as AppDatabase,
  );
  late final AccountsDao accountsDao = AccountsDao(this as AppDatabase);
  late final TransactionsDao transactionsDao = TransactionsDao(
    this as AppDatabase,
  );
  late final ExchangeRatesDao exchangeRatesDao = ExchangeRatesDao(
    this as AppDatabase,
  );
  late final InflationRatesDao inflationRatesDao = InflationRatesDao(
    this as AppDatabase,
  );
  late final AssetEntriesDao assetEntriesDao = AssetEntriesDao(
    this as AppDatabase,
  );
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final CustomThemesDao customThemesDao = CustomThemesDao(
    this as AppDatabase,
  );
  late final ApiFetchStatusesDao apiFetchStatusesDao = ApiFetchStatusesDao(
    this as AppDatabase,
  );
  late final SmsPresetsDao smsPresetsDao = SmsPresetsDao(this as AppDatabase);
  late final SyncLogDao syncLogDao = SyncLogDao(this as AppDatabase);
  late final ConflictHistoryDao conflictHistoryDao = ConflictHistoryDao(
    this as AppDatabase,
  );
  late final CustomDataSourcesDao customDataSourcesDao = CustomDataSourcesDao(
    this as AppDatabase,
  );
  late final ApiSettingsDao apiSettingsDao = ApiSettingsDao(
    this as AppDatabase,
  );
  late final SyncProcessedFilesDao syncProcessedFilesDao =
      SyncProcessedFilesDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    languages,
    currencies,
    currencyDesignations,
    styles,
    categories,
    accountTypes,
    accounts,
    transactions,
    exchangeRates,
    inflationRates,
    assetEntries,
    settings,
    customThemes,
    apiFetchStatuses,
    apiSettingsTable,
    smsPresets,
    syncProcessedFiles,
    syncLog,
    syncPushQueue,
    conflictHistory,
    customDataSources,
    idxTransactionsDate,
    idxTransactionsAccount,
    idxTransactionsCategory,
    idxTransactionsDateCategory,
    idxTransactionsAccountDate,
    idxExchangeRatesDate,
    idxExchangeRatesComposite,
    idxSyncPushQueueTable,
  ];
}

typedef $$LanguagesTableCreateCompanionBuilder =
    LanguagesCompanion Function({
      required String language,
      required String languageCode,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<int> rowid,
    });
typedef $$LanguagesTableUpdateCompanionBuilder =
    LanguagesCompanion Function({
      Value<String> language,
      Value<String> languageCode,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<int> rowid,
    });

final class $$LanguagesTableReferences
    extends BaseReferences<_$AppDatabase, $LanguagesTable, Language> {
  $$LanguagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CurrenciesTable, List<Currency>>
  _currenciesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.currencies,
    aliasName: $_aliasNameGenerator(
      db.languages.languageCode,
      db.currencies.languageCode,
    ),
  );

  $$CurrenciesTableProcessedTableManager get currenciesRefs {
    final manager = $$CurrenciesTableTableManager($_db, $_db.currencies).filter(
      (f) => f.languageCode.languageCode.sqlEquals(
        $_itemColumn<String>('language_code')!,
      ),
    );

    final cache = $_typedResult.readTableOrNull(_currenciesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AccountTypesTable, List<AccountType>>
  _accountTypesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accountTypes,
    aliasName: $_aliasNameGenerator(
      db.languages.languageCode,
      db.accountTypes.languageCode,
    ),
  );

  $$AccountTypesTableProcessedTableManager get accountTypesRefs {
    final manager = $$AccountTypesTableTableManager($_db, $_db.accountTypes)
        .filter(
          (f) => f.languageCode.languageCode.sqlEquals(
            $_itemColumn<String>('language_code')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_accountTypesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LanguagesTableFilterComposer
    extends Composer<_$AppDatabase, $LanguagesTable> {
  $$LanguagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> currenciesRefs(
    Expression<bool> Function($$CurrenciesTableFilterComposer f) f,
  ) {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> accountTypesRefs(
    Expression<bool> Function($$AccountTypesTableFilterComposer f) f,
  ) {
    final $$AccountTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.accountTypes,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountTypesTableFilterComposer(
            $db: $db,
            $table: $db.accountTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LanguagesTableOrderingComposer
    extends Composer<_$AppDatabase, $LanguagesTable> {
  $$LanguagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get language => $composableBuilder(
    column: $table.language,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LanguagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LanguagesTable> {
  $$LanguagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get language =>
      $composableBuilder(column: $table.language, builder: (column) => column);

  GeneratedColumn<String> get languageCode => $composableBuilder(
    column: $table.languageCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  Expression<T> currenciesRefs<T extends Object>(
    Expression<T> Function($$CurrenciesTableAnnotationComposer a) f,
  ) {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> accountTypesRefs<T extends Object>(
    Expression<T> Function($$AccountTypesTableAnnotationComposer a) f,
  ) {
    final $$AccountTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.accountTypes,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.accountTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LanguagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LanguagesTable,
          Language,
          $$LanguagesTableFilterComposer,
          $$LanguagesTableOrderingComposer,
          $$LanguagesTableAnnotationComposer,
          $$LanguagesTableCreateCompanionBuilder,
          $$LanguagesTableUpdateCompanionBuilder,
          (Language, $$LanguagesTableReferences),
          Language,
          PrefetchHooks Function({bool currenciesRefs, bool accountTypesRefs})
        > {
  $$LanguagesTableTableManager(_$AppDatabase db, $LanguagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LanguagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LanguagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LanguagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> language = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LanguagesCompanion(
                language: language,
                languageCode: languageCode,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String language,
                required String languageCode,
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LanguagesCompanion.insert(
                language: language,
                languageCode: languageCode,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LanguagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({currenciesRefs = false, accountTypesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (currenciesRefs) db.currencies,
                    if (accountTypesRefs) db.accountTypes,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (currenciesRefs)
                        await $_getPrefetchedData<
                          Language,
                          $LanguagesTable,
                          Currency
                        >(
                          currentTable: table,
                          referencedTable: $$LanguagesTableReferences
                              ._currenciesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LanguagesTableReferences(
                                db,
                                table,
                                p0,
                              ).currenciesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.languageCode == item.languageCode,
                              ),
                          typedResults: items,
                        ),
                      if (accountTypesRefs)
                        await $_getPrefetchedData<
                          Language,
                          $LanguagesTable,
                          AccountType
                        >(
                          currentTable: table,
                          referencedTable: $$LanguagesTableReferences
                              ._accountTypesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LanguagesTableReferences(
                                db,
                                table,
                                p0,
                              ).accountTypesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.languageCode == item.languageCode,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LanguagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LanguagesTable,
      Language,
      $$LanguagesTableFilterComposer,
      $$LanguagesTableOrderingComposer,
      $$LanguagesTableAnnotationComposer,
      $$LanguagesTableCreateCompanionBuilder,
      $$LanguagesTableUpdateCompanionBuilder,
      (Language, $$LanguagesTableReferences),
      Language,
      PrefetchHooks Function({bool currenciesRefs, bool accountTypesRefs})
    >;
typedef $$CurrenciesTableCreateCompanionBuilder =
    CurrenciesCompanion Function({
      required String name,
      required String code,
      required String languageCode,
      Value<TypeCurrency> type,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<int> rowid,
    });
typedef $$CurrenciesTableUpdateCompanionBuilder =
    CurrenciesCompanion Function({
      Value<String> name,
      Value<String> code,
      Value<String> languageCode,
      Value<TypeCurrency> type,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<int> rowid,
    });

final class $$CurrenciesTableReferences
    extends BaseReferences<_$AppDatabase, $CurrenciesTable, Currency> {
  $$CurrenciesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LanguagesTable _languageCodeTable(_$AppDatabase db) =>
      db.languages.createAlias(
        $_aliasNameGenerator(
          db.currencies.languageCode,
          db.languages.languageCode,
        ),
      );

  $$LanguagesTableProcessedTableManager get languageCode {
    final $_column = $_itemColumn<String>('language_code')!;

    final manager = $$LanguagesTableTableManager(
      $_db,
      $_db.languages,
    ).filter((f) => f.languageCode.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_languageCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $CurrencyDesignationsTable,
    List<CurrencyDesignation>
  >
  _currencyDesignationsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.currencyDesignations,
        aliasName: $_aliasNameGenerator(
          db.currencies.code,
          db.currencyDesignations.currencyCode,
        ),
      );

  $$CurrencyDesignationsTableProcessedTableManager
  get currencyDesignationsRefs {
    final manager =
        $$CurrencyDesignationsTableTableManager(
          $_db,
          $_db.currencyDesignations,
        ).filter(
          (f) => f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _currencyDesignationsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AccountsTable, List<DbAccount>>
  _accountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.accounts.currencyCode,
    ),
  );

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter(
      (f) => f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!),
    );

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.transactions.currencyCode,
    ),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager($_db, $_db.transactions)
        .filter(
          (f) => f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExchangeRatesTable, List<ExchangeRate>>
  _exchangeRatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exchangeRates,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.exchangeRates.fromCurrencyCode,
    ),
  );

  $$ExchangeRatesTableProcessedTableManager get exchangeRatesRefs {
    final manager = $$ExchangeRatesTableTableManager($_db, $_db.exchangeRates)
        .filter(
          (f) =>
              f.fromCurrencyCode.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(_exchangeRatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ExchangeRatesTable, List<ExchangeRate>>
  _ToCurrencyRatesTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.exchangeRates,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.exchangeRates.toCurrencyCode,
    ),
  );

  $$ExchangeRatesTableProcessedTableManager get ToCurrencyRates {
    final manager = $$ExchangeRatesTableTableManager($_db, $_db.exchangeRates)
        .filter(
          (f) => f.toCurrencyCode.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(_ToCurrencyRatesTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AssetEntriesTable, List<AssetEntry>>
  _assetEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetEntries,
    aliasName: $_aliasNameGenerator(
      db.currencies.code,
      db.assetEntries.currencyCode,
    ),
  );

  $$AssetEntriesTableProcessedTableManager get assetEntriesRefs {
    final manager = $$AssetEntriesTableTableManager($_db, $_db.assetEntries)
        .filter(
          (f) => f.currencyCode.code.sqlEquals($_itemColumn<String>('code')!),
        );

    final cache = $_typedResult.readTableOrNull(_assetEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CurrenciesTableFilterComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<TypeCurrency, TypeCurrency, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  $$LanguagesTableFilterComposer get languageCode {
    final $$LanguagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableFilterComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> currencyDesignationsRefs(
    Expression<bool> Function($$CurrencyDesignationsTableFilterComposer f) f,
  ) {
    final $$CurrencyDesignationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.currencyDesignations,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrencyDesignationsTableFilterComposer(
            $db: $db,
            $table: $db.currencyDesignations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> accountsRefs(
    Expression<bool> Function($$AccountsTableFilterComposer f) f,
  ) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> exchangeRatesRefs(
    Expression<bool> Function($$ExchangeRatesTableFilterComposer f) f,
  ) {
    final $$ExchangeRatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.exchangeRates,
      getReferencedColumn: (t) => t.fromCurrencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExchangeRatesTableFilterComposer(
            $db: $db,
            $table: $db.exchangeRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> ToCurrencyRates(
    Expression<bool> Function($$ExchangeRatesTableFilterComposer f) f,
  ) {
    final $$ExchangeRatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.exchangeRates,
      getReferencedColumn: (t) => t.toCurrencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExchangeRatesTableFilterComposer(
            $db: $db,
            $table: $db.exchangeRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assetEntriesRefs(
    Expression<bool> Function($$AssetEntriesTableFilterComposer f) f,
  ) {
    final $$AssetEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.assetEntries,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetEntriesTableFilterComposer(
            $db: $db,
            $table: $db.assetEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CurrenciesTableOrderingComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get code => $composableBuilder(
    column: $table.code,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  $$LanguagesTableOrderingComposer get languageCode {
    final $$LanguagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableOrderingComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CurrenciesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CurrenciesTable> {
  $$CurrenciesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TypeCurrency, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  $$LanguagesTableAnnotationComposer get languageCode {
    final $$LanguagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableAnnotationComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> currencyDesignationsRefs<T extends Object>(
    Expression<T> Function($$CurrencyDesignationsTableAnnotationComposer a) f,
  ) {
    final $$CurrencyDesignationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.code,
          referencedTable: $db.currencyDesignations,
          getReferencedColumn: (t) => t.currencyCode,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CurrencyDesignationsTableAnnotationComposer(
                $db: $db,
                $table: $db.currencyDesignations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($$AccountsTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> exchangeRatesRefs<T extends Object>(
    Expression<T> Function($$ExchangeRatesTableAnnotationComposer a) f,
  ) {
    final $$ExchangeRatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.exchangeRates,
      getReferencedColumn: (t) => t.fromCurrencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExchangeRatesTableAnnotationComposer(
            $db: $db,
            $table: $db.exchangeRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> ToCurrencyRates<T extends Object>(
    Expression<T> Function($$ExchangeRatesTableAnnotationComposer a) f,
  ) {
    final $$ExchangeRatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.exchangeRates,
      getReferencedColumn: (t) => t.toCurrencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExchangeRatesTableAnnotationComposer(
            $db: $db,
            $table: $db.exchangeRates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assetEntriesRefs<T extends Object>(
    Expression<T> Function($$AssetEntriesTableAnnotationComposer a) f,
  ) {
    final $$AssetEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.code,
      referencedTable: $db.assetEntries,
      getReferencedColumn: (t) => t.currencyCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.assetEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CurrenciesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CurrenciesTable,
          Currency,
          $$CurrenciesTableFilterComposer,
          $$CurrenciesTableOrderingComposer,
          $$CurrenciesTableAnnotationComposer,
          $$CurrenciesTableCreateCompanionBuilder,
          $$CurrenciesTableUpdateCompanionBuilder,
          (Currency, $$CurrenciesTableReferences),
          Currency,
          PrefetchHooks Function({
            bool languageCode,
            bool currencyDesignationsRefs,
            bool accountsRefs,
            bool transactionsRefs,
            bool exchangeRatesRefs,
            bool ToCurrencyRates,
            bool assetEntriesRefs,
          })
        > {
  $$CurrenciesTableTableManager(_$AppDatabase db, $CurrenciesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrenciesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrenciesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CurrenciesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> name = const Value.absent(),
                Value<String> code = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<TypeCurrency> type = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesCompanion(
                name: name,
                code: code,
                languageCode: languageCode,
                type: type,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String code,
                required String languageCode,
                Value<TypeCurrency> type = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesCompanion.insert(
                name: name,
                code: code,
                languageCode: languageCode,
                type: type,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CurrenciesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                languageCode = false,
                currencyDesignationsRefs = false,
                accountsRefs = false,
                transactionsRefs = false,
                exchangeRatesRefs = false,
                ToCurrencyRates = false,
                assetEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (currencyDesignationsRefs) db.currencyDesignations,
                    if (accountsRefs) db.accounts,
                    if (transactionsRefs) db.transactions,
                    if (exchangeRatesRefs) db.exchangeRates,
                    if (ToCurrencyRates) db.exchangeRates,
                    if (assetEntriesRefs) db.assetEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (languageCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.languageCode,
                                    referencedTable: $$CurrenciesTableReferences
                                        ._languageCodeTable(db),
                                    referencedColumn:
                                        $$CurrenciesTableReferences
                                            ._languageCodeTable(db)
                                            .languageCode,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (currencyDesignationsRefs)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          CurrencyDesignation
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._currencyDesignationsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).currencyDesignationsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (accountsRefs)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          DbAccount
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._accountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).accountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (exchangeRatesRefs)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          ExchangeRate
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._exchangeRatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).exchangeRatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fromCurrencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (ToCurrencyRates)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          ExchangeRate
                        >(
                          currentTable: table,
                          referencedTable:
                              $$CurrenciesTableReferences._ToCurrencyRatesTable(
                                db,
                              ),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).ToCurrencyRates,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.toCurrencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                      if (assetEntriesRefs)
                        await $_getPrefetchedData<
                          Currency,
                          $CurrenciesTable,
                          AssetEntry
                        >(
                          currentTable: table,
                          referencedTable: $$CurrenciesTableReferences
                              ._assetEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrenciesTableReferences(
                                db,
                                table,
                                p0,
                              ).assetEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyCode == item.code,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CurrenciesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CurrenciesTable,
      Currency,
      $$CurrenciesTableFilterComposer,
      $$CurrenciesTableOrderingComposer,
      $$CurrenciesTableAnnotationComposer,
      $$CurrenciesTableCreateCompanionBuilder,
      $$CurrenciesTableUpdateCompanionBuilder,
      (Currency, $$CurrenciesTableReferences),
      Currency,
      PrefetchHooks Function({
        bool languageCode,
        bool currencyDesignationsRefs,
        bool accountsRefs,
        bool transactionsRefs,
        bool exchangeRatesRefs,
        bool ToCurrencyRates,
        bool assetEntriesRefs,
      })
    >;
typedef $$CurrencyDesignationsTableCreateCompanionBuilder =
    CurrencyDesignationsCompanion Function({
      Value<String> id,
      required String value,
      required String currencyCode,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$CurrencyDesignationsTableUpdateCompanionBuilder =
    CurrencyDesignationsCompanion Function({
      Value<String> id,
      Value<String> value,
      Value<String> currencyCode,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$CurrencyDesignationsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CurrencyDesignationsTable,
          CurrencyDesignation
        > {
  $$CurrencyDesignationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.currencyDesignations.currencyCode,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AccountsTable, List<DbAccount>>
  _accountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: $_aliasNameGenerator(
      db.currencyDesignations.id,
      db.accounts.currencyDesignationId,
    ),
  );

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager($_db, $_db.accounts).filter(
      (f) => f.currencyDesignationId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CurrencyDesignationsTableFilterComposer
    extends Composer<_$AppDatabase, $CurrencyDesignationsTable> {
  $$CurrencyDesignationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> accountsRefs(
    Expression<bool> Function($$AccountsTableFilterComposer f) f,
  ) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.currencyDesignationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CurrencyDesignationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CurrencyDesignationsTable> {
  $$CurrencyDesignationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CurrencyDesignationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CurrencyDesignationsTable> {
  $$CurrencyDesignationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($$AccountsTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.currencyDesignationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CurrencyDesignationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CurrencyDesignationsTable,
          CurrencyDesignation,
          $$CurrencyDesignationsTableFilterComposer,
          $$CurrencyDesignationsTableOrderingComposer,
          $$CurrencyDesignationsTableAnnotationComposer,
          $$CurrencyDesignationsTableCreateCompanionBuilder,
          $$CurrencyDesignationsTableUpdateCompanionBuilder,
          (CurrencyDesignation, $$CurrencyDesignationsTableReferences),
          CurrencyDesignation,
          PrefetchHooks Function({bool currencyCode, bool accountsRefs})
        > {
  $$CurrencyDesignationsTableTableManager(
    _$AppDatabase db,
    $CurrencyDesignationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CurrencyDesignationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CurrencyDesignationsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$CurrencyDesignationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrencyDesignationsCompanion(
                id: id,
                value: value,
                currencyCode: currencyCode,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String value,
                required String currencyCode,
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrencyDesignationsCompanion.insert(
                id: id,
                value: value,
                currencyCode: currencyCode,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CurrencyDesignationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({currencyCode = false, accountsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (accountsRefs) db.accounts],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (currencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyCode,
                                    referencedTable:
                                        $$CurrencyDesignationsTableReferences
                                            ._currencyCodeTable(db),
                                    referencedColumn:
                                        $$CurrencyDesignationsTableReferences
                                            ._currencyCodeTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accountsRefs)
                        await $_getPrefetchedData<
                          CurrencyDesignation,
                          $CurrencyDesignationsTable,
                          DbAccount
                        >(
                          currentTable: table,
                          referencedTable: $$CurrencyDesignationsTableReferences
                              ._accountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CurrencyDesignationsTableReferences(
                                db,
                                table,
                                p0,
                              ).accountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.currencyDesignationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CurrencyDesignationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CurrencyDesignationsTable,
      CurrencyDesignation,
      $$CurrencyDesignationsTableFilterComposer,
      $$CurrencyDesignationsTableOrderingComposer,
      $$CurrencyDesignationsTableAnnotationComposer,
      $$CurrencyDesignationsTableCreateCompanionBuilder,
      $$CurrencyDesignationsTableUpdateCompanionBuilder,
      (CurrencyDesignation, $$CurrencyDesignationsTableReferences),
      CurrencyDesignation,
      PrefetchHooks Function({bool currencyCode, bool accountsRefs})
    >;
typedef $$StylesTableCreateCompanionBuilder =
    StylesCompanion Function({
      Value<String> id,
      required String name,
      required String iconName,
      required String colorHex,
      Value<IconType> iconType,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$StylesTableUpdateCompanionBuilder =
    StylesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> iconName,
      Value<String> colorHex,
      Value<IconType> iconType,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$StylesTableReferences
    extends BaseReferences<_$AppDatabase, $StylesTable, Style> {
  $$StylesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$CategoriesTable, List<Category>>
  _categoriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.categories,
    aliasName: $_aliasNameGenerator(db.styles.id, db.categories.styleId),
  );

  $$CategoriesTableProcessedTableManager get categoriesRefs {
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.styleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_categoriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AccountsTable, List<DbAccount>>
  _accountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: $_aliasNameGenerator(db.styles.id, db.accounts.styleId),
  );

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.styleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StylesTableFilterComposer
    extends Composer<_$AppDatabase, $StylesTable> {
  $$StylesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<IconType, IconType, int> get iconType =>
      $composableBuilder(
        column: $table.iconType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> categoriesRefs(
    Expression<bool> Function($$CategoriesTableFilterComposer f) f,
  ) {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.styleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> accountsRefs(
    Expression<bool> Function($$AccountsTableFilterComposer f) f,
  ) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.styleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StylesTableOrderingComposer
    extends Composer<_$AppDatabase, $StylesTable> {
  $$StylesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconName => $composableBuilder(
    column: $table.iconName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iconType => $composableBuilder(
    column: $table.iconType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StylesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StylesTable> {
  $$StylesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconName =>
      $composableBuilder(column: $table.iconName, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumnWithTypeConverter<IconType, int> get iconType =>
      $composableBuilder(column: $table.iconType, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  Expression<T> categoriesRefs<T extends Object>(
    Expression<T> Function($$CategoriesTableAnnotationComposer a) f,
  ) {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.styleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($$AccountsTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.styleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StylesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StylesTable,
          Style,
          $$StylesTableFilterComposer,
          $$StylesTableOrderingComposer,
          $$StylesTableAnnotationComposer,
          $$StylesTableCreateCompanionBuilder,
          $$StylesTableUpdateCompanionBuilder,
          (Style, $$StylesTableReferences),
          Style,
          PrefetchHooks Function({bool categoriesRefs, bool accountsRefs})
        > {
  $$StylesTableTableManager(_$AppDatabase db, $StylesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StylesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StylesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StylesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> iconName = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<IconType> iconType = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StylesCompanion(
                id: id,
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                iconType: iconType,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String iconName,
                required String colorHex,
                Value<IconType> iconType = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StylesCompanion.insert(
                id: id,
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                iconType: iconType,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$StylesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({categoriesRefs = false, accountsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (categoriesRefs) db.categories,
                    if (accountsRefs) db.accounts,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (categoriesRefs)
                        await $_getPrefetchedData<
                          Style,
                          $StylesTable,
                          Category
                        >(
                          currentTable: table,
                          referencedTable: $$StylesTableReferences
                              ._categoriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StylesTableReferences(
                                db,
                                table,
                                p0,
                              ).categoriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.styleId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (accountsRefs)
                        await $_getPrefetchedData<
                          Style,
                          $StylesTable,
                          DbAccount
                        >(
                          currentTable: table,
                          referencedTable: $$StylesTableReferences
                              ._accountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$StylesTableReferences(
                                db,
                                table,
                                p0,
                              ).accountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.styleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$StylesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StylesTable,
      Style,
      $$StylesTableFilterComposer,
      $$StylesTableOrderingComposer,
      $$StylesTableAnnotationComposer,
      $$StylesTableCreateCompanionBuilder,
      $$StylesTableUpdateCompanionBuilder,
      (Style, $$StylesTableReferences),
      Style,
      PrefetchHooks Function({bool categoriesRefs, bool accountsRefs})
    >;
typedef $$CategoriesTableCreateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      required String name,
      Value<String?> parentId,
      Value<String?> styleId,
      Value<CategoryType> type,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> parentId,
      Value<String?> styleId,
      Value<CategoryType> type,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _parentIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.categories.parentId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StylesTable _styleIdTable(_$AppDatabase db) => db.styles.createAlias(
    $_aliasNameGenerator(db.categories.styleId, db.styles.id),
  );

  $$StylesTableProcessedTableManager? get styleId {
    final $_column = $_itemColumn<String>('style_id');
    if ($_column == null) return null;
    final manager = $$StylesTableTableManager(
      $_db,
      $_db.styles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_styleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(
      db.categories.id,
      db.transactions.categoryId,
    ),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<CategoryType, CategoryType, int> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get parentId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StylesTableFilterComposer get styleId {
    final $$StylesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.styleId,
      referencedTable: $db.styles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StylesTableFilterComposer(
            $db: $db,
            $table: $db.styles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get parentId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StylesTableOrderingComposer get styleId {
    final $$StylesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.styleId,
      referencedTable: $db.styles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StylesTableOrderingComposer(
            $db: $db,
            $table: $db.styles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<CategoryType, int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get parentId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StylesTableAnnotationComposer get styleId {
    final $$StylesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.styleId,
      referencedTable: $db.styles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StylesTableAnnotationComposer(
            $db: $db,
            $table: $db.styles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({
            bool parentId,
            bool styleId,
            bool transactionsRefs,
          })
        > {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> styleId = const Value.absent(),
                Value<CategoryType> type = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                parentId: parentId,
                styleId: styleId,
                type: type,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<String?> styleId = const Value.absent(),
                Value<CategoryType> type = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                styleId: styleId,
                type: type,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({parentId = false, styleId = false, transactionsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (parentId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.parentId,
                                    referencedTable: $$CategoriesTableReferences
                                        ._parentIdTable(db),
                                    referencedColumn:
                                        $$CategoriesTableReferences
                                            ._parentIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (styleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.styleId,
                                    referencedTable: $$CategoriesTableReferences
                                        ._styleIdTable(db),
                                    referencedColumn:
                                        $$CategoriesTableReferences
                                            ._styleIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          Category,
                          $CategoriesTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.categoryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({
        bool parentId,
        bool styleId,
        bool transactionsRefs,
      })
    >;
typedef $$AccountTypesTableCreateCompanionBuilder =
    AccountTypesCompanion Function({
      Value<String> id,
      required String name,
      required String languageCode,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$AccountTypesTableUpdateCompanionBuilder =
    AccountTypesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> languageCode,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$AccountTypesTableReferences
    extends BaseReferences<_$AppDatabase, $AccountTypesTable, AccountType> {
  $$AccountTypesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LanguagesTable _languageCodeTable(_$AppDatabase db) =>
      db.languages.createAlias(
        $_aliasNameGenerator(
          db.accountTypes.languageCode,
          db.languages.languageCode,
        ),
      );

  $$LanguagesTableProcessedTableManager get languageCode {
    final $_column = $_itemColumn<String>('language_code')!;

    final manager = $$LanguagesTableTableManager(
      $_db,
      $_db.languages,
    ).filter((f) => f.languageCode.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_languageCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$AccountsTable, List<DbAccount>>
  _accountsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: $_aliasNameGenerator(
      db.accountTypes.id,
      db.accounts.accountTypeId,
    ),
  );

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.accountTypeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountTypesTableFilterComposer
    extends Composer<_$AppDatabase, $AccountTypesTable> {
  $$AccountTypesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$LanguagesTableFilterComposer get languageCode {
    final $$LanguagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableFilterComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> accountsRefs(
    Expression<bool> Function($$AccountsTableFilterComposer f) f,
  ) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountTypesTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountTypesTable> {
  $$AccountTypesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$LanguagesTableOrderingComposer get languageCode {
    final $$LanguagesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableOrderingComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountTypesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountTypesTable> {
  $$AccountTypesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$LanguagesTableAnnotationComposer get languageCode {
    final $$LanguagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.languageCode,
      referencedTable: $db.languages,
      getReferencedColumn: (t) => t.languageCode,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LanguagesTableAnnotationComposer(
            $db: $db,
            $table: $db.languages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($$AccountsTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.accountTypeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountTypesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountTypesTable,
          AccountType,
          $$AccountTypesTableFilterComposer,
          $$AccountTypesTableOrderingComposer,
          $$AccountTypesTableAnnotationComposer,
          $$AccountTypesTableCreateCompanionBuilder,
          $$AccountTypesTableUpdateCompanionBuilder,
          (AccountType, $$AccountTypesTableReferences),
          AccountType,
          PrefetchHooks Function({bool languageCode, bool accountsRefs})
        > {
  $$AccountTypesTableTableManager(_$AppDatabase db, $AccountTypesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountTypesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountTypesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountTypesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> languageCode = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountTypesCompanion(
                id: id,
                name: name,
                languageCode: languageCode,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String languageCode,
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountTypesCompanion.insert(
                id: id,
                name: name,
                languageCode: languageCode,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountTypesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({languageCode = false, accountsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (accountsRefs) db.accounts],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (languageCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.languageCode,
                                    referencedTable:
                                        $$AccountTypesTableReferences
                                            ._languageCodeTable(db),
                                    referencedColumn:
                                        $$AccountTypesTableReferences
                                            ._languageCodeTable(db)
                                            .languageCode,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (accountsRefs)
                        await $_getPrefetchedData<
                          AccountType,
                          $AccountTypesTable,
                          DbAccount
                        >(
                          currentTable: table,
                          referencedTable: $$AccountTypesTableReferences
                              ._accountsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountTypesTableReferences(
                                db,
                                table,
                                p0,
                              ).accountsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountTypeId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountTypesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountTypesTable,
      AccountType,
      $$AccountTypesTableFilterComposer,
      $$AccountTypesTableOrderingComposer,
      $$AccountTypesTableAnnotationComposer,
      $$AccountTypesTableCreateCompanionBuilder,
      $$AccountTypesTableUpdateCompanionBuilder,
      (AccountType, $$AccountTypesTableReferences),
      AccountType,
      PrefetchHooks Function({bool languageCode, bool accountsRefs})
    >;
typedef $$AccountsTableCreateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      required String name,
      Value<String?> description,
      required double balance,
      Value<int?> balanceMinor,
      Value<double> openingBalance,
      Value<int?> openingBalanceMinor,
      required String currencyCode,
      required String currencyDesignationId,
      Value<String?> styleId,
      required String accountTypeId,
      Value<DateTime> creationDate,
      Value<String?> country,
      Value<String?> assetId,
      Value<double> assetQuantity,
      Value<String?> feeStructure,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<double> balance,
      Value<int?> balanceMinor,
      Value<double> openingBalance,
      Value<int?> openingBalanceMinor,
      Value<String> currencyCode,
      Value<String> currencyDesignationId,
      Value<String?> styleId,
      Value<String> accountTypeId,
      Value<DateTime> creationDate,
      Value<String?> country,
      Value<String?> assetId,
      Value<double> assetQuantity,
      Value<String?> feeStructure,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, DbAccount> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.accounts.currencyCode, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrencyDesignationsTable _currencyDesignationIdTable(
    _$AppDatabase db,
  ) => db.currencyDesignations.createAlias(
    $_aliasNameGenerator(
      db.accounts.currencyDesignationId,
      db.currencyDesignations.id,
    ),
  );

  $$CurrencyDesignationsTableProcessedTableManager get currencyDesignationId {
    final $_column = $_itemColumn<String>('currency_designation_id')!;

    final manager = $$CurrencyDesignationsTableTableManager(
      $_db,
      $_db.currencyDesignations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _currencyDesignationIdTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $StylesTable _styleIdTable(_$AppDatabase db) => db.styles.createAlias(
    $_aliasNameGenerator(db.accounts.styleId, db.styles.id),
  );

  $$StylesTableProcessedTableManager? get styleId {
    final $_column = $_itemColumn<String>('style_id');
    if ($_column == null) return null;
    final manager = $$StylesTableTableManager(
      $_db,
      $_db.styles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_styleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountTypesTable _accountTypeIdTable(_$AppDatabase db) =>
      db.accountTypes.createAlias(
        $_aliasNameGenerator(db.accounts.accountTypeId, db.accountTypes.id),
      );

  $$AccountTypesTableProcessedTableManager get accountTypeId {
    final $_column = $_itemColumn<String>('account_type_id')!;

    final manager = $$AccountTypesTableTableManager(
      $_db,
      $_db.accountTypes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountTypeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TransactionsTable, List<Transaction>>
  _transactionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transactions,
    aliasName: $_aliasNameGenerator(db.accounts.id, db.transactions.accountId),
  );

  $$TransactionsTableProcessedTableManager get transactionsRefs {
    final manager = $$TransactionsTableTableManager(
      $_db,
      $_db.transactions,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transactionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AssetEntriesTable, List<AssetEntry>>
  _assetEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetEntries,
    aliasName: $_aliasNameGenerator(db.accounts.id, db.assetEntries.accountId),
  );

  $$AssetEntriesTableProcessedTableManager get assetEntriesRefs {
    final manager = $$AssetEntriesTableTableManager(
      $_db,
      $_db.assetEntries,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_assetEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get balanceMinor => $composableBuilder(
    column: $table.balanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get assetQuantity => $composableBuilder(
    column: $table.assetQuantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feeStructure => $composableBuilder(
    column: $table.feeStructure,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrencyDesignationsTableFilterComposer get currencyDesignationId {
    final $$CurrencyDesignationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyDesignationId,
      referencedTable: $db.currencyDesignations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrencyDesignationsTableFilterComposer(
            $db: $db,
            $table: $db.currencyDesignations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$StylesTableFilterComposer get styleId {
    final $$StylesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.styleId,
      referencedTable: $db.styles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StylesTableFilterComposer(
            $db: $db,
            $table: $db.styles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountTypesTableFilterComposer get accountTypeId {
    final $$AccountTypesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountTypeId,
      referencedTable: $db.accountTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountTypesTableFilterComposer(
            $db: $db,
            $table: $db.accountTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> transactionsRefs(
    Expression<bool> Function($$TransactionsTableFilterComposer f) f,
  ) {
    final $$TransactionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableFilterComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> assetEntriesRefs(
    Expression<bool> Function($$AssetEntriesTableFilterComposer f) f,
  ) {
    final $$AssetEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetEntriesTableFilterComposer(
            $db: $db,
            $table: $db.assetEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get balance => $composableBuilder(
    column: $table.balance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get balanceMinor => $composableBuilder(
    column: $table.balanceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get assetQuantity => $composableBuilder(
    column: $table.assetQuantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feeStructure => $composableBuilder(
    column: $table.feeStructure,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrencyDesignationsTableOrderingComposer get currencyDesignationId {
    final $$CurrencyDesignationsTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.currencyDesignationId,
          referencedTable: $db.currencyDesignations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CurrencyDesignationsTableOrderingComposer(
                $db: $db,
                $table: $db.currencyDesignations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$StylesTableOrderingComposer get styleId {
    final $$StylesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.styleId,
      referencedTable: $db.styles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StylesTableOrderingComposer(
            $db: $db,
            $table: $db.styles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountTypesTableOrderingComposer get accountTypeId {
    final $$AccountTypesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountTypeId,
      referencedTable: $db.accountTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountTypesTableOrderingComposer(
            $db: $db,
            $table: $db.accountTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get balance =>
      $composableBuilder(column: $table.balance, builder: (column) => column);

  GeneratedColumn<int> get balanceMinor => $composableBuilder(
    column: $table.balanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<double> get openingBalance => $composableBuilder(
    column: $table.openingBalance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get openingBalanceMinor => $composableBuilder(
    column: $table.openingBalanceMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<double> get assetQuantity => $composableBuilder(
    column: $table.assetQuantity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feeStructure => $composableBuilder(
    column: $table.feeStructure,
    builder: (column) => column,
  );

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrencyDesignationsTableAnnotationComposer get currencyDesignationId {
    final $$CurrencyDesignationsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.currencyDesignationId,
          referencedTable: $db.currencyDesignations,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$CurrencyDesignationsTableAnnotationComposer(
                $db: $db,
                $table: $db.currencyDesignations,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }

  $$StylesTableAnnotationComposer get styleId {
    final $$StylesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.styleId,
      referencedTable: $db.styles,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StylesTableAnnotationComposer(
            $db: $db,
            $table: $db.styles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountTypesTableAnnotationComposer get accountTypeId {
    final $$AccountTypesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountTypeId,
      referencedTable: $db.accountTypes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountTypesTableAnnotationComposer(
            $db: $db,
            $table: $db.accountTypes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> transactionsRefs<T extends Object>(
    Expression<T> Function($$TransactionsTableAnnotationComposer a) f,
  ) {
    final $$TransactionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transactions,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransactionsTableAnnotationComposer(
            $db: $db,
            $table: $db.transactions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> assetEntriesRefs<T extends Object>(
    Expression<T> Function($$AssetEntriesTableAnnotationComposer a) f,
  ) {
    final $$AssetEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.assetEntries,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.assetEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          DbAccount,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (DbAccount, $$AccountsTableReferences),
          DbAccount,
          PrefetchHooks Function({
            bool currencyCode,
            bool currencyDesignationId,
            bool styleId,
            bool accountTypeId,
            bool transactionsRefs,
            bool assetEntriesRefs,
          })
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<double> balance = const Value.absent(),
                Value<int?> balanceMinor = const Value.absent(),
                Value<double> openingBalance = const Value.absent(),
                Value<int?> openingBalanceMinor = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String> currencyDesignationId = const Value.absent(),
                Value<String?> styleId = const Value.absent(),
                Value<String> accountTypeId = const Value.absent(),
                Value<DateTime> creationDate = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<double> assetQuantity = const Value.absent(),
                Value<String?> feeStructure = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                description: description,
                balance: balance,
                balanceMinor: balanceMinor,
                openingBalance: openingBalance,
                openingBalanceMinor: openingBalanceMinor,
                currencyCode: currencyCode,
                currencyDesignationId: currencyDesignationId,
                styleId: styleId,
                accountTypeId: accountTypeId,
                creationDate: creationDate,
                country: country,
                assetId: assetId,
                assetQuantity: assetQuantity,
                feeStructure: feeStructure,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required double balance,
                Value<int?> balanceMinor = const Value.absent(),
                Value<double> openingBalance = const Value.absent(),
                Value<int?> openingBalanceMinor = const Value.absent(),
                required String currencyCode,
                required String currencyDesignationId,
                Value<String?> styleId = const Value.absent(),
                required String accountTypeId,
                Value<DateTime> creationDate = const Value.absent(),
                Value<String?> country = const Value.absent(),
                Value<String?> assetId = const Value.absent(),
                Value<double> assetQuantity = const Value.absent(),
                Value<String?> feeStructure = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                description: description,
                balance: balance,
                balanceMinor: balanceMinor,
                openingBalance: openingBalance,
                openingBalanceMinor: openingBalanceMinor,
                currencyCode: currencyCode,
                currencyDesignationId: currencyDesignationId,
                styleId: styleId,
                accountTypeId: accountTypeId,
                creationDate: creationDate,
                country: country,
                assetId: assetId,
                assetQuantity: assetQuantity,
                feeStructure: feeStructure,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                currencyCode = false,
                currencyDesignationId = false,
                styleId = false,
                accountTypeId = false,
                transactionsRefs = false,
                assetEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (transactionsRefs) db.transactions,
                    if (assetEntriesRefs) db.assetEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (currencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyCode,
                                    referencedTable: $$AccountsTableReferences
                                        ._currencyCodeTable(db),
                                    referencedColumn: $$AccountsTableReferences
                                        ._currencyCodeTable(db)
                                        .code,
                                  )
                                  as T;
                        }
                        if (currencyDesignationId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyDesignationId,
                                    referencedTable: $$AccountsTableReferences
                                        ._currencyDesignationIdTable(db),
                                    referencedColumn: $$AccountsTableReferences
                                        ._currencyDesignationIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (styleId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.styleId,
                                    referencedTable: $$AccountsTableReferences
                                        ._styleIdTable(db),
                                    referencedColumn: $$AccountsTableReferences
                                        ._styleIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (accountTypeId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountTypeId,
                                    referencedTable: $$AccountsTableReferences
                                        ._accountTypeIdTable(db),
                                    referencedColumn: $$AccountsTableReferences
                                        ._accountTypeIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (transactionsRefs)
                        await $_getPrefetchedData<
                          DbAccount,
                          $AccountsTable,
                          Transaction
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._transactionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).transactionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (assetEntriesRefs)
                        await $_getPrefetchedData<
                          DbAccount,
                          $AccountsTable,
                          AssetEntry
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._assetEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).assetEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.accountId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      DbAccount,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (DbAccount, $$AccountsTableReferences),
      DbAccount,
      PrefetchHooks Function({
        bool currencyCode,
        bool currencyDesignationId,
        bool styleId,
        bool accountTypeId,
        bool transactionsRefs,
        bool assetEntriesRefs,
      })
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      required String description,
      required double amount,
      Value<int?> amountMinor,
      required DateTime date,
      required String accountId,
      required String categoryId,
      required String currencyCode,
      Value<double?> exchangeRate,
      Value<int?> exchangeRatePreset,
      Value<double> fee,
      Value<int?> feeMinor,
      Value<String?> linkedTransactionId,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> description,
      Value<double> amount,
      Value<int?> amountMinor,
      Value<DateTime> date,
      Value<String> accountId,
      Value<String> categoryId,
      Value<String> currencyCode,
      Value<double?> exchangeRate,
      Value<int?> exchangeRatePreset,
      Value<double> fee,
      Value<int?> feeMinor,
      Value<String?> linkedTransactionId,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$TransactionsTableReferences
    extends BaseReferences<_$AppDatabase, $TransactionsTable, Transaction> {
  $$TransactionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.transactions.accountId, db.accounts.id),
      );

  $$AccountsTableProcessedTableManager get accountId {
    final $_column = $_itemColumn<String>('account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
        $_aliasNameGenerator(db.transactions.categoryId, db.categories.id),
      );

  $$CategoriesTableProcessedTableManager get categoryId {
    final $_column = $_itemColumn<String>('category_id')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.transactions.currencyCode, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransactionsTableFilterComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exchangeRatePreset => $composableBuilder(
    column: $table.exchangeRatePreset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fee => $composableBuilder(
    column: $table.fee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get feeMinor => $composableBuilder(
    column: $table.feeMinor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableOrderingComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exchangeRatePreset => $composableBuilder(
    column: $table.exchangeRatePreset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fee => $composableBuilder(
    column: $table.fee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get feeMinor => $composableBuilder(
    column: $table.feeMinor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransactionsTable> {
  $$TransactionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<int> get amountMinor => $composableBuilder(
    column: $table.amountMinor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get exchangeRate => $composableBuilder(
    column: $table.exchangeRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exchangeRatePreset => $composableBuilder(
    column: $table.exchangeRatePreset,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fee =>
      $composableBuilder(column: $table.fee, builder: (column) => column);

  GeneratedColumn<int> get feeMinor =>
      $composableBuilder(column: $table.feeMinor, builder: (column) => column);

  GeneratedColumn<String> get linkedTransactionId => $composableBuilder(
    column: $table.linkedTransactionId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransactionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransactionsTable,
          Transaction,
          $$TransactionsTableFilterComposer,
          $$TransactionsTableOrderingComposer,
          $$TransactionsTableAnnotationComposer,
          $$TransactionsTableCreateCompanionBuilder,
          $$TransactionsTableUpdateCompanionBuilder,
          (Transaction, $$TransactionsTableReferences),
          Transaction,
          PrefetchHooks Function({
            bool accountId,
            bool categoryId,
            bool currencyCode,
          })
        > {
  $$TransactionsTableTableManager(_$AppDatabase db, $TransactionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransactionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransactionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransactionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<int?> amountMinor = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<double?> exchangeRate = const Value.absent(),
                Value<int?> exchangeRatePreset = const Value.absent(),
                Value<double> fee = const Value.absent(),
                Value<int?> feeMinor = const Value.absent(),
                Value<String?> linkedTransactionId = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                description: description,
                amount: amount,
                amountMinor: amountMinor,
                date: date,
                accountId: accountId,
                categoryId: categoryId,
                currencyCode: currencyCode,
                exchangeRate: exchangeRate,
                exchangeRatePreset: exchangeRatePreset,
                fee: fee,
                feeMinor: feeMinor,
                linkedTransactionId: linkedTransactionId,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String description,
                required double amount,
                Value<int?> amountMinor = const Value.absent(),
                required DateTime date,
                required String accountId,
                required String categoryId,
                required String currencyCode,
                Value<double?> exchangeRate = const Value.absent(),
                Value<int?> exchangeRatePreset = const Value.absent(),
                Value<double> fee = const Value.absent(),
                Value<int?> feeMinor = const Value.absent(),
                Value<String?> linkedTransactionId = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                description: description,
                amount: amount,
                amountMinor: amountMinor,
                date: date,
                accountId: accountId,
                categoryId: categoryId,
                currencyCode: currencyCode,
                exchangeRate: exchangeRate,
                exchangeRatePreset: exchangeRatePreset,
                fee: fee,
                feeMinor: feeMinor,
                linkedTransactionId: linkedTransactionId,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$TransactionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({accountId = false, categoryId = false, currencyCode = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (accountId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.accountId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._accountIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._accountIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._categoryIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }
                        if (currencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.currencyCode,
                                    referencedTable:
                                        $$TransactionsTableReferences
                                            ._currencyCodeTable(db),
                                    referencedColumn:
                                        $$TransactionsTableReferences
                                            ._currencyCodeTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransactionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransactionsTable,
      Transaction,
      $$TransactionsTableFilterComposer,
      $$TransactionsTableOrderingComposer,
      $$TransactionsTableAnnotationComposer,
      $$TransactionsTableCreateCompanionBuilder,
      $$TransactionsTableUpdateCompanionBuilder,
      (Transaction, $$TransactionsTableReferences),
      Transaction,
      PrefetchHooks Function({
        bool accountId,
        bool categoryId,
        bool currencyCode,
      })
    >;
typedef $$ExchangeRatesTableCreateCompanionBuilder =
    ExchangeRatesCompanion Function({
      required String fromCurrencyCode,
      required String toCurrencyCode,
      required double rate,
      required int preset,
      required DateTime date,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<String?> sourceId,
      Value<int> rowid,
    });
typedef $$ExchangeRatesTableUpdateCompanionBuilder =
    ExchangeRatesCompanion Function({
      Value<String> fromCurrencyCode,
      Value<String> toCurrencyCode,
      Value<double> rate,
      Value<int> preset,
      Value<DateTime> date,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<String?> sourceId,
      Value<int> rowid,
    });

final class $$ExchangeRatesTableReferences
    extends BaseReferences<_$AppDatabase, $ExchangeRatesTable, ExchangeRate> {
  $$ExchangeRatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CurrenciesTable _fromCurrencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.exchangeRates.fromCurrencyCode,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get fromCurrencyCode {
    final $_column = $_itemColumn<String>('from_currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromCurrencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CurrenciesTable _toCurrencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(
          db.exchangeRates.toCurrencyCode,
          db.currencies.code,
        ),
      );

  $$CurrenciesTableProcessedTableManager get toCurrencyCode {
    final $_column = $_itemColumn<String>('to_currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toCurrencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExchangeRatesTableFilterComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get preset => $composableBuilder(
    column: $table.preset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get fromCurrencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableFilterComposer get toCurrencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExchangeRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<double> get rate => $composableBuilder(
    column: $table.rate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preset => $composableBuilder(
    column: $table.preset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get fromCurrencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableOrderingComposer get toCurrencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExchangeRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExchangeRatesTable> {
  $$ExchangeRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<double> get rate =>
      $composableBuilder(column: $table.rate, builder: (column) => column);

  GeneratedColumn<int> get preset =>
      $composableBuilder(column: $table.preset, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get fromCurrencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CurrenciesTableAnnotationComposer get toCurrencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toCurrencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExchangeRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExchangeRatesTable,
          ExchangeRate,
          $$ExchangeRatesTableFilterComposer,
          $$ExchangeRatesTableOrderingComposer,
          $$ExchangeRatesTableAnnotationComposer,
          $$ExchangeRatesTableCreateCompanionBuilder,
          $$ExchangeRatesTableUpdateCompanionBuilder,
          (ExchangeRate, $$ExchangeRatesTableReferences),
          ExchangeRate,
          PrefetchHooks Function({bool fromCurrencyCode, bool toCurrencyCode})
        > {
  $$ExchangeRatesTableTableManager(_$AppDatabase db, $ExchangeRatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExchangeRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExchangeRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExchangeRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fromCurrencyCode = const Value.absent(),
                Value<String> toCurrencyCode = const Value.absent(),
                Value<double> rate = const Value.absent(),
                Value<int> preset = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion(
                fromCurrencyCode: fromCurrencyCode,
                toCurrencyCode: toCurrencyCode,
                rate: rate,
                preset: preset,
                date: date,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                sourceId: sourceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fromCurrencyCode,
                required String toCurrencyCode,
                required double rate,
                required int preset,
                required DateTime date,
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion.insert(
                fromCurrencyCode: fromCurrencyCode,
                toCurrencyCode: toCurrencyCode,
                rate: rate,
                preset: preset,
                date: date,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                sourceId: sourceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ExchangeRatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({fromCurrencyCode = false, toCurrencyCode = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (fromCurrencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.fromCurrencyCode,
                                    referencedTable:
                                        $$ExchangeRatesTableReferences
                                            ._fromCurrencyCodeTable(db),
                                    referencedColumn:
                                        $$ExchangeRatesTableReferences
                                            ._fromCurrencyCodeTable(db)
                                            .code,
                                  )
                                  as T;
                        }
                        if (toCurrencyCode) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.toCurrencyCode,
                                    referencedTable:
                                        $$ExchangeRatesTableReferences
                                            ._toCurrencyCodeTable(db),
                                    referencedColumn:
                                        $$ExchangeRatesTableReferences
                                            ._toCurrencyCodeTable(db)
                                            .code,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ExchangeRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExchangeRatesTable,
      ExchangeRate,
      $$ExchangeRatesTableFilterComposer,
      $$ExchangeRatesTableOrderingComposer,
      $$ExchangeRatesTableAnnotationComposer,
      $$ExchangeRatesTableCreateCompanionBuilder,
      $$ExchangeRatesTableUpdateCompanionBuilder,
      (ExchangeRate, $$ExchangeRatesTableReferences),
      ExchangeRate,
      PrefetchHooks Function({bool fromCurrencyCode, bool toCurrencyCode})
    >;
typedef $$InflationRatesTableCreateCompanionBuilder =
    InflationRatesCompanion Function({
      required DateTime date,
      required double percent,
      Value<String> country,
      required int preset,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<String?> sourceId,
      Value<int> rowid,
    });
typedef $$InflationRatesTableUpdateCompanionBuilder =
    InflationRatesCompanion Function({
      Value<DateTime> date,
      Value<double> percent,
      Value<String> country,
      Value<int> preset,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<String?> sourceId,
      Value<int> rowid,
    });

class $$InflationRatesTableFilterComposer
    extends Composer<_$AppDatabase, $InflationRatesTable> {
  $$InflationRatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get preset => $composableBuilder(
    column: $table.preset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$InflationRatesTableOrderingComposer
    extends Composer<_$AppDatabase, $InflationRatesTable> {
  $$InflationRatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get percent => $composableBuilder(
    column: $table.percent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get country => $composableBuilder(
    column: $table.country,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preset => $composableBuilder(
    column: $table.preset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InflationRatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InflationRatesTable> {
  $$InflationRatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get percent =>
      $composableBuilder(column: $table.percent, builder: (column) => column);

  GeneratedColumn<String> get country =>
      $composableBuilder(column: $table.country, builder: (column) => column);

  GeneratedColumn<int> get preset =>
      $composableBuilder(column: $table.preset, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);
}

class $$InflationRatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InflationRatesTable,
          InflationRate,
          $$InflationRatesTableFilterComposer,
          $$InflationRatesTableOrderingComposer,
          $$InflationRatesTableAnnotationComposer,
          $$InflationRatesTableCreateCompanionBuilder,
          $$InflationRatesTableUpdateCompanionBuilder,
          (
            InflationRate,
            BaseReferences<_$AppDatabase, $InflationRatesTable, InflationRate>,
          ),
          InflationRate,
          PrefetchHooks Function()
        > {
  $$InflationRatesTableTableManager(
    _$AppDatabase db,
    $InflationRatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InflationRatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InflationRatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InflationRatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> date = const Value.absent(),
                Value<double> percent = const Value.absent(),
                Value<String> country = const Value.absent(),
                Value<int> preset = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InflationRatesCompanion(
                date: date,
                percent: percent,
                country: country,
                preset: preset,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                sourceId: sourceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime date,
                required double percent,
                Value<String> country = const Value.absent(),
                required int preset,
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InflationRatesCompanion.insert(
                date: date,
                percent: percent,
                country: country,
                preset: preset,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                sourceId: sourceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$InflationRatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InflationRatesTable,
      InflationRate,
      $$InflationRatesTableFilterComposer,
      $$InflationRatesTableOrderingComposer,
      $$InflationRatesTableAnnotationComposer,
      $$InflationRatesTableCreateCompanionBuilder,
      $$InflationRatesTableUpdateCompanionBuilder,
      (
        InflationRate,
        BaseReferences<_$AppDatabase, $InflationRatesTable, InflationRate>,
      ),
      InflationRate,
      PrefetchHooks Function()
    >;
typedef $$AssetEntriesTableCreateCompanionBuilder =
    AssetEntriesCompanion Function({
      Value<String> id,
      required String assetId,
      required String name,
      required DateTime date,
      required double value,
      Value<double> quantity,
      Value<String?> assetType,
      Value<String?> description,
      required String currencyCode,
      Value<String?> accountId,
      required String source,
      Value<int> preset,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<String?> sourceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$AssetEntriesTableUpdateCompanionBuilder =
    AssetEntriesCompanion Function({
      Value<String> id,
      Value<String> assetId,
      Value<String> name,
      Value<DateTime> date,
      Value<double> value,
      Value<double> quantity,
      Value<String?> assetType,
      Value<String?> description,
      Value<String> currencyCode,
      Value<String?> accountId,
      Value<String> source,
      Value<int> preset,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<String?> sourceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

final class $$AssetEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $AssetEntriesTable, AssetEntry> {
  $$AssetEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CurrenciesTable _currencyCodeTable(_$AppDatabase db) =>
      db.currencies.createAlias(
        $_aliasNameGenerator(db.assetEntries.currencyCode, db.currencies.code),
      );

  $$CurrenciesTableProcessedTableManager get currencyCode {
    final $_column = $_itemColumn<String>('currency_code')!;

    final manager = $$CurrenciesTableTableManager(
      $_db,
      $_db.currencies,
    ).filter((f) => f.code.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_currencyCodeTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias(
        $_aliasNameGenerator(db.assetEntries.accountId, db.accounts.id),
      );

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $AssetEntriesTable> {
  $$AssetEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get assetType => $composableBuilder(
    column: $table.assetType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get preset => $composableBuilder(
    column: $table.preset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  $$CurrenciesTableFilterComposer get currencyCode {
    final $$CurrenciesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableFilterComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetEntriesTable> {
  $$AssetEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetId => $composableBuilder(
    column: $table.assetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get assetType => $composableBuilder(
    column: $table.assetType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preset => $composableBuilder(
    column: $table.preset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceId => $composableBuilder(
    column: $table.sourceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  $$CurrenciesTableOrderingComposer get currencyCode {
    final $$CurrenciesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableOrderingComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetEntriesTable> {
  $$AssetEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get assetId =>
      $composableBuilder(column: $table.assetId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get assetType =>
      $composableBuilder(column: $table.assetType, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<int> get preset =>
      $composableBuilder(column: $table.preset, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get sourceId =>
      $composableBuilder(column: $table.sourceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  $$CurrenciesTableAnnotationComposer get currencyCode {
    final $$CurrenciesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.currencyCode,
      referencedTable: $db.currencies,
      getReferencedColumn: (t) => t.code,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CurrenciesTableAnnotationComposer(
            $db: $db,
            $table: $db.currencies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetEntriesTable,
          AssetEntry,
          $$AssetEntriesTableFilterComposer,
          $$AssetEntriesTableOrderingComposer,
          $$AssetEntriesTableAnnotationComposer,
          $$AssetEntriesTableCreateCompanionBuilder,
          $$AssetEntriesTableUpdateCompanionBuilder,
          (AssetEntry, $$AssetEntriesTableReferences),
          AssetEntry,
          PrefetchHooks Function({bool currencyCode, bool accountId})
        > {
  $$AssetEntriesTableTableManager(_$AppDatabase db, $AssetEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> assetId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<String?> assetType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<int> preset = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetEntriesCompanion(
                id: id,
                assetId: assetId,
                name: name,
                date: date,
                value: value,
                quantity: quantity,
                assetType: assetType,
                description: description,
                currencyCode: currencyCode,
                accountId: accountId,
                source: source,
                preset: preset,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                sourceId: sourceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String assetId,
                required String name,
                required DateTime date,
                required double value,
                Value<double> quantity = const Value.absent(),
                Value<String?> assetType = const Value.absent(),
                Value<String?> description = const Value.absent(),
                required String currencyCode,
                Value<String?> accountId = const Value.absent(),
                required String source,
                Value<int> preset = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<String?> sourceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetEntriesCompanion.insert(
                id: id,
                assetId: assetId,
                name: name,
                date: date,
                value: value,
                quantity: quantity,
                assetType: assetType,
                description: description,
                currencyCode: currencyCode,
                accountId: accountId,
                source: source,
                preset: preset,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                sourceId: sourceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssetEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({currencyCode = false, accountId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (currencyCode) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.currencyCode,
                                referencedTable: $$AssetEntriesTableReferences
                                    ._currencyCodeTable(db),
                                referencedColumn: $$AssetEntriesTableReferences
                                    ._currencyCodeTable(db)
                                    .code,
                              )
                              as T;
                    }
                    if (accountId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.accountId,
                                referencedTable: $$AssetEntriesTableReferences
                                    ._accountIdTable(db),
                                referencedColumn: $$AssetEntriesTableReferences
                                    ._accountIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssetEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetEntriesTable,
      AssetEntry,
      $$AssetEntriesTableFilterComposer,
      $$AssetEntriesTableOrderingComposer,
      $$AssetEntriesTableAnnotationComposer,
      $$AssetEntriesTableCreateCompanionBuilder,
      $$AssetEntriesTableUpdateCompanionBuilder,
      (AssetEntry, $$AssetEntriesTableReferences),
      AssetEntry,
      PrefetchHooks Function({bool currencyCode, bool accountId})
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<String?> device,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<String?> device,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get device => $composableBuilder(
    column: $table.device,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get device => $composableBuilder(
    column: $table.device,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get device =>
      $composableBuilder(column: $table.device, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<String?> device = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                device: device,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<String?> device = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                device: device,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$CustomThemesTableCreateCompanionBuilder =
    CustomThemesCompanion Function({
      Value<String> id,
      required String name,
      required String primaryColorHex,
      required String secondaryColorHex,
      required String surfaceColorHex,
      required String backgroundColorHex,
      Value<String?> backgroundImagePath,
      Value<double> backgroundImageOpacity,
      Value<double> backgroundImageBlur,
      required int windowEffectType,
      Value<double> effectOpacity,
      Value<double> surfaceOpacity,
      required int themeMode,
      Value<bool> isPreset,
      Value<bool> isActive,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$CustomThemesTableUpdateCompanionBuilder =
    CustomThemesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> primaryColorHex,
      Value<String> secondaryColorHex,
      Value<String> surfaceColorHex,
      Value<String> backgroundColorHex,
      Value<String?> backgroundImagePath,
      Value<double> backgroundImageOpacity,
      Value<double> backgroundImageBlur,
      Value<int> windowEffectType,
      Value<double> effectOpacity,
      Value<double> surfaceOpacity,
      Value<int> themeMode,
      Value<bool> isPreset,
      Value<bool> isActive,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$CustomThemesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomThemesTable> {
  $$CustomThemesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get primaryColorHex => $composableBuilder(
    column: $table.primaryColorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secondaryColorHex => $composableBuilder(
    column: $table.secondaryColorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get surfaceColorHex => $composableBuilder(
    column: $table.surfaceColorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundColorHex => $composableBuilder(
    column: $table.backgroundColorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backgroundImagePath => $composableBuilder(
    column: $table.backgroundImagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get backgroundImageOpacity => $composableBuilder(
    column: $table.backgroundImageOpacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get backgroundImageBlur => $composableBuilder(
    column: $table.backgroundImageBlur,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get windowEffectType => $composableBuilder(
    column: $table.windowEffectType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get effectOpacity => $composableBuilder(
    column: $table.effectOpacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get surfaceOpacity => $composableBuilder(
    column: $table.surfaceOpacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPreset => $composableBuilder(
    column: $table.isPreset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomThemesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomThemesTable> {
  $$CustomThemesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get primaryColorHex => $composableBuilder(
    column: $table.primaryColorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secondaryColorHex => $composableBuilder(
    column: $table.secondaryColorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get surfaceColorHex => $composableBuilder(
    column: $table.surfaceColorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundColorHex => $composableBuilder(
    column: $table.backgroundColorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backgroundImagePath => $composableBuilder(
    column: $table.backgroundImagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get backgroundImageOpacity => $composableBuilder(
    column: $table.backgroundImageOpacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get backgroundImageBlur => $composableBuilder(
    column: $table.backgroundImageBlur,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get windowEffectType => $composableBuilder(
    column: $table.windowEffectType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get effectOpacity => $composableBuilder(
    column: $table.effectOpacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get surfaceOpacity => $composableBuilder(
    column: $table.surfaceOpacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get themeMode => $composableBuilder(
    column: $table.themeMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPreset => $composableBuilder(
    column: $table.isPreset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomThemesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomThemesTable> {
  $$CustomThemesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get primaryColorHex => $composableBuilder(
    column: $table.primaryColorHex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secondaryColorHex => $composableBuilder(
    column: $table.secondaryColorHex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get surfaceColorHex => $composableBuilder(
    column: $table.surfaceColorHex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backgroundColorHex => $composableBuilder(
    column: $table.backgroundColorHex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backgroundImagePath => $composableBuilder(
    column: $table.backgroundImagePath,
    builder: (column) => column,
  );

  GeneratedColumn<double> get backgroundImageOpacity => $composableBuilder(
    column: $table.backgroundImageOpacity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get backgroundImageBlur => $composableBuilder(
    column: $table.backgroundImageBlur,
    builder: (column) => column,
  );

  GeneratedColumn<int> get windowEffectType => $composableBuilder(
    column: $table.windowEffectType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get effectOpacity => $composableBuilder(
    column: $table.effectOpacity,
    builder: (column) => column,
  );

  GeneratedColumn<double> get surfaceOpacity => $composableBuilder(
    column: $table.surfaceOpacity,
    builder: (column) => column,
  );

  GeneratedColumn<int> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<bool> get isPreset =>
      $composableBuilder(column: $table.isPreset, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$CustomThemesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomThemesTable,
          DbCustomTheme,
          $$CustomThemesTableFilterComposer,
          $$CustomThemesTableOrderingComposer,
          $$CustomThemesTableAnnotationComposer,
          $$CustomThemesTableCreateCompanionBuilder,
          $$CustomThemesTableUpdateCompanionBuilder,
          (
            DbCustomTheme,
            BaseReferences<_$AppDatabase, $CustomThemesTable, DbCustomTheme>,
          ),
          DbCustomTheme,
          PrefetchHooks Function()
        > {
  $$CustomThemesTableTableManager(_$AppDatabase db, $CustomThemesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomThemesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomThemesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomThemesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> primaryColorHex = const Value.absent(),
                Value<String> secondaryColorHex = const Value.absent(),
                Value<String> surfaceColorHex = const Value.absent(),
                Value<String> backgroundColorHex = const Value.absent(),
                Value<String?> backgroundImagePath = const Value.absent(),
                Value<double> backgroundImageOpacity = const Value.absent(),
                Value<double> backgroundImageBlur = const Value.absent(),
                Value<int> windowEffectType = const Value.absent(),
                Value<double> effectOpacity = const Value.absent(),
                Value<double> surfaceOpacity = const Value.absent(),
                Value<int> themeMode = const Value.absent(),
                Value<bool> isPreset = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomThemesCompanion(
                id: id,
                name: name,
                primaryColorHex: primaryColorHex,
                secondaryColorHex: secondaryColorHex,
                surfaceColorHex: surfaceColorHex,
                backgroundColorHex: backgroundColorHex,
                backgroundImagePath: backgroundImagePath,
                backgroundImageOpacity: backgroundImageOpacity,
                backgroundImageBlur: backgroundImageBlur,
                windowEffectType: windowEffectType,
                effectOpacity: effectOpacity,
                surfaceOpacity: surfaceOpacity,
                themeMode: themeMode,
                isPreset: isPreset,
                isActive: isActive,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String primaryColorHex,
                required String secondaryColorHex,
                required String surfaceColorHex,
                required String backgroundColorHex,
                Value<String?> backgroundImagePath = const Value.absent(),
                Value<double> backgroundImageOpacity = const Value.absent(),
                Value<double> backgroundImageBlur = const Value.absent(),
                required int windowEffectType,
                Value<double> effectOpacity = const Value.absent(),
                Value<double> surfaceOpacity = const Value.absent(),
                required int themeMode,
                Value<bool> isPreset = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomThemesCompanion.insert(
                id: id,
                name: name,
                primaryColorHex: primaryColorHex,
                secondaryColorHex: secondaryColorHex,
                surfaceColorHex: surfaceColorHex,
                backgroundColorHex: backgroundColorHex,
                backgroundImagePath: backgroundImagePath,
                backgroundImageOpacity: backgroundImageOpacity,
                backgroundImageBlur: backgroundImageBlur,
                windowEffectType: windowEffectType,
                effectOpacity: effectOpacity,
                surfaceOpacity: surfaceOpacity,
                themeMode: themeMode,
                isPreset: isPreset,
                isActive: isActive,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomThemesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomThemesTable,
      DbCustomTheme,
      $$CustomThemesTableFilterComposer,
      $$CustomThemesTableOrderingComposer,
      $$CustomThemesTableAnnotationComposer,
      $$CustomThemesTableCreateCompanionBuilder,
      $$CustomThemesTableUpdateCompanionBuilder,
      (
        DbCustomTheme,
        BaseReferences<_$AppDatabase, $CustomThemesTable, DbCustomTheme>,
      ),
      DbCustomTheme,
      PrefetchHooks Function()
    >;
typedef $$ApiFetchStatusesTableCreateCompanionBuilder =
    ApiFetchStatusesCompanion Function({
      required String id,
      Value<int> attempts,
      Value<DateTime?> lastAttempt,
      Value<String> status,
      Value<int> rowid,
    });
typedef $$ApiFetchStatusesTableUpdateCompanionBuilder =
    ApiFetchStatusesCompanion Function({
      Value<String> id,
      Value<int> attempts,
      Value<DateTime?> lastAttempt,
      Value<String> status,
      Value<int> rowid,
    });

class $$ApiFetchStatusesTableFilterComposer
    extends Composer<_$AppDatabase, $ApiFetchStatusesTable> {
  $$ApiFetchStatusesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiFetchStatusesTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiFetchStatusesTable> {
  $$ApiFetchStatusesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiFetchStatusesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiFetchStatusesTable> {
  $$ApiFetchStatusesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAttempt => $composableBuilder(
    column: $table.lastAttempt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$ApiFetchStatusesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiFetchStatusesTable,
          ApiFetchStatus,
          $$ApiFetchStatusesTableFilterComposer,
          $$ApiFetchStatusesTableOrderingComposer,
          $$ApiFetchStatusesTableAnnotationComposer,
          $$ApiFetchStatusesTableCreateCompanionBuilder,
          $$ApiFetchStatusesTableUpdateCompanionBuilder,
          (
            ApiFetchStatus,
            BaseReferences<
              _$AppDatabase,
              $ApiFetchStatusesTable,
              ApiFetchStatus
            >,
          ),
          ApiFetchStatus,
          PrefetchHooks Function()
        > {
  $$ApiFetchStatusesTableTableManager(
    _$AppDatabase db,
    $ApiFetchStatusesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiFetchStatusesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiFetchStatusesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiFetchStatusesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttempt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiFetchStatusesCompanion(
                id: id,
                attempts: attempts,
                lastAttempt: lastAttempt,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<int> attempts = const Value.absent(),
                Value<DateTime?> lastAttempt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiFetchStatusesCompanion.insert(
                id: id,
                attempts: attempts,
                lastAttempt: lastAttempt,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiFetchStatusesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiFetchStatusesTable,
      ApiFetchStatus,
      $$ApiFetchStatusesTableFilterComposer,
      $$ApiFetchStatusesTableOrderingComposer,
      $$ApiFetchStatusesTableAnnotationComposer,
      $$ApiFetchStatusesTableCreateCompanionBuilder,
      $$ApiFetchStatusesTableUpdateCompanionBuilder,
      (
        ApiFetchStatus,
        BaseReferences<_$AppDatabase, $ApiFetchStatusesTable, ApiFetchStatus>,
      ),
      ApiFetchStatus,
      PrefetchHooks Function()
    >;
typedef $$ApiSettingsTableTableCreateCompanionBuilder =
    ApiSettingsTableCompanion Function({
      required String id,
      Value<bool> enabled,
      Value<bool> autoFetch,
      Value<int?> lastFetchAt,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$ApiSettingsTableTableUpdateCompanionBuilder =
    ApiSettingsTableCompanion Function({
      Value<String> id,
      Value<bool> enabled,
      Value<bool> autoFetch,
      Value<int?> lastFetchAt,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$ApiSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ApiSettingsTableTable> {
  $$ApiSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoFetch => $composableBuilder(
    column: $table.autoFetch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiSettingsTableTable> {
  $$ApiSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoFetch => $composableBuilder(
    column: $table.autoFetch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiSettingsTableTable> {
  $$ApiSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get autoFetch =>
      $composableBuilder(column: $table.autoFetch, builder: (column) => column);

  GeneratedColumn<int> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$ApiSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiSettingsTableTable,
          ApiSettingsTableData,
          $$ApiSettingsTableTableFilterComposer,
          $$ApiSettingsTableTableOrderingComposer,
          $$ApiSettingsTableTableAnnotationComposer,
          $$ApiSettingsTableTableCreateCompanionBuilder,
          $$ApiSettingsTableTableUpdateCompanionBuilder,
          (
            ApiSettingsTableData,
            BaseReferences<
              _$AppDatabase,
              $ApiSettingsTableTable,
              ApiSettingsTableData
            >,
          ),
          ApiSettingsTableData,
          PrefetchHooks Function()
        > {
  $$ApiSettingsTableTableTableManager(
    _$AppDatabase db,
    $ApiSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiSettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiSettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> autoFetch = const Value.absent(),
                Value<int?> lastFetchAt = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiSettingsTableCompanion(
                id: id,
                enabled: enabled,
                autoFetch: autoFetch,
                lastFetchAt: lastFetchAt,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<bool> enabled = const Value.absent(),
                Value<bool> autoFetch = const Value.absent(),
                Value<int?> lastFetchAt = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiSettingsTableCompanion.insert(
                id: id,
                enabled: enabled,
                autoFetch: autoFetch,
                lastFetchAt: lastFetchAt,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiSettingsTableTable,
      ApiSettingsTableData,
      $$ApiSettingsTableTableFilterComposer,
      $$ApiSettingsTableTableOrderingComposer,
      $$ApiSettingsTableTableAnnotationComposer,
      $$ApiSettingsTableTableCreateCompanionBuilder,
      $$ApiSettingsTableTableUpdateCompanionBuilder,
      (
        ApiSettingsTableData,
        BaseReferences<
          _$AppDatabase,
          $ApiSettingsTableTable,
          ApiSettingsTableData
        >,
      ),
      ApiSettingsTableData,
      PrefetchHooks Function()
    >;
typedef $$SmsPresetsTableCreateCompanionBuilder =
    SmsPresetsCompanion Function({
      Value<String> id,
      required String name,
      required String senderFilter,
      Value<bool> isBuiltIn,
      Value<bool> isEnabled,
      Value<String?> defaultAccountId,
      Value<String?> defaultCategoryId,
      required String rulesJson,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$SmsPresetsTableUpdateCompanionBuilder =
    SmsPresetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> senderFilter,
      Value<bool> isBuiltIn,
      Value<bool> isEnabled,
      Value<String?> defaultAccountId,
      Value<String?> defaultCategoryId,
      Value<String> rulesJson,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$SmsPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $SmsPresetsTable> {
  $$SmsPresetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderFilter => $composableBuilder(
    column: $table.senderFilter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultAccountId => $composableBuilder(
    column: $table.defaultAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultCategoryId => $composableBuilder(
    column: $table.defaultCategoryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rulesJson => $composableBuilder(
    column: $table.rulesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SmsPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $SmsPresetsTable> {
  $$SmsPresetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderFilter => $composableBuilder(
    column: $table.senderFilter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isBuiltIn => $composableBuilder(
    column: $table.isBuiltIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEnabled => $composableBuilder(
    column: $table.isEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultAccountId => $composableBuilder(
    column: $table.defaultAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultCategoryId => $composableBuilder(
    column: $table.defaultCategoryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rulesJson => $composableBuilder(
    column: $table.rulesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SmsPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SmsPresetsTable> {
  $$SmsPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get senderFilter => $composableBuilder(
    column: $table.senderFilter,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isBuiltIn =>
      $composableBuilder(column: $table.isBuiltIn, builder: (column) => column);

  GeneratedColumn<bool> get isEnabled =>
      $composableBuilder(column: $table.isEnabled, builder: (column) => column);

  GeneratedColumn<String> get defaultAccountId => $composableBuilder(
    column: $table.defaultAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultCategoryId => $composableBuilder(
    column: $table.defaultCategoryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rulesJson =>
      $composableBuilder(column: $table.rulesJson, builder: (column) => column);

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$SmsPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SmsPresetsTable,
          SmsPreset,
          $$SmsPresetsTableFilterComposer,
          $$SmsPresetsTableOrderingComposer,
          $$SmsPresetsTableAnnotationComposer,
          $$SmsPresetsTableCreateCompanionBuilder,
          $$SmsPresetsTableUpdateCompanionBuilder,
          (
            SmsPreset,
            BaseReferences<_$AppDatabase, $SmsPresetsTable, SmsPreset>,
          ),
          SmsPreset,
          PrefetchHooks Function()
        > {
  $$SmsPresetsTableTableManager(_$AppDatabase db, $SmsPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SmsPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SmsPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SmsPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> senderFilter = const Value.absent(),
                Value<bool> isBuiltIn = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String?> defaultAccountId = const Value.absent(),
                Value<String?> defaultCategoryId = const Value.absent(),
                Value<String> rulesJson = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsPresetsCompanion(
                id: id,
                name: name,
                senderFilter: senderFilter,
                isBuiltIn: isBuiltIn,
                isEnabled: isEnabled,
                defaultAccountId: defaultAccountId,
                defaultCategoryId: defaultCategoryId,
                rulesJson: rulesJson,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String senderFilter,
                Value<bool> isBuiltIn = const Value.absent(),
                Value<bool> isEnabled = const Value.absent(),
                Value<String?> defaultAccountId = const Value.absent(),
                Value<String?> defaultCategoryId = const Value.absent(),
                required String rulesJson,
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SmsPresetsCompanion.insert(
                id: id,
                name: name,
                senderFilter: senderFilter,
                isBuiltIn: isBuiltIn,
                isEnabled: isEnabled,
                defaultAccountId: defaultAccountId,
                defaultCategoryId: defaultCategoryId,
                rulesJson: rulesJson,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SmsPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SmsPresetsTable,
      SmsPreset,
      $$SmsPresetsTableFilterComposer,
      $$SmsPresetsTableOrderingComposer,
      $$SmsPresetsTableAnnotationComposer,
      $$SmsPresetsTableCreateCompanionBuilder,
      $$SmsPresetsTableUpdateCompanionBuilder,
      (SmsPreset, BaseReferences<_$AppDatabase, $SmsPresetsTable, SmsPreset>),
      SmsPreset,
      PrefetchHooks Function()
    >;
typedef $$SyncProcessedFilesTableCreateCompanionBuilder =
    SyncProcessedFilesCompanion Function({
      required String fileName,
      required int processedAt,
      required String deviceId,
      Value<int> rowid,
    });
typedef $$SyncProcessedFilesTableUpdateCompanionBuilder =
    SyncProcessedFilesCompanion Function({
      Value<String> fileName,
      Value<int> processedAt,
      Value<String> deviceId,
      Value<int> rowid,
    });

class $$SyncProcessedFilesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncProcessedFilesTable> {
  $$SyncProcessedFilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncProcessedFilesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncProcessedFilesTable> {
  $$SyncProcessedFilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncProcessedFilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncProcessedFilesTable> {
  $$SyncProcessedFilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get processedAt => $composableBuilder(
    column: $table.processedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);
}

class $$SyncProcessedFilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncProcessedFilesTable,
          SyncProcessedFile,
          $$SyncProcessedFilesTableFilterComposer,
          $$SyncProcessedFilesTableOrderingComposer,
          $$SyncProcessedFilesTableAnnotationComposer,
          $$SyncProcessedFilesTableCreateCompanionBuilder,
          $$SyncProcessedFilesTableUpdateCompanionBuilder,
          (
            SyncProcessedFile,
            BaseReferences<
              _$AppDatabase,
              $SyncProcessedFilesTable,
              SyncProcessedFile
            >,
          ),
          SyncProcessedFile,
          PrefetchHooks Function()
        > {
  $$SyncProcessedFilesTableTableManager(
    _$AppDatabase db,
    $SyncProcessedFilesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncProcessedFilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncProcessedFilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncProcessedFilesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> fileName = const Value.absent(),
                Value<int> processedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncProcessedFilesCompanion(
                fileName: fileName,
                processedAt: processedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fileName,
                required int processedAt,
                required String deviceId,
                Value<int> rowid = const Value.absent(),
              }) => SyncProcessedFilesCompanion.insert(
                fileName: fileName,
                processedAt: processedAt,
                deviceId: deviceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncProcessedFilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncProcessedFilesTable,
      SyncProcessedFile,
      $$SyncProcessedFilesTableFilterComposer,
      $$SyncProcessedFilesTableOrderingComposer,
      $$SyncProcessedFilesTableAnnotationComposer,
      $$SyncProcessedFilesTableCreateCompanionBuilder,
      $$SyncProcessedFilesTableUpdateCompanionBuilder,
      (
        SyncProcessedFile,
        BaseReferences<
          _$AppDatabase,
          $SyncProcessedFilesTable,
          SyncProcessedFile
        >,
      ),
      SyncProcessedFile,
      PrefetchHooks Function()
    >;
typedef $$SyncLogTableCreateCompanionBuilder =
    SyncLogCompanion Function({
      Value<int> id,
      required String changedTableName,
      required String recordId,
      required String action,
      required int timestamp,
      Value<bool> exported,
    });
typedef $$SyncLogTableUpdateCompanionBuilder =
    SyncLogCompanion Function({
      Value<int> id,
      Value<String> changedTableName,
      Value<String> recordId,
      Value<String> action,
      Value<int> timestamp,
      Value<bool> exported,
    });

class $$SyncLogTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedTableName => $composableBuilder(
    column: $table.changedTableName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get exported => $composableBuilder(
    column: $table.exported,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncLogTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedTableName => $composableBuilder(
    column: $table.changedTableName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get exported => $composableBuilder(
    column: $table.exported,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get changedTableName => $composableBuilder(
    column: $table.changedTableName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<int> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<bool> get exported =>
      $composableBuilder(column: $table.exported, builder: (column) => column);
}

class $$SyncLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncLogTable,
          SyncLogData,
          $$SyncLogTableFilterComposer,
          $$SyncLogTableOrderingComposer,
          $$SyncLogTableAnnotationComposer,
          $$SyncLogTableCreateCompanionBuilder,
          $$SyncLogTableUpdateCompanionBuilder,
          (
            SyncLogData,
            BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogData>,
          ),
          SyncLogData,
          PrefetchHooks Function()
        > {
  $$SyncLogTableTableManager(_$AppDatabase db, $SyncLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> changedTableName = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<int> timestamp = const Value.absent(),
                Value<bool> exported = const Value.absent(),
              }) => SyncLogCompanion(
                id: id,
                changedTableName: changedTableName,
                recordId: recordId,
                action: action,
                timestamp: timestamp,
                exported: exported,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String changedTableName,
                required String recordId,
                required String action,
                required int timestamp,
                Value<bool> exported = const Value.absent(),
              }) => SyncLogCompanion.insert(
                id: id,
                changedTableName: changedTableName,
                recordId: recordId,
                action: action,
                timestamp: timestamp,
                exported: exported,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncLogTable,
      SyncLogData,
      $$SyncLogTableFilterComposer,
      $$SyncLogTableOrderingComposer,
      $$SyncLogTableAnnotationComposer,
      $$SyncLogTableCreateCompanionBuilder,
      $$SyncLogTableUpdateCompanionBuilder,
      (SyncLogData, BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogData>),
      SyncLogData,
      PrefetchHooks Function()
    >;
typedef $$SyncPushQueueTableCreateCompanionBuilder =
    SyncPushQueueCompanion Function({
      Value<int> id,
      required String changedTableName,
      required String recordKey,
    });
typedef $$SyncPushQueueTableUpdateCompanionBuilder =
    SyncPushQueueCompanion Function({
      Value<int> id,
      Value<String> changedTableName,
      Value<String> recordKey,
    });

class $$SyncPushQueueTableFilterComposer
    extends Composer<_$AppDatabase, $SyncPushQueueTable> {
  $$SyncPushQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedTableName => $composableBuilder(
    column: $table.changedTableName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordKey => $composableBuilder(
    column: $table.recordKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncPushQueueTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncPushQueueTable> {
  $$SyncPushQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedTableName => $composableBuilder(
    column: $table.changedTableName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordKey => $composableBuilder(
    column: $table.recordKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncPushQueueTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncPushQueueTable> {
  $$SyncPushQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get changedTableName => $composableBuilder(
    column: $table.changedTableName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordKey =>
      $composableBuilder(column: $table.recordKey, builder: (column) => column);
}

class $$SyncPushQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncPushQueueTable,
          SyncPushQueueData,
          $$SyncPushQueueTableFilterComposer,
          $$SyncPushQueueTableOrderingComposer,
          $$SyncPushQueueTableAnnotationComposer,
          $$SyncPushQueueTableCreateCompanionBuilder,
          $$SyncPushQueueTableUpdateCompanionBuilder,
          (
            SyncPushQueueData,
            BaseReferences<
              _$AppDatabase,
              $SyncPushQueueTable,
              SyncPushQueueData
            >,
          ),
          SyncPushQueueData,
          PrefetchHooks Function()
        > {
  $$SyncPushQueueTableTableManager(_$AppDatabase db, $SyncPushQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPushQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPushQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncPushQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> changedTableName = const Value.absent(),
                Value<String> recordKey = const Value.absent(),
              }) => SyncPushQueueCompanion(
                id: id,
                changedTableName: changedTableName,
                recordKey: recordKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String changedTableName,
                required String recordKey,
              }) => SyncPushQueueCompanion.insert(
                id: id,
                changedTableName: changedTableName,
                recordKey: recordKey,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncPushQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncPushQueueTable,
      SyncPushQueueData,
      $$SyncPushQueueTableFilterComposer,
      $$SyncPushQueueTableOrderingComposer,
      $$SyncPushQueueTableAnnotationComposer,
      $$SyncPushQueueTableCreateCompanionBuilder,
      $$SyncPushQueueTableUpdateCompanionBuilder,
      (
        SyncPushQueueData,
        BaseReferences<_$AppDatabase, $SyncPushQueueTable, SyncPushQueueData>,
      ),
      SyncPushQueueData,
      PrefetchHooks Function()
    >;
typedef $$ConflictHistoryTableCreateCompanionBuilder =
    ConflictHistoryCompanion Function({
      Value<String> id,
      required String changedTableName,
      required String recordId,
      required String rejectedData,
      required int rejectedAt,
      Value<String?> rejectedDevice,
      Value<int> rowid,
    });
typedef $$ConflictHistoryTableUpdateCompanionBuilder =
    ConflictHistoryCompanion Function({
      Value<String> id,
      Value<String> changedTableName,
      Value<String> recordId,
      Value<String> rejectedData,
      Value<int> rejectedAt,
      Value<String?> rejectedDevice,
      Value<int> rowid,
    });

class $$ConflictHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $ConflictHistoryTable> {
  $$ConflictHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get changedTableName => $composableBuilder(
    column: $table.changedTableName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectedData => $composableBuilder(
    column: $table.rejectedData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rejectedDevice => $composableBuilder(
    column: $table.rejectedDevice,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ConflictHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $ConflictHistoryTable> {
  $$ConflictHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get changedTableName => $composableBuilder(
    column: $table.changedTableName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectedData => $composableBuilder(
    column: $table.rejectedData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rejectedDevice => $composableBuilder(
    column: $table.rejectedDevice,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConflictHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConflictHistoryTable> {
  $$ConflictHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get changedTableName => $composableBuilder(
    column: $table.changedTableName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get rejectedData => $composableBuilder(
    column: $table.rejectedData,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rejectedAt => $composableBuilder(
    column: $table.rejectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rejectedDevice => $composableBuilder(
    column: $table.rejectedDevice,
    builder: (column) => column,
  );
}

class $$ConflictHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConflictHistoryTable,
          ConflictHistoryData,
          $$ConflictHistoryTableFilterComposer,
          $$ConflictHistoryTableOrderingComposer,
          $$ConflictHistoryTableAnnotationComposer,
          $$ConflictHistoryTableCreateCompanionBuilder,
          $$ConflictHistoryTableUpdateCompanionBuilder,
          (
            ConflictHistoryData,
            BaseReferences<
              _$AppDatabase,
              $ConflictHistoryTable,
              ConflictHistoryData
            >,
          ),
          ConflictHistoryData,
          PrefetchHooks Function()
        > {
  $$ConflictHistoryTableTableManager(
    _$AppDatabase db,
    $ConflictHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConflictHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConflictHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConflictHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> changedTableName = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> rejectedData = const Value.absent(),
                Value<int> rejectedAt = const Value.absent(),
                Value<String?> rejectedDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictHistoryCompanion(
                id: id,
                changedTableName: changedTableName,
                recordId: recordId,
                rejectedData: rejectedData,
                rejectedAt: rejectedAt,
                rejectedDevice: rejectedDevice,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String changedTableName,
                required String recordId,
                required String rejectedData,
                required int rejectedAt,
                Value<String?> rejectedDevice = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConflictHistoryCompanion.insert(
                id: id,
                changedTableName: changedTableName,
                recordId: recordId,
                rejectedData: rejectedData,
                rejectedAt: rejectedAt,
                rejectedDevice: rejectedDevice,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ConflictHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConflictHistoryTable,
      ConflictHistoryData,
      $$ConflictHistoryTableFilterComposer,
      $$ConflictHistoryTableOrderingComposer,
      $$ConflictHistoryTableAnnotationComposer,
      $$ConflictHistoryTableCreateCompanionBuilder,
      $$ConflictHistoryTableUpdateCompanionBuilder,
      (
        ConflictHistoryData,
        BaseReferences<
          _$AppDatabase,
          $ConflictHistoryTable,
          ConflictHistoryData
        >,
      ),
      ConflictHistoryData,
      PrefetchHooks Function()
    >;
typedef $$CustomDataSourcesTableCreateCompanionBuilder =
    CustomDataSourcesCompanion Function({
      Value<String> id,
      required String name,
      required String url,
      required int dataType,
      Value<bool> enabled,
      Value<bool> autoFetch,
      Value<int?> lastFetchAt,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });
typedef $$CustomDataSourcesTableUpdateCompanionBuilder =
    CustomDataSourcesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> url,
      Value<int> dataType,
      Value<bool> enabled,
      Value<bool> autoFetch,
      Value<int?> lastFetchAt,
      Value<int> modifiedAt,
      Value<String?> deviceId,
      Value<bool> isDeleted,
      Value<int> rowid,
    });

class $$CustomDataSourcesTableFilterComposer
    extends Composer<_$AppDatabase, $CustomDataSourcesTable> {
  $$CustomDataSourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoFetch => $composableBuilder(
    column: $table.autoFetch,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CustomDataSourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $CustomDataSourcesTable> {
  $$CustomDataSourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dataType => $composableBuilder(
    column: $table.dataType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoFetch => $composableBuilder(
    column: $table.autoFetch,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CustomDataSourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CustomDataSourcesTable> {
  $$CustomDataSourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<int> get dataType =>
      $composableBuilder(column: $table.dataType, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<bool> get autoFetch =>
      $composableBuilder(column: $table.autoFetch, builder: (column) => column);

  GeneratedColumn<int> get lastFetchAt => $composableBuilder(
    column: $table.lastFetchAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get modifiedAt => $composableBuilder(
    column: $table.modifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);
}

class $$CustomDataSourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CustomDataSourcesTable,
          CustomDataSource,
          $$CustomDataSourcesTableFilterComposer,
          $$CustomDataSourcesTableOrderingComposer,
          $$CustomDataSourcesTableAnnotationComposer,
          $$CustomDataSourcesTableCreateCompanionBuilder,
          $$CustomDataSourcesTableUpdateCompanionBuilder,
          (
            CustomDataSource,
            BaseReferences<
              _$AppDatabase,
              $CustomDataSourcesTable,
              CustomDataSource
            >,
          ),
          CustomDataSource,
          PrefetchHooks Function()
        > {
  $$CustomDataSourcesTableTableManager(
    _$AppDatabase db,
    $CustomDataSourcesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CustomDataSourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CustomDataSourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CustomDataSourcesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> url = const Value.absent(),
                Value<int> dataType = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<bool> autoFetch = const Value.absent(),
                Value<int?> lastFetchAt = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomDataSourcesCompanion(
                id: id,
                name: name,
                url: url,
                dataType: dataType,
                enabled: enabled,
                autoFetch: autoFetch,
                lastFetchAt: lastFetchAt,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String url,
                required int dataType,
                Value<bool> enabled = const Value.absent(),
                Value<bool> autoFetch = const Value.absent(),
                Value<int?> lastFetchAt = const Value.absent(),
                Value<int> modifiedAt = const Value.absent(),
                Value<String?> deviceId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomDataSourcesCompanion.insert(
                id: id,
                name: name,
                url: url,
                dataType: dataType,
                enabled: enabled,
                autoFetch: autoFetch,
                lastFetchAt: lastFetchAt,
                modifiedAt: modifiedAt,
                deviceId: deviceId,
                isDeleted: isDeleted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CustomDataSourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CustomDataSourcesTable,
      CustomDataSource,
      $$CustomDataSourcesTableFilterComposer,
      $$CustomDataSourcesTableOrderingComposer,
      $$CustomDataSourcesTableAnnotationComposer,
      $$CustomDataSourcesTableCreateCompanionBuilder,
      $$CustomDataSourcesTableUpdateCompanionBuilder,
      (
        CustomDataSource,
        BaseReferences<
          _$AppDatabase,
          $CustomDataSourcesTable,
          CustomDataSource
        >,
      ),
      CustomDataSource,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LanguagesTableTableManager get languages =>
      $$LanguagesTableTableManager(_db, _db.languages);
  $$CurrenciesTableTableManager get currencies =>
      $$CurrenciesTableTableManager(_db, _db.currencies);
  $$CurrencyDesignationsTableTableManager get currencyDesignations =>
      $$CurrencyDesignationsTableTableManager(_db, _db.currencyDesignations);
  $$StylesTableTableManager get styles =>
      $$StylesTableTableManager(_db, _db.styles);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$AccountTypesTableTableManager get accountTypes =>
      $$AccountTypesTableTableManager(_db, _db.accountTypes);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$TransactionsTableTableManager get transactions =>
      $$TransactionsTableTableManager(_db, _db.transactions);
  $$ExchangeRatesTableTableManager get exchangeRates =>
      $$ExchangeRatesTableTableManager(_db, _db.exchangeRates);
  $$InflationRatesTableTableManager get inflationRates =>
      $$InflationRatesTableTableManager(_db, _db.inflationRates);
  $$AssetEntriesTableTableManager get assetEntries =>
      $$AssetEntriesTableTableManager(_db, _db.assetEntries);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$CustomThemesTableTableManager get customThemes =>
      $$CustomThemesTableTableManager(_db, _db.customThemes);
  $$ApiFetchStatusesTableTableManager get apiFetchStatuses =>
      $$ApiFetchStatusesTableTableManager(_db, _db.apiFetchStatuses);
  $$ApiSettingsTableTableTableManager get apiSettingsTable =>
      $$ApiSettingsTableTableTableManager(_db, _db.apiSettingsTable);
  $$SmsPresetsTableTableManager get smsPresets =>
      $$SmsPresetsTableTableManager(_db, _db.smsPresets);
  $$SyncProcessedFilesTableTableManager get syncProcessedFiles =>
      $$SyncProcessedFilesTableTableManager(_db, _db.syncProcessedFiles);
  $$SyncLogTableTableManager get syncLog =>
      $$SyncLogTableTableManager(_db, _db.syncLog);
  $$SyncPushQueueTableTableManager get syncPushQueue =>
      $$SyncPushQueueTableTableManager(_db, _db.syncPushQueue);
  $$ConflictHistoryTableTableManager get conflictHistory =>
      $$ConflictHistoryTableTableManager(_db, _db.conflictHistory);
  $$CustomDataSourcesTableTableManager get customDataSources =>
      $$CustomDataSourcesTableTableManager(_db, _db.customDataSources);
}

mixin _$ApiFetchStatusesDaoMixin on DatabaseAccessor<AppDatabase> {
  $ApiFetchStatusesTable get apiFetchStatuses =>
      attachedDatabase.apiFetchStatuses;
}
mixin _$SmsPresetsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SmsPresetsTable get smsPresets => attachedDatabase.smsPresets;
}
mixin _$SyncLogDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}
mixin _$ConflictHistoryDaoMixin on DatabaseAccessor<AppDatabase> {
  $ConflictHistoryTable get conflictHistory => attachedDatabase.conflictHistory;
}
mixin _$CustomDataSourcesDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomDataSourcesTable get customDataSources =>
      attachedDatabase.customDataSources;
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}
mixin _$ApiSettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ApiSettingsTableTable get apiSettingsTable =>
      attachedDatabase.apiSettingsTable;
  $SyncLogTable get syncLog => attachedDatabase.syncLog;
}
mixin _$SyncProcessedFilesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncProcessedFilesTable get syncProcessedFiles =>
      attachedDatabase.syncProcessedFiles;
}
