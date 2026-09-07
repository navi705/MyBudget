part of 'sms_bloc.dart';

class SmsState extends Equatable {
  final bool isLoading;
  final bool hasPermission;
  final List<SmsPreset> presets;
  final bool isImporting;
  final double importProgress;
  final String? importError;
  final List<SmsParseResult> importedResults;
  final DateTime? lastSyncTimestamp;
  final int createdTransactionsCount;

  /// Messages that matched a preset but whose transaction never reached the
  /// repository. Counted apart from [createdTransactionsCount] so a failing
  /// write can no longer be reported to the user as a successful import.
  final int failedTransactionsCount;

  /// Messages that were already imported by an earlier run and so wrote
  /// nothing this time.
  ///
  /// Its own counter rather than part of [failedTransactionsCount]: re-running
  /// "All time" over an inbox that has already been imported is a normal thing
  /// to do, and without this the screen reports the whole run as zero and
  /// leaves the user unable to tell "nothing new" from "nothing worked".
  final int duplicateTransactionsCount;

  const SmsState({
    this.isLoading = false,
    this.hasPermission = false,
    this.presets = const [],
    this.isImporting = false,
    this.importProgress = 0,
    this.importError,
    this.importedResults = const [],
    this.lastSyncTimestamp,
    this.createdTransactionsCount = 0,
    this.failedTransactionsCount = 0,
    this.duplicateTransactionsCount = 0,
  });

  SmsState copyWith({
    bool? isLoading,
    bool? hasPermission,
    List<SmsPreset>? presets,
    bool? isImporting,
    double? importProgress,
    String? importError,
    List<SmsParseResult>? importedResults,
    DateTime? lastSyncTimestamp,
    int? createdTransactionsCount,
    int? failedTransactionsCount,
    int? duplicateTransactionsCount,
  }) {
    return SmsState(
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      presets: presets ?? this.presets,
      isImporting: isImporting ?? this.isImporting,
      importProgress: importProgress ?? this.importProgress,
      importError: importError,
      importedResults: importedResults ?? this.importedResults,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      createdTransactionsCount:
          createdTransactionsCount ?? this.createdTransactionsCount,
      failedTransactionsCount:
          failedTransactionsCount ?? this.failedTransactionsCount,
      duplicateTransactionsCount:
          duplicateTransactionsCount ?? this.duplicateTransactionsCount,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    hasPermission,
    presets,
    isImporting,
    importProgress,
    importError,
    importedResults,
    lastSyncTimestamp,
    createdTransactionsCount,
    failedTransactionsCount,
    duplicateTransactionsCount,
  ];
}
