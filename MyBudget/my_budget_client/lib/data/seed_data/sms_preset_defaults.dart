import 'package:my_budget_client/domain/entities/sms_preset.dart';

/// Built-in presets for common banks
class SmsPresetDefaults {
  static List<SmsPreset> getBuiltInPresets() {
    return [_altaBankPreset()];
  }

  static SmsPreset _altaBankPreset() {
    return SmsPreset(
      id: 'alta_bank',
      name: 'Alta Bank',
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
        // Transfer in (income)
        // Example: "Proknjizen je priliv na vas racun... u iznosu od 10.00 EUR"
        const SmsParsingRule(
          id: 'alta_transfer_in',
          type: TransactionType.income,
          matchPattern: r'priliv',
          amountPattern: r'iznosu od\s+([\d,.]+)\s*(\w{3})',
          currencyPattern: r'iznosu od\s+[\d,.]+\s*(\w{3})',
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
    );
  }
}
