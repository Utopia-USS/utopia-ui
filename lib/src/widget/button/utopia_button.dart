import 'package:flutter/material.dart';
import 'package:utopia_ui/src/util/utopia_context_extensions.dart';
import 'package:utopia_ui/src/widget/layout/utopia_gradient_background.dart';
import 'package:utopia_ui/src/widget/loading/utopia_three_bounce.dart';

/// The primary call-to-action button: a gradient-filled, rounded surface with
/// an inline loading state.
class UtopiaButton extends StatelessWidget {
  /// The button's content, styled with `UtopiaThemeTextStyles.button`.
  final Widget child;

  /// Called on tap, while [isEnabled] is `true`.
  final void Function() onTap;

  /// Whether the button responds to taps; visually dims via [UtopiaGradientBackground] when `false`.
  final bool isEnabled;

  /// Replaces [child] with a [UtopiaThreeBounce] indicator while `true`.
  final bool loading;

  /// Uses a shorter fixed extent (10x instead of 15x the token base - 40
  /// instead of 60 by default) when [height] is not set.
  final bool dense;

  /// Upper bound on the button's width.
  final double maxWidth;

  /// Overrides the default primary/accent gradient.
  final List<Color>? colors;

  /// Overrides the fixed square extent (min/max height and min width). Defaults
  /// to 10x the token base when [dense] (40), 15x otherwise (60, matching a
  /// resting field's total height). Pair with [maxWidth] == [height] for a
  /// square icon button.
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
    final x = context.tokens.x;
    final extent = height ?? (dense ? x * 10 : x * 15);
    // Default sweep stops halfway from primary to accent - a full
    // primary -> accent run reads too loud for a flat button surface.
    final themeColors = context.colors;
    final gradient =
        colors ?? [themeColors.primary, Color.lerp(themeColors.primary, themeColors.accent, 0.5)!];
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: extent, maxHeight: extent, minWidth: extent, maxWidth: maxWidth),
      child: UtopiaGradientBackground(
        colors: gradient,
        clipBehavior: Clip.antiAlias,
        borderRadius: context.theme.borderRadius,
        isEnabled: isEnabled,
        // The Material sits INSIDE the gradient (not around it) so the
        // hover/press overlay paints on top of the gradient fill - an InkWell
        // around the gradient draws its ink underneath and stays invisible.
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            hoverColor: context.colors.onColoredHover,
            child: Center(heightFactor: 1, child: _buildTitle(context)),
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
