import 'package:equatable/equatable.dart';

enum TransactionType { income, expense }

/// Maps a keyword (substring) to a category ID.
/// Used for automatic category assignment based on SMS body content.
class SmsCategoryKeyword extends Equatable {
  final String keyword;
  final String categoryId;

  /// Name of the category this keyword would rather have, when that category
  /// is one the user made and no built-in id can name it.
  ///
  /// Resolved against the user's own categories by name; [categoryId] is the
  /// fallback for the install that has no such category. This exists because a
  /// preset ships in the app and the category it wants may only exist on one
  /// device - "Ai" and "VPS" here - and a hard-coded id would point at nothing.
  final String? categoryNameHint;

  const SmsCategoryKeyword({
    required this.keyword,
    required this.categoryId,
    this.categoryNameHint,
  });

  @override
  List<Object?> get props => [keyword, categoryId, categoryNameHint];
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

  /// Version of the built-in template this preset's rules came from.
  ///
  /// A built-in preset is stored on the device the moment the user toggles it,
  /// and from then on the stored copy wins - which also froze the rules at
  /// whatever the app shipped that day, so a fixed pattern or a new merchant
  /// keyword never reached anyone who had already used the preset. Shipping a
  /// higher number replaces the rules and keywords, and only those: the
  /// account, the category and the on/off switch stay the user's.
  ///
  /// Zero is what a preset stored before this existed decodes as.
  final int templateVersion;

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
    this.templateVersion = 0,
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
    int? templateVersion,
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
      templateVersion: templateVersion ?? this.templateVersion,
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
    templateVersion,
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

  /// Regex whose first group names what the money was spent on - the merchant
  /// on a card payment. Without it every transaction the import writes is
  /// called after the bank, which is the same word on all of them and tells
  /// the person reviewing the queue nothing.
  final String? descriptionPattern;

  /// Marks every transaction this rule writes for review, and skips the
  /// keyword matching entirely.
  ///
  /// For the messages that carry a place name which is not a merchant: a cash
  /// withdrawal names the ATM, and "ATM BPS- MAXI V" would otherwise be filed
  /// under groceries by the `maxi` keyword. The rule is certain about the
  /// amount and certain that it cannot know the category.
  final bool forceReview;

  const SmsParsingRule({
    required this.id,
    required this.type,
    required this.matchPattern,
    required this.amountPattern,
    this.currencyPattern,
    this.datePattern,
    this.categoryId,
    this.descriptionPattern,
    this.forceReview = false,
  });

  SmsParsingRule copyWith({
    String? id,
    TransactionType? type,
    String? matchPattern,
    String? amountPattern,
    String? currencyPattern,
    String? datePattern,
    String? categoryId,
    String? descriptionPattern,
    bool? forceReview,
  }) {
    return SmsParsingRule(
      id: id ?? this.id,
      type: type ?? this.type,
      matchPattern: matchPattern ?? this.matchPattern,
      amountPattern: amountPattern ?? this.amountPattern,
      currencyPattern: currencyPattern ?? this.currencyPattern,
      datePattern: datePattern ?? this.datePattern,
      categoryId: categoryId ?? this.categoryId,
      descriptionPattern: descriptionPattern ?? this.descriptionPattern,
      forceReview: forceReview ?? this.forceReview,
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
    descriptionPattern,
    forceReview,
  ];
}
