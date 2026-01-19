part of 'sms_bloc.dart';

class SmsState extends Equatable {
  final bool isLoading;
  final bool hasPermission;
  final List<SmsPreset> presets;
  final SmsParseResult? testResult;
  final bool isImporting;
  final double importProgress;
  final String? importError;
  final List<SmsParseResult> importedResults;
  final DateTime? lastSyncTimestamp;

  const SmsState({
    this.isLoading = false,
    this.hasPermission = false,
    this.presets = const [],
    this.testResult,
    this.isImporting = false,
    this.importProgress = 0,
    this.importError,
    this.importedResults = const [],
    this.lastSyncTimestamp,
  });

  SmsState copyWith({
    bool? isLoading,
    bool? hasPermission,
    List<SmsPreset>? presets,
    SmsParseResult? testResult,
    bool? isImporting,
    double? importProgress,
    String? importError,
    List<SmsParseResult>? importedResults,
    DateTime? lastSyncTimestamp,
  }) {
    return SmsState(
      isLoading: isLoading ?? this.isLoading,
      hasPermission: hasPermission ?? this.hasPermission,
      presets: presets ?? this.presets,
      testResult: testResult ?? this.testResult,
      isImporting: isImporting ?? this.isImporting,
      importProgress: importProgress ?? this.importProgress,
      importError: importError,
      importedResults: importedResults ?? this.importedResults,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    hasPermission,
    presets,
    testResult,
    isImporting,
    importProgress,
    importError,
    importedResults,
    lastSyncTimestamp,
  ];
}
