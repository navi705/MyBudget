import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/category.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:uuid/uuid.dart';

import 'package:my_budget_client/core/extensions/context_extensions.dart';

/// Dialog for building SMS parsing rules
class SmsRuleBuilderDialog extends StatefulWidget {
  final SmsParsingRule? existingRule;

  /// Available categories for the optional category dropdown.
  final List<Category> categories;

  const SmsRuleBuilderDialog({
    super.key,
    this.existingRule,
    this.categories = const [],
  });

  @override
  State<SmsRuleBuilderDialog> createState() => _SmsRuleBuilderDialogState();
}

class _SmsRuleBuilderDialogState extends State<SmsRuleBuilderDialog> {
  late TransactionType _type;
  late final TextEditingController _matchController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _testSmsController;
  String? _selectedCategoryId;

  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _type = widget.existingRule?.type ?? TransactionType.expense;
    _selectedCategoryId = widget.existingRule?.categoryId;
    _matchController = TextEditingController(
      text: widget.existingRule?.matchPattern ?? '',
    );
    _amountController = TextEditingController(
      text: widget.existingRule?.amountPattern ?? r'([\d,.]+)\s*(\w{3})',
    );
    _currencyController = TextEditingController(
      text: widget.existingRule?.currencyPattern ?? r'[\d,.]+\s*(\w{3})',
    );
    _testSmsController = TextEditingController();
  }

  @override
  void dispose() {
    _matchController.dispose();
    _amountController.dispose();
    _currencyController.dispose();
    _testSmsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(
        widget.existingRule == null
            ? l10n.smsRuleAddTitle
            : l10n.smsRuleEditTitle,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type
            Text(
              l10n.smsRuleTransactionType,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(l10n.expenseLabel),
                  icon: const Icon(Icons.arrow_upward, color: Colors.red),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(l10n.incomeLabel),
                  icon: const Icon(Icons.arrow_downward, color: Colors.green),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 16),

            // Match Pattern
            TextField(
              controller: _matchController,
              decoration: InputDecoration(
                labelText: l10n.smsRuleMatchPattern,
                hintText: l10n.smsRuleMatchPatternHint,
                helperText: l10n.smsRuleMatchPatternHelp,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Pattern
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: l10n.smsRuleAmountPattern,
                hintText: l10n.smsRuleAmountPatternHint,
                helperText: l10n.smsRuleAmountPatternHelp,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Currency Pattern
            TextField(
              controller: _currencyController,
              decoration: InputDecoration(
                labelText: l10n.smsRuleCurrencyPattern,
                hintText: l10n.smsRuleCurrencyPatternHint,
                helperText: l10n.smsRuleCurrencyPatternHelp,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Category (optional)
            if (widget.categories.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  helperText: 'Override category for this rule',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('— None —'),
                  ),
                  ...widget.categories.map(
                    (cat) => DropdownMenuItem<String?>(
                      value: cat.id,
                      child: Text(cat.name),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              const SizedBox(height: 24),
            ] else
              const SizedBox(height: 24),

            // Test Section
            const Divider(),
            Text(
              l10n.smsRuleTestTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _testSmsController,
              decoration: InputDecoration(
                labelText: l10n.smsRuleTestSmsHint,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _testPattern,
              child: Text(l10n.smsRuleTestButton),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _testSuccess
                      ? Colors.green.withAlpha(30)
                      : Colors.red.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _testResult!,
                  style: TextStyle(
                    color: _testSuccess ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.saveButton)),
      ],
    );
  }

  void _testPattern() {
    final l10n = context.l10n;
    final sms = _testSmsController.text;
    if (sms.isEmpty) {
      setState(() {
        _testResult = l10n.smsRuleTestEnterSmsError;
        _testSuccess = false;
      });
      return;
    }

    try {
      final matchRegex = RegExp(_matchController.text, caseSensitive: false);
      if (!matchRegex.hasMatch(sms)) {
        setState(() {
          _testResult = l10n.smsRuleTestMatchError;
          _testSuccess = false;
        });
        return;
      }

      final amountRegex = RegExp(_amountController.text, caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(sms);
      if (amountMatch == null) {
        setState(() {
          _testResult = l10n.smsRuleTestAmountError;
          _testSuccess = false;
        });
        return;
      }

      final amountStr = amountMatch.group(1);
      String? currency;
      if (_currencyController.text.isNotEmpty) {
        final currencyRegex = RegExp(
          _currencyController.text,
          caseSensitive: false,
        );
        final currencyMatch = currencyRegex.firstMatch(sms);
        currency = currencyMatch?.group(1)?.toUpperCase();
      }

      setState(() {
        _testResult = l10n.smsRuleTestSuccess(
          _type.name,
          amountStr ?? '?',
          currency ?? 'N/A',
        );
        _testSuccess = true;
      });
    } catch (e) {
      setState(() {
        _testResult = l10n.smsRuleTestRegexError(e.toString());
        _testSuccess = false;
      });
    }
  }

  void _save() {
    if (_matchController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.smsRuleRequiredError)),
      );
      return;
    }

    final rule = SmsParsingRule(
      id: widget.existingRule?.id ?? const Uuid().v4(),
      type: _type,
      matchPattern: _matchController.text,
      amountPattern: _amountController.text,
      currencyPattern: _currencyController.text.isEmpty
          ? null
          : _currencyController.text,
      categoryId: _selectedCategoryId,
    );

    Navigator.pop(context, rule);
  }
}
