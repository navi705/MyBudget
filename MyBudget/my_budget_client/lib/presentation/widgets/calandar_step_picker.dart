import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/presentation/blocs/transactions/transactions_bloc.dart';

enum PickerVisibility { visible, hidden }

class CalendarStepPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTimeRange? initialRange;
  final DateStep initialStep;
  final FilterMode initialFilterMode;
  
  // Configuration to hide specific sections
  final PickerVisibility rangeOptionVisibility;
  
  final Function(
    DateTime date, 
    DateTimeRange? range, 
    DateStep step, 
    FilterMode mode
  ) onApply;

  const CalendarStepPicker({
    super.key,
    required this.initialDate,
    this.initialRange,
    required this.initialStep,
    required this.initialFilterMode,
    required this.onApply,
    this.rangeOptionVisibility = PickerVisibility.visible,
  });

  @override
  State<CalendarStepPicker> createState() => _CalendarStepPickerState();
}

class _CalendarStepPickerState extends State<CalendarStepPicker> {
  late DateTime _currentDate;
  late DateTimeRange? _currentRange;
  late DateStep _currentStep;
  late FilterMode _currentFilterMode;
  
  // Used for range selection logic when clicking the calendar
  DateTime? _tempRangeStart;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _currentRange = widget.initialRange;
    _currentStep = widget.initialStep;
    _currentFilterMode = widget.initialFilterMode;
    
    if (widget.rangeOptionVisibility == PickerVisibility.hidden && 
        _currentFilterMode == FilterMode.range) {
      _currentFilterMode = FilterMode.date;
    }
  }

  void _handleDateChanged(DateTime date) {
    setState(() {
      if (_currentFilterMode == FilterMode.range && _currentStep == DateStep.day) {
        // Logic to build a range by clicking two dates
        if (_tempRangeStart == null) {
          _tempRangeStart = date;
          _currentRange = DateTimeRange(start: date, end: date);
        } else {
          if (date.isBefore(_tempRangeStart!)) {
            _currentRange = DateTimeRange(start: date, end: _tempRangeStart!);
          } else {
            _currentRange = DateTimeRange(start: _tempRangeStart!, end: date);
          }
          _tempRangeStart = null; 
        }
      } else {
        _currentDate = date;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: 16),
          
          if (widget.rangeOptionVisibility == PickerVisibility.visible) ...[
            _buildTopModeSelector(),
            const SizedBox(height: 16),
          ],

          Flexible(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildPickerBody(),
            ),
          ),
          
          const SizedBox(height: 16),
          _buildBottomStepSelector(),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.onApply(
                  _currentDate,
                  _currentRange,
                  _currentStep,
                  _currentFilterMode,
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Select Date',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  // --- Top Section: Date vs Range ---
  Widget _buildTopModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              label: 'Single Date',
              isSelected: _currentFilterMode == FilterMode.date,
              onTap: () => setState(() => _currentFilterMode = FilterMode.date),
            ),
          ),
          Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
          Expanded(
            child: _buildTabButton(
              label: 'Range',
              isSelected: _currentFilterMode == FilterMode.range,
              onTap: () => setState(() {
                 _currentFilterMode = FilterMode.range;
                 _currentRange ??= DateTimeRange(start: _currentDate, end: _currentDate);
              }),
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom Section: Day / Month / Year ---
  Widget _buildBottomStepSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          _buildStepButton('Day', DateStep.day),
          Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
          _buildStepButton('Month', DateStep.month),
          Container(width: 1, height: 40, color: Theme.of(context).dividerColor),
          _buildStepButton('Year', DateStep.year),
        ],
      ),
    );
  }

  Widget _buildStepButton(String label, DateStep step) {
    return Expanded(
      child: _buildTabButton(
        label: label,
        isSelected: _currentStep == step,
        onTap: () => setState(() => _currentStep = step),
      ),
    );
  }

  Widget _buildTabButton({
    required String label, 
    required bool isSelected, 
    required VoidCallback onTap
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? primaryColor : null,
          ),
        ),
      ),
    );
  }

  // --- Middle Section: Picker Body ---
  Widget _buildPickerBody() {
    if (_currentStep == DateStep.year) {
      return YearPicker(
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        selectedDate: _currentDate,
        onChanged: _handleDateChanged,
      );
    }

    if (_currentStep == DateStep.month) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _currentDate = DateTime(_currentDate.year - 1, _currentDate.month)),
                ),
                Text('${_currentDate.year}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _currentDate = DateTime(_currentDate.year + 1, _currentDate.month)),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthDate = DateTime(_currentDate.year, index + 1);
                final isSelected = monthDate.month == _currentDate.month;
                final primaryColor = Theme.of(context).primaryColor;

                return InkWell(
                  onTap: () => _handleDateChanged(monthDate),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.transparent : Colors.grey.withOpacity(0.5)
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat.MMM().format(monthDate),
                      style: TextStyle(
                        color: isSelected ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Default: Calendar for Days
    return CalendarDatePicker(
      initialDate: _currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      onDateChanged: _handleDateChanged,
    );
  }
}