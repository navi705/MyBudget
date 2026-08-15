// Runs once before the tests in every file under test/ - `flutter test` picks
// this up by name, so nothing imports it and no test file has to opt in.
//
// It exists to switch the shipped exchange-rate seed off. Creating an
// AppDatabase normally reads a 6.8 MB JSON file, parses it in a spawned
// isolate and inserts roughly 283,000 rate rows. That happens once on a real
// install; across this suite it happened 146 times, because 39 files build a
// database and a dozen of those build one per test rather than per file.
//
// The suites that genuinely read seeded rates set
// `AppDatabase.seedExchangeRatesOnCreate = true` in their own setUpAll. That
// is deliberately the loud direction: with the seed off, a test that depended
// on it fails on an empty table rather than passing on data it never asked
// for.
import 'dart:async';

import 'package:my_budget_client/core/database/app_database.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppDatabase.seedExchangeRatesOnCreate = false;
  await testMain();
}
