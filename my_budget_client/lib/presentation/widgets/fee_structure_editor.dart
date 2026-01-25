import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_budget_client/domain/services/fee_calculator.dart';

class FeeStructureEditor extends StatefulWidget {
  final String? initialFeeStructureJson;
  final ValueChanged<String?> onChanged;

  const FeeStructureEditor({
    super.key,
    this.initialFeeStructureJson,
    required this.onChanged,
  });

  @override
  State<FeeStructureEditor> createState() => _FeeStructureEditorState();
}

class _FeeStructureEditorState extends State<FeeStructureEditor> {
  late List<FeeRule> _rules;

  @override
  void initState() {
    super.initState();
    _parseRules();
  }

  void _parseRules() {
    if (widget.initialFeeStructureJson == null ||
        widget.initialFeeStructureJson!.isEmpty) {
      _rules = [];
      return;
    }

    try {
      final List<dynamic> jsonList = jsonDecode(
        widget.initialFeeStructureJson!,
      );
      _rules = jsonList
          .map((json) => FeeCalculator.parseRule(json as Map<String, dynamic>))
          .whereType<FeeRule>()
          .toList();
    } catch (e) {
      // If parsing fails, start empty or handle error
      _rules = [];
    }
  }

  void _updateJson() {
    if (_rules.isEmpty) {
      widget.onChanged(null);
      return;
    }
    final jsonList = _rules.map((rule) => rule.toJson()).toList();
    widget.onChanged(jsonEncode(jsonList));
  }

  void _addRule(String type) {
    setState(() {
      if (type == 'fixed') {
        _rules.add(FixedFee(0.0));
      } else if (type == 'percent') {
        _rules.add(PercentFee(0.0));
      } else if (type == 'tax') {
        _rules.add(TaxRate(0.0));
      }
      _updateJson();
    });
  }

  void _removeRule(int index) {
    setState(() {
      _rules.removeAt(index);
      _updateJson();
    });
  }

  void _updateRule(int index, FeeRule newRule) {
    setState(() {
      _rules[index] = newRule;
      _updateJson();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fee Structure',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_rules.isEmpty)
          const Text(
            'No fee rules applied.',
            style: TextStyle(color: Colors.grey),
          ),
        ..._rules.asMap().entries.map((entry) {
          final index = entry.key;
          final rule = entry.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        _getRuleName(rule),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeRule(index),
                      ),
                    ],
                  ),
                  _buildRuleEditor(index, rule),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        PopupMenuButton<String>(
          onSelected: _addRule,
          child: FilledButton.tonal(
            onPressed: null, // To use the popup menu as the button
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add),
                SizedBox(width: 8),
                Text('Add Fee Rule'),
              ],
            ),
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'fixed', child: Text('Fixed Fee')),
            const PopupMenuItem(value: 'percent', child: Text('Percent Fee')),
            const PopupMenuItem(value: 'tax', child: Text('Tax Rate')),
          ],
        ),
      ],
    );
  }

  String _getRuleName(FeeRule rule) {
    if (rule is FixedFee) return 'Fixed Fee';
    if (rule is PercentFee) return 'Percent Fee';
    if (rule is TaxRate) return 'Tax Rate';
    return 'Unknown Rule';
  }

  Widget _buildRuleEditor(int index, FeeRule rule) {
    if (rule is FixedFee) {
      return TextFormField(
        initialValue: rule.amount.toString(),
        decoration: const InputDecoration(labelText: 'Amount'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) {
          final amount = double.tryParse(value) ?? 0.0;
          _updateRule(index, FixedFee(amount));
        },
      );
    } else if (rule is PercentFee) {
      return TextFormField(
        initialValue: (rule.rate * 100).toString(),
        decoration: const InputDecoration(labelText: 'Rate (%)'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (value) {
          final rate = (double.tryParse(value) ?? 0.0) / 100;
          _updateRule(index, PercentFee(rate));
        },
      );
    } else if (rule is TaxRate) {
      return Column(
        children: [
          TextFormField(
            initialValue: (rule.rate * 100).toString(),
            decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final rate = (double.tryParse(value) ?? 0.0) / 100;
              _updateRule(index, TaxRate(rate, costBasis: rule.costBasis));
            },
          ),
          TextFormField(
            initialValue: rule.costBasis.toString(),
            decoration: const InputDecoration(labelText: 'Cost Basis'),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final costBasis = double.tryParse(value) ?? 0.0;
              _updateRule(index, TaxRate(rule.rate, costBasis: costBasis));
            },
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}
