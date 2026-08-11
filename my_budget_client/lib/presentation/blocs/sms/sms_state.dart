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
  ];
}
