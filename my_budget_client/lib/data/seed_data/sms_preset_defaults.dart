import 'package:my_budget_client/domain/entities/sms_preset.dart';

/// Built-in presets for common banks
class SmsPresetDefaults {
  static List<SmsPreset> getBuiltInPresets() {
    return [_altaBankPreset()];
  }

  static SmsPreset _altaBankPreset() {
    return SmsPreset(
      id: 'alta_bank',
      name: 'Alta_Bank',
      senderFilter: 'ALTA',
      isBuiltIn: true,
      isEnabled: false,
      rules: [
        // Card payment (expense)
        // Example: "Placanje VISA karticom **3677: iznos 16.99RSD, mesto LIDL..."
        const SmsParsingRule(
          id: 'alta_card_payment',
          type: TransactionType.expense,
          matchPattern: r'Placanje.*karticom',
          amountPattern: r'iznos\s+([\d,.]+)\s*(\w{3})',
          currencyPattern: r'iznos\s+[\d,.]+\s*(\w{3})',
        ),
        // Transfer in (income) — salary/incoming transfer
        // Example: "Proknjizen je priliv na vas racun... u iznosu od 10.00 EUR"
        const SmsParsingRule(
          id: 'alta_transfer_in',
          type: TransactionType.income,
          matchPattern: r'priliv',
          amountPattern: r'iznosu od\s+([\d,.]+)\s*(\w{3})',
          currencyPattern: r'iznosu od\s+[\d,.]+\s*(\w{3})',
          categoryId: 'cat_salary',
        ),
        // Transfer out (expense)
        // Example: "Odliv sa racuna:... u iznosu od: 280.00 RSD"
        const SmsParsingRule(
          id: 'alta_transfer_out',
          type: TransactionType.expense,
          matchPattern: r'Odliv',
          amountPattern: r'iznosu od:\s*([\d,.]+)\s*(\w{3})',
          currencyPattern: r'iznosu od:\s*[\d,.]+\s*(\w{3})',
        ),
      ],
      // Keyword-based category rules for card payments.
      // Applied after a rule matches; first keyword found in SMS body wins.
      // All comparisons are case-insensitive (toLowerCase in parser).
      categoryKeywords: const [
        // Grocery stores
        SmsCategoryKeyword(keyword: 'c market', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(keyword: 'lidl', categoryId: 'cat_groceries'),
        // Utilities / home services
        SmsCategoryKeyword(keyword: 'epssnabdevan', categoryId: 'cat_housing'),
        SmsCategoryKeyword(keyword: 'mts', categoryId: 'cat_housing'),
        // VPS / subscriptions — mapped to Housing as closest available category
        SmsCategoryKeyword(keyword: 'contabo', categoryId: 'cat_housing'),
      ],
    );
  }
}
