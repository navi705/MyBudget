import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_client/core/utils/sms_parser.dart';
import 'package:my_budget_client/data/seed_data/sms_preset_defaults.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';

void main() {
  late SmsParser parser;
  late SmsPreset altaBankPreset;

  setUp(() {
    parser = SmsParser();
    altaBankPreset = SmsPresetDefaults.getBuiltInPresets().firstWhere(
      (p) => p.id == 'alta_bank',
    );
  });

  group('Alta Bank SMS Parsing', () {
    test('parses card payment in RSD', () {
      const sms =
          'Placanje VISA karticom **3677: iznos 16.99RSD, '
          'mesto LIDL 128 BEOGRA, dana 19.01.2026 u 12:52:35h. '
          'Rasp.: RSD 100,145.83. Vasa ALTA banka';

      final result = parser.parse(sms, altaBankPreset);

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.expense);
      expect(result.amount, 16.99);
      expect(result.currencyCode, 'RSD');
    });

    test('parses card payment in EUR', () {
      const sms =
          'Placanje VISA karticom **3677: iznos 9.04EUR, '
          'mesto aliexpress>Luxe, dana 08.11.2025 u 11:44:20h. '
          'Rasp.: EUR 0.96. Vasa ALTA banka';

      final result = parser.parse(sms, altaBankPreset);

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.expense);
      expect(result.amount, 9.04);
      expect(result.currencyCode, 'EUR');
    });

    test('parses transfer in (income) RSD', () {
      const sms =
          'Proknjizen je priliv na vas racun 0001000477288 '
          'u iznosu od 1,000.00 RSD, 07.01.2026';

      final result = parser.parse(sms, altaBankPreset);

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.income);
      expect(result.amount, 1000.00);
      expect(result.currencyCode, 'RSD');
    });

    test('parses transfer in (income) EUR', () {
      const sms =
          'Proknjizen je priliv na vas racun 0031000267760 '
          'u iznosu od 10.00 EUR, 08.11.2025';

      final result = parser.parse(sms, altaBankPreset);

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.income);
      expect(result.amount, 10.00);
      expect(result.currencyCode, 'EUR');
    });

    test('parses transfer out (expense) RSD', () {
      const sms =
          'Odliv sa racuna: 0001000228369 u iznosu od: 280.00 RSD, '
          'dana: 31.12.2025. Raspolozivo stanje po odlivu 417,473.88 RSD. '
          'Vasa Alta banka';

      final result = parser.parse(sms, altaBankPreset);

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.expense);
      expect(result.amount, 280.00);
      expect(result.currencyCode, 'RSD');
    });

    test('returns no match for unrelated SMS', () {
      const sms = 'Vash kod podtverzheniya: 123456';

      final result = parser.parse(sms, altaBankPreset);

      expect(result.isMatch, isFalse);
    });
  });

  group('Amount Parsing', () {
    test('parses European format with comma decimal', () {
      // Test internal method through a custom rule
      const rule = SmsParsingRule(
        id: 'test',
        type: TransactionType.expense,
        matchPattern: r'test',
        amountPattern: r'([\d,.]+)',
      );

      final preset = SmsPreset(
        id: 'test',
        name: 'Test',
        senderFilter: '',
        rules: [rule],
      );

      final result = parser.parse('test 1.234,56', preset);
      expect(result.amount, 1234.56);
    });

    test('parses US format with dot decimal', () {
      const rule = SmsParsingRule(
        id: 'test',
        type: TransactionType.expense,
        matchPattern: r'test',
        amountPattern: r'([\d,.]+)',
      );

      final preset = SmsPreset(
        id: 'test',
        name: 'Test',
        senderFilter: '',
        rules: [rule],
      );

      final result = parser.parse('test 1,234.56', preset);
      expect(result.amount, 1234.56);
    });
  });
}
