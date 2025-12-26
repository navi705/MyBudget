import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:my_budget_client/core/utils/import_utils.dart';
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
  })  : _accountRepository = accountRepository,
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
        for (var r in allRecords) '${r.date}-${r.amount}-${r.from}-${r.to}': r
      }.values.toList();

      final uniqueBalances = <String, AccountBalanceRecord>{};
      for (var b in allBalances) {
        uniqueBalances[b.name.trim().toLowerCase()] = b;
      }

      emit(state.copyWith(
        files: event.files,
        parsedRecords: uniqueRecords,
        parsedBalances: uniqueBalances.values.toList(),
        step: ImportStep.mappingAccounts,
      ));

      add(ProceedToNextStep());
    } catch (e) {
      emit(state.copyWith(step: ImportStep.failure, errorMessage: e.toString()));
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

    emit(state.copyWith(
      accountMappings: newMappings,
      unmappedAccounts: newUnmapped,
    ));

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

    emit(state.copyWith(
      categoryMappings: newMappings,
      unmappedCategories: newUnmapped,
    ));

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

    emit(state.copyWith(
      currencyMappings: newMappings,
      unmappedCurrencies: newUnmapped,
    ));

    if (newUnmapped.isEmpty) {
      add(ProceedToNextStep());
    }
  }
  
  Future<void> _onResolveDuplicate(
    ResolveDuplicate event,
    Emitter<ImportState> emit,
  ) async {
    final newResolutions = Map<OneMoneyRecord, String>.from(state.duplicateResolutions);
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
      final existingAccountNames = existingAccounts.map((a) => a.name.trim().toLowerCase()).toSet();
      final csvAccountNames = state.parsedRecords.map((r) => r.from.trim().toLowerCase()).toSet();
      
      final mappedInSession = state.accountMappings.keys.map((k) => k.trim().toLowerCase()).toSet();
      final unmapped = csvAccountNames.where((name) => !existingAccountNames.contains(name) && !mappedInSession.contains(name) && name.isNotEmpty).toSet();

      if (unmapped.isEmpty) {
        emit(state.copyWith(step: ImportStep.mappingCategories));
        add(ProceedToNextStep());
      } else {
        emit(state.copyWith(unmappedAccounts: unmapped));
      }

    } else if (state.step == ImportStep.mappingCategories) {
      final existingCategories = await _categoryRepository.getCategories();
      final existingCategoryNames = existingCategories.map((c) => c.name.trim().toLowerCase()).toSet();
      
      final csvCategories = <String, String>{};
      for (final record in state.parsedRecords) {
        final recordType = record.type.toLowerCase();
        if (recordType == 'expense' || recordType == 'income') {
          final categoryName = record.to.trim().toLowerCase();
          if (categoryName.isNotEmpty) {
            csvCategories[categoryName] = record.type;
          }
        }
      }

      final mappedInSession = state.categoryMappings.keys.map((k) => k.trim().toLowerCase()).toSet();
      
      final unmapped = <String, String>{};
      csvCategories.forEach((name, type) {
        if (!existingCategoryNames.contains(name) && !mappedInSession.contains(name)) {
          unmapped[name] = type;
        }
      });

      if (unmapped.isEmpty) {
        emit(state.copyWith(
          step: ImportStep.mappingCurrencies,
          parsedCategoryDetails: csvCategories,
        ));
        add(ProceedToNextStep());
      } else {
        emit(state.copyWith(
          unmappedCategories: unmapped,
          parsedCategoryDetails: csvCategories,
        ));
      }
    } else if (state.step == ImportStep.mappingCurrencies) {
      final existingCurrencies = await _currencyRepository.getCurrencies();
      final existingCurrencyCodes = existingCurrencies.map((c) => c.code.trim().toLowerCase()).toSet();
      final csvCurrencyCodes = state.parsedRecords.map((r) => r.currency.trim().toLowerCase()).toSet();

      final mappedInSession = state.currencyMappings.keys.map((k) => k.trim().toLowerCase()).toSet();
      final unmapped = csvCurrencyCodes.where((code) => !existingCurrencyCodes.contains(code) && !mappedInSession.contains(code) && code.isNotEmpty).toSet();

      if (unmapped.isEmpty) {
        emit(state.copyWith(step: ImportStep.resolvingDuplicates));
        add(ProceedToNextStep());
      } else {
        emit(state.copyWith(unmappedCurrencies: unmapped));
      }
    } else if (state.step == ImportStep.resolvingDuplicates) {
      final existingTransactions = await _transactionRepository.getTransactionsWithFilters(limit: 100000);
      final Set<String> existingTransactionSignatures = existingTransactions.map((t) => '${t.date.toIso8601String().substring(0, 10)}-${t.amount.toStringAsFixed(2)}').toSet();
      
      final potentialDuplicates = <OneMoneyRecord>[];

      for (final record in state.parsedRecords) {
        final recordAmount = record.type == 'Expense' ? -record.amount : record.amount;
        final signature = '${record.date.toIso8601String().substring(0, 10)}-${recordAmount.toStringAsFixed(2)}';
        
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
      final newCurrencyCodes = state.currencyMappings.entries
          .where((e) => e.value == 'new')
          .map((e) => e.key)
          .toList();
      
      for (final code in newCurrencyCodes) {
        await _currencyRepository.addCurrency(Currency(
          name: code.toUpperCase(),
          code: code.toUpperCase(),
          languageCode: 'en',
        ));
        await _currencyRepository.addCurrencyDesignation(CurrencyDesignation(
          id: uuid.v4(),
          value: code.toUpperCase(),
          currencyCode: code.toUpperCase(),
        ));
      }

      final newAccountNames = state.accountMappings.entries
          .where((e) => e.value == 'new')
          .map((e) => e.key)
          .toList();
      
      final parsedBalancesMap = {
        for (var b in state.parsedBalances) b.name.trim().toLowerCase(): b
      };

      final newAccounts = <Account>[];
      final allCurrencies = await _currencyRepository.getCurrencies();
      final allDesignations = await _currencyRepository.getAllCurrencyDesignations();

      for (final name in newAccountNames) {
        final record = state.parsedRecords.firstWhere((r) => r.from.trim().toLowerCase() == name.trim().toLowerCase());
        final currencyCode = state.currencyMappings[record.currency.toLowerCase()] ?? record.currency;
        final currency = allCurrencies.firstWhere((c) => c.code.toLowerCase() == currencyCode.toLowerCase(), orElse: () => allCurrencies.first);
        final designation = allDesignations.firstWhere((d) => d.currencyCode.toLowerCase() == currency.code.toLowerCase(), orElse: () => allDesignations.first);
        final initialBalance = parsedBalancesMap[name.trim().toLowerCase()]?.balance ?? 0.0;

        newAccounts.add(Account(
          name: name,
          balance: initialBalance,
          currencyCode: currency.code,
          currencyDesignationId: designation.id, 
          accountTypeId: '1', // default to something, maybe 'Cash'
          creationDate: DateTime.now(),
        ));
      }

      if (newAccounts.isNotEmpty) {
        await _accountRepository.addAccounts(newAccounts);
      }
      emit(state.copyWith(progress: 0.2, createdAccountsCount: newAccounts.length));

      final newCategoryNames = state.categoryMappings.entries
        .where((e) => e.value == 'new')
        .map((e) => e.key)
        .toList();

      final newCategories = newCategoryNames.map((name) {
        final typeString = state.parsedCategoryDetails[name.toLowerCase()];
        final type = typeString?.toLowerCase() == 'income' ? CategoryType.income : CategoryType.expense;
        return Category(
          name: name,
          type: type,
        );
      }).toList();
      
      if (newCategories.isNotEmpty) {
        await _categoryRepository.addCategories(newCategories);
      }
      emit(state.copyWith(progress: 0.4, createdCategoriesCount: newCategories.length));

      final allAccounts = await _accountRepository.getAccounts();
      var allCategories = await _categoryRepository.getCategories();
      var transferCategory = allCategories.firstWhereOrNull((c) => c.name == 'Transfer');
      if (transferCategory == null) {
        final newCategory = Category(name: 'Transfer', type: CategoryType.transfer);
        await _categoryRepository.addCategory(newCategory);
        allCategories = await _categoryRepository.getCategories();
        transferCategory = allCategories.firstWhere((c) => c.name == 'Transfer');
      }

      final accountIdMap = {for (var a in allAccounts) a.name.trim().toLowerCase(): a.id!};
      final categoryIdMap = {for (var c in allCategories) c.name.trim().toLowerCase(): c.id!};

      int skippedCount = 0;
      final transactionsToInsert = <Transaction>[];
      for (final record in state.parsedRecords) {
        final resolution = state.duplicateResolutions[record];
        if (resolution == 'skip') {
          skippedCount++;
          continue;
        }

        if (record.type.toLowerCase() == 'transfer') {
          final fromAccountId = accountIdMap[record.from.trim().toLowerCase()];
          final toAccountId = accountIdMap[record.to.trim().toLowerCase()];

          if (fromAccountId != null && toAccountId != null) {
            transactionsToInsert.add(Transaction(
              date: record.date,
              description: 'Transfer to ${record.to}',
              amount: -record.amount,
              accountId: fromAccountId,
              categoryId: transferCategory.id!,
              currencyCode: record.currency,
            ));
            
            final creditAmount = record.amount2 ?? record.amount;
            final creditCurrency = record.currency2?.isNotEmpty == true ? record.currency2! : record.currency;

            transactionsToInsert.add(Transaction(
              date: record.date,
              description: 'Transfer from ${record.from}',
              amount: creditAmount,
              accountId: toAccountId,
              categoryId: transferCategory.id!,
              currencyCode: creditCurrency,
            ));
          }
        } else {
          final accountId = accountIdMap[record.from.trim().toLowerCase()];
          final categoryId = categoryIdMap[record.to.trim().toLowerCase()];

          if (accountId != null && categoryId != null) {
            var description = record.notes.isNotEmpty ? record.notes : record.to;
            if (description.length > 100) {
              description = description.substring(0, 100);
            }
            
            final currencyCode = state.currencyMappings[record.currency.toLowerCase()] ?? record.currency;

            transactionsToInsert.add(Transaction(
              date: record.date,
              description: description,
              amount: record.type.toLowerCase() == 'expense' ? -record.amount : record.amount,
              accountId: accountId,
              categoryId: categoryId,
              currencyCode: currencyCode,
            ));
          } else {
            if (record.type.toLowerCase() != 'transfer') {
              if (accountId == null) {
                debugPrint('Skipping transaction due to unmapped account: "${record.from}"');
              }
              if (categoryId == null) {
                debugPrint('Skipping transaction due to unmapped category: "${record.to}"');
              }
            }
          }
        }
      }
      emit(state.copyWith(progress: 0.7, skippedDuplicatesCount: skippedCount));

      if (transactionsToInsert.isNotEmpty) {
        await _transactionRepository.addTransactions(transactionsToInsert);
      }

      final allDbAccounts = await _accountRepository.getAccounts();
      for (final account in allDbAccounts) {
        final parsedBalance = parsedBalancesMap[account.name.trim().toLowerCase()];
        if (parsedBalance != null && account.balance != parsedBalance.balance) {
          await _accountRepository.updateAccount(account.copyWith(balance: parsedBalance.balance));
        }
      }

      emit(state.copyWith(
        step: ImportStep.complete,
        progress: 1.0,
        importedTransactionsCount: transactionsToInsert.length,
      ));

    } catch (e) {
      emit(state.copyWith(step: ImportStep.failure, errorMessage: e.toString()));
    }
  }

  void _onResetImport(
    ResetImport event,
    Emitter<ImportState> emit,
  ) {
    emit(const ImportState());
  }
}
