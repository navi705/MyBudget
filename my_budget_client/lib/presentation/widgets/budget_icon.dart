import 'package:flutter/material.dart';
import 'package:my_budget_client/core/utils/icon_utils.dart';
import 'package:my_budget_client/domain/entities/style.dart';

class BudgetIcon extends StatelessWidget {
  final Style style;
  final double radius;
  final double? iconSize;

  const BudgetIcon({
    super.key,
    required this.style,
    this.radius = 16,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    // Rounding to double to avoid subpixel rendering issues that can look like shifts
    final diameter = (radius * 2).toDouble();
    final effectiveIconSize = (iconSize ?? (radius * 1.3)).toDouble();

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: IconUtils.getColorFromHex(style.colorHex),
        shape: BoxShape.circle,
      ),
      child: IconUtils.getIconWidget(style, size: effectiveIconSize),
    );
  }
}
