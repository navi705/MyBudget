part of 'import_bloc.dart';

enum ImportStep {
  idle,
  parsing,
  mappingAccounts,
  mappingCategories,
  resolvingDuplicates,
  readyToImport,
  importing,
  complete,
  failure,
}

class ImportState extends Equatable {
  final ImportStep step;
  final List<PlatformFile> files;
  final List<OneMoneyRecord> parsedRecords;
  final Set<String> unmappedAccounts;
  final Set<String> unmappedCategories;
  final Map<String, String> accountMappings; // csvName -> 'new' or existingId
  final Map<String, String> categoryMappings; // csvName -> 'new' or existingId
  final List<OneMoneyRecord> potentialDuplicates;
  final Map<OneMoneyRecord, String> duplicateResolutions; // record -> 'skip' or 'import'
  final String? errorMessage;
  final double progress;
  final int createdAccountsCount;
  final int createdCategoriesCount;
  final int importedTransactionsCount;
  final int skippedDuplicatesCount;

  const ImportState({
    this.step = ImportStep.idle,
    this.files = const [],
    this.parsedRecords = const [],
    this.unmappedAccounts = const {},
    this.unmappedCategories = const {},
    this.accountMappings = const {},
    this.categoryMappings = const {},
    this.potentialDuplicates = const [],
    this.duplicateResolutions = const {},
    this.errorMessage,
    this.progress = 0.0,
    this.createdAccountsCount = 0,
    this.createdCategoriesCount = 0,
    this.importedTransactionsCount = 0,
    this.skippedDuplicatesCount = 0,
  });

  ImportState copyWith({
    ImportStep? step,
    List<PlatformFile>? files,
    List<OneMoneyRecord>? parsedRecords,
    Set<String>? unmappedAccounts,
    Set<String>? unmappedCategories,
    Map<String, String>? accountMappings,
    Map<String, String>? categoryMappings,
    List<OneMoneyRecord>? potentialDuplicates,
    Map<OneMoneyRecord, String>? duplicateResolutions,
    String? errorMessage,
    double? progress,
    int? createdAccountsCount,
    int? createdCategoriesCount,
    int? importedTransactionsCount,
    int? skippedDuplicatesCount,
  }) {
    return ImportState(
      step: step ?? this.step,
      files: files ?? this.files,
      parsedRecords: parsedRecords ?? this.parsedRecords,
      unmappedAccounts: unmappedAccounts ?? this.unmappedAccounts,
      unmappedCategories: unmappedCategories ?? this.unmappedCategories,
      accountMappings: accountMappings ?? this.accountMappings,
      categoryMappings: categoryMappings ?? this.categoryMappings,
      potentialDuplicates: potentialDuplicates ?? this.potentialDuplicates,
      duplicateResolutions: duplicateResolutions ?? this.duplicateResolutions,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
      createdAccountsCount: createdAccountsCount ?? this.createdAccountsCount,
      createdCategoriesCount: createdCategoriesCount ?? this.createdCategoriesCount,
      importedTransactionsCount: importedTransactionsCount ?? this.importedTransactionsCount,
      skippedDuplicatesCount: skippedDuplicatesCount ?? this.skippedDuplicatesCount,
    );
  }

  @override
  List<Object?> get props => [
        step,
        files,
        parsedRecords,
        unmappedAccounts,
        unmappedCategories,
        accountMappings,
        categoryMappings,
        potentialDuplicates,
        duplicateResolutions,
        errorMessage,
        progress,
        createdAccountsCount,
        createdCategoriesCount,
        importedTransactionsCount,
        skippedDuplicatesCount,
      ];
}
