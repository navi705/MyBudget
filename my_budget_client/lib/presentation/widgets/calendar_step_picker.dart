import 'package:flutter/material.dart';
import 'package:flutter_date_pickers/flutter_date_pickers.dart' as date_pickers;
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';

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
    FilterMode mode,
  )
  onApply;

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
  DateTime? _tempRangeStart;

  late ScrollController _monthScrollController;
  late ScrollController _yearScrollController;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.initialDate;
    _currentRange = widget.initialRange;
    _currentStep = widget.initialStep;
    _currentFilterMode = widget.initialFilterMode;

    _monthScrollController = ScrollController();
    _yearScrollController = ScrollController();

    if (widget.rangeOptionVisibility == PickerVisibility.hidden &&
        _currentFilterMode == FilterMode.range) {
      _currentFilterMode = FilterMode.date;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToInitial();
    });
  }

  @override
  void dispose() {
    _monthScrollController.dispose();
    _yearScrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant CalendarStepPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate != oldWidget.initialDate ||
        widget.initialStep != oldWidget.initialStep) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToInitial();
      });
    }
  }

  void _scrollToInitial() {
    if (_currentStep == DateStep.month) {
      final monthIndex = _currentDate.month - 1;
      final screenWidth = MediaQuery.of(context).size.width;
      final gridWidth = screenWidth < 400 ? screenWidth - 32 : 400 - 32;
      final itemWidth = gridWidth / 3;
      final itemHeight = itemWidth / 1.5;
      final row = monthIndex ~/ 3;
      final offset = row * itemHeight;

      _monthScrollController.jumpTo(offset);
    } else if (_currentStep == DateStep.year) {
      final yearIndex = _currentDate.year - 2000;
      final screenWidth = MediaQuery.of(context).size.width;
      final gridWidth = screenWidth < 400 ? screenWidth - 32 : 400 - 32;
      final itemWidth = gridWidth / 3;
      final itemHeight = itemWidth / 2.5;
      final row = yearIndex ~/ 3;
      final offset = row * itemHeight;
      _yearScrollController.jumpTo(offset);
    }
  }

  void _handleDateChanged(DateTime date) {
    setState(() {
      if (_currentFilterMode == FilterMode.range) {
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
        maxWidth: 400,
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

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  widget.onApply(
                    DateTime.now(),
                    null,
                    _currentStep,
                    FilterMode.date,
                  );
                  Navigator.of(context).pop();
                },
                child: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: () {
                  widget.onApply(
                    _currentDate,
                    _currentRange,
                    _currentStep,
                    _currentFilterMode,
                  );
                  Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Apply'),
              ),
            ],
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

  Widget _buildTopModeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabButton(
              label: 'Single Date',
              isSelected: _currentFilterMode == FilterMode.date,
              onTap: () {
                setState(() {
                  _currentFilterMode = FilterMode.date;
                  _tempRangeStart = null;
                });
              },
            ),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            _buildTabButton(
              label: 'Range',
              isSelected: _currentFilterMode == FilterMode.range,
              onTap: () => setState(() {
                _currentFilterMode = FilterMode.range;
                _currentRange ??= DateTimeRange(
                  start: _currentDate,
                  end: _currentDate,
                );
              }),
            ),
          ],
        ),
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
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStepButton('Day', DateStep.day),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            _buildStepButton('Month', DateStep.month),
            Container(
              width: 1,
              height: 40,
              color: Theme.of(context).dividerColor,
            ),
            _buildStepButton('Year', DateStep.year),
          ],
        ),
      ),
    );
  }

  Widget _buildStepButton(String label, DateStep step) {
    return _buildTabButton(
      label: label,
      isSelected: _currentStep == step,
      onTap: () => setState(() {
        _currentStep = step;
        _tempRangeStart = null;
      }),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final primaryColor = Theme.of(context).primaryColor;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? onPrimaryColor : null,
          ),
        ),
      ),
    );
  }

  // --- Middle Section: Picker Body ---
  Widget _buildPickerBody() {
    final primaryColor = Theme.of(context).primaryColor;
    final onPrimaryColor = Theme.of(context).colorScheme.onPrimary;

    if (_currentStep == DateStep.year) {
      return GridView.builder(
        controller: _yearScrollController,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.5,
        ),
        itemCount: 201, // 2000 to 2200
        itemBuilder: (context, index) {
          final year = 2000 + index;
          final yearDate = DateTime(year);

          bool isSelected = false;
          if (_currentFilterMode == FilterMode.range && _currentRange != null) {
            isSelected =
                year >= _currentRange!.start.year &&
                year <= _currentRange!.end.year;
          } else {
            isSelected = year == _currentDate.year;
          }

          bool isStart =
              _currentFilterMode == FilterMode.range &&
              _currentRange != null &&
              year == _currentRange!.start.year;
          bool isEnd =
              _currentFilterMode == FilterMode.range &&
              _currentRange != null &&
              year == _currentRange!.end.year;

          Color? backgroundColor;
          if (isStart || isEnd) {
            backgroundColor = primaryColor;
          } else if (isSelected) {
            backgroundColor = primaryColor.withAlpha(100);
          }

          return InkWell(
            onTap: () => _handleDateChanged(yearDate),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: year == DateTime.now().year
                      ? primaryColor
                      : Colors.grey.withAlpha(50),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                year.toString(),
                style: TextStyle(
                  color: isSelected ? onPrimaryColor : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        },
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
                  onPressed: () => setState(
                    () => _currentDate = DateTime(
                      _currentDate.year - 1,
                      _currentDate.month,
                    ),
                  ),
                ),
                Text(
                  '${_currentDate.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                    () => _currentDate = DateTime(
                      _currentDate.year + 1,
                      _currentDate.month,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: _monthScrollController,
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                final monthDate = DateTime(_currentDate.year, index + 1);

                bool isSelected = false;
                if (_currentFilterMode == FilterMode.range &&
                    _currentRange != null) {
                  final firstDayOfMonth = DateTime(
                    monthDate.year,
                    monthDate.month,
                    1,
                  );
                  final lastDayOfMonth = DateTime(
                    monthDate.year,
                    monthDate.month + 1,
                    0,
                  );
                  isSelected =
                      !(firstDayOfMonth.isAfter(_currentRange!.end) ||
                          lastDayOfMonth.isBefore(_currentRange!.start));
                } else {
                  isSelected =
                      monthDate.month == _currentDate.month &&
                      monthDate.year == _currentDate.year;
                }

                bool isStart =
                    _currentFilterMode == FilterMode.range &&
                    _currentRange != null &&
                    monthDate.year == _currentRange!.start.year &&
                    monthDate.month == _currentRange!.start.month;
                bool isEnd =
                    _currentFilterMode == FilterMode.range &&
                    _currentRange != null &&
                    monthDate.year == _currentRange!.end.year &&
                    monthDate.month == _currentRange!.end.month;

                Color? backgroundColor;
                if (isStart || isEnd) {
                  backgroundColor = primaryColor;
                } else if (isSelected) {
                  backgroundColor = primaryColor.withAlpha(100);
                }

                return InkWell(
                  onTap: () => _handleDateChanged(monthDate),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : Colors.grey.withAlpha(128),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat.MMM(
                        Localizations.localeOf(context).toString(),
                      ).format(monthDate),
                      style: TextStyle(
                        color: isSelected ? onPrimaryColor : null,
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

    if (_currentFilterMode == FilterMode.range) {
      date_pickers.DatePickerRangeStyles styles =
          date_pickers.DatePickerRangeStyles(
            selectedPeriodStartDecoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10.0),
                bottomLeft: Radius.circular(10.0),
              ),
            ),
            selectedPeriodMiddleDecoration: BoxDecoration(
              color: primaryColor.withAlpha(100),
            ),
            selectedPeriodLastDecoration: BoxDecoration(
              color: primaryColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0),
              ),
            ),
            selectedDateStyle: TextStyle(
              color: onPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          );

      return date_pickers.RangePicker(
        selectedPeriod: date_pickers.DatePeriod(
          _currentRange!.start,
          _currentRange!.end,
        ),
        onChanged: (date_pickers.DatePeriod newPeriod) {
          setState(() {
            _currentRange = DateTimeRange(
              start: newPeriod.start,
              end: newPeriod.end,
            );
          });
        },
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        datePickerStyles: styles,
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
