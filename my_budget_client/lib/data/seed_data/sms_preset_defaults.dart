import 'package:my_budget_client/domain/entities/sms_preset.dart';

/// Built-in presets for common banks
class SmsPresetDefaults {
  /// Bumped whenever the rules or the keywords below change.
  ///
  /// A built-in preset is copied into the device's own storage the first time
  /// the user touches it, and the stored copy wins from then on - so without a
  /// version to compare, a fixed pattern or a newly added merchant would never
  /// reach anyone who had already enabled the preset. See
  /// [SmsPreset.templateVersion] for what the upgrade keeps.
  static const int altaBankTemplateVersion = 2;

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
      templateVersion: altaBankTemplateVersion,
      rules: [
        // Reversal of a card payment - the money comes back.
        // Example: "Stornirano placanje VISA karticom u iznosu od -0.93 EUR,
        // dana 11.05.2025 u 10:18:27 casova."
        //
        // First in the list and anchored at the start of the message on
        // purpose: it contains "placanje ... karticom" and would otherwise be
        // read as a payment. The amount carries its own minus sign and is
        // sometimes written ",100.00"; the rule takes the digits alone,
        // because the type below already says which way the money went.
        //
        // Queued for review with no attempt at a category: the message never
        // names what was refunded, and the payment it reverses was imported
        // days earlier under a category of its own.
        const SmsParsingRule(
          id: 'alta_storno',
          type: TransactionType.income,
          matchPattern: r'^Stornirano\s+placanje',
          amountPattern: r'iznosu od\s*-?\s*([\d,.]+)\s*(\w{3})',
          currencyPattern: r'iznosu od\s*-?\s*[\d,.]+\s*(\w{3})',
          categoryId: 'cat_other_income',
          forceReview: true,
        ),
        // Card payment (expense)
        // Example: "Placanje VISA karticom **3677: iznos 16.99RSD, mesto LIDL..."
        //
        // Anchored so it cannot swallow the bank's "Placate 1.200,00 RSD
        // trgovcu ... karticom ****9574" - that one is the confirmation prompt
        // sent *before* a payment, and the completed payment arrives as its own
        // message. Importing both would book every online payment twice.
        const SmsParsingRule(
          id: 'alta_card_payment',
          type: TransactionType.expense,
          matchPattern: r'^Placanje\s+\w+\s+karticom',
          amountPattern: r'iznos\s+([\d,.]+)\s*(\w{3})',
          currencyPattern: r'iznos\s+[\d,.]+\s*(\w{3})',
          descriptionPattern: r'mesto\s+(.+?)\s*,\s*dana',
        ),
        // Cash withdrawal (expense)
        // Example: "Podizanje gotovine DINA karticom **9574: iznos
        // 40,000.00RSD, mesto ATM BPS- MAXI V, dana ..."
        //
        // The same shape as a card payment, but `mesto` names the cash machine
        // rather than a shop - "ATM BPS- MAXI V" is a cash point in a Maxi car
        // park, not a grocery bill - so the keywords are skipped and the row is
        // queued under a category that claims nothing. What the cash was spent
        // on is not in the message and only the user knows it.
        const SmsParsingRule(
          id: 'alta_cash_withdrawal',
          type: TransactionType.expense,
          matchPattern: r'^Podizanje\s+gotovine',
          amountPattern: r'iznos\s+([\d,.]+)\s*(\w{3})',
          currencyPattern: r'iznos\s+[\d,.]+\s*(\w{3})',
          descriptionPattern: r'mesto\s+(.+?)\s*,\s*dana',
          categoryId: 'cat_other_expense',
          forceReview: true,
        ),
        // Transfer in (income) - salary/incoming transfer
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
        //
        // Carries no merchant at all, so nothing can classify it and every one
        // of these lands in the review queue - the honest answer for a standing
        // order the bank describes only as an outflow.
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
      //
      // The bank truncates the merchant to fifteen characters, so every keyword
      // here is short enough to survive that cut. A message no keyword matches
      // is still imported and goes to the review queue: a missing merchant
      // costs a moment of filing, a wrong keyword costs a wrong budget.
      categoryKeywords: const [
        // --- Recurring services -------------------------------------------
        // These name a category the user made rather than one this app ships,
        // so they carry the name and fall back to the generic subscriptions
        // category on an install that has no such category of its own.
        SmsCategoryKeyword(
          keyword: 'anthropic',
          categoryId: 'cat_subscriptions',
          categoryNameHint: 'Ai',
        ),
        SmsCategoryKeyword(
          keyword: 'claude',
          categoryId: 'cat_subscriptions',
          categoryNameHint: 'Ai',
        ),
        SmsCategoryKeyword(
          keyword: 'contabo',
          categoryId: 'cat_subscriptions',
          categoryNameHint: 'VPS',
        ),
        SmsCategoryKeyword(
          keyword: 'oracle',
          categoryId: 'cat_subscriptions',
          categoryNameHint: 'VPS',
        ),
        SmsCategoryKeyword(
          keyword: 'northflank',
          categoryId: 'cat_subscriptions',
          categoryNameHint: 'VPS',
        ),
        SmsCategoryKeyword(keyword: 'mapbox', categoryId: 'cat_subscriptions'),
        SmsCategoryKeyword(keyword: 'google', categoryId: 'cat_subscriptions'),

        // --- Phone ---------------------------------------------------------
        SmsCategoryKeyword(keyword: 'yettel', categoryId: 'cat_phone'),
        SmsCategoryKeyword(keyword: 'a1 srbija', categoryId: 'cat_phone'),

        // --- Utilities / home services -------------------------------------
        // MTS is billed as part of the flat rather than as a phone line, which
        // is the user's own filing and why it is not with Yettel above.
        SmsCategoryKeyword(keyword: 'epssnabdevan', categoryId: 'cat_housing'),
        SmsCategoryKeyword(keyword: 'eps ad', categoryId: 'cat_housing'),
        SmsCategoryKeyword(keyword: 'mts', categoryId: 'cat_housing'),
        SmsCategoryKeyword(keyword: 'infostan', categoryId: 'cat_housing'),

        // --- Health ---------------------------------------------------------
        // Ahead of the grocery chains: "LILLY VIDI 3-AP" and "15344 AU DRMAX"
        // are pharmacies whose names carry no shop word of their own.
        SmsCategoryKeyword(keyword: 'apoteka', categoryId: 'cat_healthcare'),
        SmsCategoryKeyword(keyword: 'lilly', categoryId: 'cat_healthcare'),
        SmsCategoryKeyword(keyword: 'drmax', categoryId: 'cat_healthcare'),
        SmsCategoryKeyword(keyword: 'benu', categoryId: 'cat_healthcare'),
        SmsCategoryKeyword(
          keyword: 'primax farm',
          categoryId: 'cat_healthcare',
        ),
        SmsCategoryKeyword(keyword: 'hemoluks', categoryId: 'cat_healthcare'),
        SmsCategoryKeyword(keyword: 'euromedik', categoryId: 'cat_healthcare'),
        SmsCategoryKeyword(
          keyword: 'poliklinika',
          categoryId: 'cat_healthcare',
        ),
        SmsCategoryKeyword(
          keyword: 'opsta bolnica',
          categoryId: 'cat_healthcare',
        ),
        SmsCategoryKeyword(keyword: 'dental', categoryId: 'cat_healthcare'),

        // --- Transport -------------------------------------------------------
        SmsCategoryKeyword(keyword: 'srbijavoz', categoryId: 'cat_transport'),
        SmsCategoryKeyword(keyword: 'srbija voz', categoryId: 'cat_transport'),
        SmsCategoryKeyword(keyword: 'busticket', categoryId: 'cat_transport'),

        // --- Groceries --------------------------------------------------------
        SmsCategoryKeyword(keyword: 'c market', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(keyword: 'lidl', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(keyword: 'maxi', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(keyword: 'aman', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(keyword: 'tempo', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(keyword: 'dis market', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(keyword: 'gomex', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(
          keyword: 'univerexport',
          categoryId: 'cat_groceries',
        ),
        SmsCategoryKeyword(keyword: 'konzum', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(keyword: 'bingo doo', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(
          keyword: 'sumadija market',
          categoryId: 'cat_groceries',
        ),
        SmsCategoryKeyword(
          keyword: 'total market',
          categoryId: 'cat_groceries',
        ),
        SmsCategoryKeyword(
          keyword: 'trgovina mesovi',
          categoryId: 'cat_groceries',
        ),
        SmsCategoryKeyword(keyword: 'hiper mc', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(keyword: 'mister li', categoryId: 'cat_groceries'),
        SmsCategoryKeyword(
          keyword: 'mini shanghai',
          categoryId: 'cat_groceries',
        ),

        // --- Eating out --------------------------------------------------------
        SmsCategoryKeyword(keyword: 'restoran', categoryId: 'cat_restaurant'),
        SmsCategoryKeyword(keyword: 'fast food', categoryId: 'cat_restaurant'),
        SmsCategoryKeyword(keyword: 'pizzagram', categoryId: 'cat_restaurant'),
        SmsCategoryKeyword(keyword: 'burrito', categoryId: 'cat_restaurant'),
        SmsCategoryKeyword(keyword: 'gyropolis', categoryId: 'cat_restaurant'),
        SmsCategoryKeyword(keyword: 'coffe bean', categoryId: 'cat_restaurant'),
        SmsCategoryKeyword(
          keyword: 'loong bubble',
          categoryId: 'cat_restaurant',
        ),
        SmsCategoryKeyword(keyword: 'ascinica', categoryId: 'cat_restaurant'),
        SmsCategoryKeyword(keyword: 'samo pivo', categoryId: 'cat_restaurant'),

        // --- Beauty / drugstore -------------------------------------------------
        SmsCategoryKeyword(keyword: 'dm filijala', categoryId: 'cat_beauty'),

        // --- Shopping ------------------------------------------------------------
        SmsCategoryKeyword(keyword: 'aliexpress', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'temu.com', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'ananas', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'emmezeta', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'forma ideale', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'ikea', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'decathlon', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'cropp', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'okov centar', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'uradi sam', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'trgocentar', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(
          keyword: 'beli elektronik',
          categoryId: 'cat_shopping',
        ),
        SmsCategoryKeyword(keyword: 'starcat', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(keyword: 'tornado shop', categoryId: 'cat_shopping'),
        SmsCategoryKeyword(
          keyword: 'stampa sistem',
          categoryId: 'cat_shopping',
        ),
      ],
    );
  }
}
