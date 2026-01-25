import 'package:flutter/material.dart';

class NavigationItem {
  const NavigationItem({
    required this.route,
    required this.label,
    required this.icon,
    this.tooltip,
    this.tooltipDescription,
    this.hotkeyId,
  });

  final String route;
  final String label;
  final IconData icon;
  final String? tooltip;
  final String? tooltipDescription;
  final String? hotkeyId;
}
