import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/entities/sms_preset.dart';
import 'package:uuid/uuid.dart';

/// Dialog for building SMS parsing rules
class SmsRuleBuilderDialog extends StatefulWidget {
  final SmsParsingRule? existingRule;

  const SmsRuleBuilderDialog({super.key, this.existingRule});

  @override
  State<SmsRuleBuilderDialog> createState() => _SmsRuleBuilderDialogState();
}

class _SmsRuleBuilderDialogState extends State<SmsRuleBuilderDialog> {
  late TransactionType _type;
  late final TextEditingController _matchController;
  late final TextEditingController _amountController;
  late final TextEditingController _currencyController;
  late final TextEditingController _testSmsController;

  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _type = widget.existingRule?.type ?? TransactionType.expense;
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
    return AlertDialog(
      title: Text(widget.existingRule == null ? 'Add Rule' : 'Edit Rule'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transaction Type
            Text(
              'Transaction Type',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_upward, color: Colors.red),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_downward, color: Colors.green),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (set) => setState(() => _type = set.first),
            ),
            const SizedBox(height: 16),

            // Match Pattern
            TextField(
              controller: _matchController,
              decoration: const InputDecoration(
                labelText: 'Match Pattern (Regex)',
                hintText: 'e.g., Placanje.*karticom',
                helperText: 'Pattern to identify this SMS type',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Pattern
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount Pattern (Regex)',
                hintText: r'e.g., iznos\s+([\d,.]+)',
                helperText: 'Group 1 should capture the amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Currency Pattern
            TextField(
              controller: _currencyController,
              decoration: const InputDecoration(
                labelText: 'Currency Pattern (Regex, optional)',
                hintText: r'e.g., [\d,.]+\s*(\w{3})',
                helperText: 'Group 1 should capture currency code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Test Section
            const Divider(),
            Text(
              'Test Your Rule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _testSmsController,
              decoration: const InputDecoration(
                labelText: 'Paste SMS text here',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: _testPattern,
              child: const Text('Test Pattern'),
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
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }

  void _testPattern() {
    final sms = _testSmsController.text;
    if (sms.isEmpty) {
      setState(() {
        _testResult = 'Enter SMS text to test';
        _testSuccess = false;
      });
      return;
    }

    try {
      final matchRegex = RegExp(_matchController.text, caseSensitive: false);
      if (!matchRegex.hasMatch(sms)) {
        setState(() {
          _testResult = '✗ Match pattern did not find a match';
          _testSuccess = false;
        });
        return;
      }

      final amountRegex = RegExp(_amountController.text, caseSensitive: false);
      final amountMatch = amountRegex.firstMatch(sms);
      if (amountMatch == null) {
        setState(() {
          _testResult = '✗ Amount pattern did not find a match';
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
        _testResult =
            '✓ Match found!\n'
            'Type: ${_type.name}\n'
            'Amount: $amountStr\n'
            'Currency: ${currency ?? 'N/A'}';
        _testSuccess = true;
      });
    } catch (e) {
      setState(() {
        _testResult = '✗ Invalid regex: $e';
        _testSuccess = false;
      });
    }
  }

  void _save() {
    if (_matchController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match and Amount patterns are required')),
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
    );

    Navigator.pop(context, rule);
  }
}
