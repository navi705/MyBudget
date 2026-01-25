part of 'import_bloc.dart';

enum ImportStep {
  idle,
  parsing,
  mappingAccounts,
  mappingCategories,
  mappingCurrencies,
  fetchingRates,
  resolvingDuplicates,
  readyToImport,
  importing,
  complete,
  failure,
}

class ImportState extends Equatable {
  final ImportStep step;
  final List<File> files;
  final List<OneMoneyRecord> parsedRecords;
  final List<AccountBalanceRecord> parsedBalances;
  final Set<String> unmappedAccounts;
  final Map<String, String> unmappedCategories;
  final Map<String, String> parsedCategoryDetails;
  final Set<String> unmappedCurrencies;
  final Map<String, String> accountMappings; // csvName -> 'new' or existingId
  final Map<String, String> categoryMappings; // csvName -> 'new' or existingId
  final Map<String, String> currencyMappings; // csvName -> 'new' or existingId
  final List<OneMoneyRecord> potentialDuplicates;
  final Map<OneMoneyRecord, String>
  duplicateResolutions; // record -> 'skip' or 'import'
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
    this.parsedBalances = const [],
    this.unmappedAccounts = const {},
    this.unmappedCategories = const {},
    this.parsedCategoryDetails = const {},
    this.unmappedCurrencies = const {},
    this.accountMappings = const {},
    this.categoryMappings = const {},
    this.currencyMappings = const {},
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
    List<File>? files,
    List<OneMoneyRecord>? parsedRecords,
    List<AccountBalanceRecord>? parsedBalances,
    Set<String>? unmappedAccounts,
    Map<String, String>? unmappedCategories,
    Map<String, String>? parsedCategoryDetails,
    Set<String>? unmappedCurrencies,
    Map<String, String>? accountMappings,
    Map<String, String>? categoryMappings,
    Map<String, String>? currencyMappings,
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
      parsedBalances: parsedBalances ?? this.parsedBalances,
      unmappedAccounts: unmappedAccounts ?? this.unmappedAccounts,
      unmappedCategories: unmappedCategories ?? this.unmappedCategories,
      parsedCategoryDetails:
          parsedCategoryDetails ?? this.parsedCategoryDetails,
      unmappedCurrencies: unmappedCurrencies ?? this.unmappedCurrencies,
      accountMappings: accountMappings ?? this.accountMappings,
      categoryMappings: categoryMappings ?? this.categoryMappings,
      currencyMappings: currencyMappings ?? this.currencyMappings,
      potentialDuplicates: potentialDuplicates ?? this.potentialDuplicates,
      duplicateResolutions: duplicateResolutions ?? this.duplicateResolutions,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
      createdAccountsCount: createdAccountsCount ?? this.createdAccountsCount,
      createdCategoriesCount:
          createdCategoriesCount ?? this.createdCategoriesCount,
      importedTransactionsCount:
          importedTransactionsCount ?? this.importedTransactionsCount,
      skippedDuplicatesCount:
          skippedDuplicatesCount ?? this.skippedDuplicatesCount,
    );
  }

  @override
  List<Object?> get props => [
    step,
    files,
    parsedRecords,
    parsedBalances,
    unmappedAccounts,
    unmappedCategories,
    parsedCategoryDetails,
    unmappedCurrencies,
    accountMappings,
    categoryMappings,
    currencyMappings,
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
