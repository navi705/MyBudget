import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Debug-only handle on the running app's widget tree, driven over the Dart VM
/// Service.
///
/// Reviewing a screen used to mean taking a picture of the window and clicking
/// at pixel coordinates read off that picture: every tap was a guess, a tooltip
/// or a scroll invalidated the guess, and nothing could be checked afterwards
/// except by taking another picture. This exposes the tree the app actually
/// built — types, keys, text, on-screen rectangles — and dispatches taps
/// through the framework's own pointer pipeline, so driving the app and
/// inspecting it use the same source of truth.
///
/// Registered from `main()` and only in debug builds; in profile and release
/// [registerUiProbe] returns without doing anything and none of this is
/// reachable.
///
/// Service extensions:
///  * `ext.mybudget.probe.find`  — `{"q": "text:Categories", "limit": "20"}`
///  * `ext.mybudget.probe.tap`   — `{"q": "key:categories-view-mode-toggle"}`
///  * `ext.mybudget.probe.tree`  — `{"depth": "12"}`
///
/// A query is `<field>:<substring>`, matched case-insensitively, where field is
/// `type`, `key`, `text` or `tooltip`. A query with no prefix matches any of
/// them. Several terms separated by `&&` must all match the same widget.
void registerUiProbe() {
  if (!kDebugMode) return;
  if (_registered) return;
  _registered = true;

  developer.registerExtension('ext.mybudget.probe.find', (
    method,
    params,
  ) async {
    final limit = int.tryParse(params['limit'] ?? '') ?? 20;
    final matches = _find(params['q'] ?? '', limit);
    return _ok({'matches': matches});
  });

  developer.registerExtension('ext.mybudget.probe.tap', (method, params) async {
    final index = int.tryParse(params['index'] ?? '') ?? 0;
    final matches = _find(params['q'] ?? '', index + 1);
    if (matches.length <= index) {
      return _err('no widget at index $index for "${params['q']}"');
    }
    final match = matches[index];
    final x = (match['x'] as num) + (match['w'] as num) / 2;
    final y = (match['y'] as num) + (match['h'] as num) / 2;
    _tapAt(Offset(x.toDouble(), y.toDouble()));
    return _ok({'tapped': match});
  });

  developer.registerExtension('ext.mybudget.probe.tree', (
    method,
    params,
  ) async {
    final depth = int.tryParse(params['depth'] ?? '') ?? 12;
    final lines = <String>[];
    final root = WidgetsBinding.instance.rootElement;
    if (root != null) _walkTree(root, 0, depth, lines);
    return _ok({'tree': lines});
  });
}

bool _registered = false;

developer.ServiceExtensionResponse _ok(Object payload) =>
    developer.ServiceExtensionResponse.result(jsonEncode(payload));

developer.ServiceExtensionResponse _err(String message) =>
    developer.ServiceExtensionResponse.result(jsonEncode({'error': message}));

/// Widgets that describe layout rather than content.
///
/// A screen builds thousands of them and none of them is a thing anybody wants
/// to point at, so they are skipped when a query has no explicit field: without
/// this, `find "Categories"` answers with fifty Paddings whose subtree happens
/// to contain the word.
const Set<String> _structural = {
  'Padding',
  'Center',
  'Align',
  'SizedBox',
  'Expanded',
  'Flexible',
  'Column',
  'Row',
  'Stack',
  'Container',
  'DecoratedBox',
  'ConstrainedBox',
  'LayoutBuilder',
  'RepaintBoundary',
  'Semantics',
  'MediaQuery',
  'Builder',
  'BlocBuilder',
  'DefaultTextStyle',
  'AnimatedDefaultTextStyle',
  'DefaultTextEditingShortcuts',
  'RichText',
  'KeyedSubtree',
  'IgnorePointer',
  'Opacity',
  'ClipRect',
  'ClipRRect',
  'FractionalTranslation',
  'AnimatedBuilder',
  'ValueListenableBuilder',
};

