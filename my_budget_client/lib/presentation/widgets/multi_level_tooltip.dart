import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_budget_client/presentation/blocs/settings/settings_bloc.dart';
import 'package:my_budget_client/core/utils/hotkey_utils.dart';

/// Gap between the anchor and the hover card, and the minimum distance the card
/// keeps from the edge of the overlay.
const double _kTooltipGap = 4.0;
const double _kTooltipScreenPadding = 8.0;
const double _kTooltipMaxWidth = 250.0;

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
  Timer? _hoverTimer;
  OverlayEntry? _overlayEntry;
  bool _isLevel2 = false;
  static const Duration _showDelay = Duration(milliseconds: 1000);
  static const Duration _expandDelay = Duration(milliseconds: 3000);

  /// How long the card stays up after a long press. A finger cannot hold a
  /// hover, so the touch path shows the whole card at once and takes it away
  /// on a timer instead of on a pointer exit.
  static const Duration _touchShowDuration = Duration(milliseconds: 4000);

  @override
  void dispose() {
    _removeOverlay();
    _hoverTimer?.cancel();
    super.dispose();
  }

  /// The anchor's box in the overlay's coordinate space, or null while the
  /// widget is between frames and has no layout yet.
  Rect? _anchorRect(OverlayState overlayState) {
    final box = context.findRenderObject() as RenderBox?;
    final overlayBox = overlayState.context.findRenderObject() as RenderBox?;
    if (box == null || overlayBox == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    return topLeft & box.size;
  }

  void _showOverlay(BuildContext context, String hotkeyDisplay) {
    if (_overlayEntry != null) return;

    final overlayState = Overlay.of(context);
    final textDirection = Directionality.of(context);

    _overlayEntry = OverlayEntry(
      builder: (_) {
        final anchor = _anchorRect(overlayState);
        if (anchor == null) return const SizedBox.shrink();

        // Positioned.fill + CustomSingleChildLayout replaces the old
        // Positioned(width: 250) + CompositedTransformFollower(offset: 0, 48).
        // The follower copies the anchor's position verbatim, so a control in
        // the right third of a maximised window - the rail toggle, the filter
        // bar overflow - had its card run off the screen, and a control near
        // the bottom had it clipped. The delegate below sees the card's real
        // size and the overlay's real bounds, so it can flip above the anchor
        // and clamp to the viewport instead.
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomSingleChildLayout(
              delegate: _TooltipPositionDelegate(
                anchor: anchor,
                textDirection: textDirection,
              ),
              child: Material(
                color: Colors.transparent,
                child: _buildTooltipContent(hotkeyDisplay),
              ),
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
          color: colorScheme.secondary,
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
                // Flexible so a long title wraps inside the clamped width
                // rather than forcing the card past the viewport edge.
                Flexible(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
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
    _hoverTimer?.cancel();

    // First timer shows level 1.
    _hoverTimer = Timer(_showDelay, () {
      if (!mounted) return;

      _showOverlay(context, hotkeyDisplay);

      // Second timer, started inside the first, expands the card to level 2.
      _hoverTimer = Timer(_expandDelay, () {
        if (mounted && _overlayEntry != null) {
          setState(() {
            _isLevel2 = true;
          });
          _overlayEntry?.markNeedsBuild();
        }
      });
    });
  }

  void _onExit(PointerEvent event) {
    _removeOverlay();
  }

  /// The touch equivalent of the hover dwell.
  ///
  /// Opens the card straight at level 2 - the title, the shortcut badge and
  /// the description together - because there is no "keep hovering three more
  /// seconds" gesture on a phone, then dismisses it on a timer.
  void _onLongPress(String hotkeyDisplay) {
    _hoverTimer?.cancel();
    _isLevel2 = true;
    if (_overlayEntry == null) {
      _showOverlay(context, hotkeyDisplay);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
    _hoverTimer = Timer(_touchShowDuration, () {
      if (mounted) _removeOverlay();
    });
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

        // The hover card is a pointer-only affordance, and this widget is the
        // sole label carrier for the nav destinations, the dashboard FAB and
        // every IconButton in the filter bars. Without the two wrappers below,
        // a phone user sees a bare glyph with no way to learn it and TalkBack
        // announces "button" with no name.
        Widget labelled = MouseRegion(
          onEnter: (event) => _onEnter(event, display),
          onExit: _onExit,
          child: widget.child,
        );

        final platform = Theme.of(context).platform;
        final isTouch =
            platform == TargetPlatform.android ||
            platform == TargetPlatform.iOS;
        if (isTouch) {
          // A Material `Tooltip` used to sit here for the long-press label, but
          // a Tooltip opens on hover as well as on its `triggerMode`, so on an
          // Android device with a mouse attached the control showed its message
          // twice - once from the Tooltip, once from the card above - and
          // announced it twice, the Tooltip's own semantics landing inside the
          // Semantics below. Long-pressing now opens the same single card,
          // which also gives a touch user the description a Tooltip could not.
          labelled = GestureDetector(
            behavior: HitTestBehavior.deferToChild,
            // The Semantics below is the accessible name; a "long press"
            // annotation from here would be read out on top of it.
            excludeFromSemantics: true,
            onLongPress: () => _onLongPress(display),
            child: labelled,
          );
        }

        return Semantics(
          label: widget.message,
          hint: widget.description,
          child: labelled,
        );
      },
    );
  }
}

/// Places the hover card near its anchor without letting it leave the overlay.
class _TooltipPositionDelegate extends SingleChildLayoutDelegate {
  const _TooltipPositionDelegate({
    required this.anchor,
    required this.textDirection,
  });

  /// The anchor's box, in overlay coordinates.
  final Rect anchor;
  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    // Loose, so IntrinsicWidth still shrink-wraps short titles, but never wider
    // than the viewport minus its padding on a 620dp-wide window.
    return BoxConstraints.loose(
      Size(
        math.min(
          _kTooltipMaxWidth,
          math.max(0.0, constraints.maxWidth - _kTooltipScreenPadding * 2),
        ),
        math.max(0.0, constraints.maxHeight - _kTooltipScreenPadding * 2),
      ),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Start aligned with the anchor's leading edge so the card reads as
    // belonging to it, then clamp. Under RTL the leading edge is the right one.
    double x = textDirection == TextDirection.rtl
        ? anchor.right - childSize.width
        : anchor.left;
    final maxX = math.max(
      _kTooltipScreenPadding,
      size.width - childSize.width - _kTooltipScreenPadding,
    );
    x = x.clamp(_kTooltipScreenPadding, maxX);

    // Below the anchor by default; flip above when there is no room, which is
    // the case for anything in the bottom band of a maximised window.
    double y = anchor.bottom + _kTooltipGap;
    if (y + childSize.height > size.height - _kTooltipScreenPadding) {
      final above = anchor.top - childSize.height - _kTooltipGap;
      y = above >= _kTooltipScreenPadding
          ? above
          : math.max(
              _kTooltipScreenPadding,
              size.height - childSize.height - _kTooltipScreenPadding,
            );
    }

    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_TooltipPositionDelegate oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.textDirection != textDirection;
}
