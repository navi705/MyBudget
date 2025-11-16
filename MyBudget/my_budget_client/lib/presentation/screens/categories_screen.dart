import 'package:flutter/material.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categoriesAppBarTitle),
      ),
      body: Center(
        child: Text(l10n.categoriesScreenBody),
      ),
    );
  }
}
