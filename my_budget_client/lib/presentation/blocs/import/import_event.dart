part of 'import_bloc.dart';

abstract class ImportEvent extends Equatable {
  const ImportEvent();

  @override
  List<Object?> get props => [];
}

class StartImportProcess extends ImportEvent {
  final List<ImportFileData> files;

  const StartImportProcess(this.files);

  @override
  List<Object?> get props => [files];
}

class MapAccount extends ImportEvent {
  final String csvAccountName;
  final String decision; // 'new' or existing account ID

  const MapAccount(this.csvAccountName, this.decision);

  @override
  List<Object?> get props => [csvAccountName, decision];
}

class MapCategory extends ImportEvent {
  final String csvCategoryName;
  final String decision; // 'new' or existing category ID

  const MapCategory(this.csvCategoryName, this.decision);

  @override
  List<Object?> get props => [csvCategoryName, decision];
}

class MapCurrency extends ImportEvent {
  final String csvCurrencyName;
  final String decision; // 'new' or existing currency code

  const MapCurrency(this.csvCurrencyName, this.decision);

  @override
  List<Object?> get props => [csvCurrencyName, decision];
}

class ProceedToNextStep extends ImportEvent {}

class ResolveDuplicate extends ImportEvent {
  final OneMoneyRecord record;
  final String decision; // 'skip' or 'import'

  const ResolveDuplicate(this.record, this.decision);

  @override
  List<Object?> get props => [record, decision];
}

class FinalizeImport extends ImportEvent {}

class FetchRates extends ImportEvent {}

class ResetImport extends ImportEvent {}
