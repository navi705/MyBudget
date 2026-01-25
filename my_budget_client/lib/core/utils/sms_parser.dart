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

  const SmsParseResult({
    required this.isMatch,
    this.type,
    this.amount,
    this.currencyCode,
    this.date,
    this.rawMessage,
    this.ruleId,
  });

  static const noMatch = SmsParseResult(isMatch: false);
}

/// Parses SMS messages using preset rules
class SmsParser {
  /// Try to parse an SMS using the given preset's rules
  SmsParseResult parse(String smsBody, SmsPreset preset, DateTime smsDate) {
    for (final rule in preset.rules) {
      final matchRegex = RegExp(rule.matchPattern, caseSensitive: false);
      if (!matchRegex.hasMatch(smsBody)) {
        continue;
      }

      // Try to extract amount
      final amountRegex = RegExp(rule.amountPattern, caseSensitive: false);
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
        final currencyRegex = RegExp(
          rule.currencyPattern!,
          caseSensitive: false,
        );
        final currencyMatch = currencyRegex.firstMatch(smsBody);
        currencyCode = currencyMatch?.group(1)?.toUpperCase();
      }

      // Try to extract date (optional)
      DateTime? date;
      if (rule.datePattern != null) {
        final dateRegex = RegExp(rule.datePattern!, caseSensitive: false);
        final dateMatch = dateRegex.firstMatch(smsBody);
        if (dateMatch != null) {
          date = _parseDate(dateMatch.group(0));
        }
      }

      return SmsParseResult(
        isMatch: true,
        type: rule.type,
        amount: amount,
        currencyCode: currencyCode,
        date: date ?? smsDate,
        rawMessage: smsBody,
        ruleId: rule.id,
      );
    }

    return SmsParseResult.noMatch;
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

    return double.tryParse(cleaned);
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