List<Map<String, Object?>> _find(String query, int limit) {
  final terms = query
      .split('&&')
      .map((t) => t.trim())
      .where((t) => t.isNotEmpty)
      .toList();
  final results = <Map<String, Object?>>[];
  final root = WidgetsBinding.instance.rootElement;
  if (root == null || terms.isEmpty) return results;

  void visit(Element element) {
    if (results.length >= limit) return;
    final info = _describe(element);
    if (terms.every((term) => _matches(info, term))) {
      final rect = _rectOf(element);
      // A widget with no box has no place on screen, so it cannot be tapped
      // and is not what the caller is looking for.
      if (rect != null) {
        results.add({
          'type': info.type,
          if (info.key != null) 'key': info.key,
          if (info.text != null) 'text': info.text,
          if (info.tooltip != null) 'tooltip': info.tooltip,
          'x': rect.left.roundToDouble(),
          'y': rect.top.roundToDouble(),
          'w': rect.width.roundToDouble(),
          'h': rect.height.roundToDouble(),
          'path': _ancestry(element),
        });
      }
    }
    element.visitChildren(visit);
  }

  visit(root);
  return results;
}

class _Info {
  const _Info({required this.type, this.key, this.text, this.tooltip});
  final String type;
  final String? key;
  final String? text;
  final String? tooltip;
}

_Info _describe(Element element) {
  final widget = element.widget;
  String? text;
  String? tooltip;
  if (widget is Text) {
    text = widget.data;
  } else if (widget is Tooltip) {
    tooltip = widget.message;
  } else if (widget is IconButton) {
    tooltip = widget.tooltip;
  }
  final key = widget.key;
  return _Info(
    type: widget.runtimeType.toString(),
    key: key == null ? null : _keyLabel(key),
    text: text,
    tooltip: tooltip,
  );
}

/// The readable part of a key: `[<'dashboard-day-20'>]` reads as
/// `dashboard-day-20`.
String _keyLabel(Key key) {
  final raw = key.toString();
  final match = RegExp(r"<'?(.*?)'?>").firstMatch(raw);
  return match?.group(1) ?? raw;
}

bool _matches(_Info info, String term) {
  final colon = term.indexOf(':');
  if (colon > 0) {
    final field = term.substring(0, colon).toLowerCase();
    final value = term.substring(colon + 1).toLowerCase();
    switch (field) {
      case 'type':
        return info.type.toLowerCase().contains(value);
      case 'key':
        return (info.key ?? '').toLowerCase().contains(value);
      case 'text':
        return (info.text ?? '').toLowerCase().contains(value);
      case 'tooltip':
        return (info.tooltip ?? '').toLowerCase().contains(value);
    }
  }
  if (_structural.contains(info.type)) return false;
  final needle = term.toLowerCase();
  return info.type.toLowerCase().contains(needle) ||
      (info.key ?? '').toLowerCase().contains(needle) ||
      (info.text ?? '').toLowerCase().contains(needle) ||
      (info.tooltip ?? '').toLowerCase().contains(needle);
}

Rect? _rectOf(Element element) {
  final renderObject = element.renderObject;
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  if (!renderObject.attached) return null;
  final origin = renderObject.localToGlobal(Offset.zero);
  return origin & renderObject.size;
}

/// The nearest few named ancestors, so a bare `Text` can be told apart from the
/// identical `Text` on the other tab.
String _ancestry(Element element) {
  final names = <String>[];
  element.visitAncestorElements((ancestor) {
    final name = ancestor.widget.runtimeType.toString();
    if (!_structural.contains(name) && !name.startsWith('_')) {
      names.add(name);
    }
    return names.length < 4;
  });
  return names.join(' < ');
}

void _walkTree(Element element, int depth, int maxDepth, List<String> out) {
  if (depth > maxDepth) return;
  final info = _describe(element);
  final name = info.type;
  if (!name.startsWith('_') && !_structural.contains(name)) {
    final rect = _rectOf(element);
    final label = [
      if (info.key != null) 'key=${info.key}',
      if (info.text != null) 'text=${info.text}',
      if (info.tooltip != null) 'tooltip=${info.tooltip}',
      if (rect != null)
        '@${rect.left.round()},${rect.top.round()} '
            '${rect.width.round()}x${rect.height.round()}',
    ].join(' ');
    out.add('${'  ' * depth}$name${label.isEmpty ? '' : '  $label'}');
  }
  element.visitChildren((child) => _walkTree(child, depth + 1, maxDepth, out));
}

/// Sends a tap through the same pipeline a real click uses.
///
/// Synthesising the pointer here rather than moving the OS cursor keeps the
/// coordinates in the app's own logical pixels — the window can be at any DPI,
/// any position, and behind another window, and the tap still lands where the
/// tree says the widget is.
void _tapAt(Offset position) {
  final binding = WidgetsBinding.instance;
  const pointer = 7654321;
  binding.handlePointerEvent(
    PointerDownEvent(pointer: pointer, position: position),
  );
  binding.handlePointerEvent(
    PointerUpEvent(pointer: pointer, position: position),
  );
}
