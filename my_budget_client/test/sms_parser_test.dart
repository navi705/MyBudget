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

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

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

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.expense);
      expect(result.amount, 9.04);
      expect(result.currencyCode, 'EUR');
    });

    test('parses transfer in (income) RSD', () {
      const sms =
          'Proknjizen je priliv na vas racun 0001000477288 '
          'u iznosu od 1,000.00 RSD, 07.01.2026';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.income);
      expect(result.amount, 1000.00);
      expect(result.currencyCode, 'RSD');
    });

    test('parses transfer in (income) EUR', () {
      const sms =
          'Proknjizen je priliv na vas racun 0031000267760 '
          'u iznosu od 10.00 EUR, 08.11.2025';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

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

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.expense);
      expect(result.amount, 280.00);
      expect(result.currencyCode, 'RSD');
    });

    test('returns no match for unrelated SMS', () {
      const sms = 'Vash kod podtverzheniya: 123456';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isFalse);
    });
  });

  group('Category Keyword Matching', () {
    test('LIDL → cat_groceries', () {
      const sms =
          'Placanje VISA karticom **3677: iznos 16.99RSD, '
          'mesto LIDL 128 BEOGRA, dana 19.01.2026 u 12:52:35h. '
          'Rasp.: RSD 100,145.83. Vasa ALTA banka';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.categoryId, 'cat_groceries');
    });

    test('C Market → cat_groceries (case-insensitive)', () {
      const sms =
          'Placanje VISA karticom **3677: iznos 850.00RSD, '
          'mesto C MARKET NOVI SAD, dana 20.01.2026 u 10:00:00h. '
          'Rasp.: RSD 99,000.00. Vasa ALTA banka';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.categoryId, 'cat_groceries');
    });

    test('epssnabdevan → cat_housing', () {
      const sms =
          'Placanje VISA karticom **3677: iznos 5000.00RSD, '
          'mesto EPSSNABDEVAN, dana 21.01.2026 u 09:00:00h. '
          'Rasp.: RSD 94,000.00. Vasa ALTA banka';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.categoryId, 'cat_housing');
    });

    test('mts → cat_housing', () {
      const sms =
          'Placanje VISA karticom **3677: iznos 1200.00RSD, '
          'mesto MTS TELEKOM, dana 22.01.2026 u 08:00:00h. '
          'Rasp.: RSD 92,800.00. Vasa ALTA banka';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.categoryId, 'cat_housing');
    });

    test('contabo → the subscriptions category, hinting at VPS', () {
      const sms =
          'Placanje VISA karticom **3677: iznos 7.50EUR, '
          'mesto CONTABO GMBH, dana 23.01.2026 u 07:00:00h. '
          'Rasp.: EUR 10.00. Vasa ALTA banka';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      // A server rental is not what the flat costs. It used to be filed under
      // housing because that was the closest category this app shipped.
      expect(result.categoryId, 'cat_subscriptions');
      expect(result.categoryNameHint, 'VPS');
    });

    test('priliv (transfer in) → cat_salary via rule.categoryId', () {
      const sms =
          'Proknjizen je priliv na vas racun 0001000477288 '
          'u iznosu od 1,000.00 RSD, 07.01.2026';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.income);
      expect(result.categoryId, 'cat_salary');
    });

    test('unknown merchant → no category (null)', () {
      const sms =
          'Placanje VISA karticom **3677: iznos 500.00RSD, '
          'mesto RANDOM SHOP, dana 24.01.2026 u 11:00:00h. '
          'Rasp.: RSD 91,000.00. Vasa ALTA banka';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.categoryId, isNull);
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

      final result = parser.parse('test 1.234,56', preset, DateTime.now());
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

      final result = parser.parse('test 1,234.56', preset, DateTime.now());
      expect(result.amount, 1234.56);
    });
  });

  group('Per-merchant categories inside one sender', () {
    /// The bank's card-payment message, with [merchant] where it prints the
    /// shop. Truncated to fifteen characters the way the bank truncates it,
    /// so a keyword that only matches the full name fails here too.
    String payment(String merchant, {String amount = '100.00RSD'}) =>
        'Placanje VISA karticom **3677: iznos $amount, '
        'mesto ${merchant.length > 15 ? merchant.substring(0, 15) : merchant}, '
        'dana 19.01.2026 u 12:52:35h. Rasp.: RSD 100,145.83. Vasa ALTA banka';

    test('Anthropic is the user own Ai category, not a built-in one', () {
      final result = parser.parse(
        payment('ANTHROPIC* CLAUDE', amount: '20.00EUR'),
        altaBankPreset,
        DateTime.now(),
      );

      expect(result.isMatch, isTrue);
      // The hint names a category only this user has. The id beside it is what
      // an install without it falls back to, so the row is never dropped.
      expect(result.categoryNameHint, 'Ai');
      expect(result.categoryId, 'cat_subscriptions');
    });

    test('Contabo and Oracle are the user own VPS category', () {
      for (final merchant in ['WWW CONTABO COM', 'ORACLE IRELAND']) {
        final result = parser.parse(
          payment(merchant, amount: '7.50EUR'),
          altaBankPreset,
          DateTime.now(),
        );

        expect(result.isMatch, isTrue, reason: merchant);
        expect(result.categoryNameHint, 'VPS', reason: merchant);
        expect(result.categoryId, 'cat_subscriptions', reason: merchant);
      }
    });

    test('the phone networks and the cable company split', () {
      // Both are telecoms and one preset used to file both the same way. The
      // phone contracts are a phone bill; the cable/internet one is part of
      // what the flat costs.
      final yettel = parser.parse(
        payment('Yettel'),
        altaBankPreset,
        DateTime.now(),
      );
      final mts = parser.parse(
        payment('PLACANJE MTS RACUNA'),
        altaBankPreset,
        DateTime.now(),
      );

      expect(yettel.categoryId, 'cat_phone');
      expect(mts.categoryId, 'cat_housing');
    });

    test('Srbijavoz is transport', () {
      final result = parser.parse(
        payment('Srbijavoz a.d.'),
        altaBankPreset,
        DateTime.now(),
      );

      expect(result.categoryId, 'cat_transport');
    });

    test('a pharmacy is healthcare, not the supermarket it sits in', () {
      // Ordering: the healthcare keywords are matched before the grocery ones,
      // because "LILLY DROGERIE" and "APOTEKA" read as shops otherwise.
      for (final merchant in ['LILLY DROGERIE', 'APOTEKA BENU']) {
        final result = parser.parse(
          payment(merchant),
          altaBankPreset,
          DateTime.now(),
        );

        expect(result.categoryId, 'cat_healthcare', reason: merchant);
      }
    });

    test('the merchant becomes the description', () {
      // Without this every imported row read "Alta_Bank", which is the same
      // word on every row and tells the person working through the queue
      // nothing about what they are looking at.
      final result = parser.parse(
        payment('LIDL 128 BEOGRAD'),
        altaBankPreset,
        DateTime.now(),
      );

      expect(result.description, 'LIDL 128 BEOGRA');
      expect(result.needsReview, isFalse);
    });
  });

  group('Messages that must not be booked as an ordinary payment', () {
    test('a cash withdrawal is queued and keeps the ATM out of groceries', () {
      // "ATM BPS- MAXI V" is a cash point in a Maxi car park. Matching the
      // keywords here would file every withdrawal as a grocery bill, and the
      // message does not say what the cash was spent on at all.
      const sms =
          'Podizanje gotovine DINA karticom **9574: iznos 40,000.00RSD, '
          'mesto ATM BPS- MAXI V, dana 05.01.2026 u 17:24:10h. '
          'Rasp.: RSD 12,000.00. Vasa ALTA banka';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.type, TransactionType.expense);
      expect(result.amount, 40000.00);
      expect(result.currencyCode, 'RSD');
      expect(result.needsReview, isTrue);
      expect(result.categoryId, 'cat_other_expense');
      expect(result.description, 'ATM BPS- MAXI V');
    });

    test('a reversal is money coming back, not another payment', () {
      const sms =
          'Stornirano placanje VISA karticom u iznosu od -0.93 EUR, '
          'dana 11.05.2025 u 10:18:27 casova.';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      // It contains "placanje ... karticom" and was read as an expense before
      // the anchored rules, so the refund was booked as a second charge.
      expect(result.type, TransactionType.income);
      expect(result.amount, 0.93);
      expect(result.currencyCode, 'EUR');
      expect(result.needsReview, isTrue);
    });

    test('a reversal with the bank own malformed amount still parses', () {
      // The bank really does send ",100.00" - a thousands separator with no
      // thousands in front of it.
      const sms =
          'Stornirano placanje VISA karticom u iznosu od -,100.00 RSD, '
          'dana 11.05.2025 u 10:18:27 casova.';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isTrue);
      expect(result.amount, 100.0);
      expect(result.currencyCode, 'RSD');
    });

    test('the pre-authorisation prompt is not a payment', () {
      // Sent before the payment goes through; the completed payment arrives as
      // its own message. Importing both books every online payment twice.
      const sms =
          'Placate 1.200,00 RSD trgovcu WWW.MTS.RS karticom ****9574. '
          'Ukoliko niste Vi, pozovite banku.';

      final result = parser.parse(sms, altaBankPreset, DateTime.now());

      expect(result.isMatch, isFalse);
    });
  });
}
