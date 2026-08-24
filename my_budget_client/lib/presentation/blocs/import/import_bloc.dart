import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:my_budget_client/core/utils/import_file_data.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'package:my_budget_client/core/constants/app_constants.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/category_type.dart';
import 'package:my_budget_client/domain/entities/currency.dart';
import 'package:my_budget_client/domain/entities/currency_designation.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/currency_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';
import 'package:uuid/uuid.dart';

part 'import_event.dart';
part 'import_state.dart';

class ImportBloc extends Bloc<ImportEvent, ImportState> {
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;
  final CurrencyRepository _currencyRepository;

  ImportBloc({
    required AccountRepository accountRepository,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
    required CurrencyRepository currencyRepository,
  }) : _accountRepository = accountRepository,
       _categoryRepository = categoryRepository,
       _transactionRepository = transactionRepository,
       _currencyRepository = currencyRepository,
       super(const ImportState()) {
    on<StartImportProcess>(_onStartImportProcess);
    on<MapAccount>(_onMapAccount);
    on<MapCategory>(_onMapCategory);
    on<MapCurrency>(_onMapCurrency);
    on<ProceedToNextStep>(_onProceedToNextStep);
    on<ResolveDuplicate>(_onResolveDuplicate);
    on<FinalizeImport>(_onFinalizeImport);
    on<ResetImport>(_onResetImport);
  }

  /// Everything a row says, so that two rows only count as the same row when
  /// they really are.
  ///
  /// Deduplication used to key on date, amount, from and to alone. That is not
  /// what makes a transaction distinct: the same amount can leave the same
  /// account for the same category twice in one day - two fares, two coffees -
  /// and the two rows differ only in their note, if at all. It also ignored the
  /// currency, so 100 USD and 100 EUR spent on the same day collapsed into one.
  /// Every row dropped that way is money the import loses without saying so.
  ///
  /// The unit separator joins the fields because a note can hold a comma, a
  /// dash or a newline, but not a control character the CSV never carries.
  static String _recordKey(OneMoneyRecord r) => [
    r.date.toIso8601String(),
    r.type,
    r.from,
    r.to,
    r.amount,
    r.currency,
    r.amount2 ?? '',
    r.currency2 ?? '',
    r.notes,
  ].join('');

  /// The sign the app stores, whichever sign the file wrote.
  ///
  /// A OneMoney export writes an expense as a negative number, and the import
  /// negated it again: every expense arrived as income, so a statement full of
  /// spending put money into the account it was spent from and the balance the
  /// same file states was nowhere near the one the app computed. Other exports
  /// write the same row positive, so the sign in the file is not something to
  /// trust in either direction - the row's type is what says which way the
  /// money went.
  /// The currency code a row is written under.
  ///
  /// The mapping step stores a decision, not always a code: choosing to make
  /// a currency out of the one the file names records the string 'new'. Read
  /// back as though it were a code, that decision became the row's currency -
  /// transactions were stored under a currency called NEW, and the account
  /// holding them fell back to whichever currency happened to be first in the
  /// list. A row the user asked to keep as its own currency keeps the code the
  /// file gave it, which is the code the import then creates.
  String _mappedCurrency(String fileCurrency) {
    final decision = state.currencyMappings[fileCurrency.trim().toLowerCase()];
    return decision == null || decision == 'new' ? fileCurrency : decision;
  }

  /// What a transaction is described as: the note on the row when it carries
  /// one, [fallback] when it does not.
  static String _describe(String notes, String fallback) {
    final note = notes.trim();
    final description = note.isEmpty ? fallback : note;
    return description.length > 100
        ? description.substring(0, 100)
        : description;
  }
  static double _signedAmount(String type, double amount) =>
      type.trim().toLowerCase() == 'expense' ? -amount.abs() : amount.abs();

  String _getCategoryKey(String name, String type) {
    return '${name.trim().toLowerCase()}_${type.trim().toLowerCase()}';
  }

  String _getCategoryDisplayName(String name, String type) {
    final typeClean = type.trim().toLowerCase();
    final typeDisplay = typeClean[0].toUpperCase() + typeClean.substring(1);
    return '$name ($typeDisplay)';
  }

