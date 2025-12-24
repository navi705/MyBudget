import 'package:flutter/material.dart';

class GenericFilterAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String totalCountText;
  final String dateStepText;
  final VoidCallback onNavigatePrevious;
  final VoidCallback onNavigateNext;
  final VoidCallback onOpenAdvancedFilter;
  final VoidCallback onShowSortOptions;
  final VoidCallback onShowDateStepPicker;
  final VoidCallback onShowDateOptionsDialog;
  final VoidCallback onSelectDate;

  const GenericFilterAppBar({
    super.key,
    required this.title,
    required this.totalCountText,
    required this.dateStepText,
    required this.onNavigatePrevious,
    required this.onNavigateNext,
    required this.onOpenAdvancedFilter,
    required this.onShowSortOptions,
    required this.onShowDateStepPicker,
    required this.onShowDateOptionsDialog,
    required this.onSelectDate,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      color: Theme.of(context).appBarTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Stack(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
                onPressed: onNavigatePrevious,
              ),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    tooltip: 'Фильтр',
                    onPressed: onOpenAdvancedFilter,
                  ),
                  SizedBox(
                    width: 40,
                    child: TextButton(
                      onPressed: onShowDateStepPicker,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      child: Text(
                        dateStepText,
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
                            onTap: onShowDateOptionsDialog,
                            hoverColor: Colors.white.withAlpha(25),
                            borderRadius: BorderRadius.circular(4.0),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12.0),
                              alignment: Alignment.center,
                              child: Text(
                                title,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 18),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today,
                              color: Colors.white),
                          onPressed: onSelectDate,
                          tooltip: 'Выбрать дату',
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sort, color: Colors.white),
                    tooltip: 'Сортировка',
                    onPressed: onShowSortOptions,
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios,
                    color: Colors.white, size: 20),
                onPressed: onNavigateNext,
              ),
            ],
          ),
          Positioned(
            left: 50,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                totalCountText,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
