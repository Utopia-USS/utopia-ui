import 'package:flutter/widgets.dart';

/// Builds multiple nested widgets from a flat list, innermost last.
///
/// Designed for cases with many nested but relatively simple wrapper widgets;
/// flattening them into a list keeps the code readable. The
/// [UtopiaMultiWidget.keyed] constructor additionally allows conditionally
/// including wrappers *without losing the subtree's state*:
/// ```dart
/// UtopiaMultiWidget.keyed([
///   MapEntry("a", (child) => A(child: child)),
///   if (condition) MapEntry("b", (child) => B(child: child)),
///   MapEntry("c", (child) => C(child: child)),
/// ]);
/// ```
///
/// Vendored from `utopia_widgets`' `MultiWidget` - `utopia_widgets` is
/// expected to depend on this package in the future, so the dependency cannot
/// point the other way.
class UtopiaMultiWidget extends StatefulWidget {
  /// The wrappers to nest, outermost first, each paired with an optional
  /// identity key used to preserve subtree state across rebuilds.
  final List<MapEntry<Object?, Widget Function(Widget child)>> widgets;

  /// Nests [widgets] without identity keys.
  UtopiaMultiWidget(List<Widget Function(Widget child)> widgets, {super.key})
    : widgets = widgets.map((it) => MapEntry(null, it)).toList();

  /// Nests keyed wrappers, preserving each keyed subtree's state even when
  /// wrappers are conditionally added or removed around it.
  const UtopiaMultiWidget.keyed(this.widgets, {super.key});

  @override
  State<UtopiaMultiWidget> createState() => _UtopiaMultiWidgetState();
}

class _UtopiaMultiWidgetState extends State<UtopiaMultiWidget> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return widget.widgets.reversed.fold<Widget>(
      const SizedBox.shrink(),
      (child, entry) => KeyedSubtree(
        key: entry.key == null ? null : _UtopiaMultiWidgetKey(parent: _key, value: entry.key!),
        child: entry.value(child),
      ),
    );
  }
}

class _UtopiaMultiWidgetKey extends GlobalKey {
  final Key parent;
  final Object value;

  const _UtopiaMultiWidgetKey({required this.parent, required this.value}) : super.constructor();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _UtopiaMultiWidgetKey &&
          runtimeType == other.runtimeType &&
          parent == other.parent &&
          value == other.value;

  @override
  int get hashCode => parent.hashCode ^ value.hashCode;
}
