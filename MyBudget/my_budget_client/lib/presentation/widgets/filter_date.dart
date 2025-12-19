import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum DateStep { day, month, year }
enum FilterMode { date, range }

class FilterDate extends StatefulWidget implements PreferredSizeWidget {
  const FilterDate({super.key});

  @override
  State<FilterDate> createState() => _FilterDateState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _FilterDateState extends State<FilterDate> {
  late final TextEditingController _dateController;
  DateTime _date = DateTime.now();
  DateStep _dateStep = DateStep.day;
  FilterMode _filterMode = FilterMode.date;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: _formatDate(_date, _dateStep));
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date, DateStep step) {
    switch (step) {
      case DateStep.day:
        return DateFormat('dd.MM.yyyy').format(date);
      case DateStep.month:
        return DateFormat('MMMM yyyy', 'ru_RU').format(date);
      case DateStep.year:
        return DateFormat('yyyy').format(date);
    }
  }

  String _formatDateRange(DateTimeRange range) {
    final start = DateFormat('dd.MM.yyyy').format(range.start);
    final end = DateFormat('dd.MM.yyyy').format(range.end);
    return '$start - $end';
  }

  void _previousDate() {
    if (_filterMode == FilterMode.range) return;
    setState(() {
      switch (_dateStep) {
        case DateStep.day:
          _date = _date.subtract(const Duration(days: 1));
          break;
        case DateStep.month:
          _date = DateTime(_date.year, _date.month - 1, _date.day);
          break;
        case DateStep.year:
          _date = DateTime(_date.year - 1, _date.month, _date.day);
          break;
      }
      _dateController.text = _formatDate(_date, _dateStep);
    });
  }

  void _nextDate() {
    if (_filterMode == FilterMode.range) return;
    setState(() {
      switch (_dateStep) {
        case DateStep.day:
          _date = _date.add(const Duration(days: 1));
          break;
        case DateStep.month:
          _date = DateTime(_date.year, _date.month + 1, _date.day);
          break;
        case DateStep.year:
          _date = DateTime(_date.year + 1, _date.month, _date.day);
          break;
      }
      _dateController.text = _formatDate(_date, _dateStep);
    });
  }

  void _setDateStep(DateStep step) {
    setState(() {
      _filterMode = FilterMode.date;
      _dateStep = step;
      _dateController.text = _formatDate(_date, _dateStep);
    });
  }

  void _showDateStepPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return SimpleDialog(
          title: const Text('Выберите шаг'),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                _setDateStep(DateStep.day);
              },
              child: const Text('День'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                _setDateStep(DateStep.month);
              },
              child: const Text('Месяц'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(dialogContext);
                _setDateStep(DateStep.year);
              },
              child: const Text('Год'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _filterMode = FilterMode.date;
        _date = picked;
        _dateController.text = _formatDate(_date, _dateStep);
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) {
      setState(() {
        _filterMode = FilterMode.range;
        _dateRange = picked;
        _dateController.text = _formatDateRange(picked);
      });
    }
  }

  void _showDateOptionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Выберите опцию'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _showDateStepPicker(context);
                },
                child: const Text('Выбрать шаг даты'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _selectDate(context);
                },
                child: const Text('Выбрать день'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _selectDateRange(context);
                },
                child: const Text('Выбрать диапазон'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.preferredSize.height,
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          IconButton(
            icon:
                const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: _previousDate,
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.tune, color: Colors.white),
                tooltip: 'Фильтр',
                onPressed: () {},
              ),
              SizedBox(
                width: 40,
                child: TextButton(
                  onPressed: () => _showDateStepPicker(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  child: Text(
                    _dateStep.name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              IntrinsicWidth(
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _showDateOptionsDialog(context),
                        hoverColor: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          alignment: Alignment.center,
                          child: Text(
                            _dateController.text,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today,
                          color: Colors.white),
                      onPressed: () => _selectDate(context),
                      tooltip: 'Выбрать дату',
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.sort, color: Colors.white),
                tooltip: 'Сортировка',
                onPressed: () {},
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios,
                color: Colors.white, size: 20),
            onPressed: _nextDate,
          ),
        ],
      ),
    );
  }
}
