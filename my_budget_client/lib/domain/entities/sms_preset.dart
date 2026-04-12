import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

/// Maps a keyword (substring) to a category ID.
/// Used for automatic category assignment based on SMS body content.
class SmsCategoryKeyword extends Equatable {
  final String keyword;
  final String categoryId;

  const SmsCategoryKeyword({required this.keyword, required this.categoryId});

  @override
  List<Object?> get props => [keyword, categoryId];
}

class SmsPreset extends Equatable {
  final String id;
  final String name;
  final String senderFilter;
  final bool isBuiltIn;
  final bool isEnabled;
  final String? defaultAccountId;
  final String? defaultCategoryId;
  final List<SmsParsingRule> rules;

  /// Keyword-based category rules applied after a rule matches.
  /// First keyword found in SMS body (case-insensitive) wins.
  final List<SmsCategoryKeyword> categoryKeywords;

  const SmsPreset({
    required this.id,
    required this.name,
    required this.senderFilter,
    this.isBuiltIn = false,
    this.isEnabled = true,
    this.defaultAccountId,
    this.defaultCategoryId,
    this.rules = const [],
    this.categoryKeywords = const [],
  });

  SmsPreset copyWith({
    String? id,
    String? name,
    String? senderFilter,
    bool? isBuiltIn,
    bool? isEnabled,
    String? defaultAccountId,
    String? defaultCategoryId,
    List<SmsParsingRule>? rules,
    List<SmsCategoryKeyword>? categoryKeywords,
  }) {
    return SmsPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      senderFilter: senderFilter ?? this.senderFilter,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      isEnabled: isEnabled ?? this.isEnabled,
      defaultAccountId: defaultAccountId ?? this.defaultAccountId,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      rules: rules ?? this.rules,
      categoryKeywords: categoryKeywords ?? this.categoryKeywords,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    senderFilter,
    isBuiltIn,
    isEnabled,
    defaultAccountId,
    defaultCategoryId,
    rules,
    categoryKeywords,
  ];
}

class SmsParsingRule extends Equatable {
  final String id;
  final TransactionType type;
  final String matchPattern; // Regex pattern to identify this SMS type
  final String amountPattern; // Regex to extract amount
  final String? currencyPattern; // Regex to extract currency code
  final String? datePattern; // Regex to extract date
  final String? categoryId; // Optional per-rule default category

  const SmsParsingRule({
    required this.id,
    required this.type,
    required this.matchPattern,
    required this.amountPattern,
    this.currencyPattern,
    this.datePattern,
    this.categoryId,
  });

  SmsParsingRule copyWith({
    String? id,
    TransactionType? type,
    String? matchPattern,
    String? amountPattern,
    String? currencyPattern,
    String? datePattern,
    String? categoryId,
  }) {
    return SmsParsingRule(
      id: id ?? this.id,
      type: type ?? this.type,
      matchPattern: matchPattern ?? this.matchPattern,
      amountPattern: amountPattern ?? this.amountPattern,
      currencyPattern: currencyPattern ?? this.currencyPattern,
      datePattern: datePattern ?? this.datePattern,
      categoryId: categoryId ?? this.categoryId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    matchPattern,
    amountPattern,
    currencyPattern,
    datePattern,
    categoryId,
  ];
}