  Future<void> _onStartImportProcess(
    StartImportProcess event,
    Emitter<ImportState> emit,
  ) async {
    emit(const ImportState(step: ImportStep.parsing));

    try {
      final allRecords = <OneMoneyRecord>[];
      final allBalances = <AccountBalanceRecord>[];
      // How many times a row appears in the single file that repeats it most.
      // See [_recordKey] for why the count, and not just the key, is what the
      // deduplication is allowed to work from.
      final mostInOneFile = <String, int>{};
      for (final file in event.files) {
        final parsedData = await ImportDataUtils.parseOneMoneyCsv(file);
        final inThisFile = <String, int>{};
        for (final record in parsedData.records) {
          final key = _recordKey(record);
          inThisFile[key] = (inThisFile[key] ?? 0) + 1;
        }
        inThisFile.forEach((key, count) {
          if (count > (mostInOneFile[key] ?? 0)) mostInOneFile[key] = count;
        });
        allRecords.addAll(parsedData.records);
        allBalances.addAll(parsedData.accountBalances);
      }

      // Rows are kept in the order they were read, so the import still reads
      // like the statement it came from.
      final uniqueRecords = <OneMoneyRecord>[];
      final kept = <String, int>{};
      for (final record in allRecords) {
        final key = _recordKey(record);
        final already = kept[key] ?? 0;
        if (already >= (mostInOneFile[key] ?? 0)) continue;
        kept[key] = already + 1;
        uniqueRecords.add(record);
      }

      final uniqueBalances = <String, AccountBalanceRecord>{};
      for (var b in allBalances) {
        uniqueBalances[b.name.trim().toLowerCase()] = b;
      }

      emit(
        state.copyWith(
          files: event.files,
          parsedRecords: uniqueRecords,
          parsedBalances: uniqueBalances.values.toList(),
          step: ImportStep.mappingAccounts,
        ),
      );

      add(ProceedToNextStep());
    } catch (e) {
      emit(
        state.copyWith(step: ImportStep.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onMapAccount(
    MapAccount event,
    Emitter<ImportState> emit,
  ) async {
    final newMappings = Map<String, String>.from(state.accountMappings);
    newMappings[event.csvAccountName] = event.decision;

    final newUnmapped = Set<String>.from(state.unmappedAccounts);
    newUnmapped.remove(event.csvAccountName);

    emit(
      state.copyWith(
        accountMappings: newMappings,
        unmappedAccounts: newUnmapped,
      ),
    );

    if (newUnmapped.isEmpty) {
      add(ProceedToNextStep());
    }
  }

  Future<void> _onMapCategory(
    MapCategory event,
    Emitter<ImportState> emit,
  ) async {
    final newMappings = Map<String, String>.from(state.categoryMappings);
    newMappings[event.csvCategoryName] = event.decision;

    final newUnmapped = Map<String, String>.from(state.unmappedCategories);
    newUnmapped.remove(event.csvCategoryName);

    emit(
      state.copyWith(
        categoryMappings: newMappings,
        unmappedCategories: newUnmapped,
      ),
    );

    if (newUnmapped.isEmpty) {
      add(ProceedToNextStep());
    }
  }

  Future<void> _onMapCurrency(
    MapCurrency event,
    Emitter<ImportState> emit,
  ) async {
    final newMappings = Map<String, String>.from(state.currencyMappings);
    newMappings[event.csvCurrencyName] = event.decision;

    final newUnmapped = Set<String>.from(state.unmappedCurrencies);
    newUnmapped.remove(event.csvCurrencyName);

    emit(
      state.copyWith(
        currencyMappings: newMappings,
        unmappedCurrencies: newUnmapped,
      ),
    );

    if (newUnmapped.isEmpty) {
      add(ProceedToNextStep());
    }
  }

  Future<void> _onResolveDuplicate(
    ResolveDuplicate event,
    Emitter<ImportState> emit,
  ) async {
    final newResolutions = Map<OneMoneyRecord, String>.from(
      state.duplicateResolutions,
    );
    newResolutions[event.record] = event.decision;

    emit(state.copyWith(duplicateResolutions: newResolutions));

    if (newResolutions.length == state.potentialDuplicates.length) {
      emit(state.copyWith(step: ImportStep.readyToImport));
    }
  }

  Future<void> _onProceedToNextStep(
    ProceedToNextStep event,
    Emitter<ImportState> emit,
  ) async {
    if (state.step == ImportStep.mappingAccounts) {
      final existingAccounts = await _accountRepository.getAccounts();
      final existingAccountNames = existingAccounts
          .map((a) => a.name.trim().toLowerCase())
          .toSet();
      final csvAccountNames = state.parsedRecords
          .map((r) => r.from.trim().toLowerCase())
          .toSet();

      final mappedInSession = state.accountMappings.keys
          .map((k) => k.trim().toLowerCase())
          .toSet();
      final unmapped = csvAccountNames
          .where(
            (name) =>
                !existingAccountNames.contains(name) &&
                !mappedInSession.contains(name) &&
                name.isNotEmpty,
          )
          .toSet();

      if (unmapped.isEmpty) {
        emit(state.copyWith(step: ImportStep.mappingCategories));
        add(ProceedToNextStep());
      } else {
        emit(state.copyWith(unmappedAccounts: unmapped));
      }
    } else if (state.step == ImportStep.mappingCategories) {
      final existingCategories = await _categoryRepository.getCategories();

      // 1. Build a Set of existing keys (Name + Type)
      final existingCategoryKeys = existingCategories.map((c) {
        final typeStr = c.type == CategoryType.income ? 'income' : 'expense';
        return _getCategoryKey(c.name, typeStr);
      }).toSet();

      // 2. Parse CSV Categories into Unique Keys
      // Key: "salary_income", Value: "Salary" (Original Name)
      final csvCategoryOriginalNames = <String, String>{};
      // Key: "salary_income", Value: "income" (Type)
      final csvCategoryTypes = <String, String>{};

      for (final record in state.parsedRecords) {
        final recordType = record.type.toLowerCase();
        if (recordType == 'expense' || recordType == 'income') {
          final categoryName = record.to.trim();
          if (categoryName.isNotEmpty) {
            final key = _getCategoryKey(categoryName, recordType);
            csvCategoryOriginalNames[key] = categoryName;
            csvCategoryTypes[key] = recordType;
          }
        }
      }

      final mappedInSession = state.categoryMappings.keys
          .toSet(); // keys are now "name_type"

      // 3. Prepare Unmapped List
      final unmapped = <String, String>{};

      csvCategoryOriginalNames.forEach((key, originalName) {
        // If not in DB AND not mapped yet
        if (!existingCategoryKeys.contains(key) &&
            !mappedInSession.contains(key)) {
          final type = csvCategoryTypes[key]!;
          // We set the VALUE to "Salary (Income)" so the user sees the difference
          unmapped[key] = _getCategoryDisplayName(originalName, type);
        }
      });

      if (unmapped.isEmpty) {
        emit(
          state.copyWith(
            step: ImportStep.mappingCurrencies,
            parsedCategoryDetails: csvCategoryTypes, // We need this later
          ),
        );
        add(ProceedToNextStep());
      } else {
        emit(
          state.copyWith(
            unmappedCategories: unmapped,
            parsedCategoryDetails: csvCategoryTypes,
          ),
        );
      }
    } else if (state.step == ImportStep.mappingCurrencies) {
      final existingCurrencies = await _currencyRepository.getCurrencies();
      final existingCurrencyCodes = existingCurrencies
          .map((c) => c.code.trim().toLowerCase())
          .toSet();
      final csvCurrencyCodes = state.parsedRecords
          .map((r) => r.currency.trim().toLowerCase())
          .toSet();

      final mappedInSession = state.currencyMappings.keys
          .map((k) => k.trim().toLowerCase())
          .toSet();
      final unmapped = csvCurrencyCodes
          .where(
            (code) =>
                !existingCurrencyCodes.contains(code) &&
                !mappedInSession.contains(code) &&
                code.isNotEmpty,
          )
          .toSet();

      if (unmapped.isEmpty) {
        emit(state.copyWith(step: ImportStep.resolvingDuplicates));
        add(ProceedToNextStep());
      } else {
        emit(state.copyWith(unmappedCurrencies: unmapped));
      }
    } else if (state.step == ImportStep.resolvingDuplicates) {
      final existingTransactions = await _transactionRepository
          .getTransactionsWithFilters(limit: 100000);
      // Day, amount and currency: a transaction already in the database is
      // only a candidate for the same transaction when all three agree. The
      // currency was missing from this, so 100 EUR already recorded made a
      // 100 USD row from the file look like a repeat of it, and the import
      // stopped to ask about a row nobody had entered twice.
      String signatureOf(DateTime date, double amount, String currency) =>
          '${date.toIso8601String().substring(0, 10)}'
          '-${amount.toStringAsFixed(2)}'
          '-${currency.trim().toUpperCase()}';

      final Set<String> existingTransactionSignatures = existingTransactions
          .map((t) => signatureOf(t.date, t.amount, t.currencyCode))
          .toSet();

      final potentialDuplicates = <OneMoneyRecord>[];

      for (final record in state.parsedRecords) {
        final recordAmount = _signedAmount(record.type, record.amount);
        // The code the row will be written under, which is what the database
        // already holds for a row imported from an earlier copy of this file.
        final recordCurrency = _mappedCurrency(record.currency);
        final signature = signatureOf(
          record.date,
          recordAmount,
          recordCurrency,
        );

        if (existingTransactionSignatures.contains(signature)) {
          potentialDuplicates.add(record);
        }
      }

      if (potentialDuplicates.isEmpty) {
        emit(state.copyWith(step: ImportStep.readyToImport));
      } else {
        emit(state.copyWith(potentialDuplicates: potentialDuplicates));
      }
    }
  }

  Future<void> _onFinalizeImport(
    FinalizeImport event,
    Emitter<ImportState> emit,
  ) async {
    emit(state.copyWith(step: ImportStep.importing, progress: 0.0));

    try {
      final uuid = Uuid();

      // --- OPTIMIZATION: Pre-group CSV records by account name (O(N) instead of O(N×M)) ---
      final recordsByAccountName = <String, List<OneMoneyRecord>>{};
      for (final record in state.parsedRecords) {
        final accountKey = record.from.trim().toLowerCase();
        recordsByAccountName.putIfAbsent(accountKey, () => []).add(record);
      }

      // --- 1. CURRENCIES (No Changes) ---
      final newCurrencyCodes = state.currencyMappings.entries
          .where((e) => e.value == 'new')
          .map((e) => e.key)
          .toList();

      for (final code in newCurrencyCodes) {
        await _currencyRepository.addCurrency(
          Currency(
            name: code.toUpperCase(),
            code: code.toUpperCase(),
            languageCode: 'en',
            type: TypeCurrency.other,
          ),
        );
        await _currencyRepository.addCurrencyDesignation(
          CurrencyDesignation(
            id: uuid.v4(),
            value: code.toUpperCase(),
            currencyCode: code.toUpperCase(),
          ),
        );
      }

      // --- 2. ACCOUNTS (No Changes) ---
      final newAccountNames = state.accountMappings.entries
          .where((e) => e.value == 'new')
          .map((e) => e.key)
          .toList();

      final parsedBalancesMap = {
        for (var b in state.parsedBalances) b.name.trim().toLowerCase(): b,
      };

      final newAccounts = <Account>[];
      final allCurrencies = await _currencyRepository.getCurrencies();
      final allDesignations = await _currencyRepository
          .getAllCurrencyDesignations();
      final allAccountTypes = await _accountRepository.getAccountTypes();

      // Use stable IDs for checking account type, fallback to 'default_cash'
      final defaultAccountType = allAccountTypes.firstWhere(
        (t) =>
            t.id == 'default_card' || t.name.toLowerCase().contains('checking'),
        orElse: () => allAccountTypes.firstWhere(
          (t) => t.id == 'default_cash',
          orElse: () => allAccountTypes.first,
        ),
      );

      for (final name in newAccountNames) {
        // Use pre-grouped records instead of filtering
        final accountRecords =
            recordsByAccountName[name.trim().toLowerCase()] ?? [];

        if (accountRecords.isEmpty) continue;

        accountRecords.sort((a, b) => a.date.compareTo(b.date));
        final earliestRecord = accountRecords.first;

        final currencyCode = _mappedCurrency(earliestRecord.currency);
        final currency = allCurrencies.firstWhere(
          (c) => c.code.toLowerCase() == currencyCode.toLowerCase(),
          orElse: () => allCurrencies.first,
        );
        final designation = allDesignations.firstWhere(
          (d) => d.currencyCode.toLowerCase() == currency.code.toLowerCase(),
          orElse: () => allDesignations.first,
        );
        final initialBalance =
            parsedBalancesMap[name.trim().toLowerCase()]?.balance ?? 0.0;

        newAccounts.add(
          Account(
            name: name,
            balance: initialBalance,
            currencyCode: currency.code,
            currencyDesignationId: designation.id,
            accountTypeId: defaultAccountType.id,
            creationDate: earliestRecord.date,
          ),
        );
      }

      if (newAccounts.isNotEmpty) {
        await _accountRepository.addAccounts(newAccounts);
      }
      emit(
        state.copyWith(progress: 0.2, createdAccountsCount: newAccounts.length),
      );

      // --- 3. CATEGORIES (FIXED) ---
      final newCategoryKeys = state.categoryMappings.entries
          .where((e) => e.value == 'new')
          .map((e) => e.key) // keys are "name_type"
          .toList();

      final newCategories = newCategoryKeys.map((key) {
        // Retrieve the type we stored earlier
        final typeString = state.parsedCategoryDetails[key] ?? 'expense';
        final type = typeString.toLowerCase() == 'income'
            ? CategoryType.income
            : CategoryType.expense;

        // Extract original name from the Key (assuming key is "name_type")
        // NOTE: A safer way is to store the original name map in state,
        // but splitting the key works if your delimiter (_) is safe.
        final lastUnderscoreIndex = key.lastIndexOf('_');
        final originalNameClean = key.substring(0, lastUnderscoreIndex);
        // Capitalize for display
        final nameDisplay =
            originalNameClean[0].toUpperCase() + originalNameClean.substring(1);

        return Category(
          // HERE IS THE CHANGE: Save as "Salary (Income)"
          name: _getCategoryDisplayName(nameDisplay, typeString),
          type: type,
          styleId: type == CategoryType.income
              ? 'style_other_income'
              : 'style_other_expense',
        );
      }).toList();

      if (newCategories.isNotEmpty) {
        await _categoryRepository.addCategories(newCategories);
      }
      emit(
        state.copyWith(
          progress: 0.4,
          createdCategoriesCount: newCategories.length,
        ),
      );

      // --- 4. PREPARE LOOKUPS (FIXED) ---
      final allAccounts = await _accountRepository.getAccounts();
      var allCategories = await _categoryRepository.getCategories(
        includeSystem: true,
      );

      // Handle Transfer Category
      var transferCategory = allCategories.firstWhereOrNull(
        (c) => c.name == AppConstants.systemTransferCategoryName,
      );
      if (transferCategory == null) {
        final newCategory = Category(
          name: AppConstants.systemTransferCategoryName,
          type: CategoryType.transfer,
          styleId: 'style_transfer',
        );
        await _categoryRepository.addCategory(newCategory);
        allCategories = await _categoryRepository.getCategories(
          includeSystem: true,
        );
        // Named rather than `firstWhere`: the import is inside a try whose
        // catch puts the exception text on the failure screen, and a bare
        // `Bad state: No element` there says nothing about what went wrong.
        transferCategory = allCategories.firstWhereOrNull(
          (c) => c.name == AppConstants.systemTransferCategoryName,
        );
        if (transferCategory == null) {
          throw StateError(
            'The transfer category could not be created, so transfers have '
            'nowhere to go.',
          );
        }
      }

      final accountIdMap = {
        for (var a in allAccounts) a.name.trim().toLowerCase(): a.id!,
      };

      // Build Category ID Map using Unique Keys
      final categoryIdMap = <String, String>{};
      for (var c in allCategories) {
        final typeStr = c.type == CategoryType.income ? 'income' : 'expense';

        // We match strictly by Name + Type
        // If the DB has "Salary (Income)", the key is "salary (income)_income"
        // If the DB has "Salary", the key is "salary_income"
        // We need to support the CSV matching "Salary" to "Salary (Income)"

        final keyStrict = _getCategoryKey(c.name, typeStr);
        categoryIdMap[keyStrict] = c.id!;

        // Special handling: If the DB name contains brackets like " (Income)",
        // we also want to map the "clean" CSV name to this ID.
        if (c.name.toLowerCase().contains('($typeStr)')) {
          final cleanName = c.name
              .toLowerCase()
              .replaceAll('($typeStr)', '')
              .trim();
          final keyClean = _getCategoryKey(cleanName, typeStr);
          categoryIdMap[keyClean] = c.id!;
        }
      }

      // --- 5. TRANSACTIONS (FIXED) ---
      int skippedCount = 0;
      final transactionsToInsert = <Transaction>[];

      for (final record in state.parsedRecords) {
        final resolution = state.duplicateResolutions[record];
        if (resolution == 'skip') {
          skippedCount++;
          continue;
        }

        if (record.type.toLowerCase() == 'transfer') {
          // Transfer Logic - Add linkedTransactionId to link the two transactions
          final fromAccountId = accountIdMap[record.from.trim().toLowerCase()];
          final toAccountId = accountIdMap[record.to.trim().toLowerCase()];
          if (fromAccountId != null && toAccountId != null) {
            // Generate IDs for both transactions to link them
            final debitTransactionId = uuid.v4();
            final creditTransactionId = uuid.v4();
            // The note on the row is the only part of it the user wrote.
            // Both legs were described in English by the account they
            // touched instead, and whatever the row said was dropped -
            // the one transfer a person would recognise their own words
            // on came back as 'Transfer to Savings'.
            final debitDescription = _describe(
              record.notes,
              'Transfer to ${record.to}',
            );
            final creditDescription = _describe(
              record.notes,
              'Transfer from ${record.from}',
            );

            transactionsToInsert.add(
              Transaction(
                id: debitTransactionId,
                date: record.date,
                description: debitDescription,
                amount: -record.amount.abs(),
                accountId: fromAccountId,
                categoryId: transferCategory.id!,
                currencyCode: _mappedCurrency(
                  record.currency,
                ).toUpperCase(),
                linkedTransactionId:
                    creditTransactionId, // Link to credit transaction
              ),
            );
            final creditAmount = (record.amount2 ?? record.amount).abs();
            final creditCurrency = record.currency2?.isNotEmpty == true
                ? record.currency2!
                : record.currency;
            transactionsToInsert.add(
              Transaction(
                id: creditTransactionId,
                date: record.date,
                description: creditDescription,
                amount: creditAmount,
                accountId: toAccountId,
                categoryId: transferCategory.id!,
                currencyCode: _mappedCurrency(
                  creditCurrency,
                ).toUpperCase(),
                linkedTransactionId:
                    debitTransactionId, // Link to debit transaction
              ),
            );
          }
        } else {
          final accountId = accountIdMap[record.from.trim().toLowerCase()];

          // GENERATE KEY to find category
          final recordType = record.type.toLowerCase();
          final categoryKey = _getCategoryKey(record.to, recordType);

          final categoryId = categoryIdMap[categoryKey];

          if (accountId != null && categoryId != null) {
            final description = _describe(record.notes, record.to);

            final currencyCode = _mappedCurrency(
              record.currency,
            ).toUpperCase();

            transactionsToInsert.add(
              Transaction(
                date: record.date,
                description: description,
                amount: _signedAmount(record.type, record.amount),
                accountId: accountId,
                categoryId:
                    categoryId, // Uses correct ID for that specific Type
                currencyCode: currencyCode,
              ),
            );
          } else {
            if (accountId == null) {
              debugPrint('Unmapped Account: ${record.from}');
            }
            if (categoryId == null) {
              debugPrint('Unmapped Category: ${record.to} ($recordType)');
            }
          }
        }
      }

      emit(state.copyWith(progress: 0.7, skippedDuplicatesCount: skippedCount));

      if (transactionsToInsert.isNotEmpty) {
        await _transactionRepository.addTransactions(transactionsToInsert);
      }

      // --- 6. UPDATE BALANCES AND CREATION DATE ---
      final allDbAccounts = await _accountRepository.getAccounts();
      for (final account in allDbAccounts) {
        final accountNameNormalized = account.name.trim().toLowerCase();

        // Use pre-grouped records instead of filtering
        final accountRecords =
            recordsByAccountName[accountNameNormalized] ?? [];

        DateTime? newCreationDate;
        if (accountRecords.isNotEmpty) {
          accountRecords.sort((a, b) => a.date.compareTo(b.date));
          final earliestDate = accountRecords.first.date;
          if (earliestDate.isBefore(account.creationDate)) {
            newCreationDate = earliestDate;
          }
        }

        final parsedBalance = parsedBalancesMap[accountNameNormalized];

        bool needsUpdate = false;
        Account updatedAccount = account;

        if (parsedBalance != null && account.balance != parsedBalance.balance) {
          updatedAccount = updatedAccount.copyWith(
            balance: parsedBalance.balance,
          );
          needsUpdate = true;
        }

        if (newCreationDate != null) {
          updatedAccount = updatedAccount.copyWith(
            creationDate: newCreationDate,
          );
          needsUpdate = true;
        }

        if (needsUpdate) {
          await _accountRepository.updateAccount(updatedAccount);
        }
      }

      emit(
        state.copyWith(
          step: ImportStep.complete,
          progress: 1.0,
          importedTransactionsCount: transactionsToInsert.length,
        ),
      );
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrint(s.toString());
      emit(
        state.copyWith(step: ImportStep.failure, errorMessage: e.toString()),
      );
    }
  }

  void _onResetImport(ResetImport event, Emitter<ImportState> emit) {
    emit(const ImportState());
  }
}
