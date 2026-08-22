import 'package:drift/drift.dart';
import 'package:my_budget_client/core/database/app_database.dart';
import 'package:my_budget_client/data/seed_data/seed_name_translations.dart';

/// The account types seeded on first launch, named in [languageCode].
///
/// `languageCode` on the row itself stays `en`: that column is a foreign key
/// into the Languages table, which seeds English alone, so tagging the row
/// with the display language would break the insert. It records which language
/// the *set* of types came from, not what the name reads as.
List<AccountTypesCompanion> getDefaultAccountTypes(String languageCode) {
  String t(String english) => seedName(languageCode, english);

  return [
    AccountTypesCompanion.insert(
      id: const Value('account_type_checking'),
      name: t('Checking'),
      languageCode: 'en',
      modifiedAt: const Value(1),
    ),
    AccountTypesCompanion.insert(
      id: const Value('account_type_savings'),
      name: t('Savings'),
      languageCode: 'en',
      modifiedAt: const Value(1),
    ),
    AccountTypesCompanion.insert(
      id: const Value('account_type_credit_card'),
      name: t('Credit Card'),
      languageCode: 'en',
      modifiedAt: const Value(1),
    ),
    AccountTypesCompanion.insert(
      id: const Value('account_type_cash'),
      name: t('Cash'),
      languageCode: 'en',
      modifiedAt: const Value(1),
    ),
    AccountTypesCompanion.insert(
      id: const Value('account_type_investment'),
      name: t('Investment'),
      languageCode: 'en',
      modifiedAt: const Value(1),
    ),
    AccountTypesCompanion.insert(
      id: const Value('account_type_loan'),
      name: t('Loan'),
      languageCode: 'en',
      modifiedAt: const Value(1),
    ),
  ];
}

/// The English seed set. The stable-id migration matches legacy rows by their
/// English names, which is what every database seeded before this existed
/// holds, so that lookup must not follow the display language.
final List<AccountTypesCompanion> defaultAccountTypes = getDefaultAccountTypes(
  'en',
);
