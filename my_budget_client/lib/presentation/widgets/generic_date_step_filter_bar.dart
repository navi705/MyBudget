import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:my_budget_client/core/enums/filter_enums.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

class GenericDateStepFilterBar extends StatelessWidget
    implements PreferredSizeWidget {
  final DateTime currentDate;
  final DateTimeRange? dateRange;
  final DateStep dateStep;
  final FilterMode filterMode;
  final Sort? sort;
  final int totalCount;
  final bool showSort;

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTitleTap;
  final VoidCallback? onSortToggle;
  final VoidCallback? onFilterPressed;

  const GenericDateStepFilterBar({
    super.key,
    required this.currentDate,
    this.dateRange,
    required this.dateStep,
    required this.filterMode,
    this.sort,
    required this.totalCount,
    required this.onPrevious,
    required this.onNext,
    required this.onTitleTap,
    this.onSortToggle,
    this.onFilterPressed,
    this.showSort = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatDate(BuildContext context) {
    if (filterMode == FilterMode.range) {
      if (dateRange == null) return 'Select Range';
      final start = DateFormat('dd.MM.yyyy').format(dateRange!.start);
      final end = DateFormat('dd.MM.yyyy').format(dateRange!.end);
      return '$start - $end';
    }

    switch (dateStep) {
      case DateStep.day:
        return DateFormat('dd.MM.yyyy').format(currentDate);
      case DateStep.month:
        return DateFormat(
          'MMMM yyyy',
          Localizations.localeOf(context).toString(),
        ).format(currentDate);
      case DateStep.year:
        return DateFormat('yyyy').format(currentDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      height: kToolbarHeight,
      color: Theme.of(context).primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Total Count Area
          Text(
            context.l10n.totalCountLabel(totalCount.toString()),
            style: TextStyle(
              color: onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),

          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Filter Button
                if (onFilterPressed != null)
                  IconButton(
                    icon: Icon(Icons.tune, color: onPrimary),
                    tooltip: 'Filters',
                    onPressed: onFilterPressed,
                  ),

                // Previous Button
                IconButton(
                  icon: Icon(Icons.chevron_left, color: onPrimary),
                  onPressed: onPrevious,
                  tooltip: 'Previous',
                ),

                // Date Title
                InkWell(
                  onTap: onTitleTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 8.0,
                    ),
                    child: Text(
                      _formatDate(context),
                      style: TextStyle(
                        color: onPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

                // Next Button
                IconButton(
                  icon: Icon(Icons.chevron_right, color: onPrimary),
                  onPressed: onNext,
                  tooltip: 'Next',
                ),

                // Sort Button
                if (showSort && onSortToggle != null && sort != null)
                  RotatedBox(
                    quarterTurns: sort == Sort.ascending ? 0 : 2,
                    child: IconButton(
                      icon: Icon(Icons.sort, color: onPrimary),
                      tooltip: 'Sort (Asc/Desc)',
                      onPressed: onSortToggle,
                    ),
                  ),
              ],
            ),
          ),
          // Placeholder for symmetry if needed, or actions
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
