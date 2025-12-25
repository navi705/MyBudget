import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:my_budget_client/core/utils/import_utils.dart';
import 'package:my_budget_client/domain/entities/account.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/transaction.dart';
import 'package:my_budget_client/domain/repositories/account_repository.dart';
import 'package:my_budget_client/domain/repositories/category_repository.dart';
import 'package:my_budget_client/domain/repositories/transaction_repository.dart';

part 'import_event.dart';
part 'import_state.dart';

class ImportBloc extends Bloc<ImportEvent, ImportState> {
  final AccountRepository _accountRepository;
  final CategoryRepository _categoryRepository;
  final TransactionRepository _transactionRepository;

  ImportBloc({
    required AccountRepository accountRepository,
    required CategoryRepository categoryRepository,
    required TransactionRepository transactionRepository,
  })  : _accountRepository = accountRepository,
        _categoryRepository = categoryRepository,
        _transactionRepository = transactionRepository,
        super(const ImportState()) {
    on<StartImportProcess>(_onStartImportProcess);
    on<MapAccount>(_onMapAccount);
    on<MapCategory>(_onMapCategory);
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
      for (final file in event.files) {
        final records = await ImportDataUtils.parseOneMoneyCsv(file.path!);
        allRecords.addAll(records);
      }

      final uniqueRecords = {
        for (var r in allRecords) '${r.date}-${r.amount}-${r.from}-${r.to}': r
      }.values.toList();
      
      emit(state.copyWith(
        files: event.files,
        parsedRecords: uniqueRecords,
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

    final newUnmapped = Set<String>.from(state.unmappedCategories);
    newUnmapped.remove(event.csvCategoryName);

    emit(state.copyWith(
      categoryMappings: newMappings,
      unmappedCategories: newUnmapped,
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
      final csvCategoryNames = state.parsedRecords
        .where((r) => r.type == 'Расход' || r.type == 'доход')
        .map((r) => r.to.trim().toLowerCase())
        .toSet();

      final mappedInSession = state.categoryMappings.keys.map((k) => k.trim().toLowerCase()).toSet();
      final unmapped = csvCategoryNames.where((name) => !existingCategoryNames.contains(name) && !mappedInSession.contains(name) && name.isNotEmpty).toSet();

      if (unmapped.isEmpty) {
        emit(state.copyWith(step: ImportStep.resolvingDuplicates));
        add(ProceedToNextStep());
      } else {
        emit(state.copyWith(unmappedCategories: unmapped));
      }
    } else if (state.step == ImportStep.resolvingDuplicates) {
      final existingTransactions = await _transactionRepository.getTransactionsWithFilters(limit: 100000);
      final Set<String> existingTransactionSignatures = existingTransactions.map((t) => '${t.date.toIso8601String().substring(0, 10)}-${t.amount.toStringAsFixed(2)}').toSet();
      
      final potentialDuplicates = <OneMoneyRecord>[];

      for (final record in state.parsedRecords) {
        final recordAmount = record.type == 'Расход' ? -record.amount : record.amount;
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
      final newAccountNames = state.accountMappings.entries
          .where((e) => e.value == 'new')
          .map((e) => e.key)
          .toList();
      
      final newAccounts = newAccountNames.map((name) => Account(
        name: name,
        balance: 0.0,
        currencyCode: 'USD',
        currencyDesignationId: '1', 
        accountTypeId: '1',
        creationDate: DateTime.now(),
      )).toList();

      if (newAccounts.isNotEmpty) {
        await _accountRepository.addAccounts(newAccounts);
      }
      emit(state.copyWith(progress: 0.2, createdAccountsCount: newAccounts.length));

      final newCategoryNames = state.categoryMappings.entries
        .where((e) => e.value == 'new')
        .map((e) => e.key)
        .toList();

      final newCategories = newCategoryNames.map((name) => Category(
        name: name,
      )).toList();
      
      if (newCategories.isNotEmpty) {
        await _categoryRepository.addCategories(newCategories);
      }
      emit(state.copyWith(progress: 0.4, createdCategoriesCount: newCategories.length));

      final allAccounts = await _accountRepository.getAccounts();
      final allCategories = await _categoryRepository.getCategories();
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

        final accountId = accountIdMap[record.from.trim().toLowerCase()];
        final categoryId = categoryIdMap[record.to.trim().toLowerCase()];

        if (accountId != null && categoryId != null) {
          var description = record.notes.isNotEmpty ? record.notes : record.to;
          if (description.length > 100) {
            description = description.substring(0, 100);
          }
          
          transactionsToInsert.add(Transaction(
            date: record.date,
            description: description,
            amount: record.type.toLowerCase() == 'расход' ? -record.amount : record.amount,
            accountId: accountId,
            categoryId: categoryId,
            currencyCode: record.currency,
          ));
        } else {
          // Add logging for skipped records
          if (record.type != 'перевод') { // Don't log skipped transfers as we expect them to be skipped
            if (accountId == null) {
              debugPrint('Skipping transaction due to unmapped account: "${record.from}"');
            }
            if (categoryId == null) {
              debugPrint('Skipping transaction due to unmapped category: "${record.to}"');
            }
          }
        }
      }
      emit(state.copyWith(progress: 0.7, skippedDuplicatesCount: skippedCount));

      if (transactionsToInsert.isNotEmpty) {
        await _transactionRepository.addTransactions(transactionsToInsert);
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
