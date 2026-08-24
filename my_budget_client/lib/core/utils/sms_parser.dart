import 'package:my_budget_client/domain/entities/sms_preset.dart';

/// Result of parsing an SMS message
class SmsParseResult {
  final bool isMatch;
  final TransactionType? type;
  final double? amount;
  final String? currencyCode;
  final DateTime? date;
  final String? rawMessage;
  final String? ruleId;

  /// Resolved category ID: keyword match > rule.categoryId (both optional).
  final String? categoryId;

  /// Name of the category the matched keyword would rather have, when it names
  /// one - see [SmsCategoryKeyword.categoryNameHint]. The caller looks it up
  /// among the user's own categories and falls back to [categoryId].
  final String? categoryNameHint;

  /// What the money was spent on, when the message names it - the merchant on
  /// a card payment. Null leaves the caller to fall back to the preset name.
  final String? description;

  /// True when nothing in the message identified the category: no keyword
  /// matched and the rule carries no category of its own, or the rule declared
  /// itself unable to classify. The transaction is still written - it really
  /// happened - and lands in the review queue for a person to file.
  final bool needsReview;

  const SmsParseResult({
    required this.isMatch,
    this.type,
    this.amount,
    this.currencyCode,
    this.date,
    this.rawMessage,
    this.ruleId,
    this.categoryId,
    this.categoryNameHint,
    this.description,
    this.needsReview = false,
  });

  static const noMatch = SmsParseResult(isMatch: false);
}

/// Parses SMS messages using preset rules
/// Parses SMS messages using preset rules
class SmsParser {
  // Cache for compiled RegExp patterns to avoid recompilation
  static final Map<String, RegExp> _regexCache = {};

  /// Get or create a cached RegExp for the given pattern
  static RegExp _getCachedRegex(String pattern, {bool caseSensitive = false}) {
    final key = '$pattern|$caseSensitive';
    return _regexCache.putIfAbsent(
      key,
      () => RegExp(pattern, caseSensitive: caseSensitive),
    );
  }

  /// Try to parse an SMS using the given preset's rules
  SmsParseResult parse(String smsBody, SmsPreset preset, DateTime smsDate) {
    for (final rule in preset.rules) {
      final matchRegex = _getCachedRegex(
        rule.matchPattern,
        caseSensitive: false,
      );
      if (!matchRegex.hasMatch(smsBody)) {
        continue;
      }

      // Try to extract amount
      final amountRegex = _getCachedRegex(
        rule.amountPattern,
        caseSensitive: false,
      );
      final amountMatch = amountRegex.firstMatch(smsBody);
      if (amountMatch == null) {
        continue;
      }

      // Parse amount (handle European format with comma as decimal)
      final amountStr = amountMatch.group(1);
      final amount = _parseAmount(amountStr);
      if (amount == null) {
        continue;
      }

      // Try to extract currency
      String? currencyCode;
      if (rule.currencyPattern != null) {
        final currencyRegex = _getCachedRegex(
          rule.currencyPattern!,
          caseSensitive: false,
        );
        final currencyMatch = currencyRegex.firstMatch(smsBody);
        currencyCode = currencyMatch?.group(1)?.toUpperCase();
      }

      // Try to extract date (optional)
      DateTime? date;
      if (rule.datePattern != null) {
        final dateRegex = _getCachedRegex(
          rule.datePattern!,
          caseSensitive: false,
        );
        final dateMatch = dateRegex.firstMatch(smsBody);
        if (dateMatch != null) {
          date = _parseDate(dateMatch.group(0));
        }
      }
      // What the money was spent on, when the rule knows how to read it.
      String? description;
      if (rule.descriptionPattern != null) {
        final descriptionRegex = _getCachedRegex(
          rule.descriptionPattern!,
          caseSensitive: false,
        );
        final descriptionMatch = descriptionRegex.firstMatch(smsBody);
        description = _cleanDescription(descriptionMatch?.group(1));
      }

      // Resolve category: keyword match > rule.categoryId.
      // A rule that declares itself unable to classify skips the keywords
      // outright - see [SmsParsingRule.forceReview] for the case that needs it.
      final matchedKeyword = rule.forceReview
          ? null
          : _matchKeyword(smsBody, preset);
      final resolvedCategoryId = matchedKeyword?.categoryId ?? rule.categoryId;

      return SmsParseResult(
        isMatch: true,
        type: rule.type,
        amount: amount,
        currencyCode: currencyCode,
        date: date ?? smsDate,
        rawMessage: smsBody,
        ruleId: rule.id,
        categoryId: resolvedCategoryId,
        categoryNameHint: matchedKeyword?.categoryNameHint,
        description: description,
        // A rule that names its own category has already made the call - a
        // `priliv` is income however the message is worded. Only a message
        // nothing could classify goes into the queue.
        needsReview: rule.forceReview || resolvedCategoryId == null,
      );
    }

    return SmsParseResult.noMatch;
  }

