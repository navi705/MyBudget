import 'package:flutter/material.dart';
import 'package:my_budget_client/l10n/app_localizations.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.transactionsAppBarTitle),
      ),
      body: Center(
        child: Text(l10n.transactionsScreenBody),
      ),
    );
  }
}
