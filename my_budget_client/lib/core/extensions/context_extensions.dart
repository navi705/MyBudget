import 'package:flutter/widgets.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';

extension ContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
