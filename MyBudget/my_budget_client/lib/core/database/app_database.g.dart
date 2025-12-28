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
}
mixin _$StylesDaoMixin on DatabaseAccessor<AppDatabase> {
  $StylesTable get styles => attachedDatabase.styles;
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
}
mixin _$SettingsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SettingsTable get settings => attachedDatabase.settings;
}
mixin _$ExchangeRatesDaoMixin on DatabaseAccessor<AppDatabase> {
  $LanguagesTable get languages => attachedDatabase.languages;
  $CurrenciesTable get currencies => attachedDatabase.currencies;
  $ExchangeRatesTable get exchangeRates => attachedDatabase.exchangeRates;
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
  @override
  List<GeneratedColumn> get $columns => [language, languageCode];
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
  const Language({required this.language, required this.languageCode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['language'] = Variable<String>(language);
    map['language_code'] = Variable<String>(languageCode);
    return map;
  }

  LanguagesCompanion toCompanion(bool nullToAbsent) {
    return LanguagesCompanion(
      language: Value(language),
      languageCode: Value(languageCode),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'language': serializer.toJson<String>(language),
      'languageCode': serializer.toJson<String>(languageCode),
    };
  }

  Language copyWith({String? language, String? languageCode}) => Language(
    language: language ?? this.language,
    languageCode: languageCode ?? this.languageCode,
  );
  Language copyWithCompanion(LanguagesCompanion data) {
    return Language(
      language: data.language.present ? data.language.value : this.language,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Language(')
          ..write('language: $language, ')
          ..write('languageCode: $languageCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(language, languageCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Language &&
          other.language == this.language &&
          other.languageCode == this.languageCode);
}

class LanguagesCompanion extends UpdateCompanion<Language> {
  final Value<String> language;
  final Value<String> languageCode;
  final Value<int> rowid;
  const LanguagesCompanion({
    this.language = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LanguagesCompanion.insert({
    required String language,
    required String languageCode,
    this.rowid = const Value.absent(),
  }) : language = Value(language),
       languageCode = Value(languageCode);
  static Insertable<Language> custom({
    Expression<String>? language,
    Expression<String>? languageCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (language != null) 'language': language,
      if (languageCode != null) 'language_code': languageCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LanguagesCompanion copyWith({
    Value<String>? language,
    Value<String>? languageCode,
    Value<int>? rowid,
  }) {
    return LanguagesCompanion(
      language: language ?? this.language,
      languageCode: languageCode ?? this.languageCode,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  @override
  List<GeneratedColumn> get $columns => [name, code, languageCode, type];
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
  final String name;
  final String code;
  final String languageCode;
  final TypeCurrency type;
  const Currency({
    required this.name,
    required this.code,
    required this.languageCode,
    required this.type,
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
    return map;
  }

  CurrenciesCompanion toCompanion(bool nullToAbsent) {
    return CurrenciesCompanion(
      name: Value(name),
      code: Value(code),
      languageCode: Value(languageCode),
      type: Value(type),
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
    };
  }

  Currency copyWith({
    String? name,
    String? code,
    String? languageCode,
    TypeCurrency? type,
  }) => Currency(
    name: name ?? this.name,
    code: code ?? this.code,
    languageCode: languageCode ?? this.languageCode,
    type: type ?? this.type,
  );
  Currency copyWithCompanion(CurrenciesCompanion data) {
    return Currency(
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Currency(')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('languageCode: $languageCode, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(name, code, languageCode, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Currency &&
          other.name == this.name &&
          other.code == this.code &&
          other.languageCode == this.languageCode &&
          other.type == this.type);
}

class CurrenciesCompanion extends UpdateCompanion<Currency> {
  final Value<String> name;
  final Value<String> code;
  final Value<String> languageCode;
  final Value<TypeCurrency> type;
  final Value<int> rowid;
  const CurrenciesCompanion({
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurrenciesCompanion.insert({
    required String name,
    required String code,
    required String languageCode,
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       code = Value(code),
       languageCode = Value(languageCode);
  static Insertable<Currency> custom({
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? languageCode,
    Expression<int>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (languageCode != null) 'language_code': languageCode,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurrenciesCompanion copyWith({
    Value<String>? name,
    Value<String>? code,
    Value<String>? languageCode,
    Value<TypeCurrency>? type,
    Value<int>? rowid,
  }) {
    return CurrenciesCompanion(
      name: name ?? this.name,
      code: code ?? this.code,
      languageCode: languageCode ?? this.languageCode,
      type: type ?? this.type,
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
  @override
  List<GeneratedColumn> get $columns => [id, value, currencyCode];
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
  const CurrencyDesignation({
    required this.id,
    required this.value,
    required this.currencyCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['value'] = Variable<String>(value);
    map['currency_code'] = Variable<String>(currencyCode);
    return map;
  }

  CurrencyDesignationsCompanion toCompanion(bool nullToAbsent) {
    return CurrencyDesignationsCompanion(
      id: Value(id),
      value: Value(value),
      currencyCode: Value(currencyCode),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'value': serializer.toJson<String>(value),
      'currencyCode': serializer.toJson<String>(currencyCode),
    };
  }

  CurrencyDesignation copyWith({
    String? id,
    String? value,
    String? currencyCode,
  }) => CurrencyDesignation(
    id: id ?? this.id,
    value: value ?? this.value,
    currencyCode: currencyCode ?? this.currencyCode,
  );
  CurrencyDesignation copyWithCompanion(CurrencyDesignationsCompanion data) {
    return CurrencyDesignation(
      id: data.id.present ? data.id.value : this.id,
      value: data.value.present ? data.value.value : this.value,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CurrencyDesignation(')
          ..write('id: $id, ')
          ..write('value: $value, ')
          ..write('currencyCode: $currencyCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, value, currencyCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CurrencyDesignation &&
          other.id == this.id &&
          other.value == this.value &&
          other.currencyCode == this.currencyCode);
}

class CurrencyDesignationsCompanion
    extends UpdateCompanion<CurrencyDesignation> {
  final Value<String> id;
  final Value<String> value;
  final Value<String> currencyCode;
  final Value<int> rowid;
  const CurrencyDesignationsCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CurrencyDesignationsCompanion.insert({
    this.id = const Value.absent(),
    required String value,
    required String currencyCode,
    this.rowid = const Value.absent(),
  }) : value = Value(value),
       currencyCode = Value(currencyCode);
  static Insertable<CurrencyDesignation> custom({
    Expression<String>? id,
    Expression<String>? value,
    Expression<String>? currencyCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'value': value,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CurrencyDesignationsCompanion copyWith({
    Value<String>? id,
    Value<String>? value,
    Value<String>? currencyCode,
    Value<int>? rowid,
  }) {
    return CurrencyDesignationsCompanion(
      id: id ?? this.id,
      value: value ?? this.value,
      currencyCode: currencyCode ?? this.currencyCode,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    iconName,
    colorHex,
    iconType,
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
  const Style({
    required this.id,
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.iconType,
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
    return map;
  }

  StylesCompanion toCompanion(bool nullToAbsent) {
    return StylesCompanion(
      id: Value(id),
      name: Value(name),
      iconName: Value(iconName),
      colorHex: Value(colorHex),
      iconType: Value(iconType),
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
    };
  }

  Style copyWith({
    String? id,
    String? name,
    String? iconName,
    String? colorHex,
    IconType? iconType,
  }) => Style(
    id: id ?? this.id,
    name: name ?? this.name,
    iconName: iconName ?? this.iconName,
    colorHex: colorHex ?? this.colorHex,
    iconType: iconType ?? this.iconType,
  );
  Style copyWithCompanion(StylesCompanion data) {
    return Style(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconName: data.iconName.present ? data.iconName.value : this.iconName,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      iconType: data.iconType.present ? data.iconType.value : this.iconType,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Style(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconName: $iconName, ')
          ..write('colorHex: $colorHex, ')
          ..write('iconType: $iconType')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, iconName, colorHex, iconType);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Style &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconName == this.iconName &&
          other.colorHex == this.colorHex &&
          other.iconType == this.iconType);
}

class StylesCompanion extends UpdateCompanion<Style> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> iconName;
  final Value<String> colorHex;
  final Value<IconType> iconType;
  final Value<int> rowid;
  const StylesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconName = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.iconType = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StylesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String iconName,
    required String colorHex,
    this.iconType = const Value.absent(),
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
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconName != null) 'icon_name': iconName,
      if (colorHex != null) 'color_hex': colorHex,
      if (iconType != null) 'icon_type': iconType,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StylesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? iconName,
    Value<String>? colorHex,
    Value<IconType>? iconType,
    Value<int>? rowid,
  }) {
    return StylesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      iconType: iconType ?? this.iconType,
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
  @override
  List<GeneratedColumn> get $columns => [id, name, parentId, styleId, type];
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
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.styleId,
    required this.type,
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
    };
  }

  Category copyWith({
    String? id,
    String? name,
    Value<String?> parentId = const Value.absent(),
    Value<String?> styleId = const Value.absent(),
    CategoryType? type,
  }) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    parentId: parentId.present ? parentId.value : this.parentId,
    styleId: styleId.present ? styleId.value : this.styleId,
    type: type ?? this.type,
  );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      styleId: data.styleId.present ? data.styleId.value : this.styleId,
      type: data.type.present ? data.type.value : this.type,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('parentId: $parentId, ')
          ..write('styleId: $styleId, ')
          ..write('type: $type')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, parentId, styleId, type);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.name == this.name &&
          other.parentId == this.parentId &&
          other.styleId == this.styleId &&
          other.type == this.type);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> parentId;
  final Value<String?> styleId;
  final Value<CategoryType> type;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.parentId = const Value.absent(),
    this.styleId = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.parentId = const Value.absent(),
    this.styleId = const Value.absent(),
    this.type = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Category> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? parentId,
    Expression<String>? styleId,
    Expression<int>? type,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (parentId != null) 'parent_id': parentId,
      if (styleId != null) 'style_id': styleId,
      if (type != null) 'type': type,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? parentId,
    Value<String?>? styleId,
    Value<CategoryType>? type,
    Value<int>? rowid,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      parentId: parentId ?? this.parentId,
      styleId: styleId ?? this.styleId,
      type: type ?? this.type,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
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
  List<GeneratedColumn> get $columns => [id, name, languageCode];
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
    );
  }

  @override
  $AccountTypesTable createAlias(String alias) {
    return $AccountTypesTable(attachedDatabase, alias);
  }
}

class AccountType extends DataClass implements Insertable<AccountType> {
  final String id;
  final String name;
  final String languageCode;
  const AccountType({
    required this.id,
    required this.name,
    required this.languageCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['language_code'] = Variable<String>(languageCode);
    return map;
  }

  AccountTypesCompanion toCompanion(bool nullToAbsent) {
    return AccountTypesCompanion(
      id: Value(id),
      name: Value(name),
      languageCode: Value(languageCode),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'languageCode': serializer.toJson<String>(languageCode),
    };
  }

  AccountType copyWith({String? id, String? name, String? languageCode}) =>
      AccountType(
        id: id ?? this.id,
        name: name ?? this.name,
        languageCode: languageCode ?? this.languageCode,
      );
  AccountType copyWithCompanion(AccountTypesCompanion data) {
    return AccountType(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      languageCode: data.languageCode.present
          ? data.languageCode.value
          : this.languageCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountType(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('languageCode: $languageCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, languageCode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountType &&
          other.id == this.id &&
          other.name == this.name &&
          other.languageCode == this.languageCode);
}

class AccountTypesCompanion extends UpdateCompanion<AccountType> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> languageCode;
  final Value<int> rowid;
  const AccountTypesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.languageCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountTypesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String languageCode,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       languageCode = Value(languageCode);
  static Insertable<AccountType> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? languageCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (languageCode != null) 'language_code': languageCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountTypesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? languageCode,
    Value<int>? rowid,
  }) {
    return AccountTypesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      languageCode: languageCode ?? this.languageCode,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    balance,
    currencyCode,
    currencyDesignationId,
    styleId,
    accountTypeId,
    creationDate,
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
  final String currencyCode;
  final String currencyDesignationId;
  final String? styleId;
  final String accountTypeId;
  final DateTime creationDate;
  const DbAccount({
    required this.id,
    required this.name,
    this.description,
    required this.balance,
    required this.currencyCode,
    required this.currencyDesignationId,
    this.styleId,
    required this.accountTypeId,
    required this.creationDate,
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
    map['currency_code'] = Variable<String>(currencyCode);
    map['currency_designation_id'] = Variable<String>(currencyDesignationId);
    if (!nullToAbsent || styleId != null) {
      map['style_id'] = Variable<String>(styleId);
    }
    map['account_type_id'] = Variable<String>(accountTypeId);
    map['creation_date'] = Variable<DateTime>(creationDate);
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
      currencyCode: Value(currencyCode),
      currencyDesignationId: Value(currencyDesignationId),
      styleId: styleId == null && nullToAbsent
          ? const Value.absent()
          : Value(styleId),
      accountTypeId: Value(accountTypeId),
      creationDate: Value(creationDate),
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
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
      currencyDesignationId: serializer.fromJson<String>(
        json['currencyDesignationId'],
      ),
      styleId: serializer.fromJson<String?>(json['styleId']),
      accountTypeId: serializer.fromJson<String>(json['accountTypeId']),
      creationDate: serializer.fromJson<DateTime>(json['creationDate']),
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
      'currencyCode': serializer.toJson<String>(currencyCode),
      'currencyDesignationId': serializer.toJson<String>(currencyDesignationId),
      'styleId': serializer.toJson<String?>(styleId),
      'accountTypeId': serializer.toJson<String>(accountTypeId),
      'creationDate': serializer.toJson<DateTime>(creationDate),
    };
  }

  DbAccount copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    double? balance,
    String? currencyCode,
    String? currencyDesignationId,
    Value<String?> styleId = const Value.absent(),
    String? accountTypeId,
    DateTime? creationDate,
  }) => DbAccount(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    balance: balance ?? this.balance,
    currencyCode: currencyCode ?? this.currencyCode,
    currencyDesignationId: currencyDesignationId ?? this.currencyDesignationId,
    styleId: styleId.present ? styleId.value : this.styleId,
    accountTypeId: accountTypeId ?? this.accountTypeId,
    creationDate: creationDate ?? this.creationDate,
  );
  DbAccount copyWithCompanion(AccountsCompanion data) {
    return DbAccount(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      balance: data.balance.present ? data.balance.value : this.balance,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('DbAccount(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('balance: $balance, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('currencyDesignationId: $currencyDesignationId, ')
          ..write('styleId: $styleId, ')
          ..write('accountTypeId: $accountTypeId, ')
          ..write('creationDate: $creationDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    balance,
    currencyCode,
    currencyDesignationId,
    styleId,
    accountTypeId,
    creationDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DbAccount &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.balance == this.balance &&
          other.currencyCode == this.currencyCode &&
          other.currencyDesignationId == this.currencyDesignationId &&
          other.styleId == this.styleId &&
          other.accountTypeId == this.accountTypeId &&
          other.creationDate == this.creationDate);
}

class AccountsCompanion extends UpdateCompanion<DbAccount> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<double> balance;
  final Value<String> currencyCode;
  final Value<String> currencyDesignationId;
  final Value<String?> styleId;
  final Value<String> accountTypeId;
  final Value<DateTime> creationDate;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.balance = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.currencyDesignationId = const Value.absent(),
    this.styleId = const Value.absent(),
    this.accountTypeId = const Value.absent(),
    this.creationDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.description = const Value.absent(),
    required double balance,
    required String currencyCode,
    required String currencyDesignationId,
    this.styleId = const Value.absent(),
    required String accountTypeId,
    this.creationDate = const Value.absent(),
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
    Expression<String>? currencyCode,
    Expression<String>? currencyDesignationId,
    Expression<String>? styleId,
    Expression<String>? accountTypeId,
    Expression<DateTime>? creationDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (balance != null) 'balance': balance,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (currencyDesignationId != null)
        'currency_designation_id': currencyDesignationId,
      if (styleId != null) 'style_id': styleId,
      if (accountTypeId != null) 'account_type_id': accountTypeId,
      if (creationDate != null) 'creation_date': creationDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<double>? balance,
    Value<String>? currencyCode,
    Value<String>? currencyDesignationId,
    Value<String?>? styleId,
    Value<String>? accountTypeId,
    Value<DateTime>? creationDate,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      balance: balance ?? this.balance,
      currencyCode: currencyCode ?? this.currencyCode,
      currencyDesignationId:
          currencyDesignationId ?? this.currencyDesignationId,
      styleId: styleId ?? this.styleId,
      accountTypeId: accountTypeId ?? this.accountTypeId,
      creationDate: creationDate ?? this.creationDate,
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
          ..write('currencyCode: $currencyCode, ')
          ..write('currencyDesignationId: $currencyDesignationId, ')
          ..write('styleId: $styleId, ')
          ..write('accountTypeId: $accountTypeId, ')
          ..write('creationDate: $creationDate, ')
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    description,
    amount,
    date,
    accountId,
    categoryId,
    currencyCode,
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
  final DateTime date;
  final String accountId;
  final String categoryId;
  final String currencyCode;
  const Transaction({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.accountId,
    required this.categoryId,
    required this.currencyCode,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['description'] = Variable<String>(description);
    map['amount'] = Variable<double>(amount);
    map['date'] = Variable<DateTime>(date);
    map['account_id'] = Variable<String>(accountId);
    map['category_id'] = Variable<String>(categoryId);
    map['currency_code'] = Variable<String>(currencyCode);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      description: Value(description),
      amount: Value(amount),
      date: Value(date),
      accountId: Value(accountId),
      categoryId: Value(categoryId),
      currencyCode: Value(currencyCode),
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
      date: serializer.fromJson<DateTime>(json['date']),
      accountId: serializer.fromJson<String>(json['accountId']),
      categoryId: serializer.fromJson<String>(json['categoryId']),
      currencyCode: serializer.fromJson<String>(json['currencyCode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'description': serializer.toJson<String>(description),
      'amount': serializer.toJson<double>(amount),
      'date': serializer.toJson<DateTime>(date),
      'accountId': serializer.toJson<String>(accountId),
      'categoryId': serializer.toJson<String>(categoryId),
      'currencyCode': serializer.toJson<String>(currencyCode),
    };
  }

  Transaction copyWith({
    String? id,
    String? description,
    double? amount,
    DateTime? date,
    String? accountId,
    String? categoryId,
    String? currencyCode,
  }) => Transaction(
    id: id ?? this.id,
    description: description ?? this.description,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    currencyCode: currencyCode ?? this.currencyCode,
  );
  Transaction copyWithCompanion(TransactionsCompanion data) {
    return Transaction(
      id: data.id.present ? data.id.value : this.id,
      description: data.description.present
          ? data.description.value
          : this.description,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transaction(')
          ..write('id: $id, ')
          ..write('description: $description, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('currencyCode: $currencyCode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    description,
    amount,
    date,
    accountId,
    categoryId,
    currencyCode,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transaction &&
          other.id == this.id &&
          other.description == this.description &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.accountId == this.accountId &&
          other.categoryId == this.categoryId &&
          other.currencyCode == this.currencyCode);
}

class TransactionsCompanion extends UpdateCompanion<Transaction> {
  final Value<String> id;
  final Value<String> description;
  final Value<double> amount;
  final Value<DateTime> date;
  final Value<String> accountId;
  final Value<String> categoryId;
  final Value<String> currencyCode;
  final Value<int> rowid;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.description = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.accountId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required String description,
    required double amount,
    required DateTime date,
    required String accountId,
    required String categoryId,
    required String currencyCode,
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
    Expression<DateTime>? date,
    Expression<String>? accountId,
    Expression<String>? categoryId,
    Expression<String>? currencyCode,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (description != null) 'description': description,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (accountId != null) 'account_id': accountId,
      if (categoryId != null) 'category_id': categoryId,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransactionsCompanion copyWith({
    Value<String>? id,
    Value<String>? description,
    Value<double>? amount,
    Value<DateTime>? date,
    Value<String>? accountId,
    Value<String>? categoryId,
    Value<String>? currencyCode,
    Value<int>? rowid,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      accountId: accountId ?? this.accountId,
      categoryId: categoryId ?? this.categoryId,
      currencyCode: currencyCode ?? this.currencyCode,
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
          ..write('date: $date, ')
          ..write('accountId: $accountId, ')
          ..write('categoryId: $categoryId, ')
          ..write('currencyCode: $currencyCode, ')
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
  @override
  List<GeneratedColumn> get $columns => [
    fromCurrencyCode,
    toCurrencyCode,
    rate,
    preset,
    date,
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    fromCurrencyCode,
    toCurrencyCode,
    date,
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
  const ExchangeRate({
    required this.fromCurrencyCode,
    required this.toCurrencyCode,
    required this.rate,
    required this.preset,
    required this.date,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_currency_code'] = Variable<String>(fromCurrencyCode);
    map['to_currency_code'] = Variable<String>(toCurrencyCode);
    map['rate'] = Variable<double>(rate);
    map['preset'] = Variable<int>(preset);
    map['date'] = Variable<DateTime>(date);
    return map;
  }

  ExchangeRatesCompanion toCompanion(bool nullToAbsent) {
    return ExchangeRatesCompanion(
      fromCurrencyCode: Value(fromCurrencyCode),
      toCurrencyCode: Value(toCurrencyCode),
      rate: Value(rate),
      preset: Value(preset),
      date: Value(date),
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
    };
  }

  ExchangeRate copyWith({
    String? fromCurrencyCode,
    String? toCurrencyCode,
    double? rate,
    int? preset,
    DateTime? date,
  }) => ExchangeRate(
    fromCurrencyCode: fromCurrencyCode ?? this.fromCurrencyCode,
    toCurrencyCode: toCurrencyCode ?? this.toCurrencyCode,
    rate: rate ?? this.rate,
    preset: preset ?? this.preset,
    date: date ?? this.date,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExchangeRate(')
          ..write('fromCurrencyCode: $fromCurrencyCode, ')
          ..write('toCurrencyCode: $toCurrencyCode, ')
          ..write('rate: $rate, ')
          ..write('preset: $preset, ')
          ..write('date: $date')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(fromCurrencyCode, toCurrencyCode, rate, preset, date);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExchangeRate &&
          other.fromCurrencyCode == this.fromCurrencyCode &&
          other.toCurrencyCode == this.toCurrencyCode &&
          other.rate == this.rate &&
          other.preset == this.preset &&
          other.date == this.date);
}

class ExchangeRatesCompanion extends UpdateCompanion<ExchangeRate> {
  final Value<String> fromCurrencyCode;
  final Value<String> toCurrencyCode;
  final Value<double> rate;
  final Value<int> preset;
  final Value<DateTime> date;
  final Value<int> rowid;
  const ExchangeRatesCompanion({
    this.fromCurrencyCode = const Value.absent(),
    this.toCurrencyCode = const Value.absent(),
    this.rate = const Value.absent(),
    this.preset = const Value.absent(),
    this.date = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExchangeRatesCompanion.insert({
    required String fromCurrencyCode,
    required String toCurrencyCode,
    required double rate,
    required int preset,
    required DateTime date,
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
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromCurrencyCode != null) 'from_currency_code': fromCurrencyCode,
      if (toCurrencyCode != null) 'to_currency_code': toCurrencyCode,
      if (rate != null) 'rate': rate,
      if (preset != null) 'preset': preset,
      if (date != null) 'date': date,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExchangeRatesCompanion copyWith({
    Value<String>? fromCurrencyCode,
    Value<String>? toCurrencyCode,
    Value<double>? rate,
    Value<int>? preset,
    Value<DateTime>? date,
    Value<int>? rowid,
  }) {
    return ExchangeRatesCompanion(
      fromCurrencyCode: fromCurrencyCode ?? this.fromCurrencyCode,
      toCurrencyCode: toCurrencyCode ?? this.toCurrencyCode,
      rate: rate ?? this.rate,
      preset: preset ?? this.preset,
      date: date ?? this.date,
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
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, device];
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
    } else if (isInserting) {
      context.missing(_deviceMeta);
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
      )!,
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
  final String device;
  const Setting({required this.key, required this.value, required this.device});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['device'] = Variable<String>(device);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      key: Value(key),
      value: Value(value),
      device: Value(device),
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
      device: serializer.fromJson<String>(json['device']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'device': serializer.toJson<String>(device),
    };
  }

  Setting copyWith({String? key, String? value, String? device}) => Setting(
    key: key ?? this.key,
    value: value ?? this.value,
    device: device ?? this.device,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      device: data.device.present ? data.device.value : this.device,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('device: $device')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, device);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.key == this.key &&
          other.value == this.value &&
          other.device == this.device);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<String> device;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.device = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    required String device,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       device = Value(device);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<String>? device,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (device != null) 'device': device,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<String>? device,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      device: device ?? this.device,
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
  late final $SettingsTable settings = $SettingsTable(this);
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
  late final SettingsDao settingsDao = SettingsDao(this as AppDatabase);
  late final ExchangeRatesDao exchangeRatesDao = ExchangeRatesDao(
    this as AppDatabase,
  );
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
    settings,
  ];
}

typedef $$LanguagesTableCreateCompanionBuilder =
    LanguagesCompanion Function({
      required String language,
      required String languageCode,
      Value<int> rowid,
    });
typedef $$LanguagesTableUpdateCompanionBuilder =
    LanguagesCompanion Function({
      Value<String> language,
      Value<String> languageCode,
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
                Value<int> rowid = const Value.absent(),
              }) => LanguagesCompanion(
                language: language,
                languageCode: languageCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String language,
                required String languageCode,
                Value<int> rowid = const Value.absent(),
              }) => LanguagesCompanion.insert(
                language: language,
                languageCode: languageCode,
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
      Value<int> rowid,
    });
typedef $$CurrenciesTableUpdateCompanionBuilder =
    CurrenciesCompanion Function({
      Value<String> name,
      Value<String> code,
      Value<String> languageCode,
      Value<TypeCurrency> type,
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
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesCompanion(
                name: name,
                code: code,
                languageCode: languageCode,
                type: type,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String name,
                required String code,
                required String languageCode,
                Value<TypeCurrency> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CurrenciesCompanion.insert(
                name: name,
                code: code,
                languageCode: languageCode,
                type: type,
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (currencyDesignationsRefs) db.currencyDesignations,
                    if (accountsRefs) db.accounts,
                    if (transactionsRefs) db.transactions,
                    if (exchangeRatesRefs) db.exchangeRates,
                    if (ToCurrencyRates) db.exchangeRates,
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
      })
    >;
typedef $$CurrencyDesignationsTableCreateCompanionBuilder =
    CurrencyDesignationsCompanion Function({
      Value<String> id,
      required String value,
      required String currencyCode,
      Value<int> rowid,
    });
typedef $$CurrencyDesignationsTableUpdateCompanionBuilder =
    CurrencyDesignationsCompanion Function({
      Value<String> id,
      Value<String> value,
      Value<String> currencyCode,
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
                Value<int> rowid = const Value.absent(),
              }) => CurrencyDesignationsCompanion(
                id: id,
                value: value,
                currencyCode: currencyCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String value,
                required String currencyCode,
                Value<int> rowid = const Value.absent(),
              }) => CurrencyDesignationsCompanion.insert(
                id: id,
                value: value,
                currencyCode: currencyCode,
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
      Value<int> rowid,
    });
typedef $$StylesTableUpdateCompanionBuilder =
    StylesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> iconName,
      Value<String> colorHex,
      Value<IconType> iconType,
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
                Value<int> rowid = const Value.absent(),
              }) => StylesCompanion(
                id: id,
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                iconType: iconType,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String iconName,
                required String colorHex,
                Value<IconType> iconType = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StylesCompanion.insert(
                id: id,
                name: name,
                iconName: iconName,
                colorHex: colorHex,
                iconType: iconType,
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
      Value<int> rowid,
    });
typedef $$CategoriesTableUpdateCompanionBuilder =
    CategoriesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> parentId,
      Value<String?> styleId,
      Value<CategoryType> type,
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
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion(
                id: id,
                name: name,
                parentId: parentId,
                styleId: styleId,
                type: type,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                Value<String?> parentId = const Value.absent(),
                Value<String?> styleId = const Value.absent(),
                Value<CategoryType> type = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CategoriesCompanion.insert(
                id: id,
                name: name,
                parentId: parentId,
                styleId: styleId,
                type: type,
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
      Value<int> rowid,
    });
typedef $$AccountTypesTableUpdateCompanionBuilder =
    AccountTypesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> languageCode,
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
                Value<int> rowid = const Value.absent(),
              }) => AccountTypesCompanion(
                id: id,
                name: name,
                languageCode: languageCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                required String languageCode,
                Value<int> rowid = const Value.absent(),
              }) => AccountTypesCompanion.insert(
                id: id,
                name: name,
                languageCode: languageCode,
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
      required String currencyCode,
      required String currencyDesignationId,
      Value<String?> styleId,
      required String accountTypeId,
      Value<DateTime> creationDate,
      Value<int> rowid,
    });
typedef $$AccountsTableUpdateCompanionBuilder =
    AccountsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<double> balance,
      Value<String> currencyCode,
      Value<String> currencyDesignationId,
      Value<String?> styleId,
      Value<String> accountTypeId,
      Value<DateTime> creationDate,
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

  ColumnFilters<DateTime> get creationDate => $composableBuilder(
    column: $table.creationDate,
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

  ColumnOrderings<DateTime> get creationDate => $composableBuilder(
    column: $table.creationDate,
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

  GeneratedColumn<DateTime> get creationDate => $composableBuilder(
    column: $table.creationDate,
    builder: (column) => column,
  );

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
                Value<String> currencyCode = const Value.absent(),
                Value<String> currencyDesignationId = const Value.absent(),
                Value<String?> styleId = const Value.absent(),
                Value<String> accountTypeId = const Value.absent(),
                Value<DateTime> creationDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                name: name,
                description: description,
                balance: balance,
                currencyCode: currencyCode,
                currencyDesignationId: currencyDesignationId,
                styleId: styleId,
                accountTypeId: accountTypeId,
                creationDate: creationDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String name,
                Value<String?> description = const Value.absent(),
                required double balance,
                required String currencyCode,
                required String currencyDesignationId,
                Value<String?> styleId = const Value.absent(),
                required String accountTypeId,
                Value<DateTime> creationDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                name: name,
                description: description,
                balance: balance,
                currencyCode: currencyCode,
                currencyDesignationId: currencyDesignationId,
                styleId: styleId,
                accountTypeId: accountTypeId,
                creationDate: creationDate,
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
              }) {
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
      })
    >;
typedef $$TransactionsTableCreateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      required String description,
      required double amount,
      required DateTime date,
      required String accountId,
      required String categoryId,
      required String currencyCode,
      Value<int> rowid,
    });
typedef $$TransactionsTableUpdateCompanionBuilder =
    TransactionsCompanion Function({
      Value<String> id,
      Value<String> description,
      Value<double> amount,
      Value<DateTime> date,
      Value<String> accountId,
      Value<String> categoryId,
      Value<String> currencyCode,
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

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
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

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
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

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

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
                Value<DateTime> date = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> categoryId = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion(
                id: id,
                description: description,
                amount: amount,
                date: date,
                accountId: accountId,
                categoryId: categoryId,
                currencyCode: currencyCode,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                required String description,
                required double amount,
                required DateTime date,
                required String accountId,
                required String categoryId,
                required String currencyCode,
                Value<int> rowid = const Value.absent(),
              }) => TransactionsCompanion.insert(
                id: id,
                description: description,
                amount: amount,
                date: date,
                accountId: accountId,
                categoryId: categoryId,
                currencyCode: currencyCode,
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
      Value<int> rowid,
    });
typedef $$ExchangeRatesTableUpdateCompanionBuilder =
    ExchangeRatesCompanion Function({
      Value<String> fromCurrencyCode,
      Value<String> toCurrencyCode,
      Value<double> rate,
      Value<int> preset,
      Value<DateTime> date,
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
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion(
                fromCurrencyCode: fromCurrencyCode,
                toCurrencyCode: toCurrencyCode,
                rate: rate,
                preset: preset,
                date: date,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fromCurrencyCode,
                required String toCurrencyCode,
                required double rate,
                required int preset,
                required DateTime date,
                Value<int> rowid = const Value.absent(),
              }) => ExchangeRatesCompanion.insert(
                fromCurrencyCode: fromCurrencyCode,
                toCurrencyCode: toCurrencyCode,
                rate: rate,
                preset: preset,
                date: date,
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
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      required String device,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<String> device,
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
                Value<String> device = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(
                key: key,
                value: value,
                device: device,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                required String device,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                device: device,
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
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
