import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/foundation.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/layout/utopia_gradient_background.dart';
import 'package:utopia_ui/src/widget/loading/utopia_three_bounce.dart';

/// The primary call-to-action button: a gradient-filled, rounded surface with
/// an inline loading state.
///
/// Its three interactive states are deliberately restrained. Hover slides the
/// whole gradient sweep half a step down the primary -> accent axis (a real
/// colour step, not a translucent overlay). Press answers with geometry -
/// a 2% scale-down - rather than another colour. Focus draws a solid ring
/// with a gap, the keyboard-only affordance; nothing lifts or casts a shadow
/// at rest.
class UtopiaButton extends HookWidget {
  /// The button's content, styled with `UtopiaThemeTextStyles.button`.
  final Widget child;

  /// Called on tap, while [isEnabled] is `true`.
  final void Function() onTap;

  /// Whether the button responds to taps; visually dims via [UtopiaGradientBackground] when `false`.
  final bool isEnabled;

  /// Replaces [child] with a [UtopiaThreeBounce] indicator while `true`.
  final bool loading;

  /// Uses a shorter fixed extent (10x instead of 12x the token base - 40
  /// instead of 48 by default) when [height] is not set.
  final bool dense;

  /// Upper bound on the button's width.
  final double maxWidth;

  /// Overrides the default primary/accent gradient.
  final List<Color>? colors;

  /// Overrides the fixed square extent (min/max height and min width). Defaults
  /// to 10x the token base when [dense] (40, matching a dense field), 12x
  /// otherwise (48, matching a resting field's total height - content floor,
  /// vertical padding and both hairline borders). Pair with [maxWidth] ==
  /// [height] for a square icon button.
  final double? height;

  /// Creates the primary call-to-action button.
  const UtopiaButton({
    super.key,
    required this.child,
    required this.onTap,
    this.isEnabled = true,
    this.loading = false,
    this.dense = false,
    this.maxWidth = 300,
    this.colors,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final x = tokens.x;
    final extent = height ?? (dense ? x * 10 : x * 12);
    final themeColors = context.colors;
    final borderRadius = context.theme.borderRadius;
    final isHovered = useState<bool>(false);
    final isPressed = useState<bool>(false);
    final isFocused = useState<bool>(false);

    // Half a step along the primary -> accent axis. The resting sweep runs
    // from primary to that midpoint (a full primary -> accent run reads too
    // loud for a flat button surface); hover slides the whole sweep down by
    // that same half step, so the surface darkens by a real colour step
    // instead of a translucent film.
    final sweepMid = Color.lerp(themeColors.primary, themeColors.accent, 0.5)!;
    final gradient = colors ?? [themeColors.primary, sweepMid];
    final hoverGradient = colors ?? [sweepMid, themeColors.accent];
    final showHover = isEnabled && isHovered.value;

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: extent, maxHeight: extent, minWidth: extent, maxWidth: maxWidth),
      child: AnimatedScale(
        // Press is answered with geometry, not another colour: the surface
        // yields 2% under the pointer and springs back.
        scale: isPressed.value ? 0.98 : 1,
        duration: tokens.durations.xs,
        child: AnimatedContainer(
          duration: tokens.durations.sm,
          // The focus ring is a pair of hard-edged shadows rather than a
          // border, so it costs no layout: the wider primary ring paints
          // first and the surface-coloured gap paints over its inner band,
          // leaving a `borders.thick` gap and a `borders.thick` ring. The gap
          // is opaque here where the twin's `outline-offset` is transparent,
          // so it is painted in `surface` - the colour buttons sit on most
          // often (cards, dialogs).
          decoration: BoxDecoration(
            borderRadius: borderRadius,
            boxShadow: isFocused.value
                ? [
                    BoxShadow(color: themeColors.primary, spreadRadius: tokens.borders.thick * 2),
                    BoxShadow(color: themeColors.surface, spreadRadius: tokens.borders.thick),
                  ]
                : const [],
          ),
          child: UtopiaGradientBackground(
            colors: gradient,
            clipBehavior: Clip.antiAlias,
            borderRadius: borderRadius,
            isEnabled: isEnabled,
            // The Material sits INSIDE the gradient (not around it) so the
            // press ripple paints on top of the gradient fill - an InkWell
            // around the gradient draws its ink underneath and stays
            // invisible.
            child: Stack(
              fit: StackFit.expand,
              children: [
                // The hover sweep is a second gradient layer cross-faded in
                // at `durations.sm`, rather than new `colors` handed to the
                // layer below: that layer animates at `durations.xl`, the
                // pace the enabled/disabled crossfade needs and far too slow
                // for a pointer.
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: showHover ? 1 : 0,
                    duration: tokens.durations.sm,
                    child: UtopiaGradientBackground(colors: hoverGradient, child: const SizedBox.shrink()),
                  ),
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isEnabled ? onTap : null,
                    // Hover is a gradient step now, not an ink overlay -
                    // without this the InkWell would fall back to the ambient
                    // Material theme's grey hover film on top of it.
                    hoverColor: Colors.transparent,
                    onHover: (value) => isHovered.value = value,
                    onHighlightChanged: (value) => isPressed.value = value,
                    onFocusChange: (value) => isFocused.value = value,
                    child: Center(heightFactor: 1, child: _buildTitle(context)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final style = context.textStyles.button;
    final content = IconTheme.merge(
      data: IconThemeData(color: style.color),
      child: DefaultTextStyle(style: style, child: child),
    );
    if (!loading) return content;
    // The label stays in the tree (invisible) so the button keeps its exact
    // label-driven size - swapping it out for the loader would let
    // intrinsic-width buttons (e.g. IntrinsicWidth-wrapped CTAs) jump.
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(opacity: 0, child: content),
        UtopiaThreeBounce(color: style.color),
      ],
    );
  }
}
