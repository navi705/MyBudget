import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
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
      List<OneMoneyRecord> allRecords = [];
      List<AccountBalanceRecord> allBalances = [];
      for (final file in event.files) {
        final parsedData = await ImportDataUtils.parseOneMoneyCsv(file.path!);
        allRecords.addAll(parsedData.records);
        allBalances.addAll(parsedData.accountBalances);
      }

      final uniqueRecords = {
        for (var r in allRecords) '${r.date}-${r.amount}-${r.from}-${r.to}': r,
      }.values.toList();

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
      final Set<String> existingTransactionSignatures = existingTransactions
          .map(
            (t) =>
                '${t.date.toIso8601String().substring(0, 10)}-${t.amount.toStringAsFixed(2)}',
          )
          .toSet();

      final potentialDuplicates = <OneMoneyRecord>[];

      for (final record in state.parsedRecords) {
        final recordAmount = record.type == 'Expense'
            ? -record.amount
            : record.amount;
        final signature =
            '${record.date.toIso8601String().substring(0, 10)}-${recordAmount.toStringAsFixed(2)}';

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

      // Fallback to the first available type if 'checking' isn't found, avoiding '1' which is invalid.
      final defaultAccountType = allAccountTypes.firstWhere(
        (t) => t.name.toLowerCase().contains('checking'),
        orElse: () => allAccountTypes.first,
      );

      for (final name in newAccountNames) {
        final accountRecords = state.parsedRecords
            .where(
              (r) => r.from.trim().toLowerCase() == name.trim().toLowerCase(),
            )
            .toList();

        if (accountRecords.isEmpty) continue;

        accountRecords.sort((a, b) => a.date.compareTo(b.date));
        final earliestRecord = accountRecords.first;

        final currencyCode =
            state.currencyMappings[earliestRecord.currency.toLowerCase()] ??
            earliestRecord.currency;
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
        );
        await _categoryRepository.addCategory(newCategory);
        allCategories = await _categoryRepository.getCategories(
          includeSystem: true,
        );
        transferCategory = allCategories.firstWhere(
          (c) => c.name == AppConstants.systemTransferCategoryName,
        );
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

            transactionsToInsert.add(
              Transaction(
                id: debitTransactionId,
                date: record.date,
                description: 'Transfer to ${record.to}',
                amount: -record.amount,
                accountId: fromAccountId,
                categoryId: transferCategory.id!,
                currencyCode: record.currency.toUpperCase(),
                linkedTransactionId:
                    creditTransactionId, // Link to credit transaction
              ),
            );
            final creditAmount = record.amount2 ?? record.amount;
            final creditCurrency = record.currency2?.isNotEmpty == true
                ? record.currency2!
                : record.currency;
            transactionsToInsert.add(
              Transaction(
                id: creditTransactionId,
                date: record.date,
                description: 'Transfer from ${record.from}',
                amount: creditAmount,
                accountId: toAccountId,
                categoryId: transferCategory.id!,
                currencyCode: creditCurrency.toUpperCase(),
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
            var description = record.notes.isNotEmpty
                ? record.notes
                : record.to;
            if (description.length > 100) {
              description = description.substring(0, 100);
            }

            final currencyCode =
                (state.currencyMappings[record.currency.toLowerCase()] ??
                        record.currency)
                    .toUpperCase();

            debugPrint(
              'DEBUG: currency=${record.currency}, mapped=${state.currencyMappings[record.currency.toLowerCase()]}, final=$currencyCode',
            );

            transactionsToInsert.add(
              Transaction(
                date: record.date,
                description: description,
                amount: record.type.toLowerCase() == 'expense'
                    ? -record.amount
                    : record.amount,
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

      // --- 6. UPDATE BALANCES (No Changes) ---
      final allDbAccounts = await _accountRepository.getAccounts();
      for (final account in allDbAccounts) {
        final parsedBalance =
            parsedBalancesMap[account.name.trim().toLowerCase()];
        if (parsedBalance != null && account.balance != parsedBalance.balance) {
          await _accountRepository.updateAccount(
            account.copyWith(balance: parsedBalance.balance),
          );
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
