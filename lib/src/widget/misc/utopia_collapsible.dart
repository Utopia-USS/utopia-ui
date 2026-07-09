import 'package:flutter/widgets.dart';

/// Animates its [child] between collapsed (zero extent) and expanded along one
/// [axis], clipping the child while it animates.
///
/// Vendored from `utopia_widgets`' `Collapsible` - `utopia_widgets` is
/// expected to depend on this package in the future, so the dependency cannot
/// point the other way.
class UtopiaCollapsible extends StatelessWidget {
  /// The content to collapse/expand.
  final Widget child;

  /// The axis along which the child collapses.
  final Axis axis;

  /// Whether the child is currently shown at its full extent.
  final bool isExpanded;

  /// Duration of the collapse/expand animation.
  final Duration duration;

  /// Curve of the collapse/expand animation.
  final Curve curve;

  /// Creates a collapsible along an explicit [axis].
  const UtopiaCollapsible({
    super.key,
    required this.duration,
    required this.axis,
    this.curve = Curves.decelerate,
    required this.isExpanded,
    required this.child,
  });

  /// Collapses the child's height.
  const UtopiaCollapsible.vertical({
    super.key,
    required this.duration,
    this.curve = Curves.decelerate,
    required this.isExpanded,
    required this.child,
  }) : axis = Axis.vertical;

  /// Collapses the child's width.
  const UtopiaCollapsible.horizontal({
    super.key,
    required this.duration,
    this.curve = Curves.decelerate,
    required this.isExpanded,
    required this.child,
  }) : axis = Axis.horizontal;

  @override
  Widget build(BuildContext context) {
    final factor = isExpanded ? 1.0 : 0.0;
    return AnimatedAlign(
      alignment: Alignment.topLeft,
      duration: duration,
      curve: curve,
      heightFactor: axis == Axis.vertical ? factor : null,
      widthFactor: axis == Axis.horizontal ? factor : null,
      child: ClipRect(child: child),
    );
  }
}
