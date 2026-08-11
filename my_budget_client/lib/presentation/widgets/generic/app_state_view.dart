import 'package:flutter/material.dart';
import 'package:my_budget_client/core/extensions/context_extensions.dart';

/// A small, reusable widget for rendering the common loading / empty / error
/// states of a screen or section.
///
/// All colors are derived from [Theme.of]'s [ColorScheme] so the widget stays
/// correct under any theme (including translucent / window-effect themes).
///
/// Use one of the named constructors:
/// * [AppStateView.loading] — centered progress indicator.
/// * [AppStateView.empty] — icon + message for "no data".
/// * [AppStateView.error] — error icon + message + optional retry button.
class AppStateView extends StatelessWidget {
  final _AppStateKind _kind;
  final String? message;
  final IconData? icon;
  final VoidCallback? onRetry;

  const AppStateView.loading({super.key})
      : _kind = _AppStateKind.loading,
        message = null,
        icon = null,
        onRetry = null;

  const AppStateView.empty({
    super.key,
    required this.message,
    this.icon,
  })  : _kind = _AppStateKind.empty,
        onRetry = null;

  const AppStateView.error({
    super.key,
    required this.message,
    this.onRetry,
  })  : _kind = _AppStateKind.error,
        icon = null;

  @override
  Widget build(BuildContext context) {
    switch (_kind) {
      case _AppStateKind.loading:
        return const Center(child: CircularProgressIndicator());
      case _AppStateKind.empty:
        return _buildEmpty(context);
      case _AppStateKind.error:
        return _buildError(context);
    }
  }

  Widget _buildEmpty(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: Text(context.l10n.retryButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _AppStateKind { loading, empty, error }
