import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';

/// A raised, rounded, hairline-bordered surface - the container the table and
/// other grouped content sit on. Styling comes from `UtopiaThemeData.cardDecoration`
/// and `cardBorderDecoration`, so it stays themable from one place.
class UtopiaCard extends StatelessWidget {
  /// The content laid over the card decoration.
  final Widget child;

  /// Creates a card surface around [child].
  const UtopiaCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: context.theme.cardDecoration,
      foregroundDecoration: context.theme.cardBorderDecoration,
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

/// The sliver counterpart of [UtopiaCard]: wraps [sliver] in the card chrome -
/// a filled, rounded, shadowed back layer plus a foreground hairline border.
///
/// Unlike a plain [DecoratedSliver], the chrome hugs the sliver's *visible*
/// extent. The bottom corners round only while the sliver's true content end
/// is on screen: while more rows continue past the viewport, the card runs
/// square to the cut and the hairline border stays open along the bottom -
/// a rounded-off edge there would read as the table ending when it hasn't.
Widget utopiaCardSliver(BuildContext context, {required Widget sliver}) {
  final theme = context.theme;
  return _SliverCardChrome(
    color: theme.colors.surface,
    shadow: theme.cardShadow,
    borderColor: theme.colors.border,
    borderWidth: theme.cardBorderWidth,
    radius: theme.cardRadius,
    child: sliver,
  );
}

class _SliverCardChrome extends SingleChildRenderObjectWidget {
  final Color color;
  final List<BoxShadow> shadow;
  final Color borderColor;
  final double borderWidth;
  final BorderRadius radius;

  const _SliverCardChrome({
    required this.color,
    required this.shadow,
    required this.borderColor,
    required this.borderWidth,
    required this.radius,
    required Widget child,
  }) : super(child: child);

  @override
  _RenderSliverCardChrome createRenderObject(BuildContext context) => _RenderSliverCardChrome(
    color: color,
    shadow: shadow,
    borderColor: borderColor,
    borderWidth: borderWidth,
    radius: radius,
  );

  @override
  void updateRenderObject(BuildContext context, _RenderSliverCardChrome renderObject) {
    renderObject
      ..color = color
      ..shadow = shadow
      ..borderColor = borderColor
      ..borderWidth = borderWidth
      ..radius = radius;
  }
}

/// Paints the card chrome over the child sliver's currently painted extent
/// and clips the child to the rounded rect, so the card's corners follow the
/// viewport edges instead of the (possibly off-screen) content edges.
class _RenderSliverCardChrome extends RenderProxySliver {
  Color _color;
  List<BoxShadow> _shadow;
  Color _borderColor;
  double _borderWidth;
  BorderRadius _radius;

  _RenderSliverCardChrome({
    required Color color,
    required List<BoxShadow> shadow,
    required Color borderColor,
    required double borderWidth,
    required BorderRadius radius,
  }) : _color = color,
       _shadow = shadow,
       _borderColor = borderColor,
       _borderWidth = borderWidth,
       _radius = radius;

  Color get color => _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  List<BoxShadow> get shadow => _shadow;
  set shadow(List<BoxShadow> value) {
    if (value == _shadow) return;
    _shadow = value;
    markNeedsPaint();
  }

  Color get borderColor => _borderColor;
  set borderColor(Color value) {
    if (value == _borderColor) return;
    _borderColor = value;
    markNeedsPaint();
  }

  double get borderWidth => _borderWidth;
  set borderWidth(double value) {
    if (value == _borderWidth) return;
    _borderWidth = value;
    markNeedsPaint();
  }

  BorderRadius get radius => _radius;
  set radius(BorderRadius value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    final geometry = child?.geometry;
    if (child == null || geometry == null || !geometry.visible) return;

    // The chrome tracks what is actually on screen this frame: from the
    // sliver's paint origin down to its painted extent.
    final rect = offset & Size(constraints.crossAxisExtent, geometry.paintExtent);

    // The bottom corners round only when the sliver's *content* end is
    // painted this frame - i.e. the painted extent reaches the scroll extent.
    // While rows continue past the viewport, the card runs square to the cut
    // so the edge doesn't read as the table's end (half-tolerance absorbs
    // float error in the sliver protocol's extents).
    final endVisible = constraints.scrollOffset + geometry.paintExtent >= geometry.scrollExtent - 0.5;
    final radius = endVisible
        ? _radius
        : BorderRadius.only(topLeft: _radius.topLeft, topRight: _radius.topRight);
    final rrect = radius.toRRect(rect);

    // NOTE: context.canvas must be re-read for every draw and never cached
    // across pushClipRRect - pushing a (possibly compositing) layer ends the
    // current picture recording, and drawing on the stale canvas crashes the
    // rasteriser ("null function" in CanvasKit).
    for (final boxShadow in _shadow) {
      context.canvas.drawRRect(
        radius.toRRect(rect.shift(boxShadow.offset).inflate(boxShadow.spreadRadius)),
        boxShadow.toPaint(),
      );
    }
    context.canvas.drawRRect(rrect, Paint()..color = _color);

    // Rows slide under the corner curves instead of poking out of them.
    context.pushClipRRect(needsCompositing, offset, rect.shift(-offset), rrect.shift(-offset), (
      innerContext,
      innerOffset,
    ) {
      innerContext.paintChild(child, innerOffset);
    });

    // Hairline on top of the content, inset so the stroke stays inside the
    // rounded silhouette. While the content continues past the cut, the
    // stroke is an open path (left, top, right - no bottom edge), so no line
    // suggests the table ends where the viewport does.
    final border = rrect.deflate(_borderWidth / 2);
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth
      ..color = _borderColor;
    if (endVisible) {
      context.canvas.drawRRect(border, borderPaint);
    } else {
      final path = Path()
        ..moveTo(border.left, rect.bottom)
        ..lineTo(border.left, border.top + border.tlRadiusY)
        ..arcToPoint(Offset(border.left + border.tlRadiusX, border.top), radius: border.tlRadius)
        ..lineTo(border.right - border.trRadiusX, border.top)
        ..arcToPoint(Offset(border.right, border.top + border.trRadiusY), radius: border.trRadius)
        ..lineTo(border.right, rect.bottom);
      context.canvas.drawPath(path, borderPaint);
    }
  }
}
