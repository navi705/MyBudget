import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';

class MultiLevelTooltip extends StatefulWidget {
  final Widget child;
  final String message; // The short title
  final String actionId; // ID to look up hotkey
  final String? description; // The long explanation (optional)
  final String?
  fallbackHotkey; // If no hotkey in settings, use this display string (optional)

  const MultiLevelTooltip({
    super.key,
    required this.child,
    required this.message,
    required this.actionId,
    this.description,
    this.fallbackHotkey,
  });

  @override
  State<MultiLevelTooltip> createState() => _MultiLevelTooltipState();
}

class _MultiLevelTooltipState extends State<MultiLevelTooltip> {
  final LayerLink _layerLink = LayerLink();
  Timer? _hoverTimer;
  OverlayEntry? _overlayEntry;
  bool _isLevel2 = false;

  @override
  void dispose() {
    _removeOverlay();
    _hoverTimer?.cancel();
    super.dispose();
  }

  void _showOverlay(BuildContext context, String hotkeyDisplay) {
    if (_overlayEntry != null) return;

    final overlayState = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: 250, // Max width constraint
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: const Offset(0, 48), // Below the widget
            child: Material(
              color: Colors.transparent,
              child: _buildTooltipContent(hotkeyDisplay),
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);
  }

  Widget _buildTooltipContent(String hotkeyDisplay) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(50),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level 1: Title + Hotkey
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.message,
                  style: TextStyle(
                    color: colorScheme.onInverseSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (hotkeyDisplay.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(100),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: colorScheme.onInverseSurface.withAlpha(50),
                      ),
                    ),
                    child: Text(
                      hotkeyDisplay,
                      style: TextStyle(
                        color: colorScheme.onInverseSurface,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Level 2: Explanation
            if (_isLevel2 && widget.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.description!,
                style: TextStyle(
                  color: colorScheme.onInverseSurface.withAlpha(200),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _hoverTimer?.cancel();
    _hoverTimer = null;
    _isLevel2 = false;
  }

  void _onEnter(PointerEvent event, String hotkeyDisplay) {
    _showOverlay(context, hotkeyDisplay);
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted && _overlayEntry != null) {
        setState(() {
          _isLevel2 = true;
        });
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  void _onExit(PointerEvent event) {
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      buildWhen: (previous, current) => previous.hotkeys != current.hotkeys,
      builder: (context, state) {
        final hotkeyString = state.hotkeys[widget.actionId] ?? '';
        final display = hotkeyString.isNotEmpty
            ? HotKeyUtils.getDisplayString(hotkeyString)
            : (widget.fallbackHotkey ?? '');

        return CompositedTransformTarget(
          link: _layerLink,
          child: MouseRegion(
            onEnter: (event) => _onEnter(event, display),
            onExit: _onExit,
            child: widget.child,
          ),
        );
      },
    );
  }
}