  /// The first [preset.categoryKeywords] entry whose keyword appears in
  /// [smsBody], or null when none does.
  ///
  /// Case-insensitive substring match, first entry wins - so the list is
  /// ordered from the most specific keyword to the least, and a bank that adds
  /// a merchant nobody has a keyword for reads as "not classified" rather than
  /// as whichever category happens to be last.
  SmsCategoryKeyword? _matchKeyword(String smsBody, SmsPreset preset) {
    if (preset.categoryKeywords.isEmpty) return null;
    final bodyLower = smsBody.toLowerCase();
    for (final kw in preset.categoryKeywords) {
      if (kw.keyword.isEmpty) continue;
      if (bodyLower.contains(kw.keyword.toLowerCase())) {
        return kw;
      }
    }
    return null;
  }

  /// Tidies a merchant name into something that fits the description column.
  ///
  /// Bank messages pad the name to a fixed width and end it with a stray `>`
  /// before the city, and the column stops at 100 characters - a longer one
  /// would be rejected by the database and lose the whole transaction.
  static String? _cleanDescription(String? raw) {
    if (raw == null) return null;
    var cleaned = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    while (cleaned.endsWith('>') || cleaned.endsWith(',')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trimRight();
    }
    if (cleaned.isEmpty) return null;
    return cleaned.length > 100 ? cleaned.substring(0, 100).trimRight() : cleaned;
  }

  /// Parse amount string (handles both 1,000.00 and 1.000,00 formats)
  double? _parseAmount(String? amountStr) {
    if (amountStr == null) return null;

    // Remove spaces
    var cleaned = amountStr.replaceAll(' ', '');

    // Detect format: if comma is after dot, it's European (1.000,00)
    final commaIndex = cleaned.lastIndexOf(',');
    final dotIndex = cleaned.lastIndexOf('.');

    if (commaIndex > dotIndex) {
      // European format: 1.000,00 -> 1000.00
      cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // US format: 1,000.00 -> 1000.00
      cleaned = cleaned.replaceAll(',', '');
    }

    // A rule's own regex decides what text lands here, and `double.tryParse`
    // reads 'NaN' and 'Infinity' as numbers. Neither is an amount, and one
    // stored as a transaction poisons every sum it reaches.
    final amount = double.tryParse(cleaned);
    return amount != null && amount.isFinite ? amount : null;
  }

  /// Parse date from SMS (basic implementation)
  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;

    // Try common formats: dd.MM.yyyy, dd/MM/yyyy
    final patterns = [
      RegExp(r'(\d{2})\.(\d{2})\.(\d{4})'),
      RegExp(r'(\d{2})/(\d{2})/(\d{4})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(dateStr);
      if (match != null) {
        final day = int.tryParse(match.group(1) ?? '');
        final month = int.tryParse(match.group(2) ?? '');
        final year = int.tryParse(match.group(3) ?? '');
        if (day != null && month != null && year != null) {
          return DateTime(year, month, day);
        }
      }
    }

    return null;
  }

  /// Test a single rule against sample text
  SmsParseResult testRule(String smsBody, SmsParsingRule rule) {
    final tempPreset = SmsPreset(
      id: 'test',
      name: 'Test',
      senderFilter: '',
      rules: [rule],
    );
    return parse(smsBody, tempPreset, DateTime.now());
  }
}
